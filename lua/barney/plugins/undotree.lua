return {
  "mbbill/undotree",
  config = function()
    local key = require("barney.lib.keymap")
    key.nmap("<leader>ut", vim.cmd.UndotreeToggle, "toggle undotree")
    key.nmap("<leader>uf", vim.cmd.UndotreeFocus, "focus undotree")
    vim.g.undotree_WindowLayout = 2
  end,
}
