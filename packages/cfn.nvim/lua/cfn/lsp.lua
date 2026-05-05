local M = {}

function M.client()
  return vim.lsp.get_clients({ name = "cfn_lsp" })[1]
end

function M.push_credentials_jwe(jwe)
  local client = M.client()
  if not client then
    return false
  end
  local bufnr = vim.api.nvim_get_current_buf()
  client:request("aws/credentials/iam/update", {
    data = jwe,
    encrypted = true,
  }, function(err)
    if err then
      vim.schedule(function()
        vim.notify("cfn.nvim: credential push failed: " .. err.message, vim.log.levels.ERROR)
      end)
    end
  end, bufnr)
  return true
end

function M.clear_credentials()
  local client = M.client()
  if not client then
    return
  end
  client:notify("aws/credentials/iam/delete")
end

return M
