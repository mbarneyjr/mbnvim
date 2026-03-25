vim.lsp.config("aws-iam-ls", {
  cmd = { "aws-iam-ls", "--stdio" },
  filetypes = { "yaml", "yaml.cloudformation", "json", "json.cloudformation", "typescript", "terraform" },
  root_markers = { ".git" },
})
vim.lsp.enable("aws-iam-ls")
