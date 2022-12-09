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

function Entry.new(path, parent)
  local self = setmetatable({}, { __index = Entry })

  path = string.gsub(path, "/+$", "")
  local lstat = vim.loop.fs_lstat(path)
  local is_dir = lstat.type == "directory"
  local name = vim.fn.fnamemodify(path, ":t")

  self.name = name
  self.path = path
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
      local absolute_path = self.path .. "/" .. name

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

return Entry
