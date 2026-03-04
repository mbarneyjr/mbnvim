vim.api.nvim_create_user_command("ReviewClear", function()
  require("review").clear()
end, { desc = "Clear review diagnostics" })
