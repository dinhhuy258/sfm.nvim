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

local function get_line_infos(current_entry, depth)
  local line_infos = {}
  local indent = string.rep("  ", depth)

  local line = ""
  local col_start = 0
  for i, e in ipairs(current_entry.entries) do
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
      line = i - 1, -- 0-indexed
    })

    line = line .. " "
    col_start = #line
    line = line .. icon

    table.insert(highlights, {
      hl_group = icon_hl_group,
      col_start = col_start,
      col_end = #line,
      line = i - 1, -- 0-indexed
    })

    line = line .. " "
    col_start = #line
    line = line .. name
    table.insert(highlights, {
      hl_group = name_hl_group,
      col_start = col_start,
      col_end = #line,
      line = i - 1, -- 0-indexed
    })

    table.insert(line_infos, {
      line = line,
      highlights = highlights,
    })

    if current_entry.is_dir and current_entry.state == entry.State.Open then
      for _, child_entry in ipairs(current_entry.entries) do
        local child_line_infos = get_line_infos(child_entry, depth + 1)
        for _, line_info in ipairs(child_line_infos) do
          table.insert(line_infos, line_info)
        end
      end
    end
  end

  return line_infos
end

function Explorer:line_infos()
  return get_line_infos(self.root, 0)
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
  self.win:render(self.line_infos(self))
end

return Explorer
