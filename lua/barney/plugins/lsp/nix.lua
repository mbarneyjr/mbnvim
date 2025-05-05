-- vim.lsp.config("nil_ls", {
--   settings = {
--     ["nil"] = {
--       nix = {
--         flake = {
--           autoEvalInputs = true,
--         },
--       },
--     },
--   },
-- })
-- vim.lsp.enable("nil_ls")

vim.lsp.config("nixd", {
  settings = {
    nixd = {
      nixpkgs = {
        expr = "import <nixpkgs> { }",
      },
      options = {
        home_manager = {
          expr = '(builtins.getFlake "' .. os.getenv("HOME") .. '/system.nix").homeConfigurations.aarch64.options',
        },
        nix_darwin = {
          expr = '(builtins.getFlake "' .. os.getenv("HOME") .. '/system.nix").darwinConfigurations.aarch64.options',
        },
      },
    },
  },
})
vim.lsp.enable("nixd")
