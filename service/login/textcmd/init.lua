local logicdispatch = require "base.logicdispatch"
local CConnection = import(service_path("cconnection"))
local Cmds = {}
--当新连接接入时的处理
function Cmds.open(source,fd,addr)
    local gate = g_GateMgr:GetGate(source)
    if gate then
        if gate:GetConnection(fd) then
            return
        end
        local conn = CConnection.New(source,fd,addr)
        gate:AddConnection(conn)
    end
end
--当有连接关闭时的处理
function Cmds.close(source,fd)
    local gate = g_GateMgr:GetGate(source)
    if gate then
        if gate:GetConnection(fd) then
            gate:DelConnection(fd)
        end
    end
    --TODO 通知其他业务服务器连接已关闭
    logicdispatch.Send(".world", "Login", "DelConnection", {fd = fd, reason = "连接被关闭"})
end

local M = {}

function M.Invoke(cmd,...)
    local f = Cmds[cmd]
    return f(...)
end

return M