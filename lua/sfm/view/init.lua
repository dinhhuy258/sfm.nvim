---@class View
local View = {}

--- View constructor
---@return View
function View.new()
  local self = setmetatable({}, { __index = View })

  return self
end

return View
