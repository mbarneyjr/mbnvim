local key = require("barney.lib.keymap")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

key.nmap("<leader>sv", "<C-w>v", "Split window vertically")
key.nmap("<leader>sh", "<C-w>s", "Split window horizontally")
key.nmap("<leader>se", "<C-w>=", "Make splits equal size")
key.nmap("<leader>sx", "<cmd>close<CR>", "Close current split")

key.nmap("<c-_>", "<cmd>noh<cr>", "Clear search highlight")

-- keymap leader w to toggle wrap
key.nmap("<leader>w", "<cmd>set wrap!<CR>", "Toggle wrap")

-- quickfixlist keymaps
key.nmap("<leader>qo", "<cmd>copen<CR>", "Open quickfix list")
key.nmap("<leader>qc", "<cmd>cclose<CR>", "Close quickfix list")
key.nmap("<leader>qn", "<cmd>cnext<CR>", "Next quickfix item")
key.nmap("<leader>qp", "<cmd>cprev<CR>", "Previous quickfix item")

-- git diff
key.nmap("<leader>GD", function()
  vim.ui.input({ prompt = "Merge Branch: " }, function(value)
    vim.api.nvim_command("Git difftool -y " .. value)
  end)
end, "Git difftool -y <branch>")
