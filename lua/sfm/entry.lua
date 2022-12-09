local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local path = require "sfm.utils.path"

local icons = {
  file = {
    default = "",
    symlink = "",
  },
  folder = {
    default = "",
    open = "",
    symlink = "",
    symlink_open = "",
  },
  indicator = {
    folder_closed = "",
    folder_open = "",
    file = " ",
  },
}

local EntryState = {
  Open = 1,
  Close = 2,
}

---@class Entry
---@field name string
---@field path string
---@field is_dir boolean
---@field parent Entry
---@field entries Entry[]
---@field state integer
local Entry = {}

function Entry.new(fpath, parent)
  local self = setmetatable({}, { __index = Entry })

  fpath = string.gsub(fpath, "/+$", "")
  local lstat = vim.loop.fs_lstat(fpath)
  local is_dir = lstat.type == "directory"
  local name = path.basename(fpath)

  self.name = name
  self.path = fpath
  self.is_dir = is_dir
  self.entries = {}
  self.parent = parent
  self.state = EntryState.Close

  return self
end

function Entry:readdir()
  if not self.is_dir then
    return
  end

  local entries = {}

  local handle = vim.loop.fs_scandir(self.path)
  if type(handle) == "userdata" then
    local function iterator()
      return vim.loop.fs_scandir_next(handle)
    end

    for name in iterator do
      local absolute_path = path.join { self.path, name }

      table.insert(entries, Entry.new(absolute_path, self))
    end

    table.sort(entries, function(a, b)
      if a.is_dir and b.is_dir then
        return string.lower(a.name) < string.lower(b.name)
      elseif a.is_dir then
        return true
      elseif b.is_dir then
        return false
      end

      return string.lower(a.name) < string.lower(b.name)
    end)
  end

  self.entries = entries
end

function Entry:get_icon()
  if self.is_dir then
    return icons.folder.default
  end

  if not has_devicons then
    return icons.file.default
  end

  return devicons.get_icon(self.name, path.basename(self.path), { default = true })
end

function Entry:get_indicator()
  if self.is_dir then
    return icons.indicator.folder_closed
  end

  return icons.indicator.file
end

return Entry
