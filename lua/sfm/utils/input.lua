local M = {}

function M.prompt(msg, default, completion, on_confirm)
  vim.ui.input({ prompt = msg, default = default, completion = completion }, function(input)
    on_confirm(input)
  end)
end

function M.select(msg, on_yes, on_no)
  vim.notify(msg)
  local choice = vim.fn.nr2char(vim.fn.getchar())
  if choice:match "^y" or choice:match "^Y" then
    on_yes()
  else
    on_no()
  end
end

function M.clear()
  vim.api.nvim_command "normal! :"
end

return M
