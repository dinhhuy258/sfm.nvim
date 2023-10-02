local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local config = require "sfm.config"

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
---@field nested_parent Entry|nil
---@field nested_children Entry[]
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
  local entry_key = fpath
  if path.isdir(fpath) then
    entry_key = path.add_trailing(fpath)
  end

  -- check if an entry object already exists for the given path
  if EntryPool._entries[entry_key] ~= nil then
    local e = EntryPool._entries[entry_key]
    e.nested_parent = nil
    e.nested_children = {}

    return e
  end

  -- create a new entry object if one doesn't exist
  local entry = Entry._new(fpath, parent and EntryPool._entries[path.add_trailing(parent.path)] or nil)
  EntryPool._entries[entry_key] = entry

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
  self.nested_parent = nil
  self.nested_children = {}
  if config.opts.file_nesting.enabled and not self.is_dir then
    self.is_open = true
  end

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
  if not self:has_children() or (self.is_open and not force) then
    return
  end

  self.is_open = true
  self:_scandir(sort_by)
end

--- check if the current entry has children
---@return boolean
function Entry:has_children()
  return self.is_dir or #self.nested_children ~= 0
end

function Entry:get_children()
  if self.is_dir then
    return self.entries
  end

  return self.nested_children
end

--- close the current directory
function Entry:close()
  if not self:has_children() then
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

  local files = {}
  local dirs = {}

  local paths = fs.scandir(self.path)
  for _, fpath in ipairs(paths) do
    local e = EntryPool.get_entry(fpath, self)
    if e.is_dir then
      table.insert(dirs, e)
    else
      table.insert(files, e)
    end
  end

  local entries = {}

  if config.opts.file_nesting.enabled then
    local nested_files = config.file_nesting_trie:nest(
      -- extract file names only
      vim.tbl_map(function(e)
        return e.name
      end, files)
    )

    for _, e in ipairs(files) do
      if nested_files[e.name] ~= nil then
        e.nested_children = {}
        for _, name in ipairs(nested_files[e.name]) do
          local child = EntryPool.get_entry(path.join { self.path, name }, self)
          table.insert(e.nested_children, child)
          child.nested_parent = e
        end

        table.insert(entries, e)
      else
        e.nested_children = {}
      end
    end

    for _, e in ipairs(dirs) do
      table.insert(entries, e)
    end
  else
    for _, e in ipairs(dirs) do
      table.insert(entries, e)
    end

    for _, e in ipairs(files) do
      table.insert(entries, e)
    end
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
