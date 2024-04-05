local M = {}

local default_opts = { noremap = true, silent = true }

local function set_keymap(mode, key, map, description, buffer)
  local opts = vim.tbl_extend("force", default_opts, { desc = description, buffer = buffer })
  vim.keymap.set(mode, key, map, opts)
end

M.nmap = function(key, map, desc, buffer)
  set_keymap("n", key, map, desc, buffer)
end
M.imap = function(key, map, desc, buffer)
  set_keymap("i", key, map, desc, buffer)
end
M.vmap = function(key, map, desc, buffer)
  set_keymap("v", key, map, desc, buffer)
end
M.tmap = function(key, map, desc, buffer)
  set_keymap("t", key, map, desc, buffer)
end

return M
