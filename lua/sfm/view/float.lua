local config = require "sfm.config"

local M = {}

--- create new sfm float window
---@return integer
function M.create_window()
  local open_win_config = vim.tbl_extend("force", config.opts.view.float.config, {
    noautocmd = true,
    zindex = 60,
  })

  if type(open_win_config.width) == "function" then
    open_win_config.width = open_win_config.width()
  end

  if type(open_win_config.height) == "function" then
    open_win_config.height = open_win_config.height()
  end

  if type(open_win_config.row) == "function" then
    open_win_config.row = open_win_config.row()
  end

  if type(open_win_config.col) == "function" then
    open_win_config.col = open_win_config.col()
  end

  return vim.api.nvim_open_win(0, true, open_win_config)
end

return M
