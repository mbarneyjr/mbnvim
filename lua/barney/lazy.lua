local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  { import = "barney.plugins" },
  { import = "barney.plugins.lsp" },
}, {
  git = {
    timeout = 900, -- 15 minutes
  },
  -- install = { colorscheme = { "tokyonight" } },
  ui = {
    border = "rounded",
  },
  checker = { enabled = true },
  change_detection = { notify = false },
  rocks = {
    hererocks = true, -- recommended if you do not have global installation of Lua 5.1.
  },
})
