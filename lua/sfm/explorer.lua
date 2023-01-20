local log = require "sfm.utils.log"
local view = require "sfm.view"
local context = require "sfm.context"
local renderer = require "sfm.renderer"
local event = require "sfm.event"
local entry = require "sfm.entry"
local actions = require "sfm.actions"
local api = require "sfm.api"

---@class Explorer
---@field view View
---@field ctx Context
---@field renderer Renderer
---@field event_manager EventManager
---@field entry_sort_method function|nil
local Explorer = {}

--- Explorer constructor
---@return Explorer
function Explorer.new()
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.event_manager = event.new_event_manager()
  self.view = view.new(self.event_manager)
  self.ctx = context.new(entry.get_entry(cwd, nil))
  self.renderer = renderer.new(self.ctx, self.view)
  self.entry_sort_method = nil

  actions.setup(self)
  api.setup(self.view, self.renderer, self.event_manager, self.ctx)

  return self
end

--- subscribe event
---@param event_name string
---@param handler function
function Explorer:subscribe(event_name, handler)
  if type(handler) ~= "function" then
    log.error(string.format("Invalid event handler, expected a function, got %s", type(handler)))

    return
  end

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
  if type(func) ~= "function" then
    log.error(string.format("Invalid renderer, expected a function, got %s", type(func)))

    return
  end

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
  if type(func) ~= "function" then
    log.error(string.format("Invalid entry filter method, expected a function, got %s", type(func)))

    return
  end

  self.renderer:register_entry_filter(name, func)
end

--- set custom entry sort method
---@param entry_sort_method function|nil
function Explorer:set_entry_sort_method(entry_sort_method)
  if type(entry_sort_method) ~= "function" then
    log.error(string.format("Invalid entry sort method, expected a function, got %s", type(entry_sort_method)))

    return
  end

  self.entry_sort_method = entry_sort_method
end

--- set window creator
---@param window_creator function|nil
function Explorer:register_window_creator(window_creator)
  if type(window_creator) ~= "function" then
    log.error(string.format("Invalid window creator method, expected a function, got %s", type(window_creator)))

    return
  end

  self.view:set_window_creator(window_creator)
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
