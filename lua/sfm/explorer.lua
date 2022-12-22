local config = require "sfm.config"
local window = require "sfm.window"
local context = require "sfm.context"
local renderer = require "sfm.renderer"
local event_manager = require "sfm.event_manager"
local entry = require "sfm.entry"
local actions = require "sfm.actions"

---@class Explorer
---@field win Window
---@field ctx Context
---@field renderer Renderer
---@field cfg Config
---@field event_manager EventManager
local Explorer = {}

--- Explorer constructor
---@param opts table
---@return Explorer
function Explorer.new(opts)
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.cfg = config.new(opts)
  self.event_manager = event_manager.new()
  self.win = window.new(self.cfg, self.event_manager)
  self.ctx = context.new(entry.new(cwd, nil, true))
  self.renderer = renderer.new(self.cfg, self.ctx, self.win)

  actions.setup(self, self.ctx, self.cfg)

  -- load root dir
  self:open_dir(self.ctx.root)

  return self
end

--- refresh the current entry
---@param e Entry
function Explorer:_refresh(e)
  -- make sure to rescan entries in refresh method
  e:clear_entries()
  self:open_dir(e)

  for _, child in ipairs(e.entries) do
    if self.ctx:is_open(child) then
      self:_refresh(child)
    end
  end
end

--- refresh the explorer
function Explorer:refresh()
  self:_refresh(self.ctx.root)
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

--- open the given directory
---@param e Entry
function Explorer:open_dir(e)
  if not e.is_dir then
    return
  end

  self.ctx:set_open(e)
  e:scandir(self.cfg.opts.sort_by)
end

--- close the given directory
---@param e Entry
function Explorer:close_dir(e)
  if not e.is_dir then
    return
  end

  self.ctx:remove_open(e)
end

--- get the current entry at the current position
---@return Entry
function Explorer:get_current_entry()
  return self.renderer:get_current_entry()
end

--- get the line number of the current path, return 0 if not found
---@param fpath string
---@return integer
function Explorer:find_line_number_for_path(fpath)
  return self.renderer:find_line_number_for_path(fpath)
end

--- subscribe event
---@param event_name string
---@param handler function
function Explorer:subscribe(event_name, handler)
  self.event_manager:subscribe(event_name, handler)
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

--- close the explorer
function Explorer:close()
  if self.win:is_open() then
    self.win:close()
  end
end

return Explorer
