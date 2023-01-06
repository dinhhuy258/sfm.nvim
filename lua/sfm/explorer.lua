local view = require "sfm.view"
local context = require "sfm.context"
local renderer = require "sfm.renderer"
local event_manager = require "sfm.event_manager"
local entry = require "sfm.entry"
local actions = require "sfm.actions"

---@class Explorer
---@field view View
---@field ctx Context
---@field renderer Renderer
---@field event_manager EventManager
local Explorer = {}

--- Explorer constructor
---@return Explorer
function Explorer.new()
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.event_manager = event_manager.new()
  self.view = view.new(self.event_manager)
  self.ctx = context.new(entry.new(cwd, nil, true))
  self.renderer = renderer.new(self.ctx, self.view)

  actions.setup(self, self.view, self.renderer, self.ctx)

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

--- load extension that is given by the name and options
---@param name string
---@param opts table
function Explorer:load_extension(name, opts)
  local ok, ext = pcall(require, "sfm.extensions." .. name)
  if not ok then
    error(string.format("'%s' extension doesn't exist or isn't installed: %s", name, ext))
  end

  ext.setup(self, opts)
end

return Explorer
