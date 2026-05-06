local M = {}

local fs = require("cfn.fs")

local function projects_dir()
  return vim.fn.stdpath("data") .. "/cfn.nvim/projects"
end

local function cwd_key()
  local cwd = vim.fn.getcwd()
  return (cwd:gsub("%%", "%%%%"):gsub("/", "%%"))
end

function M.file_path()
  return projects_dir() .. "/" .. cwd_key() .. ".json"
end

local function read()
  local path = M.file_path()
  local content = fs.read_text(path)
  if not content or content == "" then
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

local function pretty(value, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)
  local nested = string.rep("  ", indent + 1)

  if type(value) ~= "table" then
    return vim.json.encode(value)
  end
  if next(value) == nil then
    return "{}"
  end
  if vim.islist(value) then
    local items = {}
    for _, v in ipairs(value) do
      table.insert(items, nested .. pretty(v, indent + 1))
    end
    return "[\n" .. table.concat(items, ",\n") .. "\n" .. pad .. "]"
  end

  local keys = vim.tbl_keys(value)
  table.sort(keys)
  local items = {}
  for _, k in ipairs(keys) do
    table.insert(items, nested .. vim.json.encode(tostring(k)) .. ": " .. pretty(value[k], indent + 1))
  end
  return "{\n" .. table.concat(items, ",\n") .. "\n" .. pad .. "}"
end

local function encode_pretty(data)
  return pretty(data, 0) .. "\n"
end

local function write(data)
  vim.fn.mkdir(projects_dir(), "p")
  local path = M.file_path()
  local ok, err = fs.write_text(path, encode_pretty(data))
  if not ok then
    vim.notify("cfn.nvim: failed to write " .. path .. ": " .. err, vim.log.levels.ERROR)
    return false
  end
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
