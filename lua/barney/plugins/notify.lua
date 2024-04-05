return {
  "rcarriga/nvim-notify",
  priority = 999,
  opts = {
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { zindex = 1000 })
    end,
  },
  config = function()
    local notify = require("notify")
    ---@diagnostic disable-next-line: missing-fields
    notify.setup({
      timeout = 600,
      fps = 60,
      max_width = 80,
      icons = {
        ERROR = "‼",
        WARN = "⚠",
        INFO = "ℹ",
        DEBUG = ">",
        TRACE = "⌕",
      },
      stages = "fade",
    })
    vim.notify = notify
  end,
}
