require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "-" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "+" },
  },
  current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
    delay = 50,
    ignore_whitespace = false,
  },
})

local keymap = require("barney.lib.keymap")
keymap.nmap("<leader>gb", ":Gitsigns toggle_current_line_blame<CR>", "Disable inline git blame")
