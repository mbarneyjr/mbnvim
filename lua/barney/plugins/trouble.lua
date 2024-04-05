return {
  "folke/trouble.nvim",
  config = function()
    local key = require("barney.lib.keymap")
    require("trouble").setup({
      icons = false,
      fold_open = "v",
      fold_closed = ">",
      indent_lines = true,
      signs = {
        error = "[ERROR]",
        warning = "[WARN]",
        hint = "[HINT]",
        information = "[INFO]",
      },
      use_diagnostic_signs = false,
    })
    key.nmap("<leader>dl", "<cmd>TroubleToggle<cr>", "[d]iagnostics [l]ist")
  end,
}
