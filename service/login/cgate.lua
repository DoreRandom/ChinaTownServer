local skynet = require "skynet"

local CGate = class("CGate")

function CGate:Ctor(port)
    local addr = skynet.newservice("gate")
    skynet.send(addr,"lua","open",{
        port = port,
        maxclient = 4096,
        nodelay = true
    })
    self.m_Addr = addr
    self.m_Port = port
    self.m_Connections = {}
end

function CGate:Release()
    
end

function CGate:GetConnection(fd)
    return self.m_Connections[fd]
end

function CGate:AddConnection(conn)
    self.m_Connections[conn:GetFd()] = conn
    g_GateMgr:SetConnection(conn:GetFd(),conn)

    skynet.send(self.m_Addr,"lua","forward",conn:GetFd())
end

function CGate:DelConnection(fd)
    local conn = self.m_Connections[fd]
    if conn then
        conn:Release()
        self.m_Connections[fd] = nil
        g_GateMgr:SetConnection(fd,nil)
    end
end

return CGate