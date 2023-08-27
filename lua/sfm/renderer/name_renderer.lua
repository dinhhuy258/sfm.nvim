local api = require "sfm.api"

local config = require "sfm.config"

local M = {}

--- render name for the given entry
---@private
---@param entry Entry
---@return table
function M.render_entry_name(entry)
  local name = entry.name
  local name_hl_group = entry.is_dir and "SFMFolderName" or "SFMFileName"
  if config.opts.view.selection_render_method == "highlight" and api.context.is_selected(entry.path) then
    name_hl_group = "SFMSelection"
  end

  return {
    text = name,
    highlight = name_hl_group,
  }
end

return M
