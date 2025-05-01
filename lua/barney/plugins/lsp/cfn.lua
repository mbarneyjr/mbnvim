vim.lsp.config("cfn-lsp-extra", {
  cmd = { "cfn-lsp-extra" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  root_markers = { ".git" },
  settings = { validate = false },
})
vim.lsp.enable("cfn-lsp-extra")
