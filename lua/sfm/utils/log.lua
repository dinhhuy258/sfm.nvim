local M = {}

function M.info(message)
  vim.notify("[sfm] " .. message, vim.log.levels.INFO)
end

function M.error(message)
  vim.notify("[sfm] " .. message, vim.log.levels.ERROR)
end

return M
