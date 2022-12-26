local explorer = require "sfm.explorer"
local colors = require "sfm.colors"
local actions = require "sfm.actions"
local debounce = require "sfm.utils.debounce"
require "sfm.utils.table"

local M = {
  sfm_explorer = nil,
}

function M.setup(opts)
  colors.setup()

  M.sfm_explorer = explorer.new(opts)

  vim.api.nvim_create_user_command("SFMToggle", function()
    actions.toggle()
  end, {
    bang = true,
    nargs = "*",
  })

  -- prevent new opened file from opening in the same window as sfm explorer
  vim.api.nvim_create_autocmd("BufWipeout", {
    pattern = "sfm_*",
    callback = function()
      M.sfm_explorer.win:prevent_buffer_override()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if not M.sfm_explorer.win:is_open() then
        return
      end

      debounce.debounce("BufEnter:focus_file", 15, function()
        local bufnr = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(bufnr) or not M.sfm_explorer.win:is_open() then
          return
        end

        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local fpath = vim.fn.fnamemodify(bufname, ":p")

        actions.focus_file(fpath)
      end)
    end,
  })
end

function M.load_extention(name)
  local ok, ext = pcall(require, "sfm.extensions." .. name)
  if not ok then
    error(string.format("'%s' extension doesn't exist or isn't installed: %s", name, ext))
  end

  ext.setup(M.sfm_explorer)
end

return M
