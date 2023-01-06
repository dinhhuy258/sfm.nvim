local event = require "sfm.event"
local buffer_manager = require "sfm.view.buffer_manager"

---@class Window
---@field cfg Config
---@field winnr integer
---@field buffer_manager BufferManager
---@field event_manager EventManager
local Window = {}

local WIN_OPTIONS = {
  relativenumber = false,
  number = false,
  list = false,
  foldenable = false,
  winfixwidth = true,
  winfixheight = true,
  spell = false,
  signcolumn = "yes",
  foldmethod = "manual",
  foldcolumn = "0",
  cursorcolumn = false,
  cursorline = true,
  cursorlineopt = "both",
  colorcolumn = "0",
  wrap = false,
  winhl = table.concat({
    "EndOfBuffer:SFMEndOfBuffer",
    "Normal:SFMNormal",
    "CursorLine:SFMCursorLine",
    "CursorLineNr:SFMCursorLineNr",
    "LineNr:SFMLineNr",
    "WinSeparator:SFMWinSeparator",
    "StatusLine:SFMStatusLine",
    "StatusLineNC:SFMStatuslineNC",
    "SignColumn:SFMSignColumn",
    "NormalNC:SFMNormalNC",
  }, ","),
}

--- Window constructor
---@param cfg Config
---@param event_manager EventManager
---@return Window
function Window.new(cfg, event_manager)
  local self = setmetatable({}, { __index = Window })

  self.cfg = cfg
  self.winnr = nil
  self.event_manager = event_manager
  self.buffer_manager = buffer_manager.new(cfg)

  return self
end

--- check if the window is open or not
---@return boolean
function Window:is_open()
  return self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr)
end

--- close the window
function Window:close()
  if self:is_open() then
    vim.api.nvim_win_close(self.winnr, 1)
  end

  self.winnr = nil
end

--- open the sfm window
function Window:create_window()
  vim.api.nvim_command "vsp"
  vim.api.nvim_command "wincmd H"

  self.winnr = vim.api.nvim_get_current_win()
end

--- open the window
function Window:open()
  self:create_window()
  self.buffer_manager:create_buffer()
  vim.api.nvim_win_set_buf(self.winnr, self.buffer_manager.bufnr)

  vim.api.nvim_win_set_width(self.winnr, self.cfg.opts.view.width)
  for option, value in pairs(WIN_OPTIONS) do
    vim.opt_local[option] = value
  end

  self.event_manager:dispatch(event.ExplorerOpen, {
    winnr = self.winnr,
    bufnr = self.buffer_manager.bufnr,
  })
end

--- prevent explorer buffer is being overrided
function Window:prevent_buffer_override()
  if not self:is_open() then
    return
  end

  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if curwin ~= self.winnr or curbuf == self.buffer_manager.bufnr or bufname == "" then
      return
    end

    pcall(vim.api.nvim_win_close, curwin, { force = true })
    pcall(vim.cmd, "edit " .. bufname)
  end)
end

--- move the cursor to (row, col)
---@param row integer
---@param col integer
function Window:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.winnr, { row, col })
end

--- render the given lines to window
---@param lines table
function Window:render(lines)
  if not self:is_open() then
    return
  end

  self.buffer_manager:render(lines)
end

--- reset the sfm explorer window highlight (used on ColorScheme event)
function Window:reset_winhl()
  if self:is_open() then
    vim.wo[self.winnr].winhl = WIN_OPTIONS.winhl
  end
end

return Window
