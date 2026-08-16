require("copilot").setup({
  panel = { enabled = false },
  suggestion = { enabled = false },
  filetypes = {
    ["*"] = true,
  },
  server = {
    type = "binary",
    custom_server_filepath = "copilot-language-server",
  },
  server_opts_overrides = {},
})
