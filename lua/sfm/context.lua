---@class Context
---@field dir string
---@field entries Entry[]
local Context = {}

function Context.new(dir)
  local self = setmetatable({}, { __index = Context })
  self.dir = dir
  self.entries = nil

  return self
end

function Context:current()
  local entry = self.entries[vim.fn.line "."]
  if entry then
    return entry
  end

  return nil
end

return Context
