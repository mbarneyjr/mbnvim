return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  config = function()
    local keys = require("barney.lib.keymap")
    vim.g.tmux_navigator_no_mappings = true
    keys.nmap("<C-H>", "<cmd>TmuxNavigateLeft<cr>", "TmuxNavigateLeft")
    keys.nmap("<C-J>", "<cmd>TmuxNavigateDown<cr>", "TmuxNavigateDown")
    keys.nmap("<C-K>", "<cmd>TmuxNavigateUp<cr>", "TmuxNavigateUp")
    keys.nmap("<C-L>", "<cmd>TmuxNavigateRight<cr>", "TmuxNavigateRight")
  end,
}
