local config = require "sfm.config"

local M = {}

--- render indicator for the given entry
---@private
---@param entry Entry
---@return table
function M.render_entry_indicator(entry)
  local is_entry_open = entry.is_open
  local icons = config.opts.renderer.icons
  local indicator = (entry:has_children() and is_entry_open and icons.indicator.folder_open)
    or (entry:has_children() and not is_entry_open and icons.indicator.folder_closed)
    or icons.indicator.file
  local indicator_hl_group = entry:has_children() and "SFMFolderIndicator" or "SFMFileIndicator"

  return {
    text = indicator .. " ",
    highlight = indicator_hl_group,
  }
end

return M
