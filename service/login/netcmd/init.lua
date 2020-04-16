local record = require "base.record"
local Cmds = {}
Cmds.Verify = import(service_path("netcmd.verify"))
Cmds.Login = import(service_path("netcmd.login"))

local M = {}
function M.Invoke(mod,cmd,fd,data,seq)
    local m = Cmds[mod]
    if m then
        local f = m[cmd]
        if f then
            local conn = g_GateMgr:GetConnection(fd)
            if conn then
                return f(conn,data,seq)
            end
        else
            record.info(string.format("Invoke failed f %s %s",mod,cmd))
        end
    else
        record.info(string.format("Invoke failed m %s %s",mod,cmd))
    end
end

return M