local M = {}

--- render name for the given entry
---@private
---@param entry Entry
---@return table
function M.render_entry_name(entry)
  local name = entry.name
  local name_hl_group = entry.is_dir and "SFMFolderName" or "SFMFileName"

  return {
    text = name,
    highlight = name_hl_group,
  }
end

return M
