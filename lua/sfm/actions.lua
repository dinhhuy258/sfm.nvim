local input = require "sfm.utils.input"
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local log = require "sfm.utils.log"

---@class M
---@field explorer Explorer
---@field win Window
---@field renderer Renderer
---@field ctx Context
---@field cfg Config
local M = {}

M.explorer = nil
M.win = nil
M.renderer = nil
M.ctx = nil
M.cfg = nil

--- open the given directory
---@private
---@param e Entry
function M._open_dir(e)
  if not e.is_dir then
    return
  end

  M.ctx:set_open(e)
  e:scandir(M.cfg.opts.sort_by)
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

--- refresh the current entry
---@private
---@param e Entry
local function _refresh(e)
  -- make sure to rescan entries in refresh method
  e:clear_entries()
  M._open_dir(e)

  for _, child in ipairs(e.entries) do
    if M.ctx:is_open(child) then
      _refresh(child)
    end
  end
end

--- focus the given path
---@param fpath string
function M.focus_file(fpath)
  if vim.startswith(fpath, M.ctx.root.path) then
    local dirs = path.split(path.dirname(fpath))
    local current = M.ctx.root

    for _, dir in ipairs(dirs) do
      for _, entry in ipairs(current.entries) do
        if entry.is_dir and entry.name == dir then
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

  M.win:move_cursor(linenr, 0)
end

--- edit file or toggle directory
function M.edit()
  local entry = M.renderer:get_current_entry()
  if not entry.is_dir then
    vim.cmd "wincmd l"
    vim.cmd("keepalt edit " .. entry.path)

    return
  end

  if M.ctx:is_open(entry) then
    -- close directory
    M._close_dir(entry)
    -- re-render
    M.renderer:render()

    return
  end

  -- open directory
  M._open_dir(entry)
  -- render the explorer
  M.renderer:render()
end

--- navigate to the first sibling of current file/directory
function M.first_sibling()
  local entry = M.renderer:get_current_entry()
  if entry.parent == nil then
    return
  end

  local first_entry = nil
  for _, e in ipairs(entry.parent.entries) do
    if not e.is_hidden or M.cfg.opts.show_hidden then
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
    if not e.is_hidden or M.cfg.opts.show_hidden then
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

--- refresh the explorer
function M.refresh()
  _refresh(M.ctx.root)
  M.renderer:render()
end

--- add a file; leaving a trailing `/` will add a directory
function M.create()
  local entry = M.renderer:get_current_entry()
  if (not entry.is_dir or not M.ctx:is_open(entry)) and not entry.is_root then
    entry = entry.parent
  end

  input.prompt("Create file " .. path.add_trailing(entry.path), nil, "file", function(name)
    input.clear()
    if name == nil or name == "" then
      return
    end

    local fpath = path.join { entry.path, name }

    if path.exists(fpath) then
      log.warn(fpath .. " already exists")

      return
    end

    local ok = true
    if path.has_trailing(name) then
      -- create directory
      ok = fs.create_dir(fpath)
    else
      -- create file
      ok = fs.create_file(fpath)
    end

    if ok then
      -- refresh the explorer
      M.refresh()
      -- focus file
      M.focus_file(fpath)

      log.info(fpath .. " created")
    else
      log.error("Creation of file " .. fpath .. " failed due to an error.")
    end
  end)
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

