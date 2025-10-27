require("copilot").setup({
  panel = { enabled = false },
  suggestion = { enabled = false },
  -- suggestion = {
  --   enabled = true,
  --   auto_trigger = true,
  --   debounce = 75,
  --   keymap = {
  --     accept = "<c-l>",
  --     accept_word = false,
  --     accept_line = false,
  --     next = "<c-N>",
  --     prev = "<c-P>",
  --     dismiss = "<c-esc>",
  --   },
  -- },
  filetypes = {
    ["*"] = true,
  },
  copilot_node_command = "node",
  server_opts_overrides = {},
})
local keys = require("barney.lib.keymap")
keys.imap("<c-l>", "")
