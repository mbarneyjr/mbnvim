local notify = require("notify")
local keys = require("barney.lib.keymap")

notify.setup({
  timeout = 600,
  fps = 60,
  max_width = 80,
  stages = "fade",
  on_open = function(win)
    vim.api.nvim_win_set_config(win, { zindex = 1000 })
  end,
})
vim.notify = notify

local dismiss = function()
  notify.dismiss()
end

keys.nmap("<leader>nd", dismiss, "dismiss all notifications")
