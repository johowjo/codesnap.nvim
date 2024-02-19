local logger = require("codesnap.utils.logger")
local path_utils = require("codesnap.utils.path")

local client = {
  job_id = 0,
}

function client:connect()
  return vim.fn.jobstart({
    path_utils.back(path_utils.back(debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")))
      .. "/snap-server/target/debug/snap-server",
  }, {
    stderr_buffered = true,
    rpc = true,
    on_stderr = function(_, err)
      vim.fn.jobstop(self.job_id)
      logger.error(err)
    end,
    on_exit = function()
      vim.fn.chanclose(self.job_id)
      self.job_id = 0
    end,
  })
end

function client:init()
  return self.job_id == 0 and client:connect() or self.job_id
end

function client:start()
  self.job_id = client:init()

  if self.job_id == 0 then
    logger.error("cannot start rpc process")
    return
  end

  if self.job_id == -1 then
    logger.error("rpc process is not executable")
    vim.fn.jobstop(self.job_id)
    return
  end

  return self
end

function client:send(event, message)
  vim.fn.rpcnotify(self.job_id, event, message)
end

function client:stop()
  if self.job_id == 0 or self.job_id == -1 then
    return
  end

  vim.fn.jobstop(self.job_id)
end

return client
