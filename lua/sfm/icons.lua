local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local icons = {
  file = {
    default = "",
    symlink = "",
  },
  folder = {
    default = "",
    open = "",
    empty = "",
    empty_open = "",
    symlink = "",
    symlink_open = "",
  },
  indicator = {
    folder_closed = "",
    folder_open = "",
    file = " ",
  },
}

local M = {}

function M.get_icon(entry)
  if entry.is_dir then
    return icons.folder.default
  end

  if not has_devicons then
    return icons.file.default
  end

  return devicons.get_icon(entry.name, string.match(entry.name, "%a+$"), { default = true })
end

function M.get_indicator(entry)
  if entry.is_dir then
    return icons.indicator.folder_closed
  end

  return icons.indicator.file
end

return M
