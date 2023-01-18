local path = require "sfm.utils.path"
local config = require "sfm.config"
local event = require "sfm.event"

---@class M
---@field explorer Explorer
---@field view View
---@field renderer Renderer
---@field event_manager EventManager
---@field ctx Context
local M = {}

M.explorer = nil
M.view = nil
M.renderer = nil
M.ctx = nil

--- open the given directory
---@private
---@param e Entry
function M._open_dir(e)
  if not e.is_dir then
    return
  end

  M.ctx:set_open(e)
  e:scandir(config.opts.sort_by)
end

--- close the given directory
---@private
---@param e Entry
function M._close_dir(e)
  if not e.is_dir then
    return
  end

  M.ctx:remove_open(e)
end

--- reload the current entry
---@private
---@param e Entry
local function _reload(e)
  -- make sure to rescan entries in reload method
  e:clear_entries()
  M._open_dir(e)

  for _, child in ipairs(e.entries) do
    if M.ctx:is_open(child) then
      _reload(child)
    end
  end
end

--- focus the given path
---@param fpath string
function M.focus_file(fpath)
  if vim.startswith(fpath, M.ctx.root.path) then
    local dirs = path.split(path.dirname(fpath))
    local current = M.ctx.root
    local current_path = ""

    for _, dir in ipairs(dirs) do
      current_path = path.join { current_path, dir }
      for _, entry in ipairs(current.entries) do
        if entry.is_dir and entry.path == current_path then
          if not M.ctx:is_open(entry) then
            M._open_dir(entry)
          end

          current = entry

          break
        end
      end
    end
  end

  M.renderer:render()

  local linenr = M.renderer:find_line_number_for_path(fpath)
  if linenr == 0 then
    return
  end

  M.view:move_cursor(linenr, 0)
end

--- edit file or toggle directory
function M.edit()
  local entry = M.renderer:get_current_entry()
  if not entry.is_dir then
    if config.opts.view.side == "right" then
      vim.cmd "wincmd h"
    else
      vim.cmd "wincmd l"
    end

    vim.cmd("keepalt edit " .. entry.path)

    -- fire event
    M.event_manager:dispatch(event.FileOpened, {
      path = entry.path,
    })

    return
  end

  if M.ctx:is_open(entry) then
    -- close directory
    M._close_dir(entry)
    -- re-render
    M.renderer:render()
    -- fire event
    M.event_manager:dispatch(event.FolderClosed, {
      path = entry.path,
    })

    return
  end

  -- open directory
  M._open_dir(entry)
  -- render the explorer
  M.renderer:render()
  -- fire event
  M.event_manager:dispatch(event.FolderOpened, {
    path = entry.path,
  })
end

--- navigate to the first sibling of current file/directory
function M.first_sibling()
  local entry = M.renderer:get_current_entry()
  if entry.parent == nil then
    return
  end

  local first_entry = nil
  for _, e in ipairs(entry.parent.entries) do
    if M.renderer:should_render_entry(e) then
      first_entry = e

      break
    end
  end

  M.focus_file(first_entry.path)
end

--- navigate to the last sibling of current file/directory
function M.last_sibling()
  local entry = M.renderer:get_current_entry()
  if entry.parent == nil then
    return
  end

  local last_entry = nil
  for _, e in ipairs(entry.parent.entries) do
    if M.renderer:should_render_entry(e) then
      last_entry = e
    end
  end

  M.focus_file(last_entry.path)
end

--- move cursor to the parent directory
function M.parent_entry()
  local entry = M.renderer:get_current_entry()
  local parent = entry.parent
  if parent == nil then
    return
  end

  M.focus_file(parent.path)
end

--- reload the explorer
function M.reload()
  _reload(M.ctx.root)
  M.event_manager:dispatch(event.ExplorerReloaded, nil)
  M.renderer:render()
end

--- close current opened directory or parent
function M.close_entry()
  local entry = M.renderer:get_current_entry()
  if not entry.is_dir or not M.ctx:is_open(entry) then
    entry = entry.parent
  end

  if entry.is_root then
    M.first_sibling()

    return
  end

  -- close directory
  M._close_dir(entry)
  -- re-render
  M.renderer:render()
  -- re-focus entry
  M.focus_file(entry.path)
end

--- close the explorer
function M.close()
  if M.view:is_open() then
    M.view:close()
  end
end

function M.toggle()
  if M.view:is_open() then
    M.view:close()

    return
  end

  -- get current file path
  local fpath = vim.api.nvim_buf_get_name(0)
  -- open explorer window
  M.view:open()
  -- reload and render the explorer tree
  M:reload()
  -- focus the current file
  M.focus_file(fpath)
end

--- setup actions
---@param explorer Explorer
function M.setup(explorer)
  M.explorer = explorer
  M.view = explorer.view
  M.renderer = explorer.renderer
  M.event_manager = explorer.event_manager
  M.ctx = explorer.ctx
end

return M
