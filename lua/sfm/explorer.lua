local window = require "sfm.window"
local context = require "sfm.context"
local entry = require "sfm.entry"

---@class Explorer
---@field win Window
---@field ctx Context
---@field root Entry
local Explorer = {}

function Explorer.new()
  local self = setmetatable({}, { __index = Explorer })

  local cwd = vim.fn.getcwd()

  self.win = window.new()
  self.ctx = context.new(cwd)
  -- root has no parent
  self.root = entry.new(cwd, nil)

  return self
end

function Explorer:get_line_infos(current_entry, depth)
  local line_infos = {}
  local indent = string.rep("  ", depth)

  local line = ""
  local col_start = 0
  for _, e in ipairs(current_entry.entries) do
    table.insert(self.ctx.entries, e)
    local linenr = #self.ctx.entries - 1 -- 0-indexed

    local name, name_hl_group = e.get_name(e)
    local indicator, indicator_hl_group = e.get_indicator(e)
    local icon, icon_hl_group = e.get_icon(e)

    line = indent
    col_start = #line
    line = line .. indicator

    local highlights = {}
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

    line = line .. " "
    col_start = #line
    line = line .. name
    table.insert(highlights, {
      hl_group = name_hl_group,
      col_start = col_start,
      col_end = #line,
      line = linenr,
    })

    table.insert(line_infos, {
      line = line,
      highlights = highlights,
    })

    if e.is_dir and e.state == entry.State.Open then
      table.extend(line_infos, self:get_line_infos(e, depth + 1))
    end
  end

  return line_infos
end

function Explorer:line_infos()
  self.ctx.entries = {}

  return self:get_line_infos(self.root, 0)
end

function Explorer:render()
  self.win:render(self:line_infos())
end

function Explorer:move_cursor(row, col)
  self.win:move_cursor(row, col)
end

function Explorer:toggle()
  if self.win:is_open() then
    self.win:close()

    return
  end

  -- load dir
  self.root:readdir()
  -- open explorer window
  self.win:open()
  -- render
  self:render()
end

return Explorer
