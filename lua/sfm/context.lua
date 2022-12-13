---@class Context
---@field root Entry
---@field entries Entry[]
---@field open {}
---@field selections {}
local Context = {}

function Context.new(root)
  local self = setmetatable({}, { __index = Context })
  self.root = root
  self.entries = nil
  self.open = {}
  self.selections = {}

  return self
end

function Context:current()
  local entry = self.entries[vim.fn.line "."]
  if entry then
    return entry
  end

  return nil
end

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

function Context:lines()
  local lines = {}
  for linenr, e in ipairs(self.entries) do
    table.insert(lines, e:line(linenr - 1)) -- 0-indexed
  end

  return lines
end

function Context:set_open(entry)
  if self:is_open(entry) or not entry.is_dir then
    return
  end

  entry:scandir()
  self.open[entry.path] = true
  entry:set_open()
  self:refresh_entries()
end

function Context:remove_open(entry)
  if not self:is_open(entry) or not entry.is_dir then
    return
  end

  table.remove_key(self.open, entry.path)
  entry:remove_open()
  self:refresh_entries()
end

function Context:is_open(entry)
  return table.contains_key(self.open, entry.path)
end

function Context:set_selection(entry)
  if self:is_selected(entry) then
    return
  end

  entry:set_selection()
  self.selections[entry.path] = true
end

function Context:remove_selection(entry)
  if not self:is_selected(entry) then
    return
  end

  entry:remove_selection()
  table.remove_key(self.selections, entry.path)
end

function Context:is_selected(entry)
  return table.contains_key(self.selections, entry.path)
end

function Context:clear_selections()
  for selection, _ in pairs(self.selections) do
    local e = self.entries[self:get_index(selection)]
    e:remove_selection()
  end

  self.selections = {}
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
