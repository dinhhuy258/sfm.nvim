local debounce = require "sfm.utils.debounce"
local path = require "sfm.utils.path"
local log = require "sfm.utils.log"
local actions = require "sfm.actions"
local entry = require "sfm.entry"
local event = require "sfm.event"

local M = {
  explorer = {},
  entry = {},
  navigation = {},
  path = {},
  log = {},
}

--- initialize api
---@param view View
---@param renderer Renderer
---@param event_manager EventManager
---@param ctx Context
function M.setup(view, renderer, event_manager, ctx)
  M.explorer.toggle = function()
    actions.toggle()
  end
  M.explorer.open = function()
    view:open()
  end
  M.explorer.close = function()
    view:close()
  end
  M.explorer.is_open = function()
    return view:is_open()
  end
  M.explorer.reload = function()
    return actions.reload()
  end
  M.explorer.refresh = function()
    return renderer:render()
  end
  M.explorer.change_root = function(cwd)
    if path.exists(cwd) or not path.isdir(cwd) then
      log.warn(cwd .. " is not a valid directory")

      return
    end

    ctx:change_root(entry.new(cwd, nil, true))
    actions.reload()

    event_manager:dispatch(event.ExplorerRootChanged, {
      path = cwd,
    })
  end

  M.entry.root = function()
    return ctx.root
  end
  M.entry.current = function()
    return renderer:get_current_entry()
  end
  M.entry.is_open = function(e)
    return ctx:is_open(e)
  end

  M.navigation.focus = function(fpath)
    return actions.focus_file(fpath)
  end

  M.path.clean = path.clean
  M.path.split = path.split
  M.path.join = path.join
  M.path.dirname = path.dirname
  M.path.basename = path.basename
  M.path.remove_trailing = path.remove_trailing
  M.path.has_trailing = path.has_trailing
  M.path.add_trailing = path.add_trailing
  M.path.exists = path.exists
  M.path.isfile = path.isfile
  M.path.isdir = path.isdir
  M.path.islink = path.islink
  M.path.unify = path.unify
  M.path.path_separator = path.path_separator

  M.debounce = debounce.debounce

  M.log.info = log.info
  M.log.warn = log.warn
  M.log.error = log.error
end

return M
