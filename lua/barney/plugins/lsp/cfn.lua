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
