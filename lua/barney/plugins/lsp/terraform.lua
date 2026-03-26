vim.lsp.config("tflint", {
  cmd = { "tflint", "serve" },
  filetypes = { "opentofu", "opentofu-vars", "terraform", "terraform-vars" },
  root_markers = { ".terraform", ".git" },
})
vim.lsp.enable("tflint")

vim.lsp.config("tofu_ls", {
  cmd = { "tofu-ls", "serve" },
  filetypes = { "opentofu", "opentofu-vars", "terraform", "terraform-vars" },
  root_markers = { ".terraform", ".git" },
})
vim.lsp.enable("tofu_ls")
