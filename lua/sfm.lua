local explorer = require "sfm.explorer"
local colors = require "sfm.colors"
local actions = require "sfm.actions"
local debounce = require "sfm.utils.debounce"
require "sfm.utils.table"

local M = {}

function M.setup(opts)
  colors.setup()

  local sfm_explorer = explorer.new(opts)
  actions.setup(sfm_explorer)

  vim.api.nvim_create_user_command("SFMToggle", function()
    sfm_explorer:toggle()
  end, {
    bang = true,
    nargs = "*",
  })

  -- prevent new opened file from opening in the same window as sfm explorer
  vim.api.nvim_create_autocmd("BufWipeout", {
    pattern = "sfm_*",
    callback = function()
      sfm_explorer.win:prevent_buffer_override()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if not sfm_explorer.win:is_open() then
        return
      end

      debounce.debounce("BufEnter:focus_file", 15, function()
        local bufnr = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(bufnr) or not sfm_explorer.win:is_open() then
          return
        end

        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local fpath = vim.fn.fnamemodify(bufname, ":p")

        actions.focus_file(fpath)
      end)
    end,
  })
end

return M
