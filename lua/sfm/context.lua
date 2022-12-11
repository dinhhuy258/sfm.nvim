---@class Context
---@field root string
---@field entries Entry[]
---@field open {}
local Context = {}

function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root
  self.entries = nil
  self.open = {}

  return self
end

function Context:current()
  local entry = self.entries[vim.fn.line "."]
  if entry then
    return entry
  end

  return nil
end

function Context:set_open(entry)
  if self:is_open(entry) or not entry.is_dir then
    return
  end

  entry:scandir()
  self.open[entry.path] = true
end

function Context:remove_open(entry)
  if not self:is_open(entry) or not entry.is_dir then
    return
  end

  entry:close()
  table.remove_key(self.open, entry.path)
end

function Context:is_open(entry)
  return table.contains_key(self.open, entry.path)
end

function Context:get_index(entry)
  for index, e in ipairs(self.entries) do
    if entry.path == e.path then
      return index
    end
  end

  return 0
end

return Context
