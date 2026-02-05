require("barney.core")
require("barney.plugins")
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    local local_lua_file = vim.fn.getcwd() .. "/.nvim.lua"
    if vim.fn.filereadable(local_lua_file) == 1 then
      vim.cmd("source " .. local_lua_file)
    end

    -- Open README and nvim-tree if starting with a directory (or no arguments)
    vim.schedule(function()
      local argc = vim.fn.argc()
      local arg0 = vim.fn.argv(0)
      local arg_is_dir = argc == 1 and vim.fn.isdirectory(arg0) == 1

      if argc ~= 0 and not arg_is_dir then
        return
      end

      local dir = arg_is_dir and vim.fn.fnamemodify(arg0, ":p:h") or vim.fn.getcwd()
      if arg_is_dir then
        vim.cmd.cd(dir)
      end
      local readme_patterns = {
        "README.md",
        "README.markdown",
        "README.txt",
        "README",
        "readme.md",
        "readme.markdown",
        "readme.txt",
        "readme",
      }
      for _, name in ipairs(readme_patterns) do
        local readme_path = dir .. "/" .. name
        if vim.fn.filereadable(readme_path) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(readme_path))
          break
        end
      end
      require("nvim-tree.api").tree.open()
    end)
  end,
  desc = "Source local .nvim.lua configuration files",
})
