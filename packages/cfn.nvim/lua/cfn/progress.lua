local M = {}

local counter = 0

local function next_id()
  counter = counter + 1
  return "cfn.nvim:" .. counter
end

local function notify(message, level, state, timeout)
  state.handle = vim.notify(message, level, {
    title = "cfn.nvim",
    id = state.id,
    replace = state.handle,
    timeout = timeout,
  })
end

function M.start(message)
  local state = { id = next_id() }
  notify(message, vim.log.levels.INFO, state, false)
  return state
end

function M.update(state, message)
  notify(message, vim.log.levels.INFO, state, false)
end

function M.finish(state, message, level)
  level = level or vim.log.levels.INFO
  local timeout = level == vim.log.levels.ERROR and 10000 or 3000
  notify(message, level, state, timeout)
end

return M
