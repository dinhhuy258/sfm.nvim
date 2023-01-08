local buffer = require "sfm.view.buffer"
local window = require "sfm.view.window"
local event = require "sfm.event"
local config = require "sfm.config"

---@class View
---@field tab_infos table
---@field event_manager EventManager
local View = {}

--- View constructor
---@param event_manager EventManager
---@return View
function View.new(event_manager)
  local self = setmetatable({}, { __index = View })

  self.event_manager = event_manager
  self.tab_infos = {}

  return self
end

-- get current tab info
function View:_get_current_tab_info()
  local tabnr = vim.api.nvim_get_current_tabpage()

  return self.tab_infos[tabnr]
end

--- check if the explorer is open or not
---@return boolean
function View:is_open()
  local tab_info = self:_get_current_tab_info()
  if tab_info == nil then
    return false
  end

  local winnr = tab_info.winnr
  local bufnr = tab_info.bufnr

  return winnr ~= nil and vim.api.nvim_win_is_valid(winnr) and bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

--- close the explorer
function View:close()
  if not self:is_open() then
    return
  end

  local tab_info = self:_get_current_tab_info()
  vim.api.nvim_win_close(tab_info.winnr, true)

  local tabnr = vim.api.nvim_get_current_tabpage()
  table.remove_key(self.tab_infos, tabnr)
end

--- open the explorer
function View:open()
  if self:is_open() then
    return
  end

  local winnr = window.create_window()
  local bufnr = buffer.create_buffer()

  vim.api.nvim_win_set_buf(winnr, bufnr)

  buffer.set_buffer_options(bufnr)
  window.set_window_option()
  vim.api.nvim_win_set_width(winnr, config.opts.view.width)

  local tabnr = vim.api.nvim_get_current_tabpage()
  self.tab_infos[tabnr] = {
    winnr = winnr,
    bufnr = bufnr,
  }

  self.event_manager:dispatch(event.ExplorerOpened, {
    winnr = winnr,
    bufnr = bufnr,
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

    local tab_info = self:_get_current_tab_info()
    if tab_info == nil then
      return
    end

    local winnr = tab_info.winnr
    local bufnr = tab_info.bufnr

    if curwin ~= winnr or curbuf == bufnr or bufname == "" then
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

  local tab_info = self:_get_current_tab_info()
  vim.api.nvim_win_set_cursor(tab_info.winnr, { row, col })
end

--- render the given lines to window
---@param lines table
function View:render(lines)
  if not self:is_open() then
    return
  end

  local tab_info = self:_get_current_tab_info()
  buffer.render(tab_info.bufnr, lines)
end

--- reset the sfm explorer window highlight (used on ColorScheme event)
function View:reset_winhl()
  if not self:is_open() then
    return
  end

  local tab_info = self:_get_current_tab_info()
  window.reset_winhl(tab_info.winnr)
end

return View
