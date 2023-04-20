local config = require "sfm.config"

local M = {}

--- create new sfm float window
---@return integer
function M.create_window()
  local open_win_config = vim.tbl_extend("force", config.opts.view.float.config, {
    noautocmd = true,
    zindex = 60,
  })

  return vim.api.nvim_open_win(0, true, open_win_config)
end

return M
