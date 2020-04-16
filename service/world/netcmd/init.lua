local record = require "base.record"
local Cmds = {}
Cmds.Other = import(service_path("netcmd.other"))
Cmds.Room = import(service_path("netcmd.room"))
Cmds.Chat = import(service_path("netcmd.chat"))
Cmds.Battle = import(service_path("netcmd.battle"))
Cmds.Player = import(service_path("netcmd.player"))

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