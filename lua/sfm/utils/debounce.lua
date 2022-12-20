local M = {
  debouncers = {},
}

local function timer_stop_close(timer)
  if timer:is_active() then
    timer:stop()
  end
  if not timer:is_closing() then
    timer:close()
  end
end

---Execute callback timeout ms after the latest invocation with context.
---Waiting invocations for that context will be discarded.
---Invocation will be rescheduled while a callback is being executed.
---Caller must ensure that callback performs the same or functionally equivalent actions.
---
---@param context string identifies the callback to debounce
---@param timeout number ms to wait
---@param callback function to execute on completion
function M.debounce(context, timeout, callback)
  -- all execution here is done in a synchronous context; no thread safety required

  M.debouncers[context] = M.debouncers[context] or {}
  local debouncer = M.debouncers[context]

  -- cancel waiting or executing timer
  if debouncer.timer then
    timer_stop_close(debouncer.timer)
  end

  local timer = vim.loop.new_timer()
  debouncer.timer = timer
  timer:start(timeout, 0, function()
    timer_stop_close(timer)

    -- reschedule when callback is running
    if debouncer.executing then
      M.debounce(context, timeout, callback)
      return
    end

    -- call back at a safe time
    debouncer.executing = true
    vim.schedule(function()
      callback()
      debouncer.executing = false

      -- no other timer waiting
      if debouncer.timer == timer then
        M.debouncers[context] = nil
      end
    end)
  end)
end

return M
