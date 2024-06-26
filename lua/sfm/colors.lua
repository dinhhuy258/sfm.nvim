local M = {}

local function create_highlight_group(hl_group_name, link_to_if_exists, fg, bg, gui)
  local success, hl_group = pcall(vim.api.nvim_get_hl_by_name, hl_group_name, true)
  if not success or not hl_group.foreground or not hl_group.background then
    for _, link_to in ipairs(link_to_if_exists) do
      success, hl_group = pcall(vim.api.nvim_get_hl_by_name, link_to, true)
      if success then
        local new_group_has_settings = bg or fg or gui
        local link_to_has_settings = hl_group.foreground or hl_group.background
        if link_to_has_settings or not new_group_has_settings then
          vim.cmd("highlight default link " .. hl_group_name .. " " .. link_to)

          return
        end
      end
    end

    local cmd = "highlight default " .. hl_group_name
    if bg then
      cmd = cmd .. " guibg=#" .. bg
    end
    if fg then
      cmd = cmd .. " guifg=#" .. fg
    else
      cmd = cmd .. " guifg=NONE"
    end
    if gui then
      cmd = cmd .. " gui=" .. gui
    end
    vim.cmd(cmd)
  end
end

function M.setup()
  create_highlight_group("SFMRootFolder", {}, nil, nil, "bold,italic")
  create_highlight_group("SFMSymlink", { "Underlined" }, nil, nil, nil)
  create_highlight_group("SFMFileIndicator", {}, "3b4261", nil, nil)
  create_highlight_group("SFMFolderIndicator", {}, "3b4261", nil, nil)
  create_highlight_group("SFMSelection", {}, nil, nil, nil)

  create_highlight_group("SFMFolderName", { "Directory" }, nil, nil, nil)
  create_highlight_group("SFMFolderIcon", { "Directory" }, nil, nil, nil)
  create_highlight_group("SFMDefaultFileIcon", { "Normal" }, nil, nil, nil)
  create_highlight_group("SFMFileName", { "Normal" }, nil, nil, nil)

  create_highlight_group("SFMNormal", { "Normal" }, nil, nil, nil)
  create_highlight_group("SFMNormalNC", { "NormalNC" }, nil, nil, nil)
  create_highlight_group("SFMEndOfBuffer", { "EndOfBuffer" }, nil, nil, nil)
  create_highlight_group("SFMCursorLine", { "CursorLine" }, nil, nil, nil)
  create_highlight_group("SFMCursorLineNr", { "CursorLineNr" }, nil, nil, nil)
  create_highlight_group("SFMLineNr", { "LineNr" }, nil, nil, nil)
  create_highlight_group("SFMWinSeparator", { "WinSeparator" }, nil, nil, nil)
  create_highlight_group("SFMStatusLine", { "StatusLine" }, nil, nil, nil)
  create_highlight_group("SFMStatuslineNC", { "StatuslineNC" }, nil, nil, nil)
  create_highlight_group("SFMSignColumn", { "SignColumn" }, nil, nil, nil)
end

return M
