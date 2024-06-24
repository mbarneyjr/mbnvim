return {
  "folke/trouble.nvim",
  config = function()
    local key = require("barney.lib.keymap")
    require("trouble").setup()
    key.nmap("<leader>dl", "<cmd>Trouble<cr>", "[d]iagnostics [l]ist")
  end,
}
