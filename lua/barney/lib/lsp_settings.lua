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
    init_options = {
      preferences = {
        disableSuggestions = true,
      },
    },
    on_attach = function(client, bufnr)
      require("twoslash-queries").attach(client, bufnr)
      client.server_capabilities.documentFormattingProvider = false
    end,
  },
}
