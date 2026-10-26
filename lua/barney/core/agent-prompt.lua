local key = require("barney.lib.keymap")

local function selected_range()
  local first = vim.fn.line(".")
  local last = first
  if vim.fn.mode():match("^[vV\22]") then
    first = vim.fn.line("v")
  end
  if first > last then
    first, last = last, first
  end
  return first, last
end

local function resolve_status_references(first, last)
  local root = vim.fn.FugitiveWorkTree()
  local order, spans = {}, {}
  local path, counter
  for index, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, last, false)) do
    local entry = line:match("^%u%s+(.+)$") or line:match("^%?%s+(.+)$")
    local hunk_start = line:match("^@@ %-%d+,?%d* %+(%d+)")
    local file_line
    if entry then
      path = entry:match(" %-> (.+)$") or entry
      counter = nil
    elseif hunk_start and path then
      counter = tonumber(hunk_start)
      file_line = counter
    elseif counter and path and line:match("^[ +-]") then
      if not line:match("^%-") then
        counter = counter + 1
      end
      file_line = math.max(counter - (line:match("^%-") and 0 or 1), 1)
    end
    if index >= first and path and (entry or file_line) then
      local span = spans[path]
      if not span then
        span = {}
        spans[path] = span
        table.insert(order, path)
      end
      if file_line then
        span.first = math.min(span.first or file_line, file_line)
        span.last = math.max(span.last or file_line, file_line)
      end
    end
  end
  local references = {}
  for _, name in ipairs(order) do
    local span = spans[name]
    local reference = "@" .. vim.fn.fnamemodify(root .. "/" .. name, ":.")
    if span.first then
      reference = reference .. ":" .. (span.first == span.last and span.first or (span.first .. "-" .. span.last))
    end
    table.insert(references, reference)
  end
  return #references > 0 and table.concat(references, " ") or nil
end

local function resolve_reference()
  if vim.bo.filetype == "NvimTree" then
    local node = require("nvim-tree.api").tree.get_node_under_cursor()
    return node and "@" .. vim.fn.fnamemodify(node.absolute_path, ":.")
  end
  local first, last = selected_range()
  if vim.bo.filetype == "fugitive" then
    return resolve_status_references(first, last)
  end
  local name = vim.api.nvim_buf_get_name(0)
  if name:match("^fugitive://") then
    name = vim.fn.FugitiveReal(name)
  end
  if name == "" then
    return nil
  end
  local lines = first == last and tostring(first) or (first .. "-" .. last)
  return "@" .. vim.fn.fnamemodify(name, ":.") .. ":" .. lines
end

local function copy()
  local reference = resolve_reference()
  if not reference then
    vim.notify("agent_prompt: no file reference at cursor", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("+", reference)
  vim.notify("Reference copied to clipboard")
end

key.nmap("<leader>ap", copy, "[a]i [p]rompt reference copy")
key.vmap("<leader>ap", copy, "[a]i [p]rompt reference copy")
