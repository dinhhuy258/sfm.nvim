local input = require "sfm.utils.input"
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local log = require "sfm.utils.log"

local M = {}

M.explorer = nil
M.ctx = nil

--- focus the given path
---@param fpath string
local function focus_file(fpath)
  local index = M.ctx:get_index(fpath)
  if index == 0 then
    return
  end

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
  focus_file(first_entry.path)
end

--- navigate to the last sibling of current file/directory
function M.last_sibling()
  local entry = M.ctx:current()
  if entry.parent == nil then
    return
  end

  local last_entry = table.last(entry.parent.entries)
  focus_file(last_entry.path)
end

--- move cursor to the parent directory
function M.parent_entry()
  local entry = M.ctx:current()
  local parent = entry.parent
  if parent == nil then
    return
  end

  focus_file(parent.path)
end

--- refresh the explorer
function M.refresh()
  M.explorer:refresh()
end

--- add a file; leaving a trailing `/` will add a directory
function M.create()
  local entry = M.ctx:current()
  if not entry.is_dir or not M.ctx:is_open(entry) then
    entry = entry.parent
  end

  input.prompt("Create file " .. path.add_trailing(entry.path), nil, "file", function(name)
    input.clear_prompt()
    if name == nil or name == "" or name == "/" then
      return
    end

    local fpath = path.join { entry.path, name }

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
      focus_file(fpath)

      log.info(fpath .. " was created")
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
  focus_file(entry.path)
end

--- delete a file/directory
function M.delete()
  local entry = M.ctx:current()
  input.select("Remove " .. entry.name .. " (y/n)?", function()
    -- on yes
    input.clear_prompt()
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
    input.clear_prompt()
  end)
end

function M.setup(explorer)
  M.explorer = explorer
  M.ctx = explorer.ctx
end

return M
