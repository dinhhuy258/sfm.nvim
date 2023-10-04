local M = {}

--- render indent for the given entry
---@private
---@param entry Entry
---@return table
function M.render_entry_indent(entry)
  local depth = entry.depth - 1
  if entry.nested_parent ~= nil then
    depth = depth + 1
  end

  local indent = string.rep("  ", depth)

  return {
    text = indent .. " ",
    highlight = nil,
  }
end

return M
