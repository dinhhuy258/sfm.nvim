local path = require "sfm.utils.path"

local M = {}

function M.create_file(fpath)
  local fd = vim.loop.fs_open(fpath, "w", 420)
  if not fd then
    return false
  end

  vim.loop.fs_close(fd)

  return true
end

function M.create_dir(fpath)
  return vim.loop.fs_mkdir(fpath, 493)
end

function M.scandir(fpath)
  local paths = {}
  local handle = vim.loop.fs_scandir(fpath)
  if type(handle) == "userdata" then
    local function iterator()
      return vim.loop.fs_scandir_next(handle)
    end

    for name in iterator do
      local absolute_path = path.join { fpath, name }
      table.insert(paths, absolute_path)
    end
  end

  return paths
end

function M._rmdir(fpath)
  local handle = vim.loop.fs_scandir(fpath)
  if type(handle) == "string" then
    return vim.api.nvim_err_writeln(handle)
  end

  while true do
    local name = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    return M.remove(fpath.join { fpath, name })
  end

  return vim.loop.fs_rmdir(fpath)
end

function M.remove(fpath)
  if not path.exists(fpath) then
    return false
  end

  if path.isdir(fpath) then
    return M._rmdir(fpath)
  elseif path.isfile(fpath) or path.islink(fpath) then
    return vim.loop.fs_unlink(fpath)
  else
    -- not recognize the file type
    return false
  end
end

function M.rename(from_path, to_path)
  return vim.loop.fs_rename(from_path, to_path)
end

function M.copy(source_path, dest_path)
  if not path.exists(source_path) then
    return false
  end

  if source_path == dest_path then
    -- do nothing
    return true
  end

  local source_lstat = vim.loop.fs_lstat(source_path)

  if path.isfile(source_path) then
    return vim.loop.fs_copyfile(source_path, dest_path)
  elseif path.isdir(source_path) then
    local handle = vim.loop.fs_scandir(source_path)
    if type(handle) == "string" then
      return false
    elseif not handle then
      return false
    end

    local success = vim.loop.fs_mkdir(dest_path, source_lstat.mode)
    if not success then
      return false
    end

    while true do
      local name = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      success = M.copy(path.join { source_path, name }, path.join { dest_path, name })
      if not success then
        return false
      end
    end
  else
    return false
  end

  return true
end

function M.move(source_path, dest_path)
  if not path.exists(source_path) then
    return false
  end

  if source_path == dest_path then
    -- do nothing
    return true
  end

  return M.rename(source_path, dest_path)
end

return M
