local record = require "base.record"
local Cmds = {}

local M = {}
function M.Invoke(mod,cmd,fd,data,seq)
    local m = Cmds[mod]
    if m then
        local f = m[cmd]
        if f then
            local player = g_WorldMgr:GetOnlinePlayerByFd(fd)
            if player then
                return f(player,data)
            end
        else
            record.info(string.format("Invoke failed f %s %s",mod,cmd))
        end
    else
        record.info(string.format("Invoke failed m %s %s",mod,cmd))
    end
end
return M