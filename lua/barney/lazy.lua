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
  -- install = { colorscheme = { "tokyonight" } },
  ui = {
    border = "rounded",
    icons = {
      cmd = "⌘",
      config = "⚙",
      event = ">",
      ft = "F",
      init = "↻",
      import = "▼",
      keys = "K",
      lazy = "_",
      loaded = "✔",
      not_loaded = "✗",
      plugin = "*",
      runtime = "R",
      source = "S",
      start = "⏵",
      task = "✔",
      list = { "●", "➜", "★", "‒" },
    },
  },
  checker = { enabled = true },
  change_detection = { notify = false },
})
