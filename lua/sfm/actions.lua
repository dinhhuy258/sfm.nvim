local log = require "sfm.utils.log"
local path = require "sfm.utils.path"
local config = require "sfm.config"
local event = require "sfm.event"
local sfm_entry = require "sfm.entry"

---@class M
---@field _explorer Explorer
---@field _view View
---@field _renderer Renderer
---@field _event_manager EventManager
---@field _ctx Context
local M = {}

M._explorer = nil
M._view = nil
M._renderer = nil
M._event_manager = nil
M._ctx = nil

local Actions = {}

--- open the given directory
---@private
---@param e Entry
---@param force boolean|nil
function M._open_dir(e, force)
  if not e.is_dir then
    return
  end

  force = force and true or false

  e:open(M._explorer.entry_sort_method, force)
end

--- close the given directory
---@private
---@param e Entry
function M._close_dir(e)
  if not e.is_dir then
    return
  end

  e:close()
end

--- reload the current entry
---@private
---@param e Entry
local function _reload(e)
  M._open_dir(e, true)

  for _, child in ipairs(e.entries) do
    if child.is_open then
      _reload(child)
    end
  end
end

--- focus the given path
---@param fpath string
function M.focus_file(fpath)
  fpath = path.clean(fpath)

  if vim.startswith(fpath, M._ctx.root.path) then
    local dirs = path.split(path.dirname(fpath))
    local current = M._ctx.root
    local current_path = ""

    for _, dir in ipairs(dirs) do
      current_path = path.join { current_path, dir }
      for _, entry in ipairs(current.entries) do
        if entry.is_dir and entry.path == current_path then
          if not entry.is_open then
            M._open_dir(entry)
          end

          current = entry

          break
        end
      end
    end
  end

  M._renderer:render()

  local linenr = M._renderer:find_line_number_for_path(fpath)
  if linenr == nil then
    return
  end

  M._view:move_cursor(linenr, 0)
end

--- open window
---@return integer, boolean
local function open()
  -- avoid triggering autocommands when switching windows
  local eventignore = vim.o.eventignore
  vim.o.eventignore = "all"

  local current_window = vim.api.nvim_get_current_win()

  -- find a suitable window to open the file in
  if config.opts.view.side == "right" then
    vim.cmd "wincmd t"
  else
    vim.cmd "wincmd w"
  end

  local winid = vim.api.nvim_get_current_win()
  local is_sfm_window = vim.bo.filetype == "sfm"
  vim.api.nvim_set_current_win(current_window)

  vim.o.eventignore = eventignore

  return winid, is_sfm_window
end

