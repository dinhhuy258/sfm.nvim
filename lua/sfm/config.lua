local default_mappings = {
  {
    key = "<CR>",
    action = "edit",
  },
  {
    key = "<S-TAB>",
    action = "close_entry",
  },
  {
    key = "J",
    action = "last_sibling",
  },
  {
    key = "K",
    action = "first_sibling",
  },
  {
    key = "P",
    action = "parent_entry",
  },
  {
    key = "R",
    action = "reload",
  },
  {
    key = "n",
    action = "create",
  },
  {
    key = "dd",
    action = "delete",
  },
  {
    key = "ds",
    action = "delete_selections",
  },
  {
    key = "p",
    action = "copy_selections",
  },
  {
    key = "x",
    action = "move_selections",
  },
  {
    key = "r",
    action = "rename",
  },

  {
    key = "q",
    action = "close",
  },
  {
    key = "<SPACE>",
    action = "toggle_selection",
  },
  {
    key = "<C-SPACE>",
    action = "clear_selections",
  },
}

local default_config = {
  sort_by = nil,
  view = {
    side = "left",
    width = 30,
    mappings = {
      custom_only = false,
      list = {
        -- user mappings go here
      },
    },
  },
  renderer = {
    icons = {
      file = {
        default = "",
        symlink = "",
      },
      folder = {
        default = "",
        open = "",
        symlink = "",
        symlink_open = "",
      },
      indicator = {
        folder_closed = "",
        folder_open = "",
        file = " ",
      },
      selection = "",
    },
  },
}

local function merge_mappings(mappings, user_mappings)
  if user_mappings == nil or type(user_mappings) ~= "table" or table.count(user_mappings) == 0 then
    return mappings
  end

  -- local user_keys = {}
  local removed_keys = {}

  -- remove default mappings if action is a empty string
  for _, map in pairs(user_mappings) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        if map.action == nil or map.action == "" then
          table.insert(removed_keys, key)
        end
      end
    else
      if map.action == nil or map.action == "" then
        table.insert(removed_keys, map.key)
      end
    end
  end

  local default_map = vim.tbl_filter(function(map)
    if type(map.key) == "table" then
      local filtered_keys = {}
      for _, key in pairs(map.key) do
        if not vim.tbl_contains(removed_keys, key) then
          table.insert(filtered_keys, key)
        end
      end
      map.key = filtered_keys

      return not vim.tbl_isempty(map.key)
    else
      return not vim.tbl_contains(removed_keys, map.key)
    end
  end, mappings)

  local user_map = vim.tbl_filter(function(map)
    return not (
      map.action == nil
      or map.action == ""
      or map.key == nil
      or map.key == ""
      or (type(map.key) == "table" and table.count(map.key) == 0)
    )
  end, user_mappings)

  return vim.fn.extend(default_map, user_map)
end

local M = {
  opts = {},
}

---@param opts table
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", default_config, opts or {})

  if M.opts.view.mappings.custom_only then
    M.opts.view.mappings.list = merge_mappings({}, M.opts.view.mappings.list)
  else
    M.opts.view.mappings.list = merge_mappings(default_mappings, M.opts.view.mappings.list)
  end
end

return M
