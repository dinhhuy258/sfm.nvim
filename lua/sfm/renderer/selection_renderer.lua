local config = require "sfm.config"

local M = {}

--- render selection for the given entry
---@private
---@param entry Entry
---@param ctx Context
---@return table
function M.render_entry(entry, ctx)
  local icons = config.opts.renderer.icons

  if ctx:is_selected(entry) then
    return {
      text = icons.selection,
      highlight = "SFMSelection",
    }
  end

  return {
    text = nil,
    highlight = nil,
  }
end

return M
