return {
  "tpope/vim-fugitive",
  dependencies = {
    "tpope/vim-rhubarb",
  },
  lazy = false,
  config = function()
    local key = require("barney.lib.keymap")
    local function toggle_fugitive()
      -- get fugitive buffer
      local buffers = vim.api.nvim_list_bufs()
      -- find buffer with fugitive://
      local bufnr = vim.tbl_filter(function(buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        return bufname:match("fugitive://")
      end, buffers)[1]

      if not bufnr then
        vim.cmd("G")
        return
      end

      -- list windows
      local windows = vim.api.nvim_list_wins()
      -- find windows with fugitive buffer
      local fugitive_windows = vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_buf(win) == bufnr
      end, windows)
      -- close fugitive windows
      for _, win in ipairs(fugitive_windows) do
        vim.api.nvim_win_close(win, true)
      end
      -- close fugitive buffer
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    key.nmap("<c-g>", toggle_fugitive, "Toggle vim-fugitive")
  end,
}
