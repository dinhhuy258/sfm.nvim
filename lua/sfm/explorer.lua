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

  actions.setup(self, self.win, self.renderer, self.ctx, self.cfg)

  -- set the root folder as open
  self.ctx:set_open(self.ctx.root)

  return self
end

--- subscribe event
---@param event_name string
---@param handler function
function Explorer:subscribe(event_name, handler)
  self.event_manager:subscribe(event_name, handler)
end

--- remove the renderer by name
---@param name string
function Explorer:remove_renderer(name)
  self.renderer:remove_renderer(name)
end

--- register a renderer
---@param name string
---@param priority integer
---@param func function
function Explorer:register_renderer(name, priority, func)
  self.renderer:register_renderer(name, priority, func)
end

--- remove entry filter by given name
---@param name string
function Explorer:remove_entry_filter(name)
  self.renderer:remove_entry_filter(name)
end

--- register an entry filter
---@param name string
---@param func function
function Explorer:register_entry_filter(name, func)
  self.renderer:register_entry_filter(name, func)
end

return Explorer
