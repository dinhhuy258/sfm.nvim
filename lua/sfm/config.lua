local default_mappings = {
  {
    key = "<CR>",
    action = "edit",
  },
  {
    key = "<C-v>",
    action = "vsplit",
  },
  {
    key = "<C-h>",
    action = "split",
  },
  {
    key = "<C-t>",
    action = "tabnew",
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
    key = "]",
    action = "change_root_to_parent",
  },
  {
    key = "<C-]>",
    action = "change_root_to_entry",
  },
  {
    key = "R",
    action = "reload",
  },
  {
    key = "q",
    action = "close",
  },
}

local default_config = {
  view = {
    side = "left",
    width = 30,
    float = {
      enable = false,
      config = {
        relative = "editor",
        border = "rounded",
        width = 30,
        height = 30,
        row = 1,
        col = 1,
      },
    },
  },
  mappings = {
    custom_only = false,
    list = {
      -- user mappings go here
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
    },
  },
}

local function merge_mappings(mappings, user_mappings)
  if user_mappings == nil or type(user_mappings) ~= "table" or vim.tbl_isempty(user_mappings) then
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
      or (type(map.key) == "table" and vim.tbl_isempty(map.key))
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

  if M.opts.mappings.custom_only then
    M.opts.mappings.list = merge_mappings({}, M.opts.mappings.list)
  else
    M.opts.mappings.list = merge_mappings(default_mappings, M.opts.mappings.list)
  end
end

return M
