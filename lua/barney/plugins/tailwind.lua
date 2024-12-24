return {
  "luckasRanarison/tailwind-tools.nvim",
  name = "tailwind-tools",
  build = ":UpdateRemotePlugins",
  config = function()
    require("tailwind-tools").setup({
      -- your configuration
    })
  end,
}
