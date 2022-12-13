---@class Context
---@field root Entry
---@field entries Entry[]
---@field open {}
---@field selections {}
local Context = {}

--- Context constructor
---@param root Entry
---@return Context
function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root
  self.entries = {}
  self.open = {}
  self.selections = {}

  return self
end

--- get the current entry at the current position
---@return Entry
function Context:current()
  local entry = self.entries[vim.fn.line "."]
  if entry then
    return entry
  end

  error "failed to get the current entry"
end

--- refresh the render entries
function Context:refresh_entries()
  self.entries = {}

  local function _refresh_entry(current_entry)
    for _, e in ipairs(current_entry.entries) do
      table.insert(self.entries, e)

      if self:is_open(e) then
        _refresh_entry(e)
      end
    end
  end

  table.insert(self.entries, self.root)
  _refresh_entry(self.root)
end

--- open the given entry
---@param entry Entry
function Context:set_open(entry)
  if self:is_open(entry) or not entry.is_dir then
    return
  end

  entry:scandir()
  self.open[entry.path] = true
  self:refresh_entries()
end

--- close the given entry
---@param entry Entry
function Context:remove_open(entry)
  if not self:is_open(entry) or not entry.is_dir then
    return
  end

  table.remove_key(self.open, entry.path)
  self:refresh_entries()
end

--- check if the given entry is open
---@param entry Entry
---@return boolean
function Context:is_open(entry)
  return table.contains_key(self.open, entry.path)
end

--- bookmark the given entry
---@param entry Entry
function Context:set_selection(entry)
  if self:is_selected(entry) then
    return
  end

  self.selections[entry.path] = true
end

--- remove the given entry out of the bookmarks list
---@param entry Entry
function Context:remove_selection(entry)
  if not self:is_selected(entry) then
    return
  end

  table.remove_key(self.selections, entry.path)
end

--- check if the given entry is selected
---@param entry Entry
---@return boolean
function Context:is_selected(entry)
  return table.contains_key(self.selections, entry.path)
end

--- clear the bookmarks list
function Context:clear_selections()
  self.selections = {}
end

--- obtain the line of the current path
---@param fpath string
---@return integer
function Context:get_index(fpath)
  for index, e in ipairs(self.entries) do
    if fpath == e.path then
      return index
    end
  end

  return 0
end

return Context
