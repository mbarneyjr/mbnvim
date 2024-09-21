return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    lang = "javascript",
    -- configuration goes here
  },
}
