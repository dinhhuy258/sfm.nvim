local log = require "sfm.utils.log"

---@class EventManager
---@field handlers table<string, function[]>
local EventManager = {}

--- EventManager constructor
---@return EventManager
function EventManager._new()
  local self = setmetatable({}, { __index = EventManager })
  self.handlers = {}

  return self
end

--- get handlers by event name
---@private
---@param event_name string
---@return function[]
function EventManager:_get_handlers(event_name)
  return self.handlers[event_name] or {}
end

--- subscribe event
---@param event_name string
---@param handler function
function EventManager:subscribe(event_name, handler)
  local handlers = self:_get_handlers(event_name)
  table.insert(handlers, handler)
  self.handlers[event_name] = handlers
end

--- dispatch event
---@param event_name string
---@param payload table?
function EventManager:dispatch(event_name, payload)
  for _, handler in pairs(self:_get_handlers(event_name)) do
    local success, error = pcall(handler, payload)

    if not success then
      log.error("Handler for event " .. event_name .. " errored. " .. vim.inspect(error))
    end
  end
end

local Event = {
  ExplorerOpened = "ExplorerOpened",
  ExplorerClosed = "ExplorerClosed",
  ExplorerReloaded = "ExplorerReloaded",
  ExplorerRootChanged = "ExplorerRootChanged",
  FileOpened = "FileOpened",
  FolderOpened = "FolderOpened",
  FolderClosed = "FolderClosed",
}

Event.new_event_manager = EventManager._new

return Event
