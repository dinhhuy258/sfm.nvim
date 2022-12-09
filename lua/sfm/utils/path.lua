local M = {}

local path_separator = package.config:sub(1, 1)

function M.join(paths)
  return table.concat(vim.tbl_map(M.remove_trailing, paths), path_separator)
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

return M
