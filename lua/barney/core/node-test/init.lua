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

  local reporter = vim.fn.stdpath("config") .. "/lua/barney/core/node-test/reporter.mjs"
  vim.print(reporter)
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
