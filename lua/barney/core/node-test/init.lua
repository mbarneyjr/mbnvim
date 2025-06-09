local function node_test()
  local file = io.open("package.json", "r")
  if file == nil then
    vim.notify("No package.json found")
    return
  end
  local package_json = vim.json.decode(file:read("a"))
  if package_json == nil then
    vim.notify("Failed to parse package.json")
    return
  end
  local workspaces = package_json.workspaces

  local workspace_args = ""
  if workspaces ~= nil then
    local index = vim.fn.inputlist(workspaces)
    if workspaces[index] ~= nil then
      workspace_args = "--workspace " .. workspaces[index]
    end
  end

  -- Get the path of the current Lua file and construct reporter path relative to it
  local current_file = debug.getinfo(1, "S").source:sub(2) -- Remove '@' prefix
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  local reporter = current_dir .. "/reporter.mjs"
  vim.print("Using reporter at: " .. reporter)
  local command = "npm run test "
    .. workspace_args
    .. " -- --test-reporter "
    .. reporter
    .. " --test-reporter-destination stdout"
  vim.notify("Running tests:\n" .. command)
  vim.api.nvim_command('cexpr system("' .. command .. '")')
  vim.notify("Tests completed")
end

-- set makeprg
vim.api.nvim_create_user_command("NodeTest", node_test, { desc = "Run node tests", nargs = 0 })
