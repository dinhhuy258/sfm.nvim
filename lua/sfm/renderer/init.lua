local indent_renderer = require "sfm.renderer.indent_renderer"
local indicator_renderer = require "sfm.renderer.indicator_renderer"
local icon_renderer = require "sfm.renderer.icon_renderer"
local selection_renderer = require "sfm.renderer.selection_renderer"
local name_renderer = require "sfm.renderer.name_renderer"
local path = require "sfm.utils.path"

---@class Renderer
---@field view View
---@field ctx Context
---@field renderers table<string, table>
---@field entry_filters table<string, table>
---@field entries Entry[]
local Renderer = {}

--- Renderer constructor
---@param ctx Context
---@param view View
---@return Renderer
function Renderer.new(ctx, view)
  local self = setmetatable({}, { __index = Renderer })

  self.ctx = ctx
  self.view = view
  self.entries = {}
  self.renderers = {}
  self.entry_filters = {}
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

  self:_sort_renderers()

  return self
end

--- sort the renderers by priority
---@private
function Renderer:_sort_renderers()
  table.sort(self.renderers, function(a, b)
    return a.priority < b.priority
  end)
end

--- remove the renderer by name
---@param name string
function Renderer:remove_renderer(name)
  for idx, renderer in ipairs(self.renderers) do
    if renderer.name == name then
      table.remove(self.renderers, idx)

      break
    end
  end
end

--- register a renderer
---@param name string
---@param priority integer
---@param func function
function Renderer:register_renderer(name, priority, func)
  self:remove_renderer(name)

  table.insert(self.renderers, {
    name = name,
    priority = priority,
    func = func,
  })
end

--- remove entry filter by given name
---@param name string
function Renderer:remove_entry_filter(name)
  for idx, filter in ipairs(self.entry_filters) do
    if filter.name == name then
      table.remove(self.entry_filters, idx)

      break
    end
  end
end

--- register an entry filter
---@param name string
---@param func function
function Renderer:register_entry_filter(name, func)
  self:remove_entry_filter(name)

  table.insert(self.entry_filters, {
    name = name,
    func = func,
  })
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

--- check if the given entry can be renderered
---@param entry Entry
function Renderer:should_render_entry(entry)
  for _, filter in pairs(self.entry_filters) do
    if not filter.func(entry) then
      return false
    end
  end

  return true
end

--- update the rendered entries
function Renderer:_update_rendered_entries()
  self.entries = {}

  local function _update_rendered_entry(current_entry)
    for _, e in ipairs(current_entry.entries) do
      if self:should_render_entry(e) then
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
    local render_component = renderer.func(entry, self.ctx)
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

  self.view:render(lines)
end

return Renderer
