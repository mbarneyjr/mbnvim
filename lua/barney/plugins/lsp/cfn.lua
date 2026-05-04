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
    vim.schedule(function()
      coroutine.resume(co, choice)
    end)
  end)
  return coroutine.yield()
end

local function cfn_input(prompt)
  local co = coroutine.running()
  vim.ui.input({ prompt = prompt }, function(input)
    vim.schedule(function()
      coroutine.resume(co, input)
    end)
  end)
  return coroutine.yield()
end

local awsuse_dir = vim.fn.expand("~/.aws/awsuse")
local awsuse_config = awsuse_dir .. "/config"
local awsuse_credentials = awsuse_dir .. "/credentials"

local credentials = nil
local pending_imports = {}

local function extract_logical_ids(text)
  local lines = vim.split(text, "\n", { plain = true })
  local ids = {}
  for i, line in ipairs(lines) do
    local type_indent = line:match("^(%s*)Type:%s*['\"]?AWS::")
    if type_indent then
      local type_indent_len = #type_indent
      for j = i - 1, 1, -1 do
        local prev_indent, prev_key = lines[j]:match("^(%s*)([%w_-]+):%s*$")
        if prev_indent and prev_key and #prev_indent < type_indent_len then
          table.insert(ids, prev_key)
          break
        end
      end
    end
  end
  return ids
end

local function aws_env()
  if not credentials then
    return nil
  end
  local env = {
    "AWS_CONFIG_FILE=" .. awsuse_config,
    "AWS_SHARED_CREDENTIALS_FILE=" .. awsuse_credentials,
    "AWS_REGION=" .. credentials.region,
    "AWS_DEFAULT_REGION=" .. credentials.region,
    "AWS_ACCESS_KEY_ID=" .. credentials.accessKeyId,
    "AWS_SECRET_ACCESS_KEY=" .. credentials.secretAccessKey,
  }
  if credentials.sessionToken and credentials.sessionToken ~= "" then
    table.insert(env, "AWS_SESSION_TOKEN=" .. credentials.sessionToken)
  end
  return env
end

local function get_resource_at_cursor(client, bufnr)
  local result = client:request_sync("textDocument/documentSymbol", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
  }, 5000, bufnr)
  if not result or not result.result then
    return nil
  end

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return nil
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  for _, section in ipairs(result.result) do
    if section.kind == vim.lsp.protocol.SymbolKind.Namespace then
      for _, resource in ipairs(section.children or {}) do
        local range = resource.range
        if row >= range.start.line and row <= range["end"].line then
          local logical_id, resource_type = resource.name:match("^(.-)%s*%((.+)%)$")
          if logical_id and resource_type then
            return { logicalId = logical_id, resourceType = resource_type }
          end
        end
      end
    end
  end
  return nil
end

local function get_resource_type_at_cursor(client, bufnr)
  local r = get_resource_at_cursor(client, bufnr)
  return r and r.resourceType or nil
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
  credentials = {
    profile = profile,
    accessKeyId = access_key_id,
    secretAccessKey = secret_access_key,
    sessionToken = session_token,
    region = region,
  }

  local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
  if not client then
    return
  end

  local payload = vim.json.encode({
    data = {
      profile = profile,
      accessKeyId = access_key_id,
      secretAccessKey = secret_access_key,
      sessionToken = session_token,
      region = region,
    },
  })

  local jwe = vim.fn.system({ "node", jwe_script, encryption_key }, payload)
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
  credentials = nil
  local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
  if not client then
    return
  end
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
    if not purpose then
      return
    end

    local types_result = cfn_request(client, "aws/cfn/resources/types", {}, bufnr)
    if not types_result or not types_result.resourceTypes or #types_result.resourceTypes == 0 then
      vim.notify("No resource types available", vim.log.levels.WARN)
      return
    end

    local resource_type = cfn_select(types_result.resourceTypes, "Resource type:")
    if not resource_type then
      return
    end

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
    if not identifier then
      return
    end

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

    if not result then
      return
    end

    if result.completionItem and result.completionItem.textEdit then
      local edit = result.completionItem.textEdit
      local lines = vim.split(edit.newText, "\n")
      local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
      local start_line = math.min(edit.range.start.line, buf_line_count)
      local end_line = math.min(edit.range["end"].line, buf_line_count)
      if start_line >= buf_line_count then
        vim.api.nvim_buf_set_lines(bufnr, buf_line_count, buf_line_count, false, lines)
      else
        vim.api.nvim_buf_set_text(
          bufnr,
          start_line,
          edit.range.start.character,
          end_line,
          edit.range["end"].character,
          lines
        )
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
      local logical_ids = {}
      if purpose == "Import" and result.completionItem and result.completionItem.textEdit then
        logical_ids = extract_logical_ids(result.completionItem.textEdit.newText)
      end
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      local logical_idx = 1
      for rt, ids in pairs(result.successfulImports) do
        if #ids > 0 then
          vim.notify(purpose .. "d " .. rt .. ": " .. table.concat(ids, ", "))
          if purpose == "Import" and template_path ~= "" then
            pending_imports[template_path] = pending_imports[template_path] or {}
            for _, ident in ipairs(ids) do
              table.insert(pending_imports[template_path], {
                logicalId = logical_ids[logical_idx],
                resourceType = rt,
                identifier = ident,
              })
              logical_idx = logical_idx + 1
            end
          end
        end
      end
    end
  end)()
