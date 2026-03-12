vim.lsp.config("iam-legend", {
  cmd = { "iam-legend-lsp", "--stdio" },
  filetypes = { "yaml", "yaml.cloudformation", "json", "json.cloudformation", "typescript", "terraform" },
  root_markers = { ".git" },
  -- settings = { validate = false },
})
vim.lsp.enable("iam-legend")
