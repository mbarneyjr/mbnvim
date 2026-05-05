local M = {}

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local SPINNER_INTERVAL_MS = 100

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

local function render(state)
  notify(SPINNER_FRAMES[state.frame] .. "  " .. state.message, vim.log.levels.INFO, state, false)
end

local function stop_timer(state)
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

function M.start(message)
  local state = { id = next_id(), message = message, frame = 1 }
  render(state)
  if state.handle ~= nil then
    state.timer = vim.uv.new_timer()
    state.timer:start(
      SPINNER_INTERVAL_MS,
      SPINNER_INTERVAL_MS,
      vim.schedule_wrap(function()
        if not state.timer then
          return
        end
        state.frame = (state.frame % #SPINNER_FRAMES) + 1
        render(state)
      end)
    )
  end
  return state
end

function M.update(state, message)
  state.message = message
  if not state.timer then
    notify(message, vim.log.levels.INFO, state, false)
  end
end

function M.finish(state, message, level)
  stop_timer(state)
  level = level or vim.log.levels.INFO
  local timeout = level == vim.log.levels.ERROR and 10000 or 3000
  notify(message, level, state, timeout)
end

return M
