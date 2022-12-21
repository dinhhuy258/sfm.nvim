local config = require "sfm.config"
local window = require "sfm.window"
local context = require "sfm.context"
local renderer = require "sfm.renderer"
local entry = require "sfm.entry"
local actions = require "sfm.actions"

---@class Explorer
---@field win Window
---@field ctx Context
---@field renderer Renderer
---@field cfg Config
local Explorer = {}

--- Explorer constructor
---@param opts table
---@return Explorer
function Explorer.new(opts)
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.cfg = config.new(opts)
  self.win = window.new(self.cfg)
  self.ctx = context.new(entry.new(cwd, nil, true))
  self.renderer = renderer.new(self.cfg, self.ctx, self.win)

  -- load root dir
  self:open_dir(self.ctx.root)

  return self
end

--- refresh the current entry
---@param current_entry Entry
function Explorer:_refresh_entry(current_entry)
  self:open_dir(current_entry)

  for _, e in ipairs(current_entry.entries) do
    if self.ctx:is_open(e) then
      self:_refresh_entry(e)
    end
  end
end

--- refresh the explorer
function Explorer:refresh()
  self:_refresh_entry(self.ctx.root)
  self.renderer:refresh_entries()
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
  self.renderer:refresh_entries()
end

--- close the given directory
---@param e Entry
function Explorer:close_dir(e)
  if not e.is_dir then
    return
  end

  self.ctx:remove_open(e)
  self.renderer:refresh_entries()
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

--- set on open listener
---@param listener function
function Explorer:set_on_open_listener(listener)
  self.win:set_on_open_listener(listener)
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
