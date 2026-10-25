local key = require("barney.lib.keymap")

local function resolve_reference()
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
  vim.ui.input({ prompt = "Agent Prompt" }, function(input)
    if not input or input == "" then
      return
    end
    vim.fn.setreg("+", reference .. "\n\n" .. input)
    vim.notify("Prompt copied to clipboard")
  end)
end

key.nmap("<leader>ap", copy, "[a]i [p]rompt copy")
key.vmap("<leader>ap", copy, "[a]i [p]rompt copy")
