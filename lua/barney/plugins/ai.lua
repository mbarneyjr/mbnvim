require("copilot").setup({
  panel = { enabled = false },
  suggestion = { enabled = false },
  filetypes = {
    ["*"] = true,
  },
  copilot_node_command = "node",
  server_opts_overrides = {},
})
require("avante_lib").load()
require("avante").setup({
  provider = "bedrock",
  providers = {
    bedrock = {
      model = "global.anthropic.claude-haiku-4-5-20251001-v1:0",
      aws_profile = "claude",
      aws_region = "us-east-2",
    },
  },
})

local keys = require("barney.lib.keymap")
keys.imap("<c-l>", "")

require("claudecode").setup({
  terminal = {
    provider = "none",
  },
})
keys.vmap("<leader>as", ":ClaudeCodeSend<CR>", "Send to Claude")
keys.nmap("<leader>as", ":ClaudeCodeTreeAdd<CR>", "Add file")
keys.nmap("<leader>aa", ":ClaudeCodeDiffAccept<CR>", "Accept diff")
keys.nmap("<leader>ad", ":ClaudeCodeDiffDeny<CR>", "Deny diff")
