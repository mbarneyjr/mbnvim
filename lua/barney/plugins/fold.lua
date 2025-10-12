local ufo = require("ufo")
local keys = require("barney.lib.keymap")

vim.o.foldcolumn = "0" -- willing to use foldcolumn after we can set foldinner
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldmethod = "indent"
vim.opt.fillchars:append({
  eob = " ",
  fold = " ",
  foldopen = "",
  foldsep = " ",
  foldclose = "",
  -- foldinner = " ",
})

ufo.setup()

keys.nmap("zR", ufo.openAllFolds, "Open all folds")
keys.nmap("zM", ufo.closeAllFolds, "Close all folds")
keys.nmap("zr", ufo.openFoldsExceptKinds, "Open folds except kinds")
keys.nmap("zm", ufo.closeFoldsWith, "Close folds with")

local special_hl = vim.api.nvim_get_hl(0, { name = "Special" })
local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
vim.api.nvim_set_hl(0, "UfoFoldedEllipsis", { fg = normal_hl.bg, bg = special_hl.fg })
