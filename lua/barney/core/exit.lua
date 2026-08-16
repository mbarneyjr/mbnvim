vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop(true)
    end
  end,
  desc = "Force-stop all LSP clients to prevent slow exit",
})
