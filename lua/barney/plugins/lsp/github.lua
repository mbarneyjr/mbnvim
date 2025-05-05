vim.lsp.config("gh_actions_ls", {
  filetypes = { "yaml.github_actions" },
  capabilities = {
    workspace = {
      didChangeWorkspaceFolders = {
        dynamicRegistration = false,
      },
    },
  },
  init_options = {
    sessionToken = os.getenv("GITHUB_ACTIONS_LS_TOKEN"),
  },
})
vim.lsp.enable("gh_actions_ls")
