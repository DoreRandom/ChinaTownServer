local skynet = require "skynet"
local CGateMgr = class("CGateMgr")

function CGateMgr:Ctor()
    self.m_Gates = {}
    self.m_Connections = {}
end

function CGateMgr:Release()
    
end

--初始化
function CGateMgr:Init()
    
end
--添加一个gate
function CGateMgr:AddGate(gate)
    self.m_Gates[gate.m_Addr] = gate
end
--获得一个gate
function CGateMgr:GetGate(addr)
    return self.m_Gates[addr]
end
--根据fd获得一个conn
function CGateMgr:GetConnection(fd)
    return self.m_Connections[fd]
end
--根据fd设置conn
function CGateMgr:SetConnection(fd,conn)
    self.m_Connections[fd] = conn
end
--根据fd踢掉一个连接
function CGateMgr:KickConnection(fd)
    local conn = self:GetConnection(fd)
    if conn then
        skynet.send(conn:GetGate(),"lua","kick",conn:GetFd())
        local gate = self:GetGate(conn:GetGate())
        if gate and gate:GetConnection(fd) then
            gate:DelConnection(fd)
        end
    end
end

function CGateMgr:OnLogout(data)
    g_TokenMgr:ClearByPlayerToken(data.pid,data.playerToken)
end

return CGateMgr