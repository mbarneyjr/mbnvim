local key = require("barney.lib.keymap")
local cfn = require("cfn")

cfn.setup({})

key.nmap("<leader>cs", cfn.fn.toggle_status_window, "[c]loudformation [s]tatus")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml.cloudformation", "json.cloudformation" },
  callback = function(args)
    key.nmap("<leader>cr", cfn.fn.rename_resource, "[c]loudformation [r]ename resource", args.buf)
  end,
})
