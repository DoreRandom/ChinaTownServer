local skynet = require "skynet"
local netdispatch = require "base.netdispatch"
local o = class("CConnection")


function o:Ctor(data,pid)
    self.m_Gate = data.gate
    self.m_Fd = data.fd
    self.m_Addr = data.addr

    self.m_Pid = pid
end

function o:GetGate()
    return self.m_Gate
end

function o:GetFd()
    return self.m_Fd
end

function o:GetAddr()
    return self.m_Addr
end

function o:GetPid()
    return self.m_Pid
end

function o:Send(cmd,obj)
    netdispatch.Send(self.m_Gate,self.m_Fd,cmd,obj)
end

function o:SendRaw(msg)
    netdispatch.SendRaw(self.m_Gate,self.m_Fd,msg)
end

function o:Disconnected()
    local player = g_WorldMgr:FindPlayerAnywayByPid(self.m_Pid)
    if player and player:GetFd() == self.m_Fd then
        player:SetConn(nil)
    end
end

--转发到world
function o:Forward()
    local player = g_WorldMgr:FindPlayerAnywayByPid(self.m_Pid)
    if player then
        player:SetConn({gate = self.m_Gate,fd = self.m_Fd})
    end
    skynet.send(self.m_Gate,"lua","forward",self.m_Fd)
end

return o