vim.lsp.config("cfn-lsp-server", {
  cmd = { "cfn-lsp-server", "--stdio" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  root_markers = { ".git" },
  settings = {
    editor = {
      detectIndentation = true,
    },
    ["aws.cloudformation"] = {
      diagnostics = {
        cfnGuard = {
          enabled = true,
          enabledRulePacks = {},
        },
      },
    },
  },
})
vim.lsp.enable("cfn-lsp-server")
