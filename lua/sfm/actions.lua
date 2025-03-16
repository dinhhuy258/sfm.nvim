local log = require "sfm.utils.log"
local path = require "sfm.utils.path"
local config = require "sfm.config"
local event = require "sfm.event"
local sfm_entry = require "sfm.entry"
local input = require "sfm.utils.input"
local fs = require "sfm.utils.fs"

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
  if not e:has_children() then
    return
  end

  force = force and true or false

  e:open(M._explorer.entry_sort_method, force)
end

--- close the given directory
---@private
---@param e Entry
function M._close_dir(e)
  if not e:has_children() then
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
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == name then
        return buf
      end
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

  fpath = vim.fn.fnameescape(fpath)

  if config.opts.view.float.enable or (open_cmd ~= "edit" and open_cmd ~= "e") then
    result, err = pcall(vim.cmd, open_cmd .. " " .. fpath)
  else
    local winid, is_sfm_window = open()
    vim.api.nvim_set_current_win(winid)
    if is_sfm_window then
      -- sfm must be the only window, restore it's status as a sidebar
      result, err = pcall(vim.cmd, "vsplit " .. fpath)
      vim.api.nvim_win_set_width(winid, config.opts.view.width)
    else
      result, err = pcall(vim.cmd, open_cmd .. " " .. fpath)
    end
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

  -- Use window picker if available and enabled
  if package.loaded["window-picker"] then
    local window_id = require("window-picker").pick_window()
    if window_id then
      vim.api.nvim_set_current_win(window_id)
      open_file(entry.path, "split")

      return
    end
  end

  open_file(entry.path, "split")
end

--- open the file in a vertical split
function M.vsplit()
  local entry = M._renderer:get_current_entry()
  if entry.is_dir then
    return
  end

  -- Use window picker if available and enabled
  if package.loaded["window-picker"] then
    local window_id = require("window-picker").pick_window()
    if window_id then
      vim.api.nvim_set_current_win(window_id)
      open_file(entry.path, "vsplit")

      return
    end
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
    open_file(entry.path, "edit")

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

--- change the root directory to the parent directory of the current entry
function M.change_root_to_parent()
  local root_path = M._ctx.root.path
  local new_root_path = path.dirname(path.remove_trailing(root_path))

  M.change_root(new_root_path)
end

--- change the root directory to the current folder entry or to the parent directory of the current file entry
function M.change_root_to_entry()
  local entry = M._renderer:get_current_entry()
  if entry.is_dir then
    M.change_root(entry.path)
  else
    local parent = entry.parent
    if parent == nil then
      return
    end

    M.change_root(parent.path)
  end
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
  if not entry:has_children() or not entry.is_open then
    if entry.nested_parent ~= nil then
      entry = entry.nested_parent
    else
      entry = entry.parent
    end
  end

  -- check nil for avoiding warning
  if entry == nil then
    return
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

--- toggle current directory or nesting parent
function M.toggle_entry()
  local entry = M._renderer:get_current_entry()
  if not entry:has_children() then
    return
  end

  if entry.is_open then
    -- close directory
    M._close_dir(entry)
  else
    M._open_dir(entry, false)
  end

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

--- add a file; leaving a trailing `/` will add a directory
function M.create()
  local entry = M._renderer:get_current_entry()
  if (not entry.is_dir or not entry.is_open) and not entry.is_root then
    entry = entry.parent
  end

  input.prompt("Create file ", path.add_trailing(entry.path), "file", function(fpath)
    input.clear()
    if fpath == nil or fpath == "" then
      return
    end

    if path.exists(fpath) then
      log.warn(fpath .. " already exists")
      M.focus_file(fpath)

      return
    end

    local ok = true
    if path.has_trailing(fpath) then
      -- create directory
      ok = fs.mkdir(fpath)
    else
      -- create file
      ok = fs.touch(fpath)
    end

    if ok then
      -- dispatch an event
      M._event_manager:dispatch(event.EntryCreated, {
        path = fpath,
      })
      -- reload the explorer
      M.reload()
      -- focus file
      M.focus_file(fpath)

      log.info(fpath .. " created")
    else
      log.error("Creation of file " .. fpath .. " failed due to an error.")
    end
  end)
