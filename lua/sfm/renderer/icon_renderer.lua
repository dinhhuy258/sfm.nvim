local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local M = {}

--- render icon for the given entry
---@private
---@param entry Entry
---@param ctx Context
---@param cfg Config
---@return table
function M.render_entry(entry, ctx, cfg)
  local icons = cfg.opts.renderer.icons
  local is_entry_open = ctx:is_open(entry)
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
  elseif not has_devicons or not cfg.opts.devicons_enable then
    icon = icons.file.default
    icon_hl_group = "SFMDefaultFileIcon"
  else
    icon, icon_hl_group = devicons.get_icon(entry.name, nil, { default = true })
  end

  return {
    text = icon,
    highlight = icon_hl_group,
  }
end

return M
