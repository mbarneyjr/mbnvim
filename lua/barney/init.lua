require("barney.core")
require("barney.plugins")
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    local local_lua_file = vim.fn.getcwd() .. "/.nvim.lua"
    if vim.fn.filereadable(local_lua_file) == 1 then
      vim.cmd("source " .. local_lua_file)
    end
  end,
  desc = "Source local .nvim.lua configuration files",
})