end, { desc = "Import/clone a live AWS resource into template" })

vim.api.nvim_create_user_command("CfnImportMark", function()
  coroutine.wrap(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end

    local client = vim.lsp.get_clients({ name = "cfn-lsp-server" })[1]
    if not client then
      vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
      return
    end

    local resource = get_resource_at_cursor(client, bufnr)
    if not resource then
      vim.notify("No resource at cursor", vim.log.levels.WARN)
      return
    end

    local existing = pending_imports[template_path] or {}
    for i, imp in ipairs(existing) do
      if imp.logicalId == resource.logicalId and imp.resourceType == resource.resourceType then
        table.remove(existing, i)
        if #existing == 0 then
          pending_imports[template_path] = nil
        end
        vim.notify("Unmarked " .. resource.logicalId .. " (" .. resource.resourceType .. ")")
        return
      end
    end

    local list_result = cfn_request(client, "aws/cfn/resources/list", {
      resources = { { resourceType = resource.resourceType } },
    }, bufnr)
    if not list_result or not list_result.resources or #list_result.resources == 0 then
      vim.notify("No live resources found for " .. resource.resourceType, vim.log.levels.WARN)
      return
    end

    local identifiers = list_result.resources[1].resourceIdentifiers or {}
    if #identifiers == 0 then
      vim.notify("No live resources found for " .. resource.resourceType, vim.log.levels.WARN)
      return
    end

    local identifier = cfn_select(identifiers, "Identifier for " .. resource.logicalId .. ":")
    if not identifier then
      return
    end

    pending_imports[template_path] = pending_imports[template_path] or {}
    table.insert(pending_imports[template_path], {
      logicalId = resource.logicalId,
      resourceType = resource.resourceType,
      identifier = identifier,
    })
    vim.notify("Marked " .. resource.logicalId .. " (" .. resource.resourceType .. ") for import")
  end)()
end, { desc = "Mark resource at cursor for import in change set" })

vim.api.nvim_create_user_command("CfnImportList", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local template_path = vim.api.nvim_buf_get_name(bufnr)
  if template_path == "" then
    vim.notify("Buffer has no file path", vim.log.levels.ERROR)
    return
  end
  local imports = pending_imports[template_path]
  if not imports or #imports == 0 then
    vim.notify("No pending imports for this template")
    return
  end
  local lines = { "Pending imports for " .. vim.fn.fnamemodify(template_path, ":~:.") .. ":" }
  for _, imp in ipairs(imports) do
    local ident
    if type(imp.identifier) == "table" then
      ident = vim.json.encode(imp.identifier)
    else
      ident = tostring(imp.identifier)
    end
    table.insert(lines, "  - " .. (imp.logicalId or "?") .. " (" .. imp.resourceType .. ") — " .. ident)
  end
  vim.notify(table.concat(lines, "\n"))
end, { desc = "List resources marked for import in current template" })

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
      if not resource_type then
        return
      end
    end

    local related = cfn_request(client, "aws/cfn/template/resources/related", {
      parentResourceType = resource_type,
    }, bufnr)
    if not related or #related == 0 then
      vim.notify("No related resources for " .. resource_type)
      return
    end

    local choice = cfn_select(related, "Insert related resource:")
    if not choice then
      return
    end

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

