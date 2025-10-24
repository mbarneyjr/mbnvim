local key = require("barney.lib.keymap")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

key.nmap("<leader>sv", "<C-w>v", "Split window vertically")
key.nmap("<leader>sh", "<C-w>s", "Split window horizontally")
key.nmap("<leader>se", "<C-w>=", "Make splits equal size")
key.nmap("<leader>st", ":tab split<CR>", "Copy window to new tab")
key.nmap("<leader>sx", "<cmd>close<CR>", "Close current split")
key.nmap("<leader>bp", "<cmd>bprevious<CR>", "Previous buffer")
key.nmap("<leader>bn", "<cmd>bnext<CR>", "Next buffer")

key.nmap("<c-_>", "<cmd>noh<cr>", "Clear search highlight")

key.nmap("<leader>w", "<cmd>set wrap!<CR>", "Toggle wrap")

key.nmap("<C-M-j>", "<cmd>m .+1<CR>==", "Move line down")
key.nmap("<C-M-k>", "<cmd>m .-2<CR>==", "Move line up")
key.vmap("<C-M-j>", ":m '>+1<CR>gv=gv", "Move selection down")
key.vmap("<C-M-k>", ":m '<-2<CR>gv=gv", "Move selection up")

key.vmap("<", "<gv", "Indent left and reselect")
key.vmap(">", ">gv", "Indent right and reselect")

-- quickfixlist keymaps
key.nmap("<leader>qo", "<cmd>copen<CR>", "Open quickfix list")
key.nmap("<leader>qc", "<cmd>cclose<CR>", "Close quickfix list")
key.nmap("<leader>qn", "<cmd>cnext<CR>", "Next quickfix item")
key.nmap("<leader>qp", "<cmd>cprev<CR>", "Previous quickfix item")

-- tab navigation
key.nmap("<C-M-h>", "<cmd>tabprevious<CR>", "Previous tab")
key.nmap("<C-M-l>", "<cmd>tabnext<CR>", "Next tab")

-- git diff
key.nmap("<leader>GD", function()
  vim.ui.input({ prompt = "Merge Branch: " }, function(value)
    vim.api.nvim_command("Git difftool -y " .. value)
  end)
end, "Git difftool -y <branch>")
