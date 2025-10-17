vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      diagnostics = {
        globals = { "vim" },
      },
      telemetry = {
        enable = false,
      },
    },
  },
})
vim.lsp.enable("lua_ls")
