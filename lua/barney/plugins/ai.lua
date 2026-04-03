require("copilot").setup({
  panel = { enabled = false },
  suggestion = { enabled = false },
  filetypes = {
    ["*"] = true,
  },
  copilot_node_command = "node",
  server_opts_overrides = {},
})

local keys = require("barney.lib.keymap")
keys.imap("<c-l>", "")

require("claudecode").setup({
  terminal = {
    provider = "none",
  },
})
require("barney.plugins.review")
keys.vmap("<leader>as", ":ClaudeCodeSend<CR>", "Send to Claude")
keys.nmap("<leader>as", ":ClaudeCodeTreeAdd<CR>", "Add file")
keys.nmap("<leader>aa", ":ClaudeCodeDiffAccept<CR>", "Accept diff")
keys.nmap("<leader>ad", ":ClaudeCodeDiffDeny<CR>", "Deny diff")
