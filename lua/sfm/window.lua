---@class Window
---@field win integer
---@field buf integer
---@field ns_id integer
local Window = {}

function Window.new()
  local self = setmetatable({}, { __index = Window })

  self.win = nil
  self.buf = nil
  self.ns_id = vim.api.nvim_create_namespace "SFMHighlights"

  return self
end

function Window:is_open()
  return self.win ~= nil
end

function Window:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.win, { row, col })
end

function Window:open()
  vim.api.nvim_command "topleft vnew"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "sfm.nvim")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)

  --TODO: Move to configuration
  vim.api.nvim_win_set_width(win, 40)

  -- focus on explorer window
  vim.api.nvim_win_set_buf(win, buf)

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "<CMD>lua require('sfm.actions').edit()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "<S-TAB>", "<CMD>lua require('sfm.actions').close_entry()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "J", "<CMD>lua require('sfm.actions').last_sibling()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "K", "<CMD>lua require('sfm.actions').first_sibling()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "n", "<CMD>lua require('sfm.actions').create()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "d", "<CMD>lua require('sfm.actions').delete()<CR>", options)

  self.win = win
  self.buf = buf
end

function Window:close()
  vim.api.nvim_win_close(self.win, 1)
  self.win = nil
end

function Window:render(line_infos)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  local lines = {}
  local highlights = {}
  for _, line_info in ipairs(line_infos) do
    table.insert(lines, line_info.line)

    for _, highlight in ipairs(line_info.highlights) do
      table.insert(highlights, highlight)
    end
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, 1, lines)

  -- add highlights
  vim.api.nvim_buf_clear_namespace(self.buf, self.ns_id, 0, -1)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      self.buf,
      self.ns_id,
      highlight.hl_group,
      highlight.line,
      highlight.col_start,
      highlight.col_end
    )
  end

  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

return Window
