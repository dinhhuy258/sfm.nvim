---@class Context
---@field root Entry
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

--- open the given entry
---@param entry Entry
function Context:set_open(entry)
  if self:is_open(entry) or not entry.is_dir then
    return
  end

  self.open[entry.path] = true
end

--- close the given entry
---@param entry Entry
function Context:remove_open(entry)
  if not self:is_open(entry) or not entry.is_dir then
    return
  end

  table.remove_key(self.open, entry.path)
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

return Context
