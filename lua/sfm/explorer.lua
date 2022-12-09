local icons = require "sfm.icons"
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

  for _, e in ipairs(current_entry.entries) do
    table.insert(line_infos, {
      line = indent .. icons.get_indicator(e) .. " " .. icons.get_icon(e) .. " " .. e.name,
    })
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
