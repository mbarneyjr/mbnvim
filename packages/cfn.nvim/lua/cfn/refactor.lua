local M = {}

local state = require("cfn.state")

function M.scope_list()
  local list = {}
  for path in pairs(state.refactor.scope) do
    table.insert(list, path)
  end
  table.sort(list)
  return list
end

function M.scope_contains(template_path)
  return state.refactor.scope[template_path] == true
end

function M.scope_toggle(template_path)
  if state.refactor.scope[template_path] then
    state.refactor.scope[template_path] = nil
    return false
  end
  state.refactor.scope[template_path] = true
  return true
end

function M.scope_add(template_path)
  state.refactor.scope[template_path] = true
end

function M.add_move(move)
  table.insert(state.refactor.moves, move)
end

function M.moves()
  return state.refactor.moves
end

function M.mark_pending_create(template_path)
  state.refactor.pending_creates[template_path] = true
end

function M.is_pending_create(template_path)
  return state.refactor.pending_creates[template_path] == true
end

function M.has_pending_creates()
  return next(state.refactor.pending_creates) ~= nil
end

function M.clear()
  state.refactor.scope = {}
  state.refactor.moves = {}
  state.refactor.pending_creates = {}
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, err
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then
    return false, err
  end
  f:write(content)
  f:close()
  return true
end

local function buffer_for_path(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) == path then
      return bufnr
    end
  end
  return nil
end

local function get_lines(path)
  local bufnr = buffer_for_path(path)
  if bufnr then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), bufnr
  end
  local content, err = read_file(path)
  if not content then
    return nil, nil, err
  end
  return vim.split(content, "\n", { plain = true }), nil
end

local function set_lines(path, lines, bufnr)
  if bufnr then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! write")
    end)
    return true
  end
  return write_file(path, table.concat(lines, "\n"))
end

local function find_resource_block(lines, logical_id)
  local resources_indent
  local resources_line
  for i, line in ipairs(lines) do
    local indent = line:match("^(%s*)Resources:%s*$")
    if indent then
      resources_indent = #indent
      resources_line = i
      break
    end
  end
  if not resources_line then
    return nil
  end

  local block_start
  local block_indent
  for i = resources_line + 1, #lines do
    local line = lines[i]
    local indent_str, key = line:match("^(%s*)([%w_-]+):")
    if indent_str and key then
      if #indent_str <= resources_indent then
        break
      end
      if key == logical_id then
        block_start = i
        block_indent = #indent_str
        break
      end
    end
  end
  if not block_start then
    return nil
  end

  local block_end = #lines
  for i = block_start + 1, #lines do
    local line = lines[i]
    if line:match("%S") then
      local indent_str = line:match("^(%s*)")
      if #indent_str <= block_indent then
        block_end = i - 1
        break
      end
    end
  end

  while block_end > block_start and lines[block_end]:match("^%s*$") do
    block_end = block_end - 1
  end

  return {
    start_line = block_start,
    end_line = block_end,
    indent = block_indent,
    resources_indent = resources_indent,
  }
end

local function detect_resources_section(lines)
  local resources_indent
  local resources_line
  for i, line in ipairs(lines) do
    local indent = line:match("^(%s*)Resources:%s*$")
    if indent then
      resources_indent = #indent
      resources_line = i
      break
    end
  end
  if not resources_line then
    return nil
  end

  local child_indent
  local last_child_end = resources_line
  for i = resources_line + 1, #lines do
    local line = lines[i]
    if line:match("%S") then
      local indent_str = line:match("^(%s*)")
      if #indent_str <= resources_indent then
        break
      end
      if not child_indent then
        local key_indent = line:match("^(%s*)[%w_-]+:")
        if key_indent then
          child_indent = #key_indent
        end
      end
      last_child_end = i
    end
  end

  return {
    resources_line = resources_line,
    resources_indent = resources_indent,
    child_indent = child_indent or (resources_indent + 2),
    last_child_end = last_child_end,
  }
end

local function reindent(block_lines, from_indent, to_indent)
  if from_indent == to_indent then
    return block_lines
  end
  local out = {}
  for _, line in ipairs(block_lines) do
    if line:match("%S") then
      local indent_str, rest = line:match("^(%s*)(.*)$")
      local current = #indent_str
      local new_indent = current - from_indent + to_indent
      if new_indent < 0 then
        new_indent = 0
      end
      table.insert(out, string.rep(" ", new_indent) .. rest)
    else
      table.insert(out, line)
    end
  end
  return out
end

function M.move_resource(source_path, dest_path, logical_id)
  local source_lines, source_bufnr, err = get_lines(source_path)
  if not source_lines then
    return nil, "read source: " .. (err or "unknown")
  end

  local block = find_resource_block(source_lines, logical_id)
  if not block then
    return nil, "could not locate " .. logical_id .. " in " .. source_path
  end

  local block_lines = {}
  for i = block.start_line, block.end_line do
    table.insert(block_lines, source_lines[i])
  end

  local new_source_lines = {}
  for i, line in ipairs(source_lines) do
    if i < block.start_line or i > block.end_line then
      table.insert(new_source_lines, line)
    end
  end

  if not set_lines(source_path, new_source_lines, source_bufnr) then
    return nil, "write source"
  end

  local dest_lines, dest_bufnr, derr = get_lines(dest_path)
  if not dest_lines then
    return nil, "read dest: " .. (derr or "unknown")
  end

  local dest_section = detect_resources_section(dest_lines)
  local insert_at
  local target_child_indent
  local fresh_resources = false
  if dest_section then
    target_child_indent = dest_section.child_indent
    insert_at = dest_section.last_child_end
  else
    table.insert(dest_lines, "Resources:")
    target_child_indent = 2
    insert_at = #dest_lines
    fresh_resources = true
  end

  local reindented = reindent(block_lines, block.indent, target_child_indent)

  local needs_blank_before = false
  if not fresh_resources and insert_at >= 1 and dest_lines[insert_at] and dest_lines[insert_at]:match("%S") then
    needs_blank_before = true
  end

  local to_insert = {}
  if needs_blank_before then
    table.insert(to_insert, "")
  end
  for _, line in ipairs(reindented) do
    table.insert(to_insert, line)
  end

  local new_dest_lines = {}
  for i = 1, insert_at do
    table.insert(new_dest_lines, dest_lines[i])
  end
  for _, line in ipairs(to_insert) do
    table.insert(new_dest_lines, line)
  end
  for i = insert_at + 1, #dest_lines do
    table.insert(new_dest_lines, dest_lines[i])
  end

  if not set_lines(dest_path, new_dest_lines, dest_bufnr) then
    return nil, "write dest"
  end

  return true
end

return M
