local M = {}

function M.encryption_key()
  local state = require("cfn.state")
  if not state.encryption_key then
    local helper = require("cfn.helper")
    local key, err = helper.run({ "jwe", "genkey" })
    if err then
      vim.notify("cfn.nvim: failed to generate JWE key: " .. err, vim.log.levels.ERROR)
      return nil
    end
    state.encryption_key = vim.trim(key)
  end
  return state.encryption_key
end

function M.setup(_opts)
  M.encryption_key()
  require("cfn.commands").register()
end

return M
