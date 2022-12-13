local input = require "sfm.utils.input"
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local log = require "sfm.utils.log"

local M = {}

M.explorer = nil
M.ctx = nil

--- focus the given path
---@param fpath string
function M.focus_file(fpath)
  if vim.startswith(fpath, M.ctx.root.path) then
    local dirs = vim.split(string.sub(path.dirname(fpath), string.len(M.ctx.root.path) + 2), "/")
    local current = M.ctx.root

    for _, dir in ipairs(dirs) do
      for _, entry in ipairs(current.entries) do
        if entry.is_dir and entry.name == dir then
          if not M.ctx:is_open(entry) then
            M.ctx:set_open(entry)
          end

          current = entry

          break
        end
      end
    end
  end

  local index = M.ctx:get_index(fpath)
  if index == 0 then
    return
  end

  M.explorer:render()
  M.explorer:move_cursor(index, 0)
end

--- edit file or toggle directory
function M.edit()
  local entry = M.ctx:current()
  if not entry.is_dir then
    vim.cmd "wincmd l"
    vim.cmd("keepalt edit " .. entry.path)

    return
  end

  if M.ctx:is_open(entry) then
    -- close directory
    M.ctx:remove_open(entry)
    -- re-render
    M.explorer:render()

    return
  end

  -- open directory
  M.ctx:set_open(entry)
  -- refresh the explorer
  M.explorer:refresh()
end

--- navigate to the first sibling of current file/directory
function M.first_sibling()
  local entry = M.ctx:current()
  if entry.parent == nil then
    return
  end

  local first_entry = table.first(entry.parent.entries)
  M.focus_file(first_entry.path)
end

--- navigate to the last sibling of current file/directory
function M.last_sibling()
  local entry = M.ctx:current()
  if entry.parent == nil then
    return
  end

  local last_entry = table.last(entry.parent.entries)
  M.focus_file(last_entry.path)
end

--- move cursor to the parent directory
function M.parent_entry()
  local entry = M.ctx:current()
  local parent = entry.parent
  if parent == nil then
    return
  end

  M.focus_file(parent.path)
end

--- refresh the explorer
function M.refresh()
  M.explorer:refresh()
end

--- add a file; leaving a trailing `/` will add a directory
function M.create()
  local entry = M.ctx:current()
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
      M.explorer:refresh()
      -- focus file
      M.focus_file(fpath)

      log.info(fpath .. " was created")
    else
      log.error("Couldn't create " .. fpath)
    end
  end)
end

--- close current opened directory or parent
function M.close_entry()
  local entry = M.ctx:current()
  if not entry.is_dir or not M.ctx:is_open(entry) then
    entry = entry.parent
  end

  if entry.is_root then
    M.first_sibling()

    return
  end

  -- close directory
  M.ctx:remove_open(entry)
  -- re-render
  M.explorer:render()
  -- re-focus entry
  M.focus_file(entry.path)
end

--- delete a file/directory
function M.delete()
  local entry = M.ctx:current()
  input.select("Remove " .. entry.name .. " (y/n)?", function()
    -- on yes
    input.clear()
    if entry.is_dir and not entry.is_symlink then
      local ok = fs.rmdir(entry.path)

      if not ok then
        log.error("Could not delete " .. entry.path)
      end
    else
      local ok = fs.rm(entry.path)

      if not ok then
        log.error("Could not delete " .. entry.path)
      end
    end

    -- refresh the explorer
    M.explorer:refresh()
  end, function()
    -- on no
    input.clear()
  end)
end

function M.rename()
  local entry = M.ctx:current()
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
      M.explorer:refresh()
      -- focus file
      M.focus_file(to_path)

      log.info(string.format("Rename %s ➜ %s", path.basename(from_path), path.basename(to_path)))
    else
      log.error(string.format("Couldn't rename %s ➜ %s", path.basename(from_path), path.basename(to_path)))
    end
  end)
end

function M.setup(explorer)
  M.explorer = explorer
  M.ctx = explorer.ctx
end

return M
