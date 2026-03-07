local fff = require("fff")
local key = require("barney.lib.keymap")

fff.setup({
  keymaps = {
    move_up = { "<Up>", "<C-k>" },
    move_down = { "<Down>", "<C-j>" },
  },
})

key.nmap("<leader>ff", function()
  fff.find_files()
end, "[f]ind [f]iles")

key.nmap("<leader>fs", function()
  fff.live_grep()
end, "[f]ind grep [s]earch")
