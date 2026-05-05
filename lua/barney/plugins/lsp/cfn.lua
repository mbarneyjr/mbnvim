vim.lsp.config("cfn_lsp", {
  cmd = { "cfn-lsp-server", "--stdio" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  root_markers = { ".git" },
  init_options = {
    aws = {
      encryption = {
        key = require("cfn").encryption_key(),
      },
    },
  },
  settings = {
    editor = {
      detectIndentation = true,
    },
    aws = {
      cloudformation = {
        diagnostics = {
          cfnGuard = {
            enabled = true,
            enabledRulePacks = {},
          },
        },
      },
    },
  },
})
vim.lsp.enable("cfn_lsp")
