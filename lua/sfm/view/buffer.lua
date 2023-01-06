local M = {}

local NAMESPACE_ID = vim.api.nvim_create_namespace "SFMHighlights"

local BUFFER_OPTIONS = {
  swapfile = false,
  buftype = "nofile",
  modifiable = false,
  filetype = "sfm",
  bufhidden = "wipe",
  buflisted = false,
}

--- add the highlights
---@param bufnr integer
---@param highlights table
local function _add_highlights(bufnr, highlights)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE_ID, 0, -1)

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      NAMESPACE_ID,
      highlight.hl_group,
      highlight.line,
      highlight.col_start,
      highlight.col_end
    )
  end
end

--- replace the buffer with lines
---@param bufnr integer
---@param lines table
local function _set_lines(bufnr, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

--- set buffer option
---@param bufnr integer
function M.set_buffer_options(bufnr)
  for option, value in pairs(BUFFER_OPTIONS) do
    vim.bo[bufnr][option] = value
  end
end

--- create new sfm buffer
---@return integer
function M.create_buffer()
  local tabnr = vim.api.nvim_get_current_tabpage()
  local bufnr = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_name(bufnr, "sfm_" .. tabnr)

  return bufnr
end

--- render the given lines to buffer
---@param bufnr integer
---@param lines table
function M.render(bufnr, lines)
  local _lines = {}
  local highlights = {}

  for _, line in ipairs(lines) do
    table.insert(_lines, line.line)

    for _, highlight in ipairs(line.highlights) do
      table.insert(highlights, highlight)
    end
  end

  _set_lines(bufnr, _lines)
  _add_highlights(bufnr, highlights)
end

return M
