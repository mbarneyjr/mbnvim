vim.lsp.config("cedar-language-server", {
  cmd = { "cedar-language-server" },
  filetypes = { "cedar", "cedar.json" },
  root_markers = { ".git" },
})
vim.lsp.enable("cedar-language-server")
