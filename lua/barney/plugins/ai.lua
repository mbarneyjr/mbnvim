require("copilot").setup({
  panel = { enabled = false },
  suggestion = { enabled = false },
  filetypes = {
    ["*"] = true,
  },
  copilot_node_command = "node",
  server_opts_overrides = {},
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients({ name = "copilot" })) do
      client:stop(true)
    end
  end,
  desc = "Force-stop copilot LSP to prevent slow exit",
})
-- local keys = require("barney.lib.keymap")
-- keys.imap("<c-l>", "")
