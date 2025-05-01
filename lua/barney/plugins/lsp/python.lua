vim.lsp.config("pyright", {
  root_markers = { "pyrightconfig.json", "requirements.txt", ".git" },
})
vim.lsp.enable("pyright")