vim.api.nvim_create_user_command("CfnImportChangeSet", function()
  coroutine.wrap(function()
    local env = aws_env()
    if not env then
      vim.notify("No AWS credentials. Run :Awsuse first.", vim.log.levels.WARN)
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end

    local imports = pending_imports[template_path]
    if not imports or #imports == 0 then
      vim.notify("No pending imports for this template. Run :CfnImport first.", vim.log.levels.WARN)
      return
    end

    local stack_name = cfn_input("Stack name: ")
    if not stack_name or stack_name == "" then
      return
    end

    local capability_presets = {
      { label = "CAPABILITY_NAMED_IAM", value = { "CAPABILITY_NAMED_IAM" } },
      { label = "CAPABILITY_IAM", value = { "CAPABILITY_IAM" } },
      {
        label = "CAPABILITY_NAMED_IAM + CAPABILITY_AUTO_EXPAND",
        value = { "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND" },
      },
      { label = "None", value = {} },
    }
    local co = coroutine.running()
    vim.ui.select(capability_presets, {
      prompt = "Capabilities:",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      vim.schedule(function()
        coroutine.resume(co, choice)
      end)
    end)
    local capability_choice = coroutine.yield()
    if not capability_choice then
      return
    end
    local capabilities = capability_choice.value

    local summary_cmd = { "env" }
    vim.list_extend(summary_cmd, env)
    vim.list_extend(summary_cmd, {
      "aws",
      "cloudformation",
      "get-template-summary",
      "--template-body",
      "file://" .. template_path,
    })
    local summary_output = vim.fn.system(summary_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("get-template-summary failed: " .. summary_output, vim.log.levels.ERROR)
      return
    end
    local summary = vim.json.decode(summary_output)
    local id_keys = {}
    for _, ris in ipairs((summary or {}).ResourceIdentifierSummaries or {}) do
      id_keys[ris.ResourceType] = (ris.ResourceIdentifiers or {})[1]
    end

    local resources_to_import = {}
    for _, imp in ipairs(imports) do
      if not imp.logicalId then
        vim.notify("Missing logical ID for " .. imp.resourceType, vim.log.levels.ERROR)
        return
      end
      local rid
      if type(imp.identifier) == "table" then
        rid = imp.identifier
      else
        local key = id_keys[imp.resourceType]
        if not key then
          vim.notify("No identifier key found for " .. imp.resourceType, vim.log.levels.ERROR)
          return
        end
        rid = { [key] = imp.identifier }
      end
      table.insert(resources_to_import, {
        ResourceType = imp.resourceType,
        LogicalResourceId = imp.logicalId,
        ResourceIdentifier = rid,
      })
    end

    local change_set_name = stack_name .. "-import-" .. os.date("%Y%m%d-%H%M%S")
    local cs_cmd = { "env" }
    vim.list_extend(cs_cmd, env)
    vim.list_extend(cs_cmd, {
      "aws",
      "cloudformation",
      "create-change-set",
      "--stack-name",
      stack_name,
      "--change-set-name",
      change_set_name,
      "--change-set-type",
      "IMPORT",
      "--template-body",
      "file://" .. template_path,
      "--resources-to-import",
      vim.json.encode(resources_to_import),
    })
    if #capabilities > 0 then
      table.insert(cs_cmd, "--capabilities")
      vim.list_extend(cs_cmd, capabilities)
    end

    local cs_output = vim.fn.system(cs_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("create-change-set failed: " .. cs_output, vim.log.levels.ERROR)
      return
    end

    local cs_result = vim.json.decode(cs_output)
    if cs_result and cs_result.Id and cs_result.StackId then
      local url = string.format(
        "https://%s.console.aws.amazon.com/cloudformation/home?region=%s#/stacks/changesets/changes?stackId=%s&changeSetId=%s",
        credentials.region,
        credentials.region,
        cs_result.StackId,
        cs_result.Id
      )
      vim.notify("Created change set: " .. change_set_name .. "\n" .. url)
      vim.ui.open(url)
    else
      vim.notify("Created change set: " .. change_set_name)
    end
    pending_imports[template_path] = nil
  end)()
end, { desc = "Create CFN import change set from pending imports" })

return M
