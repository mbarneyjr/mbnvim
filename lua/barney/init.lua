require("barney.core")

-- Source .nvim.lua early so vim.g.large_repo and other flags
-- are available before plugin setup
local local_lua_file = vim.fn.getcwd() .. "/.nvim.lua"
if vim.fn.filereadable(local_lua_file) == 1 then
  vim.cmd("source " .. local_lua_file)
end

require("barney.plugins")
