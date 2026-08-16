vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop(true)
    end
  end,
  desc = "Force-stop all LSP clients to prevent slow exit",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local nixd_pids = vim.fn.systemlist({ "pgrep", "-P", tostring(vim.fn.getpid()), "-x", "nixd" })
    for _, pid in ipairs(nixd_pids) do
      vim.uv.kill(tonumber(pid), "sigkill")
    end
  end,
  desc = "SIGKILL nixd directly since it ignores SIGTERM",
})
