return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local nvim_tree = require("nvim-tree")
    local api = require("nvim-tree.api")

    local function on_attach(bufnr)
      api.config.mappings.default_on_attach(bufnr)
      vim.keymap.del("n", "<C-K>", { buffer = bufnr })
    end

    nvim_tree.setup({
      on_attach = on_attach,
      notify = {
        threshold = vim.log.levels.WARN,
        absolute_path = true,
      },
      view = {
        signcolumn = "auto",
        adaptive_size = {},
        side = "right",
      },
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
        ignore_dirs = { "node_modules", ".git" },
      },
      renderer = {
        add_trailing = true,
        special_files = {},
        highlight_git = true,
        highlight_diagnostics = false,
        highlight_opened_files = "none",
        highlight_modified = "none",
        icons = {
          git_placement = "signcolumn",
          modified_placement = "signcolumn",
          diagnostics_placement = "signcolumn",
          bookmarks_placement = "signcolumn",
          glyphs = {
            default = "",
            symlink = "↪",
            bookmark = "➩",
            modified = "●",
            folder = {
              arrow_closed = "˃",
              arrow_open = "˅",
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "U",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "D",
              ignored = "",
            },
          },
        },
      },
      update_focused_file = {
        enable = true,
        update_root = false,
        ignore_list = {},
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
          min = vim.diagnostic.severity.HINT,
          max = vim.diagnostic.severity.ERROR,
        },
        icons = { hint = "H", info = "I", warning = "W", error = "E" },
      },
      modified = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },
      actions = { open_file = { quit_on_open = true } },
      filters = {
        git_ignored = false,
        dotfiles = false,
        git_clean = false,
        no_buffer = false,
        custom = {},
        exclude = {},
      },
      log = {
        enable = true,
        truncate = true,
        types = {
          diagnostics = true,
          git = true,
          profile = true,
          watcher = true,
        },
      },
    })

    -- set <leader>e to toggle nvim-tree
    local key = require("barney.lib.keymap")
    key.nmap("<leader>t", api.tree.toggle, "[t]oggle nvim-tree")
  end,
}
