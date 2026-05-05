local M = {}

M.encryption_key = nil
M.active_profile = nil
M.active_region = nil
M.active_account = nil
M.pending_imports = {}
M.refactor = {
  scope = {},
  moves = {},
}

return M
