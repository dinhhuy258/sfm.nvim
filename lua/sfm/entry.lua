local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"

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

---@class EntryPool
---@field _entries table<string, Entry>
local EntryPool = {
  _entries = {},
}

--- get entry from the pool
---@param fpath string
---@param parent Entry|nil
---@return Entry
function EntryPool.get_entry(fpath, parent)
  -- check if an entry object already exists for the given path
  if EntryPool._entries[fpath] ~= nil then
    return EntryPool._entries[fpath]
  end

  -- create a new entry object if one doesn't exist
  local entry = Entry._new(fpath, parent and EntryPool._entries[parent.path] or nil)
  EntryPool._entries[fpath] = entry
  return entry
end

--- clear the entries pool
function EntryPool.clear()
  EntryPool._entries = {}
end

--- create a new entry object
function Entry._new(fpath, parent)
  local self = setmetatable({}, { __index = Entry })

  fpath = path.clean(fpath)
  local name = path.basename(fpath)

  self.name = name
  self.path = fpath
  self.is_dir = path.isdir(fpath)
  self.is_symlink = path.islink(fpath)
  self.entries = {}
  self.parent = parent
  self.is_root = parent == nil and true or false
  self.is_open = self.is_root and true or false

  if parent == nil then
    self.depth = 0
  else
    self.depth = self.parent.depth + 1
  end

  return self
end

--- open the current directory
---@param sort_by function|nil
---@param force boolean
function Entry:open(sort_by, force)
  if not self.is_dir or (self.is_open and not force) then
    return
  end

  self.is_open = true
  self:_scandir(sort_by)
end

--- close the current directory
function Entry:close()
  if not self.is_dir then
    return
  end

  self.is_open = false
end

--- scan the current directory
---@private
---@param sort_by function|nil
function Entry:_scandir(sort_by)
  if not self.is_dir then
    return
  end

  local entries = {}

  local paths = fs.scandir(self.path)
  for _, fpath in ipairs(paths) do
    table.insert(entries, EntryPool.get_entry(fpath, self))
  end

  if sort_by ~= nil then
    table.sort(entries, sort_by)
  else
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

local M = {}

M.get_entry = EntryPool.get_entry
M.clear_pool = EntryPool.clear

return M
