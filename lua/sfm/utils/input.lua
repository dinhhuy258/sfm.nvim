local M = {}

function M.clear_prompt()
  vim.api.nvim_command "normal! :"
end

function M.prompt(ask)
  return vim.fn.input(ask)
end

return M
