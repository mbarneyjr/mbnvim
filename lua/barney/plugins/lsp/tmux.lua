vim.lsp.config("tmux-language-server", {
  cmd = { "tmux-language-server" },
  filetypes = { "tmux" },
  root_markers = { ".git" },
})
vim.lsp.enable("tmux-language-server")
