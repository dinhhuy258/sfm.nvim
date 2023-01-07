local config = require "sfm.config"

local M = {}

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

--- create new sfm window
---@return integer
function M.create_window()
  vim.api.nvim_command "vsp"
  if config.opts.view.side == "right" then
    vim.api.nvim_command "wincmd L" -- right
  else
    vim.api.nvim_command "wincmd H" -- left
  end

  return vim.api.nvim_get_current_win()
end

--- set window option
function M.set_window_option()
  for option, value in pairs(WIN_OPTIONS) do
    vim.opt_local[option] = value
  end
end

--- reset the sfm explorer window highlight (used on ColorScheme event)
---@param winnr integer
function M.reset_winhl(winnr)
  vim.wo[winnr].winhl = WIN_OPTIONS.winhl
end

return M