--- find buffer by the given name
---@param name string
---@return integer
local function find_buffer_by_name(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name == name then
      return buf
    end
  end

  return -1
end

--- open the given path with the given open_cm
---@param fpath string
---@param open_cmd string
local function open_file(fpath, open_cmd)
  local result = true
  local err = nil
  open_cmd = open_cmd or "edit"

  if open_cmd == "edit" or open_cmd == "e" then
    local bufnr = find_buffer_by_name(fpath)
    if bufnr > 0 then
      -- if the file is already open, switch to it
      open_cmd = "b"
    end
  end

  local winid, is_sfm_window = open()
  vim.api.nvim_set_current_win(winid)
  if is_sfm_window then
    -- sfm must be the only window, restore it's status as a sidebar
    result, err = pcall(vim.cmd, "vsplit " .. fpath)
    vim.api.nvim_win_set_width(winid, config.opts.view.width)
  else
    result, err = pcall(vim.cmd, open_cmd .. " " .. fpath)
  end

  if result or err == "Vim(edit):E325: ATTENTION" then
    vim.api.nvim_buf_set_option(0, "buflisted", true)

    -- fire event
    M._event_manager:dispatch(event.FileOpened, {
      path = fpath,
    })
  else
    log.error "Error opening file"
  end
end

--- open the file in a horizontal split
function M.split()
  local entry = M._renderer:get_current_entry()
  if entry.is_dir then
    return
  end

  open_file(entry.path, "split")
end

--- open the file in a vertical split
function M.vsplit()
  local entry = M._renderer:get_current_entry()
  if entry.is_dir then
    return
  end

  open_file(entry.path, "vsplit")
end

-- open the file in a new tab
function M.tabnew()
  local entry = M._renderer:get_current_entry()
  if entry.is_dir then
    return
  end

  open_file(entry.path, "tabedit")
end

--- edit file or toggle directory
function M.edit()
  local entry = M._renderer:get_current_entry()
  if not entry.is_dir then
    if config.opts.view.side == "right" then
      vim.cmd "wincmd h"
    else
      vim.cmd "wincmd l"
    end

    vim.cmd("keepalt edit " .. entry.path)

    -- fire event
    M._event_manager:dispatch(event.FileOpened, {
      path = entry.path,
    })

    return
  end

  if entry.is_open then
    -- close directory
    M._close_dir(entry)
    -- re-render
    M._renderer:render()
    -- fire event
    M._event_manager:dispatch(event.FolderClosed, {
      path = entry.path,
    })

    return
  end

  -- open directory
  M._open_dir(entry)
  -- render the explorer
  M._renderer:render()
  -- fire event
  M._event_manager:dispatch(event.FolderOpened, {
    path = entry.path,
  })
end

--- navigate to the first sibling of current file/directory
function M.first_sibling()
  local entry = M._renderer:get_current_entry()
  if entry.parent == nil then
    return
  end

  local first_entry = nil
  for _, e in ipairs(entry.parent.entries) do
    if M._renderer:should_render_entry(e) then
      first_entry = e

      break
    end
  end

  M.focus_file(first_entry.path)
end

--- navigate to the last sibling of current file/directory
function M.last_sibling()
  local entry = M._renderer:get_current_entry()
  if entry.parent == nil then
    return
  end

  local last_entry = nil
  for _, e in ipairs(entry.parent.entries) do
    if M._renderer:should_render_entry(e) then
      last_entry = e
    end
  end

  M.focus_file(last_entry.path)
end

--- move cursor to the parent directory
function M.parent_entry()
  local entry = M._renderer:get_current_entry()
  local parent = entry.parent
  if parent == nil then
    return
  end

  M.focus_file(parent.path)
end

--- reload the explorer
function M.reload()
  if not M._view:is_open() then
    return
  end

  _reload(M._ctx.root)
  M._event_manager:dispatch(event.ExplorerReloaded, nil)
  M._renderer:render()
end

--- close current opened directory or parent
function M.close_entry()
  local entry = M._renderer:get_current_entry()
  if not entry.is_dir or not entry.is_open then
    entry = entry.parent
  end

  if entry.is_root then
    M.first_sibling()

    return
  end

  -- close directory
  M._close_dir(entry)
  -- re-render
  M._renderer:render()
  -- re-focus entry
  M.focus_file(entry.path)
end

--- change the explorer root
---@param cwd string
function M.change_root(cwd)
  if not path.exists(cwd) or not path.isdir(cwd) then
    log.warn(cwd .. " is not a valid directory")

    return
  end

  sfm_entry.clear_pool()
  M._ctx:change_root(sfm_entry.get_entry(cwd, nil))
  M.reload()

  M._event_manager:dispatch(event.ExplorerRootChanged, {
    path = cwd,
  })
end

--- close the explorer
function M.close()
  if M._view:is_open() then
    M._view:close()
  end
end

--- toggle the exlorer window
function M.toggle()
  if M._view:is_open() then
    M._view:close()

    return
  end

  -- get current file path
  local fpath = vim.api.nvim_buf_get_name(0)
  -- open explorer window
  M._view:open()
  -- reload and render the explorer tree
  M:reload()
  -- focus the current file
  M.focus_file(fpath)
end

function M.run(action)
  if type(action) == "function" then
    action()

    return
  end

  local defined_action = Actions[action]
  if defined_action == nil then
    log.error(
      string.format(
        "Invalid action name '%s' provided. Please provide a valid action name or check your configuration for any mistakes.",
        action
      )
    )

    return
  end

  defined_action()
end

--- setup actions
---@param explorer Explorer
function M.setup(explorer)
  M._explorer = explorer
  M._view = explorer.view
  M._renderer = explorer.renderer
  M._event_manager = explorer.event_manager
  M._ctx = explorer.ctx

  Actions = {
    edit = M.edit,
    vsplit = M.vsplit,
    split = M.split,
    tabnew = M.tabnew,
    close_entry = M.close_entry,
    last_sibling = M.last_sibling,
    first_sibling = M.first_sibling,
    parent_entry = M.parent_entry,
    reload = M.reload,
    close = M.close,
  }
end

return M
