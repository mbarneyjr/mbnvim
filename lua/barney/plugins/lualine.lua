return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    lualine.setup({
      options = {
        icons_enabled = false,
        component_separators = "|",
        section_separators = "",
        theme = "tokyonight",
        globalstatus = false,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { "filename", path = 1, file_status = true } },
        lualine_c = { "branch" },
        lualine_x = {
          { "diagnostics" },
          { "diff" },
        },
        lualine_y = {
          { lazy_status.updates, cond = lazy_status.has_updates },
          { "location" },
        },
        lualine_z = { "filetype" },
      },
      inactive_sections = {
        lualine_a = { "mode" },
        lualine_b = { { "filename", path = 1, file_status = true } },
        lualine_c = { "branch" },
        lualine_x = {
          { "diagnostics" },
          { "diff" },
        },
        lualine_y = {
          { lazy_status.updates, cond = lazy_status.has_updates },
          { "encoding" },
          { "fileformat" },
        },
        lualine_z = { "filetype" },
      },
    })
  end,
}
