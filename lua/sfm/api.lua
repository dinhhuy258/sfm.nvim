local actions = require "sfm.actions"

local M = {
  explorer = {},
  entry = {},
  navigation = {},
}

--- initialize api
---@param view View
---@param renderer Renderer
function M.setup(view, renderer)
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

  M.entry.current = function()
    return renderer:get_current_entry()
  end

  M.navigation.focus = function(fpath)
    return actions.focus_file(fpath)
  end
end

return M
