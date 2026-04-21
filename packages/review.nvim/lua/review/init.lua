local M = {}

local ns = vim.api.nvim_create_namespace("review_nvim")

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  info = vim.diagnostic.severity.INFO,
  hint = vim.diagnostic.severity.HINT,
}

local defaults = {
  cache_dir = vim.fn.expand("~/.cache/review.nvim"),
}

M.config = {}

local function get_diagnostics_path()
  local cwd = vim.fn.getcwd()
  local hash = vim.fn.sha256(cwd):sub(1, 16)
  local dir = M.config.cache_dir .. "/" .. hash
  return dir, dir .. "/diagnostics.json"
end

local function apply_diagnostics(path)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or #content == 0 then
    return
  end

  local json_str = table.concat(content, "\n")
  local parse_ok, diagnostics = pcall(vim.json.decode, json_str)
  if not parse_ok or type(diagnostics) ~= "table" then
    return
  end

  local by_file = {}
  for _, d in ipairs(diagnostics) do
    if d.filePath and d.line and d.message then
      if not by_file[d.filePath] then
        by_file[d.filePath] = {}
      end
      table.insert(by_file[d.filePath], {
        lnum = d.line - 1,
        col = 0,
        severity = severity_map[d.severity] or vim.diagnostic.severity.WARN,
        message = d.message,
        source = "review.nvim",
      })
    end
  end

  vim.diagnostic.reset(ns)

  for fp, diags in pairs(by_file) do
    local bufnr = vim.fn.bufnr(fp)
    if bufnr == -1 then
      bufnr = vim.fn.bufadd(fp)
      vim.fn.bufload(bufnr)
    end
    vim.diagnostic.set(ns, bufnr, diags)
  end

  if #diagnostics > 0 then
    vim.notify("review.nvim: " .. #diagnostics .. " diagnostic(s) published", vim.log.levels.INFO)
  end
end

function M.clear()
  vim.diagnostic.reset(ns)
  local _, path = get_diagnostics_path()
  vim.fn.writefile({ "[]" }, path)
  vim.notify("review.nvim: diagnostics cleared", vim.log.levels.INFO)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  local dir, diag_path = get_diagnostics_path()
  vim.fn.mkdir(dir, "p")
  if vim.fn.filereadable(diag_path) == 0 then
    vim.fn.writefile({ "[]" }, diag_path)
  end

  local handle = vim.uv.new_fs_event()
  if handle then
    handle:start(diag_path, {}, vim.schedule_wrap(function(err)
      if not err then
        apply_diagnostics(diag_path)
      end
    end))
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        handle:stop()
        if not handle:is_closing() then
          handle:close()
        end
      end,
    })
  end

  apply_diagnostics(diag_path)
end

return M
