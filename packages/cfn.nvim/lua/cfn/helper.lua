local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

local function binary_path()
  return plugin_root() .. "/bin/cfn-nvim-helper"
end

local function process(result)
  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    if err == "" then
      err = "cfn-nvim-helper exited " .. tostring(result.code)
    end
    return nil, err
  end
  return result.stdout or "", nil
end

function M.run(args, stdin)
  local cmd = { binary_path() }
  vim.list_extend(cmd, args)

  local opts = { text = true }
  if stdin then
    opts.stdin = stdin
  end

  local co = coroutine.running()
  if co then
    local ok, sys_err = pcall(function()
      vim.system(cmd, opts, function(result)
        vim.schedule(function()
          coroutine.resume(co, result)
        end)
      end)
    end)
    if not ok then
      return nil, "failed to spawn cfn-nvim-helper: " .. tostring(sys_err)
    end
    local result = coroutine.yield()
    return process(result)
  end

  local ok, result = pcall(function()
    return vim.system(cmd, opts):wait()
  end)
  if not ok then
    return nil, "failed to invoke cfn-nvim-helper: " .. tostring(result)
  end
  return process(result)
end

return M
