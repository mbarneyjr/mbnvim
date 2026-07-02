local tsc = require("tsc")
tsc.setup()

vim.lsp.config("ts_ls", {
  init_options = {
    preferences = {
      disableSuggestions = true,
    },
  },
})
vim.lsp.enable("ts_ls")
