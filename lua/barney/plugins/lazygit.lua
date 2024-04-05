return {
  "kdheepak/lazygit.nvim",
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local key = require("barney.lib.keymap")
    local telescope = require("telescope")
    telescope.load_extension("lazygit")
    key.nmap("<leader>gl", "<cmd>LazyGit<cr>", "[g]it [l]azygit")
    key.nmap("<leader>gr", "<cmd>Telescope lazygit<cr>", "[g]it [r]epositories")
  end,
}
