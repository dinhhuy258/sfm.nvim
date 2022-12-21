local M = {}

local path_separator = package.config:sub(1, 1)

function M.clean(path)
  -- remove double path seps
  path = path:gsub(path_separator .. path_separator, path_separator)

  -- remove trailing path sep
  path = M.remove_trailing(path)

  return path
end

function M.join(paths)
  return table.concat(vim.tbl_map(M.remove_trailing, paths), path_separator)
end

function M.dirname(path)
  return string.match(path, "^(.-)[\\/]?([^\\/]*)$")
end

function M.basename(path)
  path = M.remove_trailing(path)
  local i = path:match("^.*()" .. path_separator)
  if not i then
    return path
  end

  return path:sub(i + 1, #path)
end

function M.remove_trailing(path)
  local p, _ = path:gsub(path_separator .. "$", "")

  return p
end

function M.has_trailing(path)
  return path:match(path_separator .. "$")
end

function M.add_trailing(path)
  if path:sub(-1) == path_separator then
    return path
  end

  return path .. path_separator
end

function M.exists(path)
  return vim.loop.fs_access(path, "r")
end

function M.isfile(path)
  local lstat = vim.loop.fs_lstat(path)

  return lstat.type == "file"
end

function M.isdir(path)
  if M.islink(path) then
    local stat = vim.loop.fs_stat(path)

    if stat ~= nil then
      return stat.type == "directory"
    end
  end

  local lstat = vim.loop.fs_lstat(path)

  return lstat.type == "directory"
end

function M.islink(path)
  local lstat = vim.loop.fs_lstat(path)

  return lstat.type == "link"
end

return M
