local M = {}

function M.error(message)
  vim.notify("sfm" .. message, vim.log.levels.ERROR)
end

return M
