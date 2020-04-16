local skynet = require "skynet"
local logicdispatch = require "base.logicdispatch"
local record = require "base.record"

local Cmds = {}
Cmds.PlayerSend = import(service_path("logiccmd.playersend"))
Cmds.Channel = import(service_path("logiccmd.channel"))

local M = {}
function M.Invoke(mod,cmd,tag,data)
    local m = Cmds[mod]
    if m then
        local f = m[cmd]
        if f then
            f(tag,data)
        else
            record.error(string.format("Invoke fail %s %s %s", MY_SERVICE_NAME, mod, cmd))
        end
    else
        record.error(string.format("Invoke fail %s %s %s", MY_SERVICE_NAME, mod, cmd))
    end
end

return M