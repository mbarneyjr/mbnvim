return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    local key = require("barney.lib.keymap")
    local term = require("toggleterm")
    term.setup()

    key.tmap("<c-t>", "<CMD>ToggleTerm direction=float<CR>", "Toggle terminal")
    key.nmap("<C-t>", "<CMD>ToggleTerm direction=float<CR>", "Toggle terminal")
    key.tmap("<C-n>", "<c-\\><c-n>", "Exit terminal mode")
  end,
}
