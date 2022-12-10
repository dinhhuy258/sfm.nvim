local M = {}

M.explorer = nil

function M.edit()
  local entry = M.explorer.ctx.current(M.explorer.ctx)
  if not entry.is_dir then
    vim.cmd "wincmd l"
    vim.cmd("keepalt edit " .. entry.path)

    return
  end

  if entry.state == entry.State.Open then
    -- close directory
    entry.close(entry)
    -- re-render
    M.explorer.render(M.explorer)

    return
  end

  -- open directory
  entry.readdir(entry)
  -- re-render
  M.explorer.render(M.explorer)
end

function M.setup(explorer)
  M.explorer = explorer
end

return M
