local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local path = require "sfm.utils.path"

---@class Renderer
---@field cfg Config
---@field win Window
---@field ctx Context
---@field entries Entry[]
local Renderer = {}

--- Renderer constructor
---@param cfg Config
---@param ctx Context
---@param win Window
---@return Renderer
function Renderer.new(cfg, ctx, win)
  local self = setmetatable({}, { __index = Renderer })

  self.cfg = cfg
  self.ctx = ctx
  self.win = win
  self.entries = {}

  return self
end

--- get the current entry at the current position
---@return Entry
function Renderer:get_current_entry()
  local entry = self.entries[vim.fn.line "."]
  if entry then
    return entry
  end

  error "failed to get the current entry"
end

--- find the line of the current path, return 0 if not found
---@param fpath string
---@return integer
function Renderer:find_line_number_for_path(fpath)
  for index, e in ipairs(self.entries) do
    if fpath == e.path then
      return index
    end
  end

  return 0
end

--- refresh the render entries
function Renderer:refresh_entries()
  self.entries = {}

  local function _refresh_entry(current_entry)
    for _, e in ipairs(current_entry.entries) do
      if not e.is_hidden or self.cfg.opts.show_hidden_files then
        table.insert(self.entries, e)

        if self.ctx:is_open(e) then
          _refresh_entry(e)
        end
      end
    end
  end

  table.insert(self.entries, self.ctx.root)
  _refresh_entry(self.ctx.root)
end

--- render the given entry with linern
---@param entry Entry
---@param linenr integer
---@return table
function Renderer:_render_entry(entry, linenr)
  if entry.is_root then
    local root_name = path.join {
      path.remove_trailing(vim.fn.fnamemodify(entry.path, ":~")),
      "..",
    }

    local highlights = {}
    table.insert(highlights, {
      hl_group = "SFMRootFolder",
      col_start = 0,
      col_end = string.len(root_name),
      line = linenr,
    })

    return {
      line = root_name,
      highlights = highlights,
    }
  end

  local icons = self.cfg.opts.renderer.icons
  local indent = string.rep("  ", entry.depth - 1)

  local is_entry_open = self.ctx:is_open(entry)
  local highlights = {}
  local line = ""
  local col_start = 0
  local name = entry.name
  local name_hl_group = entry.is_dir and "SFMFolderName" or "SFMFileName"
  local indicator = (entry.is_dir and is_entry_open and icons.indicator.folder_open)
    or (entry.is_dir and not is_entry_open and icons.indicator.folder_closed)
    or icons.indicator.file
  local indicator_hl_group = entry.is_dir and "SFMFolderIndicator" or "SFMFileIndicator"
  local icon = ""
  local icon_hl_group = ""
  if entry.is_symlink then
    if entry.is_dir then
      if is_entry_open then
        icon = icons.folder.symlink_open
        icon_hl_group = "SFMFolderIcon"
      else
        icon = icons.folder.symlink
        icon_hl_group = "SFMFolderIcon"
      end
    else
      icon = icons.file.symlink
      icon_hl_group = "SFMDefaultFileIcon"
    end
  elseif entry.is_dir then
    if is_entry_open then
      icon = icons.folder.open
      icon_hl_group = "SFMFolderIcon"
    else
      icon = icons.folder.default
      icon_hl_group = "SFMFolderIcon"
    end
  elseif not has_devicons or not self.cfg.opts.devicons_enable then
    icon = icons.file.default
    icon_hl_group = "SFMDefaultFileIcon"
  else
    icon, icon_hl_group = devicons.get_icon(entry.name, nil, { default = true })
  end

  line = indent
  col_start = #line
  line = line .. indicator
  table.insert(highlights, {
    hl_group = indicator_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  line = line .. " "
  col_start = #line
  line = line .. icon
  table.insert(highlights, {
    hl_group = icon_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  if self.ctx:is_selected(entry) then
    line = line .. " "
    col_start = #line
    line = line .. icons.selected
    table.insert(highlights, {
      hl_group = "SFMSelection",
      col_start = col_start,
      col_end = #line,
      line = linenr,
    })
  end

  line = line .. " "
  col_start = #line
  line = line .. name
  table.insert(highlights, {
    hl_group = name_hl_group,
    col_start = col_start,
    col_end = #line,
    line = linenr,
  })

  return {
    line = line,
    highlights = highlights,
  }
end

--- render the explorer
function Renderer:render()
  local lines = {}
  for linenr, e in ipairs(self.entries) do
    table.insert(lines, self:_render_entry(e, linenr - 1)) -- 0-indexed
  end

  self.win:render(lines)
end

return Renderer
