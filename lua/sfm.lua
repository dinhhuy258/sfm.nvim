local colors = require "sfm.colors"
local actions = require "sfm.actions"
require "sfm.utils.table"

local M = {}

local explorer = require "sfm.explorer"
local sfm_explorer = explorer.new()

local function config_commands()
  vim.api.nvim_create_user_command("SFMToggle", function()
    sfm_explorer:toggle()
  end, {
    bang = true,
    nargs = "*",
  })
end

function M.setup(cfg)
  colors.setup()
  actions.setup(sfm_explorer)

  config_commands()
end

return M
