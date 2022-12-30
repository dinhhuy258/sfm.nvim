local M = {}

--- render selection for the given entry
---@private
---@param entry Entry
---@param ctx Context
---@param cfg Config
---@return table
function M.render_entry(entry, ctx, cfg)
  local icons = cfg.opts.renderer.icons

  if ctx:is_selected(entry) then
    return {
      text = icons.selection,
      highlight = "SFMSelection",
    }
  end

  return {
    text = nil,
    highlight = nil,
  }
end

return M
