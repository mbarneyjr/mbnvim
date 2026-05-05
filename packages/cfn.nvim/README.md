# cfn.nvim

Neovim plugin for working with AWS CloudFormation templates.

## Requirements

[aws-cloudformation/cloudformation-languageserver](https://github.com/aws-cloudformation/cloudformation-languageserver).

When you set up the LSP, pass `cfn.encryption_key()` as the credential-encryption key:

```lua
vim.lsp.config("cfn_lsp", {
  cmd = { "node", "/path/to/install-location/cfn-lsp-server-standalone.js", "--stdio" },
  filetypes = { "yaml.cloudformation", "json.cloudformation" },
  init_options = {
    aws = {
      encryption = { key = require("cfn").encryption_key() },
    },
  },
  -- ...other settings as needed
})
vim.lsp.enable("cfn_lsp")
```

## Setup

```lua
require("cfn").setup()
```
