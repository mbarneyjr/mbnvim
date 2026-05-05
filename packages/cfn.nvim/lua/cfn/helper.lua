local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

local function binary_path()
  return plugin_root() .. "/bin/cfn-nvim-helper"
end

function M.run(args, stdin)
  local cmd = { binary_path() }
  vim.list_extend(cmd, args)

  local opts = { text = true }
  if stdin then
    opts.stdin = stdin
  end

  local ok, result = pcall(function()
    return vim.system(cmd, opts):wait()
  end)
  if not ok then
    return nil, "failed to invoke cfn-nvim-helper: " .. tostring(result)
  end
  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    if err == "" then
      err = "cfn-nvim-helper exited " .. tostring(result.code)
    end
    return nil, err
  end
  return result.stdout or "", nil
end

return M
