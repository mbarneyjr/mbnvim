local lualine = require("lualine")

lualine.setup({
  options = {
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
      { "encoding" },
      { "fileformat" },
    },
    lualine_z = { "filetype" },
  },
})
