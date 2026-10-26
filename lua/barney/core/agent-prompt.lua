local key = require("barney.lib.keymap")

local function resolve_reference()
  if vim.bo.filetype == "NvimTree" then
    local node = require("nvim-tree.api").tree.get_node_under_cursor()
    return node and "@" .. vim.fn.fnamemodify(node.absolute_path, ":.")
  end
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  local first = vim.fn.line(".")
  local last = first
  if vim.fn.mode():match("^[vV\22]") then
    first = vim.fn.line("v")
    last = vim.fn.line(".")
  end
  if first > last then
    first, last = last, first
  end
  local lines = first == last and tostring(first) or (first .. "-" .. last)
  return "@" .. vim.fn.fnamemodify(name, ":.") .. ":" .. lines
end

local function copy()
  local reference = resolve_reference()
  if not reference then
    vim.notify("agent_prompt: buffer has no file", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("+", reference)
  vim.notify("Reference copied to clipboard")
end

key.nmap("<leader>ap", copy, "[a]i [p]rompt reference copy")
key.vmap("<leader>ap", copy, "[a]i [p]rompt reference copy")
