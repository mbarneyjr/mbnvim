require("nvim-web-devicons").setup({ default = true })
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.nvim_tree_disable_netrw = 0

local nvim_tree = require("nvim-tree")
local api = require("nvim-tree.api")

local function on_attach(bufnr)
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.del("n", "<C-K>", { buffer = bufnr })

  -- Import compare functionality
  local compare = require("barney.core.compare")

  -- Custom compare keymaps
  vim.keymap.set("n", "mc", function()
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "file" then
      compare.mark_file_for_compare(node.absolute_path)
    else
      vim.notify("Please select a file to mark for comparison", vim.log.levels.WARN)
    end
  end, { buffer = bufnr, desc = "Mark file for comparison" })

  vim.keymap.set("n", "gc", function()
    compare.compare_marked_files()
  end, { buffer = bufnr, desc = "Compare marked files" })

  vim.keymap.set("n", "gs", function()
    vim.notify(compare.get_compare_status())
  end, { buffer = bufnr, desc = "Show compare status" })
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
    symlink_destination = false,
    special_files = {},
    highlight_git = true,
    highlight_diagnostics = false,
    highlight_opened_files = "none",
    highlight_modified = "none",
    icons = {
      show = {
        diagnostics = false,
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
    custom = { "^.git$" },
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

-- set <leader>t to toggle nvim-tree
local key = require("barney.lib.keymap")
key.nmap("<leader>t", api.tree.toggle, "[t]oggle nvim-tree")
