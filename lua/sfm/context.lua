---@class Context
---@field root Entry
local Context = {}

--- Context constructor
---@param root Entry
---@return Context
function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root

  return self
end

--- change the explorer tree root
---@param root Entry
function Context:change_root(root)
  self.root = root
end

return Context
