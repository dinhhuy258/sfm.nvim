local window = require "sfm.window"
local context = require "sfm.context"
local renderer = require "sfm.renderer"
local entry = require "sfm.entry"
local actions = require "sfm.actions"

---@class Explorer
---@field win Window
---@field ctx Context
---@field renderer Renderer
local Explorer = {}

--- Explorer constructor
---@return Explorer
function Explorer.new()
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.win = window.new()
  self.ctx = context.new(entry.new(cwd, nil, true))
  self.renderer = renderer.new(self.ctx, self.win)

  -- load root dir
  self.ctx:set_open(self.ctx.root)

  return self
end

--- refresh the current entry
---@param current_entry Entry
function Explorer:_refresh_entry(current_entry)
  current_entry:scandir()

  for _, e in ipairs(current_entry.entries) do
    if self.ctx:is_open(e) then
      self:_refresh_entry(e)
    end
  end
end

--- refresh the explorer
function Explorer:refresh()
  self:_refresh_entry(self.ctx.root)
  self.ctx:refresh_entries()
  self:render()
end

--- render the explorer
function Explorer:render()
  self.renderer:render()
end

--- move cursor of the explorer's window to (row, col)
---@param row integer
---@param col integer
function Explorer:move_cursor(row, col)
  self.win:move_cursor(row, col)
end

--- toggle the explorer
function Explorer:toggle()
  if self.win:is_open() then
    self.win:close()

    return
  end

  -- get current file path
  local fpath = vim.api.nvim_buf_get_name(0)
  -- open explorer window
  self.win:open()
  -- refresh and render the explorer tree
  self:refresh()
  -- focus the current file
  actions.focus_file(fpath)
end

return Explorer
