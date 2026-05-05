local M = {}

local state = require("cfn.state")
local helper = require("cfn.helper")
local lsp = require("cfn.lsp")
local registrations = require("cfn.registrations")

local function ui_select(items, opts)
  local co = coroutine.running()
  vim.ui.select(items, opts or {}, function(choice)
    vim.schedule(function()
      coroutine.resume(co, choice)
    end)
  end)
  return coroutine.yield()
end

local function ui_input(opts)
  local co = coroutine.running()
  vim.ui.input(opts or {}, function(input)
    vim.schedule(function()
      coroutine.resume(co, input)
    end)
  end)
  return coroutine.yield()
end

local function lsp_request(client, method, params, bufnr)
  local co = coroutine.running()
  client:request(method, params, function(err, result)
    vim.schedule(function()
      if err then
        vim.notify("cfn.nvim LSP error: " .. err.message, vim.log.levels.ERROR)
        coroutine.resume(co, nil)
      else
        coroutine.resume(co, result)
      end
    end)
  end, bufnr)
  return coroutine.yield()
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

local function complete_profiles(arglead)
  local out, err = helper.run({ "credentials", "list-profiles" })
  if err then
    return {}
  end
  local list = vim.json.decode(out) or {}
  return vim.tbl_filter(function(v)
    return vim.startswith(v, arglead)
  end, list)
end

