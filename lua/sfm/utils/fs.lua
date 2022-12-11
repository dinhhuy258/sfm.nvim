local path = require "sfm.utils.path"
local log = require "sfm.utils.log"

local M = {}

function M.create_file(fpath)
  if path.exists(fpath) then
    log.info(fpath .. " already exists")

    return false
  end

  local fd = vim.loop.fs_open(fpath, "w", 420)
  if not fd then
    log.error("Couldn't create file " .. fpath)

    return false
  end

  vim.loop.fs_close(fd)

  return true
end

function M.create_dir(fpath)
  if path.exists(fpath) then
    log.info(fpath .. " already exists")

    return false
  end

  local ok = vim.loop.fs_mkdir(fpath, 493)
  if not ok then
    log.error("Couldn't create folder " .. fpath)

    return false
  end

  return true
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

return M
