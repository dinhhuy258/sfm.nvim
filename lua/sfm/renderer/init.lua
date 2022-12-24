local indent_renderer = require "sfm.renderer.indent_renderer"
local indicator_renderer = require "sfm.renderer.indicator_renderer"
local icon_renderer = require "sfm.renderer.icon_renderer"
local selection_renderer = require "sfm.renderer.selection_renderer"
local name_renderer = require "sfm.renderer.name_renderer"
local path = require "sfm.utils.path"

---@class Renderer
---@field cfg Config
---@field win Window
---@field ctx Context
---@field renderers table<string, table>
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
  self.renderers = {}
  table.insert(self.renderers, {
    name = "indent",
    func = indent_renderer.render_entry,
    priority = 10,
  })
  table.insert(self.renderers, {
    name = "indicator",
    func = indicator_renderer.render_entry,
    priority = 20,
  })
  table.insert(self.renderers, {
    name = "icon",
    func = icon_renderer.render_entry,
    priority = 30,
  })
  table.insert(self.renderers, {
    name = "selection",
    func = selection_renderer.render_entry,
    priority = 40,
  })
  table.insert(self.renderers, {
    name = "name",
    func = name_renderer.render_entry,
    priority = 50,
  })

  table.sort(self.renderers, function(a, b)
    return a.priority < b.priority
  end)

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

--- update the rendered entries
function Renderer:_update_rendered_entries()
  self.entries = {}

  local function _update_rendered_entry(current_entry)
    for _, e in ipairs(current_entry.entries) do
      if not e.is_hidden or self.cfg.opts.show_hidden_files then
        table.insert(self.entries, e)

        if self.ctx:is_open(e) then
          _update_rendered_entry(e)
        end
      end
    end
  end

  table.insert(self.entries, self.ctx.root)
  _update_rendered_entry(self.ctx.root)
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

  local highlights = {}
  local line = ""
  for _, renderer in pairs(self.renderers) do
    local render_component = renderer.func(entry, self.ctx, self.cfg)
    local text = render_component.text
    if text ~= nil then
      if line ~= "" then
        line = line .. " "
      end

      line = line .. text

      local highlight = render_component.highlight
      if highlight ~= nil then
        table.insert(highlights, {
          hl_group = highlight,
          col_start = #line - #text,
          col_end = #line,
          line = linenr,
        })
      end
    end
  end

  return {
    line = line,
    highlights = highlights,
  }
end

--- render the explorer
function Renderer:render()
  self:_update_rendered_entries()
  local lines = {}
  for linenr, e in ipairs(self.entries) do
    table.insert(lines, self:_render_entry(e, linenr - 1)) -- 0-indexed
  end

  self.win:render(lines)
end

return Renderer
