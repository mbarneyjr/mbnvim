local key = require("barney.lib.keymap")
require("trouble").setup()
key.nmap("<leader>dl", "<cmd>Trouble<cr>", "[d]iagnostics [l]ist")
