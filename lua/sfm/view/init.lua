local buffer = require "sfm.view.buffer"
local window = require "sfm.view.window"
local event = require "sfm.event"
local config = require "sfm.config"

---@class View
---@field winnr integer
---@field bufnr integer
---@field event_manager EventManager
local View = {}

--- View constructor
---@param event_manager EventManager
---@return View
function View.new(event_manager)
  local self = setmetatable({}, { __index = View })

  self.event_manager = event_manager
  self.winnr = nil
  self.bufnr = nil

  return self
end

--- check if the explorer is open or not
---@return boolean
function View:is_open()
  return self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr)
end

--- close the explorer
function View:close()
  if self:is_open() then
    vim.api.nvim_win_close(self.winnr, 1)
  end

  self.winnr = nil
end

--- open the explorer
function View:open()
  self.winnr = window.create_window()
  self.bufnr = buffer.create_buffer()
  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  buffer.set_buffer_options(self.bufnr)
  window.set_window_option()
  vim.api.nvim_win_set_width(self.winnr, config.opts.view.width)

  self.event_manager:dispatch(event.ExplorerOpen, {
    winnr = self.winnr,
    bufnr = self.bufnr,
  })
end

--- prevent explorer buffer is being overrided
function View:prevent_buffer_override()
  if not self:is_open() then
    return
  end

  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if curwin ~= self.winnr or curbuf == self.bufnr or bufname == "" then
      return
    end

    pcall(vim.api.nvim_win_close, curwin, { force = true })
    pcall(vim.cmd, "edit " .. bufname)
  end)
end

--- move the cursor to (row, col)
---@param row integer
---@param col integer
function View:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.winnr, { row, col })
end

--- render the given lines to window
---@param lines table
function View:render(lines)
  if not self:is_open() then
    return
  end

  buffer.render(self.bufnr, lines)
end

--- reset the sfm explorer window highlight (used on ColorScheme event)
function View:reset_winhl()
  if self:is_open() then
    window.reset_winhl(self.winnr)
  end
end

return View
