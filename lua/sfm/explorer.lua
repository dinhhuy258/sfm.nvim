local window = require "sfm.window"
local context = require "sfm.context"
local entry = require "sfm.entry"

---@class Explorer
---@field win Window
---@field ctx Context
---@field root Entry
local Explorer = {}

function Explorer.new()
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.win = window.new()
  self.ctx = context.new()
  -- root has no parent
  self.root = entry.new(cwd, nil, self.ctx, true)

  return self
end

function Explorer:_refresh_entry(current_entry)
  current_entry:scandir()

  for _, e in ipairs(current_entry.entries) do
    if self.ctx:is_open(e) then
      self:_refresh_entry(e)
    end
  end
end

function Explorer:refresh()
  self:_refresh_entry(self.root)
  self:render()
end

function Explorer:render()
  self.win:render(self.ctx:render(self.root))
end

function Explorer:move_cursor(row, col)
  self.win:move_cursor(row, col)
end

function Explorer:toggle()
  if self.win:is_open() then
    self.win:close()

    return
  end

  -- load dir
  self.ctx:set_open(self.root)
  -- open explorer window
  self.win:open()
  -- refresh and render the explorer tree
  self:refresh()
end

return Explorer
