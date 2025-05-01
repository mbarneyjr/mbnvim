vim.lsp.config("nil_ls", {
  settings = {
    ["nil"] = {
      nix = {
        flake = {
          autoEvalInputs = true,
        },
      },
    },
  },
})
vim.lsp.enable("nil_ls")
