local log_path = vim.fn.stdpath("state") .. "/exit-debug.log"

local function log(event)
  local file = io.open(log_path, "a")
  if not file then
    return
  end
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    table.insert(clients, string.format("%s(id=%d)", client.name, client.id))
  end
  file:write(string.format(
    "%s pid=%d %s hrtime=%d clients=[%s]\n",
    os.date("%Y-%m-%d %H:%M:%S"),
    vim.fn.getpid(),
    event,
    vim.uv.hrtime(),
    table.concat(clients, ",")
  ))
  file:close()
end

vim.lsp.log.set_level("debug")

vim.api.nvim_create_autocmd("ExitPre", {
  callback = function()
    log("ExitPre")
  end,
})
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    log("VimLeavePre")
  end,
})
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    log("VimLeave")
  end,
})
