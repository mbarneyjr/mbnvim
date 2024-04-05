return {
  "ThePrimeagen/git-worktree.nvim",
  config = function()
    local key = require("barney.lib.keymap")
    local git_worktree = require("git-worktree")
    local telescope = require("telescope")
    git_worktree.setup()
    telescope.load_extension("git_worktree")
    key.nmap("<leader>fw", telescope.extensions.git_worktree.git_worktrees, "[f]ind [w]orktrees")
    key.nmap("<leader>fW", telescope.extensions.git_worktree.create_git_worktree, "[f]ind [w]orktrees")
  end,
}
