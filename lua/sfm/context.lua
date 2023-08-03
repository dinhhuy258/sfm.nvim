---@class Context
---@field root Entry
---@field _selections {}
local Context = {}

--- Context constructor
---@param root Entry
---@return Context
function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root
  self._selections = {}

  return self
end

--- change the explorer tree root
---@param root Entry
function Context:change_root(root)
  self.root = root
end

--- bookmark the given entry
function Context:set_selection(entry_path)
  if self:is_selected(entry_path) then
    return
  end

  self._selections[entry_path] = true
end

--- remove the given entry out of the bookmarks list
function Context:remove_selection(entry_path)
  if not self:is_selected(entry_path) then
    return
  end

  self._selections[entry_path] = nil
end

--- check if the given entry is selected
function Context:is_selected(entry_path)
  return self._selections[entry_path] and true or false
end

--- clear the bookmarks list
function Context:clear_selections()
  self._selections = {}
end

--- get the bookmarks list
function Context:get_selections()
  return self._selections
end

return Context
