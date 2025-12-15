local telescope = require("telescope")
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")
local key = require("barney.lib.keymap")

telescope.setup({
  defaults = {
    -- stylua: ignore
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
      "--no-ignore",
      "-g", "!node_modules/",
      "-g", "!.direnv/",
      "-g", "!.git/",
      "-g", "!.worktree/",
      "-g", "!local.ignore",
      "-g", "!.venv/",
      "-g", "!.terraform/",
      "-g", "!docs/images/",
      "-g", "!coverage/",
      "-g", "!cdk.out",
      "-g", "!.sst/",
      "-g", "!.aws-sam/",
    },
    mappings = {
      i = {
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-q>"] = actions.send_to_qflist,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
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
    -- stylua: ignore
    find_command = {
      "rg",
      "--files",
      "--hidden",
      "--no-ignore",
      "-g", "!node_modules/",
      "-g", "!.git/",
      "-g", "!.worktree/",
      "-g", "!local.ignore",
      "-g", "!.venv/",
      "-g", "!.terraform/",
      "-g", "!docs/images/",
      "-g", "!coverage/",
      "-g", "!cdk.out",
      "-g", "!.sst/",
      "-g", "!.aws-sam/",
    },
  })
end

key.nmap("<leader>ff", find_files, "[f]ind [f]iles")
key.nmap("<leader>fs", builtin.live_grep, "[f]ind grep [s]earch")
key.nmap("<C-p>", builtin.commands, "Open commands")
