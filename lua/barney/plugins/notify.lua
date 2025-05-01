local notify = require("notify")

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
