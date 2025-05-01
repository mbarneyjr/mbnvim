local key = require("barney.lib.keymap")
require("tokyonight").setup({
  styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
    -- Background styles. Can be "dark", "transparent" or "normal"
    --   sidebars = "dark", -- style for sidebars, see below
    --   floats = "dark", -- style for floating windows
  },
  dim_inactive = true, -- dims inactive windows
  lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold
})
vim.opt.termguicolors = true
-- vim.o.background = "dark"
vim.cmd.colorscheme("tokyonight-storm")
local swap_colorscheme = function()
  if vim.o.background == "light" then
    vim.o.background = "dark"
  else
    vim.o.background = "light"
  end
end
key.nmap("<leader>cs", swap_colorscheme, "[c]olor [s]wap")
