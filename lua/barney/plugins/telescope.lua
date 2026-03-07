local telescope = require("telescope")
local builtin = require("telescope.builtin")
local key = require("barney.lib.keymap")

telescope.setup({
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

telescope.load_extension("fzf")

key.nmap("<C-p>", builtin.commands, "Open commands")
