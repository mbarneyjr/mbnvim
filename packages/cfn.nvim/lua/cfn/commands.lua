local M = {}

local state = require("cfn.state")
local helper = require("cfn.helper")
local lsp = require("cfn.lsp")
local registrations = require("cfn.registrations")
local refactor = require("cfn.refactor")
local progress = require("cfn.progress")

local function sleep(ms)
  local co = coroutine.running()
  vim.defer_fn(function()
    coroutine.resume(co)
  end, ms)
  coroutine.yield()
end

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

local function review_window(title, lines)
  local co = coroutine.running()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  local width = math.min(100, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })
  vim.api.nvim_set_option_value("wrap", false, { win = win })

  local resumed = false
  local function resume(value)
    if resumed then
      return
    end
    resumed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.schedule(function()
      coroutine.resume(co, value)
    end)
  end

  vim.keymap.set("n", "<CR>", function()
    resume("execute")
  end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", function()
    resume("cancel")
  end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", function()
    resume("cancel")
  end, { buffer = buf, nowait = true, silent = true })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      resume("cancel")
    end,
  })

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
        local list_out, list_err = helper.run({ "credentials", "list-profiles" })
        if list_err then
          vim.notify("Failed to list profiles: " .. list_err, vim.log.levels.ERROR)
          return
        end
        local profiles = vim.json.decode(list_out) or {}
        if #profiles == 0 then
          vim.notify("No AWS profiles found", vim.log.levels.WARN)
          return
        end
        profile = ui_select(profiles, { prompt = "Profile:" })
        if not profile then
          return
        end
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

      local p = progress.start("Resolving credentials for " .. profile .. "...")
      local out, err = helper.run(args)
      if err then
        progress.finish(p, "CfnSetProfile failed: " .. err, vim.log.levels.ERROR)
        return
      end

      local result = vim.json.decode(out)
      if not result or not result.jwe then
        progress.finish(p, "CfnSetProfile: invalid response from helper", vim.log.levels.ERROR)
        return
      end

      if not lsp.push_credentials_jwe(result.jwe) then
        progress.finish(p, "CfnSetProfile: no LSP client attached", vim.log.levels.WARN)
        return
      end

      state.active_profile = profile
      state.active_region = result.region
      state.active_account = result.account
      progress.finish(
        p,
        "cfn.nvim: using "
          .. profile
          .. " ("
          .. (result.region or "?")
          .. (result.account and (", account " .. result.account) or "")
          .. ")"
      )
    end)()
  end, {
    nargs = "*",
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

  vim.api.nvim_create_user_command("CfnStackRegister", function(opts)
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      if not state.active_profile or not state.active_account or not state.active_region then
        vim.notify("Run :CfnSetProfile <profile> first", vim.log.levels.WARN)
        return
      end

      local stack_name = opts.fargs[1]
      if not stack_name then
        local existing = registrations.get(template_path)
        local p = progress.start("Listing stacks in " .. state.active_region .. "...")
        local out, err = helper.run({
          "stacks",
          "list",
          "--profile",
          state.active_profile,
          "--region",
          state.active_region,
        })
        if err then
          progress.finish(p, "Failed to list stacks: " .. err, vim.log.levels.ERROR)
          return
        end
        local stack_list = vim.json.decode(out) or {}
        progress.finish(p, "Found " .. #stack_list .. " stacks")

        local choices = { { label = "[New Stack]", new = true } }
        for _, s in ipairs(stack_list) do
          table.insert(choices, {
            label = s.name .. "  (" .. s.status .. ")",
            name = s.name,
          })
        end

        local choice = ui_select(choices, {
          prompt = "Register " .. vim.fn.fnamemodify(template_path, ":~:.") .. " →",
          format_item = function(item)
            return item.label
          end,
        })
        if not choice then
          return
        end
        if choice.new then
          stack_name = ui_input({
            prompt = "New stack name: ",
            default = existing and existing.stack or "",
          })
          if not stack_name or stack_name == "" then
            return
          end
        else
          stack_name = choice.name
        end
      end

      registrations.set(template_path, {
        stack = stack_name,
        account = state.active_account,
        profile = state.active_profile,
        region = state.active_region,
      })
      vim.notify(
        "Registered "
          .. vim.fn.fnamemodify(template_path, ":~:.")
          .. " → "
          .. stack_name
          .. " ("
          .. state.active_account
          .. " / "
          .. state.active_region
          .. ")"
      )
    end)()
  end, { nargs = "?", desc = "Register current template to a stack" })

  vim.api.nvim_create_user_command("CfnStackUnregister", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end
    registrations.remove(template_path)
    vim.notify("Unregistered " .. vim.fn.fnamemodify(template_path, ":~:."))
  end, { desc = "Remove the registration for the current template" })

  vim.api.nvim_create_user_command("CfnStackRegistrations", function()
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
            "Template registered to account %s (profile %s); current account is %s (profile %s). Run :CfnStackRegister to update or :CfnSetProfile to switch.",
            existing.account,
            existing.profile,
            state.active_account,
            state.active_profile
          ),
          vim.log.levels.ERROR
        )
        return
      end
      if existing and existing.region ~= state.active_region then
        vim.notify(
          string.format(
            "Template registered to region %s; current region is %s. Run :CfnStackRegister to update or :CfnSetProfile to switch.",
            existing.region,
            state.active_region
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
            region = state.active_region,
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
      local p = progress.start("Creating import change set for " .. stack_name .. "...")
      local out, err = helper.run(args, vim.json.encode(payload))
      if err then
        progress.finish(p, "CfnImportSubmit failed: " .. err, vim.log.levels.ERROR)
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
        progress.finish(p, "Created change set: " .. (result.changeSetName or "") .. "\n" .. url)
        vim.ui.open(url)
      else
        progress.finish(p, "Created change set")
      end
      state.pending_imports[template_path] = nil
    end)()
  end, { desc = "Submit pending imports as an IMPORT change set" })

  vim.api.nvim_create_user_command("CfnRefactorMarkStack", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local template_path = vim.api.nvim_buf_get_name(bufnr)
    if template_path == "" then
      vim.notify("Buffer has no file path", vim.log.levels.ERROR)
      return
    end
    if not registrations.get(template_path) then
      vim.notify("Template is not registered. Run :CfnStackRegister <stack> first.", vim.log.levels.ERROR)
      return
    end
    local added = refactor.scope_toggle(template_path)
    local rel = vim.fn.fnamemodify(template_path, ":~:.")
    if added then
      vim.notify("Added " .. rel .. " to refactor scope")
    else
      vim.notify("Removed " .. rel .. " from refactor scope")
    end
  end, { desc = "Toggle the current template in the refactor scope" })

  vim.api.nvim_create_user_command("CfnRefactorMove", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local source_path = vim.api.nvim_buf_get_name(bufnr)
      if source_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      local source_reg = registrations.get(source_path)
      if not source_reg then
        vim.notify("Current template is not registered. Run :CfnStackRegister <stack>.", vim.log.levels.ERROR)
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

      local all = registrations.list()
      local choices = { { new = true } }
      for path, reg in pairs(all) do
        if path ~= source_path then
          table.insert(choices, { path = path, stack = reg.stack, account = reg.account })
        end
      end
      table.sort(choices, function(a, b)
        if a.new then
          return true
        end
        if b.new then
          return false
        end
        return a.stack < b.stack
      end)

      local choice = ui_select(choices, {
        prompt = "Move " .. resource.logicalId .. " to:",
        format_item = function(item)
          if item.new then
            return "[New Stack]"
          end
          return item.stack .. "  (" .. vim.fn.fnamemodify(item.path, ":~:.") .. ")"
        end,
      })
      if not choice then
        return
      end

      local dest_path, dest_stack
      if choice.new then
        local stack_name = ui_input({ prompt = "New stack name: " })
        if not stack_name or stack_name == "" then
          return
        end
        local default_path = vim.fn.fnamemodify(source_path, ":h") .. "/" .. stack_name .. ".yaml"
        local template_path = ui_input({ prompt = "Template path: ", default = default_path })
        if not template_path or template_path == "" then
          return
        end
        template_path = vim.fn.fnamemodify(template_path, ":p")
        if registrations.get(template_path) then
          vim.notify(
            "Template " .. vim.fn.fnamemodify(template_path, ":~:.") .. " is already registered",
            vim.log.levels.ERROR
          )
          return
        end
        if vim.fn.filereadable(template_path) == 0 then
          local f, ferr = io.open(template_path, "w")
          if not f then
            vim.notify("Failed to create template: " .. ferr, vim.log.levels.ERROR)
            return
          end
          f:write("AWSTemplateFormatVersion: '2010-09-09'\nResources:\n")
          f:close()
        end
        registrations.set(template_path, {
          stack = stack_name,
          account = state.active_account,
          profile = state.active_profile,
          region = state.active_region,
        })
        dest_path = template_path
        dest_stack = stack_name
      else
        if choice.account ~= source_reg.account then
          vim.notify(
            "Cannot move across accounts: source "
              .. source_reg.account
              .. ", destination "
              .. choice.account,
            vim.log.levels.ERROR
          )
          return
        end
        dest_path = choice.path
        dest_stack = choice.stack
      end

      local ok, err = refactor.move_resource(source_path, dest_path, resource.logicalId)
      if not ok then
        vim.notify("Move failed: " .. err, vim.log.levels.ERROR)
        return
      end

      refactor.scope_add(source_path)
      refactor.scope_add(dest_path)
      refactor.record_op({
        current_template = source_path,
        current_stack = source_reg.stack,
        current_logical_id = resource.logicalId,
        new_template = dest_path,
        new_stack = dest_stack,
        new_logical_id = resource.logicalId,
        resource_type = resource.resourceType,
      })
      vim.notify("Moved " .. resource.logicalId .. " from " .. source_reg.stack .. " to " .. dest_stack)
    end)()
  end, { desc = "Move resource at cursor to another registered template" })

  vim.api.nvim_create_user_command("CfnRefactorMarkMoved", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local dest_path = vim.api.nvim_buf_get_name(bufnr)
      if dest_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      local dest_reg = registrations.get(dest_path)
      if not dest_reg then
        vim.notify("Current template is not registered. Run :CfnStackRegister <stack>.", vim.log.levels.ERROR)
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

      local all = registrations.list()
      local choices = {}
      for path, reg in pairs(all) do
        if path ~= dest_path then
          table.insert(choices, { path = path, stack = reg.stack, account = reg.account })
        end
      end
      if #choices == 0 then
        vim.notify("No other registered templates available", vim.log.levels.WARN)
        return
      end
      table.sort(choices, function(a, b)
        return a.stack < b.stack
      end)

      local source = ui_select(choices, {
        prompt = "Source stack for " .. resource.logicalId .. ":",
        format_item = function(item)
          return item.stack .. "  (" .. vim.fn.fnamemodify(item.path, ":~:.") .. ")"
        end,
      })
      if not source then
        return
      end

      if source.account ~= dest_reg.account then
        vim.notify(
          "Cannot mark cross-account moves: source "
            .. source.account
            .. ", destination "
            .. dest_reg.account,
          vim.log.levels.ERROR
        )
        return
      end

      local source_id = ui_input({
        prompt = "Source logical id: ",
        default = resource.logicalId,
      })
      if not source_id or source_id == "" then
        return
      end

      refactor.scope_add(source.path)
      refactor.scope_add(dest_path)
      refactor.record_op({
        current_template = source.path,
        current_stack = source.stack,
        current_logical_id = source_id,
        new_template = dest_path,
        new_stack = dest_reg.stack,
        new_logical_id = resource.logicalId,
        resource_type = resource.resourceType,
      })
      vim.notify(
        "Marked " .. source.stack .. "/" .. source_id .. " → " .. dest_reg.stack .. "/" .. resource.logicalId
      )
    end)()
  end, { desc = "Mark a manually-moved resource for inclusion in the next refactor submit" })

  vim.api.nvim_create_user_command("CfnRefactorMarkRenamed", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      local reg = registrations.get(template_path)
      if not reg then
        vim.notify("Current template is not registered. Run :CfnStackRegister <stack>.", vim.log.levels.ERROR)
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

      local old_id = ui_input({ prompt = "Original logical id: " })
      if not old_id or old_id == "" or old_id == resource.logicalId then
        return
      end

      refactor.scope_add(template_path)
      refactor.record_op({
        current_template = template_path,
        current_stack = reg.stack,
        current_logical_id = old_id,
        new_template = template_path,
        new_stack = reg.stack,
        new_logical_id = resource.logicalId,
        resource_type = resource.resourceType,
      })
      vim.notify("Marked " .. reg.stack .. "/" .. old_id .. " → " .. reg.stack .. "/" .. resource.logicalId)
    end)()
  end, { desc = "Mark a manually-renamed resource for inclusion in the next refactor submit" })

  vim.api.nvim_create_user_command("CfnRefactorRename", function()
    coroutine.wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local template_path = vim.api.nvim_buf_get_name(bufnr)
      if template_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
      end
      local reg = registrations.get(template_path)
      if not reg then
        vim.notify("Current template is not registered. Run :CfnStackRegister <stack>.", vim.log.levels.ERROR)
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

      local new_id = ui_input({ prompt = "Rename " .. resource.logicalId .. " to: " })
      if not new_id or new_id == "" or new_id == resource.logicalId then
        return
      end

      local ok, err = refactor.rename_resource(template_path, resource.logicalId, new_id)
      if not ok then
        vim.notify("Rename failed: " .. err, vim.log.levels.ERROR)
        return
      end

      refactor.scope_add(template_path)
      refactor.record_op({
        current_template = template_path,
        current_stack = reg.stack,
        current_logical_id = resource.logicalId,
        new_template = template_path,
        new_stack = reg.stack,
        new_logical_id = new_id,
        resource_type = resource.resourceType,
      })
      vim.notify("Renamed " .. resource.logicalId .. " → " .. new_id .. " in " .. reg.stack)
    end)()
  end, { desc = "Rename the logical id of the resource at cursor" })

  vim.api.nvim_create_user_command("CfnRefactorList", function()
    local scope = refactor.scope_list()
    local moves = refactor.moves()
    if #scope == 0 and #moves == 0 then
      vim.notify("Refactor scope is empty")
      return
    end
    local lines = { "Refactor scope:" }
    for _, path in ipairs(scope) do
      local reg = registrations.get(path)
      local stack = reg and reg.stack or "(unregistered)"
      table.insert(lines, "  - " .. stack .. "  (" .. vim.fn.fnamemodify(path, ":~:.") .. ")")
    end
    if #moves > 0 then
      table.insert(lines, "Staged moves:")
      for _, m in ipairs(moves) do
        table.insert(
          lines,
          "  - " .. m.sourceStack .. "/" .. m.sourceLogicalId .. " → " .. m.destStack .. "/" .. m.destLogicalId
        )
      end
    end
    vim.notify(table.concat(lines, "\n"))
  end, { desc = "Show the current refactor scope and staged moves" })

  vim.api.nvim_create_user_command("CfnRefactorClear", function()
    refactor.clear()
    vim.notify("Refactor scope cleared")
  end, { desc = "Clear the refactor scope and staged moves" })

  vim.api.nvim_create_user_command("CfnRefactorSubmit", function()
    coroutine.wrap(function()
      if not state.active_profile then
        vim.notify("Run :CfnSetProfile <profile> first", vim.log.levels.WARN)
        return
      end

      local scope = refactor.scope_list()
      if #scope == 0 then
        vim.notify("Refactor scope is empty", vim.log.levels.WARN)
        return
      end

      local stack_definitions = {}
      for _, path in ipairs(scope) do
        local reg = registrations.get(path)
        if not reg then
          vim.notify("Template " .. path .. " is not registered", vim.log.levels.ERROR)
          return
        end
        if reg.account ~= state.active_account then
          vim.notify(
            string.format(
              "Stack %s is registered to account %s; current account is %s. Switch profiles with :CfnSetProfile.",
              reg.stack,
              reg.account,
              state.active_account
            ),
            vim.log.levels.ERROR
          )
          return
        end
        if reg.region ~= state.active_region then
          vim.notify(
            string.format(
              "Stack %s is registered to region %s; current region is %s. Switch profiles with :CfnSetProfile.",
              reg.stack,
              reg.region,
              state.active_region
            ),
            vim.log.levels.ERROR
          )
          return
        end
        table.insert(stack_definitions, { stackName = reg.stack, templatePath = path })
      end

      local mappings = {}
      for _, m in ipairs(refactor.moves()) do
        table.insert(mappings, {
          source = { stackName = m.sourceStack, logicalResourceId = m.sourceLogicalId },
          destination = { stackName = m.destStack, logicalResourceId = m.destLogicalId },
        })
      end

      local p_check = progress.start("Listing stacks in " .. state.active_region .. "...")
      local check_out, check_err = helper.run({
        "stacks",
        "list",
        "--profile",
        state.active_profile,
        "--region",
        state.active_region,
      })
      if check_err then
        progress.finish(p_check, "Failed to list stacks: " .. check_err, vim.log.levels.ERROR)
        return
      end
      local existing = {}
      for _, s in ipairs(vim.json.decode(check_out) or {}) do
        existing[s.name] = true
      end
      progress.finish(p_check, "Found " .. vim.tbl_count(existing) .. " stacks")
      local enable_stack_creation = false
      for _, def in ipairs(stack_definitions) do
        if not existing[def.stackName] then
          enable_stack_creation = true
          break
        end
      end

      local payload = {
        stackDefinitions = stack_definitions,
        resourceMappings = mappings,
        enableStackCreation = enable_stack_creation,
      }

      local profile_args = {
        "--profile",
        state.active_profile,
        "--region",
        state.active_region,
      }

      local p = progress.start("Submitting refactor...")
      local create_args = { "refactor", "create" }
      vim.list_extend(create_args, profile_args)
      local out, err = helper.run(create_args, vim.json.encode(payload))
      if err then
        progress.finish(p, "Submit failed: " .. err, vim.log.levels.ERROR)
        return
      end
      local create_result = vim.json.decode(out)
      if not create_result or not create_result.refactorId then
        progress.finish(p, "Submit failed: invalid response from helper", vim.log.levels.ERROR)
        return
      end
      local refactor_id = create_result.refactorId
      local prefix = "Refactor " .. refactor_id .. ": "

      local function describe()
        local desc_args = { "refactor", "describe", "--id", refactor_id }
        vim.list_extend(desc_args, profile_args)
        local desc_out, desc_err = helper.run(desc_args)
        if desc_err then
          return nil, desc_err
        end
        return vim.json.decode(desc_out), nil
      end

      progress.update(p, prefix .. "waiting")
      local last_status = "waiting"
      while true do
        local desc, derr = describe()
        if not desc then
          progress.finish(p, prefix .. "describe failed (" .. derr .. ")", vim.log.levels.ERROR)
          return
        end
        if desc.status == "CREATE_COMPLETE" then
          break
        end
        if desc.status == "CREATE_FAILED" then
          progress.finish(
            p,
            prefix .. "failed (" .. (desc.statusReason or desc.status) .. ")",
            vim.log.levels.ERROR
          )
          return
        end
        if desc.status ~= last_status then
          progress.update(p, prefix .. desc.status)
          last_status = desc.status
        end
        sleep(2000)
      end

      local actions_args = { "refactor", "list-actions", "--id", refactor_id }
      vim.list_extend(actions_args, profile_args)
      local actions_out, actions_err = helper.run(actions_args)
      if actions_err then
        progress.finish(p, prefix .. "list-actions failed (" .. actions_err .. ")", vim.log.levels.ERROR)
        return
      end
      local all_actions = vim.json.decode(actions_out) or {}
      local actions = vim.tbl_filter(function(a)
        return (a.entity or ""):upper() == "RESOURCE"
      end, all_actions)
      progress.finish(p, prefix .. "ready")

      if #actions == 0 then
        vim.notify(prefix .. "no actions to execute", vim.log.levels.WARN)
        return
      end

      local function strip_arn(name)
        if not name or name == "" then
          return name
        end
        local stripped = name:match("stack/([^/]+)/")
        return stripped or name
      end

      local lines = { "Refactor " .. refactor_id, "" }
      for _, a in ipairs(actions) do
        local src = a.source or {}
        local dst = a.destination or {}
        local src_stack = strip_arn(src.stackName)
        local dst_stack = strip_arn(dst.stackName)
        local src_id = src.logicalResourceId or ""
        local dst_id = dst.logicalResourceId or ""

        local logical_part
        if dst_id == "" then
          logical_part = src_id
        elseif src_id == "" or src_id == dst_id then
          logical_part = dst_id
        else
          logical_part = src_id .. " -> " .. dst_id
        end

        local phys = a.physicalResourceId
        if phys == nil or phys == "" then
          phys = "?"
        end

        local stack_part
        if (src_stack or "") == "" then
          stack_part = dst_stack or ""
        elseif (dst_stack or "") == "" then
          stack_part = src_stack or ""
        elseif src_stack == dst_stack then
          stack_part = src_stack
        else
          stack_part = src_stack .. " -> " .. dst_stack
        end

        local detection = string.lower(a.detection or "?")
        table.insert(
          lines,
          string.format("%s (%s): %s %s", logical_part, phys, detection, stack_part)
        )
      end
      table.insert(lines, "")
      table.insert(lines, "<CR> execute    q/<Esc> cancel")

      local choice = review_window("Refactor Review", lines)
      if choice ~= "execute" then
        vim.notify(prefix .. "not executed, state retained")
        return
      end

      local p2 = progress.start(prefix .. "executing")
      local exec_args = { "refactor", "execute", "--id", refactor_id }
      vim.list_extend(exec_args, profile_args)
      local _, exec_err = helper.run(exec_args)
      if exec_err then
        progress.finish(p2, prefix .. "execute failed (" .. exec_err .. ")", vim.log.levels.ERROR)
        return
      end

      local last_es
      while true do
        local desc, derr = describe()
        if not desc then
          progress.finish(p2, prefix .. "describe failed (" .. derr .. ")", vim.log.levels.ERROR)
          return
        end
        local es = desc.executionStatus
        if es == "EXECUTE_COMPLETE" then
          progress.finish(p2, prefix .. "complete")
          break
        end
        if es == "EXECUTE_FAILED" or es == "ROLLBACK_COMPLETE" or es == "ROLLBACK_FAILED" then
          local reason = desc.executionStatusReason
          local msg = prefix .. es
          if reason and reason ~= "" then
            msg = msg .. " (" .. reason .. ")"
          end
          progress.finish(p2, msg, vim.log.levels.ERROR)
          return
        end
        if es ~= last_es then
          progress.update(p2, prefix .. (es or "?"))
          last_es = es
        end
        sleep(5000)
      end

      refactor.clear()
    end)()
  end, { desc = "Submit the current refactor scope as a CloudFormation stack refactor" })

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
