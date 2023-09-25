local log = require "sfm.utils.log"

local M = {}

M.execute_cmd = function(cmd, timeout)
  local job_id = vim.fn.jobstart(cmd)
  exit_code = vim.fn.jobwait({ job_id }, timeout)[1]

  if exit_code == -1 then
    log.warn("Job " .. job_id .. " Timeout")
  elseif exit_code == -2 then
    log.warn("Job " .. job_id .. " Interrupted")
  elseif exit_code == -3 then
    log.warn("Job " .. job_id .. " Invalid")
  end

  return exit_code
end

return M
