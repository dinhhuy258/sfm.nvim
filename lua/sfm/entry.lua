local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local log = require "sfm.utils.log"

local icons = {
  file = {
    default = "",
    symlink = "",
  },
  folder = {
    default = "",
    open = "",
    symlink = "",
    symlink_open = "",
  },
  indicator = {
    folder_closed = "",
    folder_open = "",
    file = " ",
  },
}

---@class Entry
---@field name string
---@field path string
---@field is_dir boolean
---@field parent Entry
---@field depth integer
---@field is_root boolean
---@field entries Entry[]
---@field ctx Context
local Entry = {}

function Entry.new(fpath, parent, ctx, is_root)
  local self = setmetatable({}, { __index = Entry })

  fpath = path.clean(fpath)
  local is_dir = path.isdir(fpath)
  local name = path.basename(fpath)

  self.name = name
  self.path = fpath
  self.is_dir = is_dir
  self.entries = {}
  self.parent = parent
  if parent == nil then
    self.depth = 0
  else
    self.depth = self.parent.depth + 1
  end
  self.ctx = ctx
  self.is_root = is_root

  return self
end

function Entry:close()
  if not self.is_dir then
    log.error(self.name .. " is not a directory")

    return
  end

  if not self.ctx:is_open(self) then
    log.error("Directory " .. self.name .. " was already closed")

    return
  end

  self.entries = {}
end

function Entry:render(linenr)
  local indent = string.rep("  ", self.depth - 1)

  local line = ""
  local col_start = 0
  local name, name_hl_group = self:get_name()
  local indicator, indicator_hl_group = self:get_indicator()
  local icon, icon_hl_group = self:get_icon()

  line = indent
  col_start = #line
  line = line .. indicator

  local highlights = {}
  table.insert(highlights, {
    hl_group = indicator_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  line = line .. " "
  col_start = #line
  line = line .. icon

  table.insert(highlights, {
    hl_group = icon_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  line = line .. " "
  col_start = #line
  line = line .. name
  table.insert(highlights, {
    hl_group = name_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  return {
    line = line,
    highlights = highlights,
  }
end

function Entry:scandir()
  if not self.is_dir then
    return
  end

  local entries = {}

  local paths = fs.scandir(self.path)
  for _, fpath in ipairs(paths) do
    table.insert(entries, Entry.new(fpath, self, self.ctx, false))
  end

  -- TODO: allow users to custom entry's order
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

  self.entries = entries
end

function Entry:get_name()
  if self.is_dir then
    return self.name, "SFMFolderName"
  end

  return self.name, "SFMFileName"
end

function Entry:get_icon()
  if self.is_dir then
    if self.ctx:is_open(self) then
      return icons.folder.open, "SFMFolderIcon"
    end

    return icons.folder.default, "SFMFolderIcon"
  end

  if not has_devicons then
    return icons.file.default, "SFMDefaultFileIcon"
  end

  return devicons.get_icon(self.name, path.basename(self.path), { default = true })
end

function Entry:get_indicator()
  if self.is_dir then
    if self.ctx:is_open(self) then
      return icons.indicator.folder_open, "SFMIndicator"
    end

    return icons.indicator.folder_closed, "SFMIndicator"
  end

  return icons.indicator.file, "SFMIndicator"
end

return Entry