end

--- delete open file/s directory/ies
function M.delete()
  if vim.tbl_count(M._ctx:get_selections()) > 0 then
    M._delete_selections()
  else
    M._delete_current()
  end
end

--- delete a single file/directory
function M._delete_current()
  local entry = M._renderer:get_current_entry()
  input.confirm("Are you sure you want to delete file " .. entry.name .. "? (y/n)", function()
    -- on yes
    input.clear()

    if fs.rm(entry.path) then
      log.info(entry.path .. " has been deleted")
    else
      log.error("Deletion of file " .. entry.name .. " failed due to an error.")
    end

    -- dispatch an event
    M._event_manager:dispatch(event.EntryDeleted, {
      path = entry.path,
    })

    -- reload the explorer
    M.reload()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- delete selected files/directories
function M._delete_selections()
  local selections = M._ctx:get_selections()
  if vim.tbl_isempty(selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  input.confirm("Are you sure you want to delete the selected files/directories? (y/n)", function()
    -- on yes
    input.clear()

    local paths = {}
    for fpath, _ in pairs(selections) do
      table.insert(paths, fpath)
    end
    paths = path.unify(paths)

    local success_count = 0
    for _, fpath in ipairs(paths) do
      if fs.rm(fpath) then
        success_count = success_count + 1
        -- dispatch an event
        M._event_manager:dispatch(event.EntryDeleted, {
          path = fpath,
        })
      end
    end

    log.info(
      string.format(
        "Deletion process complete. %d files deleted successfully, %d files failed.",
        success_count,
        vim.tbl_count(paths) - success_count
      )
    )

    -- clear selections
    M._ctx:clear_selections()

    -- reload the explorer
    M.reload()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- trash open file/s directory/ies
function M.trash()
  if vim.tbl_count(M._ctx:get_selections()) > 0 then
    M._trash_selections()
  else
    M._trash_current()
  end
end

--- trash a single file/directory
function M._trash_current()
  local entry = M._renderer:get_current_entry()
  input.confirm("Are you sure you want to trash file " .. entry.name .. "? (y/n)", function()
    -- on yes
    input.clear()

    if fs.trash(entry.path, config.opts.misc.trash_cmd) then
      log.info(entry.path .. " has been trashed")
    else
      log.error("Trashing of file " .. entry.name .. " failed due to an error.")
    end

    -- dispatch an event
    M._event_manager:dispatch(event.EntryDeleted, {
      path = entry.path,
    })

    -- reload the explorer
    M.reload()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- trash selected files/directories
function M._trash_selections()
  local selections = M._ctx:get_selections()
  if vim.tbl_isempty(selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  input.confirm("Are you sure you want to trash the selected files/directories? (y/n)", function()
    -- on yes
    input.clear()

    local paths = {}
    for fpath, _ in pairs(selections) do
      table.insert(paths, fpath)
    end
    paths = path.unify(paths)

    local success_count = 0
    for _, fpath in ipairs(paths) do
      if fs.trash(fpath, config.opts.misc.trash_cmd) then
        success_count = success_count + 1
        -- dispatch an event
        M._event_manager:dispatch(event.EntryDeleted, {
          path = fpath,
        })
      end
    end

    log.info(
      string.format(
        "Trashing process complete. %d files trashed successfully, %d files failed.",
        success_count,
        vim.tbl_count(paths) - success_count
      )
    )

    -- clear selections
    M._ctx:clear_selections()

    -- reload the explorer
    M.reload()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- system open file/s directory/ies
function M.system_open()
  if vim.tbl_count(M._ctx:get_selections()) > 0 then
    M._system_open_selections()
  else
    M._system_open_current()
  end
end

--- open a single file/directory using default system program
function M._system_open_current()
  local entry = M._renderer:get_current_entry()

  if fs.system_open(entry.path, config.opts.misc.system_open_cmd) then
    log.info(entry.path .. " has been opened using a system default program")
  else
    log.error("Opening of file " .. entry.name .. "using system default program failed due to an error.")
  end
end

--- open selected files/directories using default system program
function M._system_open_selections()
  local selections = M._ctx:get_selections()
  if vim.tbl_isempty(selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  local paths = {}
  for fpath, _ in pairs(selections) do
    table.insert(paths, fpath)
  end
  paths = path.unify(paths)

  local success_count = 0
  for _, fpath in ipairs(paths) do
    if fs.system_open(fpath, config.opts.misc.system_open_cmd) then
      success_count = success_count + 1
    end
  end

  log.info(
    string.format(
      "System opening process complete. %d files opened successfully, %d files failed.",
      success_count,
      vim.tbl_count(paths) - success_count
    )
  )
end

--- move/copy selected files/directories to a current opened entry or it's parent
---@param from_paths table
---@param to_dir string
---@param action_fn function
---@param before_action_fn function?
---@param on_action_success_fn function?
local function _paste(from_paths, to_dir, action_fn, before_action_fn, on_action_success_fn)
  local success_count = 0
  local continue_processing = true

  local function perform_action_fn(fpath, dest_path)
    if before_action_fn ~= nil then
      before_action_fn(fpath, dest_path)
    end

    if action_fn(fpath, dest_path) then
      success_count = success_count + 1

      if on_action_success_fn ~= nil then
        on_action_success_fn(fpath, dest_path)
      end
    end
  end

  for _, fpath in ipairs(from_paths) do
    local basename = path.basename(fpath)
    local dest_path = path.join { to_dir, basename }

    if path.exists(dest_path) then
      input.confirm(dest_path .. " already exists. Rename it? (y/n)", function()
        -- on yes
        input.clear()
        input.prompt("New name " .. path.add_trailing(to_dir), basename, "file", function(name)
          input.clear()
          if name == nil or name == "" then
            return
          end

          dest_path = path.join { to_dir, name }

          if path.exists(dest_path) then
            log.warn(dest_path .. " already exists")

            return
          end

          perform_action_fn(fpath, dest_path)
        end)
      end, function()
        -- on no
        input.clear()
      end, function()
        -- on cancel
        input.clear()
        continue_processing = false
      end)
    else
      perform_action_fn(fpath, dest_path)
    end

    if not continue_processing then
      break
    end
  end

  log.info(
    string.format(
      "Copy/move process complete. %d files copied/moved successfully, %d files failed.",
      success_count,
      vim.tbl_count(from_paths) - success_count
    )
  )
end

--- move file/s directory/ies
function M.move()
  if vim.tbl_count(M._ctx:get_selections()) > 0 then
    M._move_selections()
  else
    M._move_current()
  end
end

--- move/rename a single current file/directory
function M._move_current()
  local entry = M._renderer:get_current_entry()
  local from_path = entry.path

  if entry.is_root then
    return
  end

  input.prompt("Move: ", entry.path, "file", function(to_path)
    input.clear()
    if to_path == nil or to_path == "" then
      return
    end

    if path.exists(to_path) then
      log.warn(to_path .. " already exists")

      return
    end

    M._event_manager:dispatch(event.EntryWillRename, {
      from_path = from_path,
      to_path = to_path,
    })

    if fs.mv(from_path, to_path) then
      -- reload the explorer
      M.reload()
      -- focus file
      M.focus_file(to_path)
      -- dispatch an event
      M._event_manager:dispatch(event.EntryRenamed, {
        from_path = from_path,
        to_path = to_path,
      })

      log.info(string.format("Moving file/directory %s ➜ %s complete", from_path, to_path))
    else
      log.error(string.format("Moving file/directory %s failed due to an error", path.basename(from_path)))
    end
  end)
end

--- move selected files/directories to a current opened entry or it's parent
function M._move_selections()
  local selections = M._ctx:get_selections()
  if vim.tbl_isempty(selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  local paths = {}
  for fpath, _ in pairs(selections) do
    table.insert(paths, fpath)
  end
  paths = path.unify(paths)

  local dest_entry = M._renderer:get_current_entry()
  if not dest_entry.is_dir or not dest_entry.is_open then
    dest_entry = dest_entry.parent
  end

  _paste(paths, dest_entry.path, fs.mv, function(from_path, to_path)
    M._event_manager:dispatch(event.EntryWillRename, {
      from_path = from_path,
      to_path = to_path,
    })
  end, function(from_path, to_path)
    M._event_manager:dispatch(event.EntryRenamed, {
      from_path = from_path,
      to_path = to_path,
    })
  end)

  M._ctx:clear_selections()
  M.reload()
end

--- copy file/s directory/ies
function M.copy()
  if vim.tbl_count(M._ctx:get_selections()) > 0 then
    M._copy_selections()
  else
    M._copy_current()
  end
end

--- copy a single file/directory
function M._copy_current()
  local entry = M._renderer:get_current_entry()
  local from_path = entry.path

  if entry.is_root then
    return
  end

  input.prompt("Copy: " .. from_path .. " -> ", from_path, "file", function(to_path)
    input.clear()
    if to_path == nil or to_path == "" then
      return
    end

    if path.exists(to_path) then
      log.warn(to_path .. " already exists")

      return
    end

    if fs.cp(entry.path, to_path) then
      -- reload the explorer
      M.reload()
      -- focus file
      M.focus_file(to_path)
      -- dispatch an event
      M._event_manager:dispatch(event.EntryCreated, {
        path = to_path,
      })

      log.info(string.format("Copying file/directory %s ➜ %s complete", from_path, to_path))
    else
      log.error(string.format("Copying file/directory %s failed due to an error", path.basename(from_path)))
    end
  end)
end

--- copy selected files/directories to a current opened entry or it's parent
function M._copy_selections()
  local selections = M._ctx:get_selections()
  if vim.tbl_isempty(selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  local paths = {}
  for fpath, _ in pairs(selections) do
    table.insert(paths, fpath)
  end

  local dest_entry = M._renderer:get_current_entry()
  if not dest_entry.is_dir or not dest_entry.is_open then
    dest_entry = dest_entry.parent
  end

  _paste(paths, dest_entry.path, fs.cp, nil, function(_, to_path)
    -- dispatch an event
    M._event_manager:dispatch(event.EntryCreated, {
      path = to_path,
    })
  end)

  M._ctx:clear_selections()
  M.reload()
end

--- toggle selection for the given entry
---@param entry Entry
local function toggle_selection_entry(entry)
  if entry.is_root then
    return
  end

  if M._ctx:is_selected(entry.path) then
    M._ctx:remove_selection(entry.path)
  else
    M._ctx:set_selection(entry.path)
  end
end

--- toggle a current file/directory to bookmarks list
function M.toggle_selection()
  local mode = vim.fn.mode()
  if mode == "n" then
    toggle_selection_entry(M._renderer:get_current_entry())
  elseif mode == "v" or mode == "V" then
    vim.cmd 'noau normal! "vy"'
    local start_line, end_line = vim.api.nvim_buf_get_mark(0, "<")[1], vim.api.nvim_buf_get_mark(0, ">")[1]
    local entries = M._renderer.entries

    for line = start_line, end_line do
      toggle_selection_entry(entries[line])
    end
  end

  M._renderer:render()
end

--- clear a bookmarks list
function M.clear_selections()
  M._ctx:clear_selections()
  M._renderer:render()
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

function M.deprecated(message)
  return function()
    log.warn(message)
  end
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
    toggle_entry = M.toggle_entry,
    last_sibling = M.last_sibling,
    first_sibling = M.first_sibling,
    parent_entry = M.parent_entry,
    change_root_to_parent = M.change_root_to_parent,
    change_root_to_entry = M.change_root_to_entry,
    reload = M.reload,
    close = M.close,
    create = M.create,
    delete = M.delete,
    trash = M.trash,
    system_open = M.system_open,
    copy = M.copy,
    move = M.move,
    toggle_selection = M.toggle_selection,
    clear_selections = M.clear_selections,
    delete_selections = M.deprecated(string.format("Deprecated action %s, use %s", "delete_selections", "delete")),
    trash_selections = M.deprecated(string.format("Deprecated action %s, use %s", "trash_selections", "trash")),
    system_open_selections = M.deprecated(
      string.format("Deprecated action %s, use %s", "system_open_selections", "system_open")
    ),
    copy_selections = M.deprecated(string.format("Deprecated action %s, use %s", "copy_selections", "copy")),
    move_selections = M.deprecated(string.format("Deprecated action %s, use %s", "move_selections", "move")),
  }
end

return M
