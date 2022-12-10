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

return M
