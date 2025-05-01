local tsc = require("tsc")
local ts_error_translator = require("ts-error-translator")
tsc.setup()
ts_error_translator.setup()

vim.lsp.config("ts_ls", {
  init_options = {
    preferences = {
      disableSuggestions = true,
    },
  },
  on_attach = function(client, bufnr)
    require("twoslash-queries").attach(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
  end,
})
vim.lsp.enable("ts_ls")
