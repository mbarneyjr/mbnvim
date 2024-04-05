local key = require("barney.lib.keymap")
-- create a function that will open a neovim scratch buffer in a vertical split
local function scratch_buffer()
  vim.cmd("vnew")
  vim.cmd("setlocal buftype=nofile")
  vim.cmd("setlocal bufhidden=hide")
  vim.cmd("setlocal noswapfile")
  vim.cmd("setlocal nobuflisted")
end

key.nmap("<c-N>", scratch_buffer, "open [N]ew scratch buffer")
