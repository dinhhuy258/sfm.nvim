local input = require "sfm.utils.input"
local path = require "sfm.utils.path"
local fs = require "sfm.utils.fs"
local log = require "sfm.utils.log"
local M = {}

M.explorer = nil

--- edit file or toggle directory
function M.edit()
  local entry = M.explorer.ctx:current()
  if not entry.is_dir then
    vim.cmd "wincmd l"
    vim.cmd("keepalt edit " .. entry.path)

    return
  end

  if entry.state == entry.State.Open then
    -- close directory
    entry:close()
    -- re-render
    M.explorer:render()

    return
  end

  -- open directory
  entry:readdir()
  -- re-render
  M.explorer:render()
end

--- navigate to the first sibling of current file/directory
function M.first_sibling()
  local entry = M.explorer.ctx:current()
  if entry.parent == nil then
    return
  end

  local first_entry = table.first(entry.parent.entries)
  local index = M.explorer.ctx:get_index(first_entry)
  if index == 0 then
    return
  end

  M.explorer:move_cursor(index, 0)
end

--- navigate to the last sibling of current file/directory
function M.last_sibling()
  local entry = M.explorer.ctx:current()
  if entry.parent == nil then
    return
  end

  local last_entry = table.last(entry.parent.entries)
  local index = M.explorer.ctx:get_index(last_entry)
  if index == 0 then
    return
  end

  M.explorer:move_cursor(index, 0)
end

--- add a file; leaving a trailing `/` will add a directory
function M.create()
  local entry = M.explorer.ctx:current()
  local dest = entry
  if not entry.is_dir or entry.state == entry.State.Close then
    dest = entry.parent
  end

  local name = input.prompt("Create file " .. path.add_trailing(dest.path))
  input.clear_prompt()
  if name == "" or name == "/" then
    return
  end

  local fpath = path.join { dest.path, name }

  local ok = true
  if path.has_trailing(fpath) then
    -- create directory
    fpath = path.remove_trailing(fpath)
    ok = fs.create_dir(path)
  else
    -- create file
    ok = fs.create_file(fpath)
  end

  if ok then
    log.info(fpath .. " was created")
  end
end

function M.setup(explorer)
  M.explorer = explorer
end

return M
