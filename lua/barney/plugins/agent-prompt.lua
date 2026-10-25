local key = require("barney.lib.keymap")
key.nmap("<leader>ap", require("agent_prompt").copy, "[a]i [p]rompt copy")
key.vmap("<leader>ap", require("agent_prompt").copy, "[a]i [p]rompt copy")
