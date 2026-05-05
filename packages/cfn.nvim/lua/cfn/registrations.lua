local M = {}

local function data_dir()
  return vim.fn.stdpath("data") .. "/cfn.nvim"
end

function M.file_path()
  return data_dir() .. "/registrations.json"
end

local function read()
  local path = M.file_path()
  local f = io.open(path, "r")
  if not f then
    return { templates = {} }
  end
  local content = f:read("*a")
  f:close()
  if content == "" then
    return { templates = {} }
  end
  local ok, parsed = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("cfn.nvim: failed to parse " .. path .. ": " .. parsed, vim.log.levels.ERROR)
    return { templates = {} }
  end
  parsed.templates = parsed.templates or {}
  return parsed
end

local function encode_pretty(data)
  local templates = data.templates or {}
  local keys = vim.tbl_keys(templates)
  table.sort(keys)
  if #keys == 0 then
    return '{\n  "templates": {}\n}\n'
  end
  local entries = {}
  for _, k in ipairs(keys) do
    table.insert(entries, "    " .. vim.json.encode(k) .. ": " .. vim.json.encode(templates[k]))
  end
  return '{\n  "templates": {\n' .. table.concat(entries, ",\n") .. "\n  }\n}\n"
end

local function write(data)
  vim.fn.mkdir(data_dir(), "p")
  local path = M.file_path()
  local f, err = io.open(path, "w")
  if not f then
    vim.notify("cfn.nvim: failed to open " .. path .. ": " .. err, vim.log.levels.ERROR)
    return false
  end
  f:write(encode_pretty(data))
  f:close()
  return true
end

function M.get(template_path)
  return read().templates[template_path]
end

function M.set(template_path, registration)
  local data = read()
  data.templates[template_path] = registration
  return write(data)
end

function M.remove(template_path)
  local data = read()
  data.templates[template_path] = nil
  return write(data)
end

function M.list()
  return read().templates
end

return M
