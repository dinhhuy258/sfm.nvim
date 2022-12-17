---@class Window
---@field cfg Config
---@field win integer
---@field buf integer
---@field ns_id integer
local Window = {}

local BUFFER_OPTIONS = {
  swapfile = false,
  buftype = "nofile",
  modifiable = false,
  filetype = "sfm",
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
    "EndOfBuffer:SFMEndOfBuffer",
    "Normal:SFMNormal",
    "CursorLine:SFMCursorLine",
    "CursorLineNr:SFMCursorLineNr",
    "LineNr:SFMLineNr",
    "WinSeparator:SFMWinSeparator",
    "StatusLine:SFMStatusLine",
    "StatusLineNC:SFMStatuslineNC",
    "SignColumn:SFMSignColumn",
    "NormalNC:SFMNormalNC",
  }, ","),
}

--- Window constructor
---@param cfg Config
---@return Window
function Window.new(cfg)
  local self = setmetatable({}, { __index = Window })

  self.cfg = cfg
  self.win = nil
  self.buf = nil
  self.ns_id = vim.api.nvim_create_namespace "SFMHighlights"

  return self
end

--- check if the window is open or not
---@return boolean
function Window:is_open()
  return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

--- close the window
function Window:close()
  if self:is_open() then
    vim.api.nvim_win_close(self.win, 1)
  end

  self.win = nil
end

--- open the window
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

  vim.api.nvim_win_set_width(win, self.cfg.opts.view.width)

  -- focus on explorer window
  vim.api.nvim_win_set_buf(win, buf)

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  for _, map in pairs(self.cfg.opts.view.mappings.list) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        vim.api.nvim_buf_set_keymap(
          buf,
          "n",
          key,
          "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
          options
        )
      end
    else
      vim.api.nvim_buf_set_keymap(
        buf,
        "n",
        map.key,
        "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
        options
      )
    end
  end

  self.win = win
  self.buf = buf
end

--- move the cursor to (row, col)
---@param row integer
---@param col integer
function Window:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.win, { row, col })
end

--- add the highlights
---@param highlights table
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

--- replace the buffer with lines
---@param lines table
function Window:_set_lines(lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

--- render the given lines to window
---@param lines table
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
