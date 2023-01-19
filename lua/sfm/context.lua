---@class Context
---@field root Entry
---@field open {}
local Context = {}

--- Context constructor
---@param root Entry
---@return Context
function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root
  self.open = {}

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

--- change the explorer tree root
---@param root Entry
function Context:change_root(root)
  self.root = root
end

return Context
