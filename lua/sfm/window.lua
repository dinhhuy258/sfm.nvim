---@class Window
---@field cfg Config
---@field winnr integer
---@field bufnr integer
---@field ns_id integer
---@field on_open_listeners table
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
  self.winnr = nil
  self.bufnr = nil
  self.ns_id = vim.api.nvim_create_namespace "SFMHighlights"
  self.on_open_listeners = {}

  return self
end

--- set on open listener
---@param listener function
function Window:set_on_open_listener(listener)
  table.insert(self.on_open_listeners, listener)
end

--- check if the window is open or not
---@return boolean
function Window:is_open()
  return self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr)
end

--- close the window
function Window:close()
  if self:is_open() then
    vim.api.nvim_win_close(self.winnr, 1)
  end

  self.winnr = nil
end

--- open the window
function Window:open()
  vim.api.nvim_command "topleft vnew"
  self.winnr = vim.api.nvim_get_current_win()
  self.bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(self.bufnr, "sfm_" .. vim.api.nvim_get_current_tabpage())

  for option, value in pairs(WIN_OPTIONS) do
    vim.api.nvim_win_set_option(self.winnr, option, value)
  end

  vim.api.nvim_win_set_width(self.winnr, self.cfg.opts.view.width)

  for option, value in pairs(BUFFER_OPTIONS) do
    vim.api.nvim_buf_set_option(self.bufnr, option, value)
  end

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  for _, map in pairs(self.cfg.opts.view.mappings.list) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        vim.api.nvim_buf_set_keymap(
          self.bufnr,
          "n",
          key,
          "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
          options
        )
      end
    else
      vim.api.nvim_buf_set_keymap(
        self.bufnr,
        "n",
        map.key,
        "<CMD>lua require('sfm.actions')." .. map.action .. "()<CR>",
        options
      )
    end
  end

  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  for _, listener in ipairs(self.on_open_listeners) do
    listener(self.winnr, self.bufnr)
  end
end

--- prevent explorer buffer is being overrided
function Window:prevent_buffer_override()
  if not self:is_open() then
    return
  end

  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if curwin ~= self.winnr or curbuf == self.bufnr or bufname == "" then
      return
    end

    pcall(vim.api.nvim_win_close, curwin, { force = true })
    pcall(vim.cmd, "edit " .. bufname)
  end)
end

--- move the cursor to (row, col)
---@param row integer
---@param col integer
function Window:move_cursor(row, col)
  if not self:is_open() then
    return
  end

  vim.api.nvim_win_set_cursor(self.winnr, { row, col })
end

--- add the highlights
---@param highlights table
function Window:_add_highlights(highlights)
  vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, -1)

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
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
  vim.api.nvim_buf_set_option(self.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(self.bufnr, "modifiable", false)
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
