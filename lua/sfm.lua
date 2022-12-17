local explorer = require "sfm.explorer"
local colors = require "sfm.colors"
local actions = require "sfm.actions"
require "sfm.utils.table"

local M = {}

function M.setup(opts)
  colors.setup()

  local sfm_explorer = explorer.new(opts)
  actions.setup(sfm_explorer)

  vim.api.nvim_create_user_command("SFMToggle", function()
    sfm_explorer:toggle()
  end, {
    bang = true,
    nargs = "*",
  })
end

return M
