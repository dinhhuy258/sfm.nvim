---@class BufferManager
---@field cfg Config
---@field bufnr integer
---@field ns_id integer
local BufferManager = {}

local BUFFER_OPTIONS = {
  swapfile = false,
  buftype = "nofile",
  modifiable = false,
  filetype = "sfm",
  bufhidden = "wipe",
  buflisted = false,
}

--- BufferManager constructor
---@param cfg Config
---@return BufferManager
function BufferManager.new(cfg)
  local self = setmetatable({}, { __index = BufferManager })

  self.cfg = cfg
  self.bufnr = nil
  self.ns_id = vim.api.nvim_create_namespace "SFMHighlights"

  return self
end

-- local function is_sfm_bufer(bufnr)
--   return vim.fn.bufexists(bufnr) and vim.bo[bufnr].filetype == BUFFER_OPTIONS.filetype
-- end

function BufferManager:create_buffer()
  local tabnr = vim.api.nvim_get_current_tabpage()
  self.bufnr = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_name(self.bufnr, "sfm_" .. tabnr)
  for option, value in pairs(BUFFER_OPTIONS) do
    vim.bo[self.bufnr][option] = value
  end

  -- TODO: moving these key mappings out of buffer manager
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
end

--- add the highlights
---@private
---@param highlights table
function BufferManager:_add_highlights(highlights)
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
function BufferManager:_set_lines(lines)
  vim.api.nvim_buf_set_option(self.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(self.bufnr, "modifiable", false)
end

--- render the given lines to window
---@param lines table
function BufferManager:render(lines)
  -- if not self:is_open() then
  --   return
  -- end

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

return BufferManager
