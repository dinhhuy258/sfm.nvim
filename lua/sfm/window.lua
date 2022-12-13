---@class Window
---@field win integer
---@field buf integer
---@field ns_id integer
local Window = {}

local BUFFER_OPTIONS = {
  swapfile = false,
  buftype = "nofile",
  modifiable = false,
  filetype = "sfm.nvim",
  bufhidden = "wipe",
  buflisted = false,
}

local WIN_OPTIONS = {
  relativenumber = false,
  number = false,
  list = false,
  foldenable = false,
  winfixwidth = true,
  winfixheight = true,
  spell = false,
  signcolumn = "yes",
  foldmethod = "manual",
  foldcolumn = "0",
  cursorcolumn = false,
  cursorline = true,
  cursorlineopt = "both",
  colorcolumn = "0",
  wrap = false,
  winhl = table.concat({
    -- TODO: Rename prefix NvimTree -> SFM
    "EndOfBuffer:NvimTreeEndOfBuffer",
    "Normal:NvimTreeNormal",
    "CursorLine:NvimTreeCursorLine",
    "CursorLineNr:NvimTreeCursorLineNr",
    "LineNr:NvimTreeLineNr",
    "WinSeparator:NvimTreeWinSeparator",
    "StatusLine:NvimTreeStatusLine",
    "StatusLineNC:NvimTreeStatuslineNC",
    "SignColumn:NvimTreeSignColumn",
    "NormalNC:NvimTreeNormalNC",
  }, ","),
}

function Window.new()
  local self = setmetatable({}, { __index = Window })

  self.win = nil
  self.buf = nil
  self.ns_id = vim.api.nvim_create_namespace "SFMHighlights"

  return self
end

function Window:is_open()
  return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

function Window:close()
  if self:is_open() then
    vim.api.nvim_win_close(self.win, 1)
  end

  self.win = nil
end

function Window:open()
  vim.api.nvim_command "topleft vnew"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  for option, value in pairs(BUFFER_OPTIONS) do
    vim.api.nvim_buf_set_option(buf, option, value)
  end

  for option, value in pairs(WIN_OPTIONS) do
    vim.api.nvim_win_set_option(win, option, value)
  end

  --TODO: move to configuration
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
  vim.api.nvim_buf_set_keymap(buf, "n", "P", "<CMD>lua require('sfm.actions').parent_entry()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "R", "<CMD>lua require('sfm.actions').refresh()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "n", "<CMD>lua require('sfm.actions').create()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "d", "<CMD>lua require('sfm.actions').delete()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "r", "<CMD>lua require('sfm.actions').rename()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "<SPACE>", "<CMD>lua require('sfm.actions').toggle_selection()<CR>", options)
  vim.api.nvim_buf_set_keymap(buf, "n", "<C-SPACE>", "<CMD>lua require('sfm.actions').clear_selections()<CR>", options)

  self.win = win
  self.buf = buf
end

function Window:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.win, { row, col })
end

function Window:_add_highlights(highlights)
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
end

function Window:_set_lines(lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function Window:render(lines)
  local _lines = {}
  local highlights = {}

  for _, line in ipairs(lines) do
    table.insert(_lines, line.line)

    for _, highlight in ipairs(line.highlights) do
      table.insert(highlights, highlight)
    end
  end

  self:_set_lines(_lines)
  self:_add_highlights(highlights)
end

return Window
