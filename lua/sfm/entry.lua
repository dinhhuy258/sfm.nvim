local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"

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
---@field is_symlink boolean
---@field parent Entry
---@field depth integer
---@field is_root boolean
---@field is_open boolean
---@field entries Entry[]
local Entry = {}

function Entry.new(fpath, parent, is_root)
  local self = setmetatable({}, { __index = Entry })

  fpath = path.clean(fpath)
  local name = path.basename(fpath)

  self.name = name
  self.path = fpath
  self.is_dir = path.isdir(fpath)
  self.is_symlink = path.islink(fpath)
  self.entries = {}
  self.parent = parent
  self.is_root = is_root
  self.is_open = false

  if parent == nil then
    self.depth = 0
  else
    self.depth = self.parent.depth + 1
  end

  return self
end

function Entry:line(linenr)
  if self.is_root then
    local root_name = path.join {
      path.remove_trailing(vim.fn.fnamemodify(self.path, ":~")),
      "..",
    }

    local highlights = {}
    table.insert(highlights, {
      hl_group = "SFMRootFolder",
      col_start = 0,
      col_end = string.len(root_name),
      line = linenr,
    })

    return {
      line = root_name,
      highlights = highlights,
    }
  end

  local indent = string.rep("  ", self.depth - 1)

  local highlights = {}
  local line = ""
  local col_start = 0
  local name, name_hl_group = self:_get_name()
  local indicator, indicator_hl_group = self:_get_indicator()
  local icon, icon_hl_group = self:_get_icon()

  line = indent
  col_start = #line
  line = line .. indicator
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

function Entry:set_open()
  self.is_open = true
end

function Entry:remove_open()
  self.is_open = false
end

function Entry:scandir()
  if not self.is_dir then
    return
  end

  local entries = {}

  local paths = fs.scandir(self.path)
  for _, fpath in ipairs(paths) do
    table.insert(entries, Entry.new(fpath, self, false))
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

function Entry:_get_name()
  if self.is_dir then
    return self.name, "SFMFolderName"
  end

  return self.name, "SFMFileName"
end

function Entry:_get_icon()
  if self.is_symlink then
    if self.is_dir then
      if self.is_open then
        return icons.folder.symlink_open, "SFMFolderIcon"
      end

      return icons.folder.symlink, "SFMFolderIcon"
    end

    return icons.file.symlink, "SFMDefaultFileIcon"
  end

  if self.is_dir then
    if self.is_open then
      return icons.folder.open, "SFMFolderIcon"
    end

    return icons.folder.default, "SFMFolderIcon"
  end

  if not has_devicons then
    return icons.file.default, "SFMDefaultFileIcon"
  end

  return devicons.get_icon(self.name, nil, { default = true })
end

function Entry:_get_indicator()
  if self.is_dir then
    if self.is_open then
      return icons.indicator.folder_open, "SFMIndicator"
    end

    return icons.indicator.folder_closed, "SFMIndicator"
  end

  return icons.indicator.file, "SFMIndicator"
end

return Entry
