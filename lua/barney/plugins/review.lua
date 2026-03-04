require("review").setup()

local key = require("barney.lib.keymap")
key.nmap("<leader>ac", require("review").clear, "[a]i review [c]lear")
