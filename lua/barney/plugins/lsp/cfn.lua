vim.lsp.config("cfn-lsp-server", {
  cmd = { "cfn-lsp-server-standalone", "--stdio" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  root_markers = { ".git" },
  settings = { validate = false },
})
vim.lsp.enable("cfn-lsp-server")
