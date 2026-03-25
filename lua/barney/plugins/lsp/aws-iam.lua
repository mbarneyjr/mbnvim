vim.lsp.config("aws-iam-language-server", {
  cmd = { "aws-iam-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.cloudformation", "json", "json.cloudformation", "typescript", "terraform" },
  root_markers = { ".git" },
})
vim.lsp.enable("aws-iam-language-server")
