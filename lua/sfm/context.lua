---@class Context
---@field entries Entry[]
---@field open {}
local Context = {}

function Context.new()
  local self = setmetatable({}, { __index = Context })
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

function Context:render(root)
  self.entries = {}

  local function render_entry(current_entry)
    for _, e in ipairs(current_entry.entries) do
      table.insert(self.entries, e)

      if self:is_open(e) then
        render_entry(e)
      end
    end
  end

  render_entry(root)

  local lines = {}
  for linenr, e in ipairs(self.entries) do
    table.insert(lines, e:render(linenr - 1)) -- 0-indexed
  end

  return lines
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

function Context:get_index(fpath)
  for index, e in ipairs(self.entries) do
    if fpath == e.path then
      return index
    end
  end

  return 0
end

return Context