function M.register()
  vim.api.nvim_create_user_command("CfnSetProfile", function(opts)
    coroutine.wrap(function()
      local profile = opts.fargs[1]
      local region_override = opts.fargs[2]
      if not profile then
        vim.notify("Usage: :CfnSetProfile <profile> [region]", vim.log.levels.ERROR)
        return
      end

      local args = {
        "credentials",
        "resolve",
        "--profile",
        profile,
        "--jwe-key",
        state.encryption_key,
      }
      if region_override then
        table.insert(args, "--region")
        table.insert(args, region_override)
      end

      local out, err = helper.run(args)
      if err then
        vim.notify("CfnSetProfile failed: " .. err, vim.log.levels.ERROR)
        return
      end

      local result = vim.json.decode(out)
      if not result or not result.jwe then
        vim.notify("CfnSetProfile: invalid response from helper", vim.log.levels.ERROR)
        return
      end

      if not lsp.push_credentials_jwe(result.jwe) then
        vim.notify("CfnSetProfile: no LSP client attached", vim.log.levels.WARN)
        return
      end

      state.active_profile = profile
      state.active_region = result.region
      state.active_account = result.account
      vim.notify(
        "cfn.nvim: using "
          .. profile
          .. " ("
          .. (result.region or "?")
          .. (result.account and (", account " .. result.account) or "")
          .. ")"
      )
    end)()
  end, {
    nargs = "+",
    complete = function(arglead, cmdline)
      local args = vim.split(cmdline, "%s+")
      if #args <= 2 then
        return complete_profiles(arglead)
      end
      return {}
    end,
    desc = "Set the active AWS profile and push credentials to the LSP",
  })

  vim.api.nvim_create_user_command("CfnClearProfile", function()
    lsp.clear_credentials()
    state.active_profile = nil
    state.active_region = nil
    state.active_account = nil
    vim.notify("cfn.nvim: credentials cleared")
  end, { desc = "Clear the active profile and credentials from the LSP" })

  vim.api.nvim_create_user_command("CfnImport", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local uri = vim.uri_from_bufnr(bufnr)
      local client = lsp.client()
      if not client then
        vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
        return
      end

      local purpose = ui_select({ "Import", "Clone" }, { prompt = "Purpose:" })
      if not purpose then
        return
      end

      local types_result = lsp_request(client, "aws/cfn/resources/types", {}, bufnr)
      if not types_result or not types_result.resourceTypes or #types_result.resourceTypes == 0 then
        vim.notify("No resource types available", vim.log.levels.WARN)
        return
      end

      local resource_type = ui_select(types_result.resourceTypes, { prompt = "Resource type:" })
      if not resource_type then
        return
      end

      local list_result = lsp_request(client, "aws/cfn/resources/list", {
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

      local identifier = ui_select(identifiers, { prompt = "Select resource:" })
      if not identifier then
        return
      end

      local result = lsp_request(client, "aws/cfn/resources/state", {
        textDocument = { uri = uri },
        resourceSelections = {
          { resourceType = resource_type, resourceIdentifiers = { identifier } },
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
        local idx = 1
        for rt, ids in pairs(result.successfulImports) do
          if #ids > 0 then
            vim.notify(purpose .. "d " .. rt .. ": " .. table.concat(ids, ", "))
            if purpose == "Import" and template_path ~= "" then
              state.pending_imports[template_path] = state.pending_imports[template_path] or {}
              for _, ident in ipairs(ids) do
                table.insert(state.pending_imports[template_path], {
                  logicalId = logical_ids[idx],
                  resourceType = rt,
                  identifier = ident,
                })
                idx = idx + 1
              end
            end
          end
        end
      end
    end)()
  end, { desc = "Import or clone a live AWS resource into the current template" })

  vim.api.nvim_create_user_command("CfnImportMark", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end

      local client = lsp.client()
      if not client then
        vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
        return
      end

      local resource = get_resource_at_cursor(client, bufnr)
      if not resource then
        vim.notify("No resource at cursor", vim.log.levels.WARN)
        return
      end

      local existing = state.pending_imports[template_path] or {}
      for i, imp in ipairs(existing) do
        if imp.logicalId == resource.logicalId and imp.resourceType == resource.resourceType then
          table.remove(existing, i)
          if #existing == 0 then
            state.pending_imports[template_path] = nil
          end
          vim.notify("Unmarked " .. resource.logicalId .. " (" .. resource.resourceType .. ")")
          return
        end
      end

      local list_result = lsp_request(client, "aws/cfn/resources/list", {
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

      local identifier = ui_select(identifiers, { prompt = "Identifier for " .. resource.logicalId .. ":" })
      if not identifier then
        return
      end

      state.pending_imports[template_path] = state.pending_imports[template_path] or {}
      table.insert(state.pending_imports[template_path], {
        logicalId = resource.logicalId,
        resourceType = resource.resourceType,
        identifier = identifier,
      })
      vim.notify("Marked " .. resource.logicalId .. " (" .. resource.resourceType .. ") for import")
    end)()
  end, { desc = "Toggle resource at cursor in pending imports" })

  vim.api.nvim_create_user_command("CfnImportList", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end
    local imports = state.pending_imports[template_path]
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
  end, { desc = "List pending imports for the current template" })

  vim.api.nvim_create_user_command("CfnRegister", function(opts)
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      if not state.active_profile or not state.active_account then
        vim.notify("Run :CfnSetProfile <profile> first", vim.log.levels.WARN)
        return
      end
      local stack_name = opts.fargs[1]
      if not stack_name then
        local existing = registrations.get(template_path) or {}
        stack_name = ui_input({ prompt = "Stack name: ", default = existing.stack or "" })
        if not stack_name or stack_name == "" then
          return
        end
      end
      registrations.set(template_path, {
        stack = stack_name,
        account = state.active_account,
        profile = state.active_profile,
      })
      vim.notify(
        "Registered "
          .. vim.fn.fnamemodify(template_path, ":~:.")
          .. " → "
          .. stack_name
          .. " ("
          .. state.active_account
          .. ")"
      )
    end)()
  end, { nargs = "?", desc = "Register current template to a stack" })

  vim.api.nvim_create_user_command("CfnUnregister", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end
    registrations.remove(template_path)
    vim.notify("Unregistered " .. vim.fn.fnamemodify(template_path, ":~:."))
  end, { desc = "Remove the registration for the current template" })

  vim.api.nvim_create_user_command("CfnRegistrations", function()
    vim.cmd("edit " .. vim.fn.fnameescape(registrations.file_path()))
  end, { desc = "Open the cfn.nvim registrations file for editing" })

  vim.api.nvim_create_user_command("CfnImportSubmit", function()
    coroutine.wrap(function()
      if not state.active_profile then
        vim.notify("Run :CfnSetProfile <profile> first", vim.log.levels.WARN)
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end

      local imports = state.pending_imports[template_path]
      if not imports or #imports == 0 then
        vim.notify("No pending imports for this template", vim.log.levels.WARN)
        return
      end

      local existing = registrations.get(template_path)
      if existing and existing.account ~= state.active_account then
        vim.notify(
          string.format(
            "Template registered to account %s (profile %s); current account is %s (profile %s). Run :CfnRegister to update or :CfnSetProfile to switch.",
            existing.account,
            existing.profile,
            state.active_account,
            state.active_profile
          ),
          vim.log.levels.ERROR
        )
        return
      end

      local stack_name = ui_input({
        prompt = "Stack name: ",
        default = existing and existing.stack or "",
      })
      if not stack_name or stack_name == "" then
        return
      end

      if not existing or existing.stack ~= stack_name then
        local save = ui_select({ "Yes", "No" }, {
          prompt = "Register this template to '" .. stack_name .. "'?",
        })
        if save == "Yes" then
          registrations.set(template_path, {
            stack = stack_name,
            account = state.active_account,
            profile = state.active_profile,
          })
        end
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
      local cap_choice = ui_select(capability_presets, {
        prompt = "Capabilities:",
        format_item = function(item)
          return item.label
        end,
      })
      if not cap_choice then
        return
      end

      local payload = {
        stackName = stack_name,
        templatePath = template_path,
        resources = imports,
        capabilities = cap_choice.value,
      }

      local args = {
        "changeset",
        "import",
        "--profile",
        state.active_profile,
        "--region",
        state.active_region,
      }
      local out, err = helper.run(args, vim.json.encode(payload))
      if err then
        vim.notify("CfnImportSubmit failed: " .. err, vim.log.levels.ERROR)
        return
      end

      local result = vim.json.decode(out)
      if result and result.changeSetId and result.stackId then
        local url = string.format(
          "https://%s.console.aws.amazon.com/cloudformation/home?region=%s#/stacks/changesets/changes?stackId=%s&changeSetId=%s",
          state.active_region,
          state.active_region,
          result.stackId,
          result.changeSetId
        )
        vim.notify("Created change set: " .. (result.changeSetName or "") .. "\n" .. url)
        vim.ui.open(url)
      else
        vim.notify("Created change set")
      end
      state.pending_imports[template_path] = nil
    end)()
  end, { desc = "Submit pending imports as an IMPORT change set" })

  vim.api.nvim_create_user_command("CfnRelatedResources", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local uri = vim.uri_from_bufnr(bufnr)
      local client = lsp.client()
      if not client then
        vim.notify("No CFN LSP client attached", vim.log.levels.WARN)
        return
      end

      local cursor = get_resource_at_cursor(client, bufnr)
      local resource_type = cursor and cursor.resourceType
      if not resource_type then
        local authored = lsp_request(client, "aws/cfn/template/resources/authored", uri, bufnr)
        if not authored or #authored == 0 then
          vim.notify("No resources found in template")
          return
        end
        resource_type = ui_select(authored, { prompt = "Select parent resource:" })
        if not resource_type then
          return
        end
      end

      local related = lsp_request(client, "aws/cfn/template/resources/related", {
        parentResourceType = resource_type,
      }, bufnr)
      if not related or #related == 0 then
        vim.notify("No related resources for " .. resource_type)
        return
      end

      local choice = ui_select(related, { prompt = "Insert related resource:" })
      if not choice then
        return
      end

      local result = lsp_request(client, "aws/cfn/template/resources/insert", {
        templateUri = uri,
        parentResourceType = resource_type,
        relatedResourceTypes = { choice },
      }, bufnr)
      if result and result.edit then
        vim.lsp.util.apply_workspace_edit(result.edit, "utf-8")
      end
    end)()
  end, { desc = "Insert resources related to the one at cursor" })
end

return M
