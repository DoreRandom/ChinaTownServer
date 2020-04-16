local skynet = require "skynet"
local logicdispatch = require "base.logicdispatch"
local record = require "base.record"

local REQUEST_TYPE = logicdispatch.REQUEST_TYPE
local Cmds = {}
Cmds.User = import(service_path("logiccmd.userdao"))
Cmds.Player = import(service_path("logiccmd.playerdao"))

local M = {}

function M.Invoke(mod,cmd,tag,dbop)
    local m = Cmds[dbop.mod]
    if m then
        local f = m[dbop.cmd]
        if f then
            local ret = f(dbop.cond,dbop.data)
            if ret.err then
                record.error(string.format("Warning gamedb.logiccmd.init Invoke op %s\n ret %s %s",table_tostring(dbop),ret.errno,ret.err))
            end
            if tag.type == REQUEST_TYPE then
                logicdispatch.Response(tag.source,tag.session,ret)
            end
        else
            record.error(string.format("Invoke fail %s %s %s", MY_SERVICE_NAME, dbop.mod, dbop.cmd))
        end
    else
        record.error(string.format("Invoke fail %s %s %s", MY_SERVICE_NAME, dbop.mod, dbop.cmd))
    end
end

return M