--- delete a file/directory
function M.delete()
  local entry = M.renderer:get_current_entry()
  input.confirm("Are you sure you want to delete file " .. entry.name .. "? (y/n)", function()
    -- on yes
    input.clear()

    if fs.remove(entry.path) then
      log.info(entry.path .. " has been deleted")
    else
      log.error("Deletion of file " .. entry.name .. " failed due to an error.")
    end

    -- refresh the explorer
    M.refresh()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- delete selected files/directories
function M.delete_selections()
  if table.is_empty(M.ctx.selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  input.confirm("Are you sure you want to delete the selected files/directories? (y/n)", function()
    -- on yes
    input.clear()

    local success_count = 0
    -- TODO: unify paths
    for fpath, _ in pairs(M.ctx.selections) do
      if fs.remove(fpath) then
        success_count = success_count + 1
      end
    end

    log.info(
      string.format(
        "Deletion process complete. %d files deleted successfully, %d files failed.",
        success_count,
        table.count(M.ctx.selections) - success_count
      )
    )

    -- clear selections
    M.ctx:clear_selections()

    -- refresh the explorer
    M.refresh()
  end, function()
    -- on no
    input.clear()
  end, function()
    -- on cancel
    input.clear()
  end)
end

--- rename a current file/directory
function M.rename()
  local entry = M.renderer:get_current_entry()
  local from_path = entry.path

  if entry.is_root then
    return
  end

  local parent = entry.parent

  input.prompt("Rename to " .. path.add_trailing(parent.path), path.basename(from_path), "dir", function(name)
    input.clear()
    if name == nil or name == "" then
      return
    end

    local to_path = path.join { parent.path, name }

    if path.exists(to_path) then
      log.warn(to_path .. " already exists")

      return
    end

    if fs.rename(from_path, to_path) then
      -- refresh the explorer
      M.refresh()
      -- focus file
      M.focus_file(to_path)

      log.info(string.format("Renaming file %s ➜ %s complete", path.basename(from_path), path.basename(to_path)))
    else
      log.error(string.format("Renaming file %s failed due to an error", path.basename(from_path)))
    end
  end)
end

--- move/copy selected files/directories to a current opened entry or it's parent
local function _paste(action_fn)
  if table.is_empty(M.ctx.selections) then
    log.warn "No files selected. Please select at least one file to proceed."

    return
  end

  local dest_entry = M.renderer:get_current_entry()
  if not dest_entry.is_dir or not M.ctx:is_open(dest_entry) then
    dest_entry = dest_entry.parent
  end

  local success_count = 0
  local continue_processing = true

  for fpath, _ in pairs(M.ctx.selections) do
    local basename = path.basename(fpath)
    local dest_path = path.join { dest_entry.path, basename }

    if path.exists(dest_path) then
      input.confirm(dest_path .. " already exists. Rename it? (y/n)", function()
        -- on yes
        input.clear()
        input.prompt("New name " .. path.add_trailing(dest_entry.path), basename, "file", function(name)
          input.clear()
          if name == nil or name == "" then
            return
          end

          dest_path = path.join { dest_entry.path, name }

          if path.exists(dest_path) then
            log.warn(dest_path .. " already exists")

            return
          end

          if action_fn(fpath, dest_path) then
            success_count = success_count + 1
          end
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
      if action_fn(fpath, dest_path) then
        success_count = success_count + 1
      end
    end

    if not continue_processing then
      break
    end
  end

  log.info(
    string.format(
      "Copy/move process complete. %d files copied/moved successfully, %d files failed.",
      success_count,
      table.count(M.ctx.selections) - success_count
    )
  )

  M.ctx:clear_selections()
  M.refresh()
end

--- copy selected files/directories to a current opened entry or it's parent
function M.copy_selections()
  _paste(fs.copy)
end

--- move selected files/directories to a current opened entry or it's parent
function M.move_selections()
  _paste(fs.move)
end

--- toggle a current file/directory to bookmarks list
function M.toggle_selection()
  local entry = M.renderer:get_current_entry()
  if entry.is_root then
    return
  end

  if M.ctx:is_selected(entry) then
    M.ctx:remove_selection(entry)
  else
    M.ctx:set_selection(entry)
  end

  M.renderer:render()
end

--- clear a bookmarks list
function M.clear_selections()
  M.ctx:clear_selections()
  M.renderer:render()
end

--- toggle visibility of hidden files/folders
function M.toggle_hidden_filter()
  local entry = M.renderer:get_current_entry()

  M.cfg.opts.show_hidden = not M.cfg.opts.show_hidden
  M.refresh()

  -- re-focus the current entry
  M.focus_file(entry.path)
end

--- close the explorer
function M.close()
  if M.win:is_open() then
    M.win:close()
  end
end

function M.toggle()
  if M.win:is_open() then
    M.win:close()

    return
  end

  -- get current file path
  local fpath = vim.api.nvim_buf_get_name(0)
  -- open explorer window
  M.win:open()
  -- refresh and render the explorer tree
  M:refresh()
  -- focus the current file
  M.focus_file(fpath)
end

--- setup actions
---@param explorer Explorer
---@param win Window
---@param renderer Renderer
---@param ctx Context
---@param cfg Config
function M.setup(explorer, win, renderer, ctx, cfg)
  M.explorer = explorer
  M.win = win
  M.renderer = renderer
  M.ctx = ctx
  M.cfg = cfg
end

return M
