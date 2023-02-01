local M = {}

M.path_separator = package.config:sub(1, 1)

function M.clean(path)
  -- remove double path seps
  path = path:gsub(M.path_separator .. "+", M.path_separator)

  -- remove trailing path sep
  path = M.remove_trailing(path)

  return path
end

function M.split(path)
  return vim.tbl_filter(function(p)
    return p ~= nil and p ~= ""
  end, vim.split(path, M.path_separator))
end

function M.join(paths)
  return table.concat(vim.tbl_map(M.remove_trailing, paths), M.path_separator)
end

function M.dirname(path)
  return string.match(path, "^(.-)[\\/]?([^\\/]*)$")
end

function M.basename(path)
  path = M.remove_trailing(path)
  local i = path:match("^.*()" .. M.path_separator)
  if not i then
    return path
  end

  return path:sub(i + 1, #path)
end

function M.remove_trailing(path)
  local p, _ = path:gsub(M.path_separator .. "$", "")

  return p
end

function M.has_trailing(path)
  return path:match(M.path_separator .. "$")
end

function M.add_trailing(path)
  if path:sub(-1) == M.path_separator then
    return path
  end

  return path .. M.path_separator
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

function M.unify(paths)
  local function ancestors(path)
    local result = {}
    local ancestor = ""
    for _, p in pairs(M.split(path)) do
      ancestor = M.join { ancestor, p }

      if ancestor ~= path then
        table.insert(result, ancestor)
      end
    end

    return result
  end

  local function is_disjoint(set1, set2)
    local map = {}

    for _, element in ipairs(set1) do
      map[element] = true
    end

    for _, element in ipairs(set2) do
      if map[element] ~= nil then
        return false
      end
    end

    return true
  end

  local result = {}

  for _, path in ipairs(paths) do
    if is_disjoint(ancestors(path), paths) then
      table.insert(result, path)
    end
  end

  return result
end

return M
