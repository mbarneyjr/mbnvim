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

## Commands

### Profile

- `:CfnSetProfile [profile [region]]` — set the active AWS profile and push credentials to the LSP. With no args, opens a picker of available profiles.
- `:CfnClearProfile` — clear the active profile and credentials from the LSP.

### Importing live resources

- `:CfnImport` — interactively import or clone a live AWS resource into the current template (picks a resource type, then an existing resource).
- `:CfnImportMark` — toggle the resource at the cursor in the pending-imports list for this template.
- `:CfnImportList` — show pending imports for the current template.
- `:CfnImportSubmit` — submit pending imports as an `IMPORT` change set on the registered stack.

### Stack registration

Templates are mapped to stacks (and the account/region/profile they belong to) so subsequent commands know where to apply changes. Registrations are stored per-cwd at `<data>/cfn.nvim/projects/<cwd-encoded>.json`.

- `:CfnStackRegister [stack]` — register the current template to a stack. With no arg, opens a picker of stacks in the active account/region (with `[New Stack]` to provision a new one).
- `:CfnStackUnregister` — remove the registration for the current template.
- `:CfnStackRegistrations` — open the registrations file for the current cwd.

### Stack refactors

CloudFormation [stack refactors](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-refactoring.html) move and rename resources between stacks. The plugin tracks an in-memory scope of templates and a list of moves; submit applies them in one API call.

- `:CfnRefactorMarkStack` — toggle the current template in the refactor scope.
- `:CfnRefactorMove` — move the resource at the cursor to another registered template (or `[New Stack]`). Edits both templates and stages the mapping.
- `:CfnRefactorRename` — rename the logical id of the resource at the cursor in the current template (also rewrites `!Ref`, `!GetAtt`, `${...}`, `Ref:`, `DependsOn:`, and inline `Fn::GetAtt:` references).
- `:CfnRefactorMarkMoved` — for a resource you cut/pasted manually: pick the source stack and confirm the source logical id, then record it.
- `:CfnRefactorMarkRenamed` — for a resource you renamed manually: provide the original logical id, then record it.
- `:CfnRefactorList` — show the current scope and staged moves.
- `:CfnRefactorClear` — clear the scope and staged moves.
- `:CfnRefactorSubmit` — create the stack refactor, poll until detected actions are ready, review them in a floating window, and execute.

### LSP-assisted authoring

- `:CfnRelatedResources` — insert resources related to the one at the cursor, using the LSP.
