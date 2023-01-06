local explorer = require "sfm.explorer"
local config = require "sfm.config"
local colors = require "sfm.colors"
local actions = require "sfm.actions"
local debounce = require "sfm.utils.debounce"
local event = require "sfm.event"
require "sfm.utils.table"

local M = {}

--- Initialize sfm explorer
---@param opts table
---@return Explorer
function M.setup(opts)
  config.setup(opts)
  colors.setup()

  local sfm_explorer = explorer.new()

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
      sfm_explorer.view:prevent_buffer_override()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if not sfm_explorer.view:is_open() then
        return
      end

      debounce.debounce("BufEnter:focus_file", 15, function()
        local bufnr = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(bufnr) or not sfm_explorer.view:is_open() then
          return
        end

        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local fpath = vim.fn.fnamemodify(bufname, ":p")

        actions.focus_file(fpath)
      end)
    end,
  })

  -- reset highlights when colorscheme is changed
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      colors.setup()
      sfm_explorer.view:reset_winhl()
      -- refresh the explorer
      actions.refresh()
    end,
  })

  sfm_explorer:subscribe(event.ExplorerOpen, function(payload)
    local bufnr = payload["bufnr"]
    local options = {
      noremap = true,
      silent = true,
      expr = false,
    }
    for _, map in pairs(config.opts.view.mappings.list) do
      if type(map.key) == "table" then
        for _, key in pairs(map.key) do
          vim.api.nvim_buf_set_keymap(
            bufnr,
            "n",
            key,
            "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
            options
          )
        end
      else
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          map.key,
          "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
          options
        )
      end
    end
  end)

  return sfm_explorer
end

return M
