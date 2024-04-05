return {
  ["nil"] = {
    settings = {
      ["nil"] = {
        nix = {
          flake = {
            autoEvalInputs = true,
          },
        },
      },
    },
  },
  tsserver = {
    settings = {
      diagnostics = {
        ignoredCodes = {
          -- ignore "All imports are unused"
          6192,
        },
      },
    },
    on_attach = function(client, bufnr)
      require("twoslash-queries").attach(client, bufnr)
      client.server_capabilities.documentFormattingProvider = false
    end,
  },
}
