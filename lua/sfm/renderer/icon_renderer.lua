local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local config = require "sfm.config"

local M = {}

--- render icon for the given entry
---@private
---@param entry Entry
---@return table
function M.render_entry_icon(entry)
  local icons = config.opts.renderer.icons
  local is_entry_open = entry.is_open
  local icon = ""
  local icon_hl_group = ""
  if entry.is_symlink then
    if entry.is_dir then
      if is_entry_open then
        icon = icons.folder.symlink_open
        icon_hl_group = "SFMFolderIcon"
      else
        icon = icons.folder.symlink
        icon_hl_group = "SFMFolderIcon"
      end
    else
      icon = icons.file.symlink
      icon_hl_group = "SFMDefaultFileIcon"
    end
  elseif entry.is_dir then
    if is_entry_open then
      icon = icons.folder.open
      icon_hl_group = "SFMFolderIcon"
    else
      icon = icons.folder.default
      icon_hl_group = "SFMFolderIcon"
    end
  elseif not has_devicons then
    icon = icons.file.default
    icon_hl_group = "SFMDefaultFileIcon"
  else
    icon, icon_hl_group = devicons.get_icon(entry.name, nil, { default = true })
    if icon_hl_group == "DevIconDefault" then
      icon = icons.file.default
      icon_hl_group = "SFMDefaultFileIcon"
    end
  end

  return {
    text = icon .. " ",
    highlight = icon_hl_group,
  }
end

return M
