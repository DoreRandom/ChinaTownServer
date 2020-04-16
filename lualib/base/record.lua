local skynet = require "skynet"
--用于记录落地日志
local M = {}

function M.info(msg)
    skynet.error(string.format("[%s] %s",MY_SERVICE_NAME,msg))
end
function M.warning(msg)
    skynet.error(string.format("[%s] %s",MY_SERVICE_NAME,msg))
end
function M.error(msg)
    skynet.error(string.format("[%s] %s",MY_SERVICE_NAME,msg))
end

return M