return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  lazy = false,
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")
    local key = require("barney.lib.keymap")

    telescope.setup({
      defaults = {
        file_ignore_patterns = {
          "node_modules",
          ".git",
          ".venv",
          ".terraform",
          "docs/images",
          "coverage",
          "cdk.out",
          ".aws%-sam",
          "local.ignore",
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.close,
          },
        },
      },
      pickers = {
        live_grep = {
          additional_args = function(opts)
            return { "--hidden" }
          end,
        },
      },
    })

    telescope.load_extension("fzf")

    local function find_files()
      builtin.find_files({
        hidden = true,
        no_ignore = true,
      })
    end
    local function live_grep()
      builtin.live_grep({
        hidden = false,
        no_ignore = false,
      })
    end

    key.nmap("<leader>ff", find_files, "[f]ind [f]iles")
    key.nmap("<leader>fs", live_grep, "[f]ind grep [s]earch")
    key.nmap("<C-p>", builtin.commands, "Open commands")
  end,
}
