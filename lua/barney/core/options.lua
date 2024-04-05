vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.wrap = false

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.colorcolumn = "120"

vim.opt.completeopt = "menuone,noselect"

vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true

vim.g.do_filetype_lua = true
vim.g.did_load_filetypes = false

vim.o.exrc = true

-- set tabs to be visible with white vertical line to the left
vim.opt.list = true
vim.opt.listchars = {
  tab = "⎸ ",
  trail = "·",
  extends = "»",
  precedes = "«",
}
