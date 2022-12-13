local M = {}

local function get_color_from_hl(hl_name, fallback)
  local id = vim.api.nvim_get_hl_id_by_name(hl_name)
  if not id then
    return fallback
  end

  local foreground = vim.fn.synIDattr(vim.fn.synIDtrans(id), "fg")
  if not foreground or foreground == "" then
    return fallback
  end

  return foreground
end

local function get_colors()
  return {
    red = vim.g.terminal_color_1 or get_color_from_hl("Keyword", "Red"),
    green = vim.g.terminal_color_2 or get_color_from_hl("Character", "Green"),
    yellow = vim.g.terminal_color_3 or get_color_from_hl("PreProc", "Yellow"),
    blue = vim.g.terminal_color_4 or get_color_from_hl("Include", "Blue"),
    purple = vim.g.terminal_color_5 or get_color_from_hl("Define", "Purple"),
    cyan = vim.g.terminal_color_6 or get_color_from_hl("Conditional", "Cyan"),
    dark_red = vim.g.terminal_color_9 or get_color_from_hl("Keyword", "DarkRed"),
    orange = vim.g.terminal_color_11 or get_color_from_hl("Number", "Orange"),
  }
end

local function get_hl_groups()
  local colors = get_colors()

  return {
    SFMIndicator = { fg = "#8094b4" },
    SFMSelection = { fg = colors.blue },
    SFMSymlink = { gui = "bold", fg = colors.cyan },
    SFMFolderIcon = { fg = "#8094b4" },
    SFMRootFolder = { fg = colors.purple },
    SFMExecFile = { gui = "bold", fg = colors.green },
    SFMSpecialFile = { gui = "bold,underline", fg = colors.yellow },
    SFMImageFile = { gui = "bold", fg = colors.purple },
    SFMOpenedFile = { gui = "bold", fg = colors.green },
  }
end

local function get_links()
  return {
    SFMFolderName = "Directory",
    SFMFolderIcon = "Directory",
    SFMDefaultFileIcon = "Normal",
    SFMFileName = "Normal",
  }
end

function M.setup()
  local higlight_groups = get_hl_groups()
  for k, d in pairs(higlight_groups) do
    local gui = d.gui and " gui=" .. d.gui or ""
    local fg = d.fg and " guifg=" .. d.fg or ""
    local bg = d.bg and " guibg=" .. d.bg or ""
    vim.api.nvim_command("hi def " .. k .. gui .. fg .. bg)
  end

  local links = get_links()
  for k, d in pairs(links) do
    vim.api.nvim_command("hi def link " .. k .. " " .. d)
  end
end

return M
