local M = {}

local encryption_key = vim.fn.system("openssl rand -base64 32"):gsub("%s+$", "")

local jwe_script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/cfn-jwe.mjs"

local function cfn_request(client, method, params, bufnr)
  local co = coroutine.running()
  client:request(method, params, function(err, result)
    vim.schedule(function()
      if err then
        vim.notify("CFN LSP error: " .. err.message, vim.log.levels.ERROR)
        coroutine.resume(co, nil)
      else
        coroutine.resume(co, result)
      end
    end)
  end, bufnr)
  return coroutine.yield()
end

local function cfn_select(items, prompt)
  local co = coroutine.running()
  vim.ui.select(items, { prompt = prompt }, function(choice)
    vim.schedule(function() coroutine.resume(co, choice) end)
  end)
  return coroutine.yield()
end

local function get_resource_type_at_cursor(client, bufnr)
  local result = client:request_sync("textDocument/documentSymbol", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
  }, 5000, bufnr)
  if not result or not result.result then return nil end

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then return nil end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  for _, section in ipairs(result.result) do
    if section.kind == vim.lsp.protocol.SymbolKind.Namespace then
      for _, resource in ipairs(section.children or {}) do
        local range = resource.range
        if row >= range.start.line and row <= range["end"].line then
          return resource.name:match("%((.+)%)$")
        end
      end
    end
  end
  return nil
end

vim.lsp.config("cfn-lsp-server", {
  cmd = { "cfn-lsp-server", "--stdio" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  root_markers = { ".git" },
  init_options = {
    aws = {
      encryption = {
        key = encryption_key,
      },
    },
  },
  settings = {
    editor = {
      detectIndentation = true,
    },
    aws = {
      cloudformation = {
        diagnostics = {
          cfnGuard = {
            enabled = true,
            enabledRulePacks = {},
          },
        },
      },
    },
  },
})
vim.lsp.enable("cfn-lsp-server")

function M.push_credentials(profile, access_key_id, secret_access_key, session_token, region)
  local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
  if not client then return end

  local payload = vim.json.encode({
    data = {
      profile = profile,
      accessKeyId = access_key_id,
      secretAccessKey = secret_access_key,
      sessionToken = session_token,
      region = region,
    },
  })

  local jwe = vim.fn.system(
    { "node", jwe_script, encryption_key },
    payload
  )
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to encrypt credentials: " .. jwe, vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  client:request("aws/credentials/iam/update", {
    data = jwe,
    encrypted = true,
  }, function(err, result)
    if err then
      vim.notify("CFN credential update failed: " .. err.message, vim.log.levels.ERROR)
    end
  end, bufnr)
end

function M.clear_credentials()
  local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
  if not client then return end
  client:notify("aws/credentials/iam/delete")
end

vim.api.nvim_create_user_command("CfnImport", function()
  coroutine.wrap(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local uri = vim.uri_from_bufnr(bufnr)
    local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
    if not client then
      vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
      return
    end

    local purpose = cfn_select({ "Import", "Clone" }, "Purpose:")
    if not purpose then return end

    local types_result = cfn_request(client, "aws/cfn/resources/types", {}, bufnr)
    if not types_result or not types_result.resourceTypes or #types_result.resourceTypes == 0 then
      vim.notify("No resource types available", vim.log.levels.WARN)
      return
    end

    local resource_type = cfn_select(types_result.resourceTypes, "Resource type:")
    if not resource_type then return end

    local list_result = cfn_request(client, "aws/cfn/resources/list", {
      resources = { { resourceType = resource_type } },
    }, bufnr)
    if not list_result or not list_result.resources or #list_result.resources == 0 then
      vim.notify("No resources found for " .. resource_type, vim.log.levels.WARN)
      return
    end

    local identifiers = list_result.resources[1].resourceIdentifiers or {}
    if #identifiers == 0 then
      vim.notify("No resources found for " .. resource_type, vim.log.levels.WARN)
      return
    end

    local identifier = cfn_select(identifiers, "Select resource:")
    if not identifier then return end

    local result = cfn_request(client, "aws/cfn/resources/state", {
      textDocument = { uri = uri },
      resourceSelections = {
        {
          resourceType = resource_type,
          resourceIdentifiers = { identifier },
        },
      },
      purpose = purpose,
    }, bufnr)

    if not result then return end

    if result.completionItem and result.completionItem.textEdit then
      local edit = result.completionItem.textEdit
      local lines = vim.split(edit.newText, "\n")
      local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
      local start_line = math.min(edit.range.start.line, buf_line_count)
      local end_line = math.min(edit.range["end"].line, buf_line_count)
      if start_line >= buf_line_count then
        vim.api.nvim_buf_set_lines(bufnr, buf_line_count, buf_line_count, false, lines)
      else
        vim.api.nvim_buf_set_text(bufnr,
          start_line, edit.range.start.character,
          end_line, edit.range["end"].character,
          lines)
      end
    end

    if result.warning then
      vim.notify(result.warning, vim.log.levels.WARN)
    end

    if result.failedImports then
      for rt, ids in pairs(result.failedImports) do
        if #ids > 0 then
          vim.notify("Failed to import " .. rt .. ": " .. table.concat(ids, ", "), vim.log.levels.ERROR)
        end
      end
    end

    if result.successfulImports then
      for rt, ids in pairs(result.successfulImports) do
        if #ids > 0 then
          vim.notify(purpose .. "d " .. rt .. ": " .. table.concat(ids, ", "))
        end
      end
    end
  end)()
end, { desc = "Import/clone a live AWS resource into template" })

vim.api.nvim_create_user_command("CfnRelatedResources", function()
  coroutine.wrap(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local uri = vim.uri_from_bufnr(bufnr)
    local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
    if not client then
      vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
      return
    end

    local resource_type = get_resource_type_at_cursor(client, bufnr)
    if not resource_type then
      local authored = cfn_request(client, "aws/cfn/template/resources/authored", uri, bufnr)
      if not authored or #authored == 0 then
        vim.notify("No resources found in template")
        return
      end
      resource_type = cfn_select(authored, "Select parent resource:")
      if not resource_type then return end
    end

    local related = cfn_request(client, "aws/cfn/template/resources/related", {
      parentResourceType = resource_type,
    }, bufnr)
    if not related or #related == 0 then
      vim.notify("No related resources for " .. resource_type)
      return
    end

    local choice = cfn_select(related, "Insert related resource:")
    if not choice then return end

    local result = cfn_request(client, "aws/cfn/template/resources/insert", {
      templateUri = uri,
      parentResourceType = resource_type,
      relatedResourceTypes = { choice },
    }, bufnr)
    if result and result.edit then
      vim.lsp.util.apply_workspace_edit(result.edit, "utf-8")
    end
  end)()
end, {})

return M
