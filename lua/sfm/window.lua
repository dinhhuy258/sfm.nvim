---@class Window
---@field win integer
---@field buf integer
local Window = {}

function Window.new()
  local self = setmetatable({}, { __index = Window })

  self.win = nil

  return self
end

function Window:is_open()
  return self.win ~= nil
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
  for _, line_info in ipairs(line_infos) do
    table.insert(lines, line_info.line)
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, 1, lines)

  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

return Window
