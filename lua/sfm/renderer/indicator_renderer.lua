local config = require "sfm.config"

local M = {}

--- render indicator for the given entry
---@private
---@param entry Entry
---@param ctx Context
---@return table
function M.render_entry(entry, ctx)
  local is_entry_open = ctx:is_open(entry)
  local icons = config.opts.renderer.icons
  local indicator = (entry.is_dir and is_entry_open and icons.indicator.folder_open)
    or (entry.is_dir and not is_entry_open and icons.indicator.folder_closed)
    or icons.indicator.file
  local indicator_hl_group = entry.is_dir and "SFMFolderIndicator" or "SFMFileIndicator"

  return {
    text = indicator,
    highlight = indicator_hl_group,
  }
end

return M
