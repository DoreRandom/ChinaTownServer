local skynet = require "skynet"
local logicdispatch = require "base.logicdispatch"
local record = require "base.record"
local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))

local CConnection = import(service_path("cconnection"))
local CPlayer = import(service_path("cplayer"))

local o = class("CWorldMgr")

function o:Ctor()
    self.m_LoginPlayers = {} --正在进行登录的玩家 k:pid v:cplayer
    self.m_OnlinePlayers = {} --已经登陆的玩家 k:pid v:cplayer
    self.m_Connections = {}
end

function o:Release()
   
end

function o:GetConnection(fd)
    return self.m_Connections[fd]
end

--Login begin 
function o:Login(data)
    local playerData = data.player
    local connData = data.conn

    local pid = playerData.pid
    if self.m_LoginPlayers[pid] then

        logicdispatch.Send(".login","Login","LoginPlayerResponse",{pid = pid,fd = connData.fd,playerToken = playerData.playerToken,retCode = gamedefines.ERROR_CODE.InLogin})
        return
    end
    local player = self.m_OnlinePlayers[pid]
    if player then --已经登陆
        local oldConn = player:GetConn()
        local fd = connData.fd

        local conn = CConnection.New(connData,pid)
        self.m_Connections[fd] = conn
        conn:Forward()
        player:InitClientData(connData,playerData)

        if oldConn and oldConn:GetFd() ~= fd then
            oldConn:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.ReEnter,retMsg = connData.addr})
            self:KickConnection(oldConn:GetFd())
        end
    
        player:OnLogin(true)

        logicdispatch.Send(".login","Login","LoginPlayerResponse",{
            pid=pid,
            fd=fd,
            playerToken=player:GetPlayerToken(),
            retCode=gamedefines.ERROR_CODE.Ok
        })
    else
        player = self:CreatePlayer(connData,playerData)
        player:InitClientData(connData,playerData)
        self.m_LoginPlayers[pid] = player

        local conn = CConnection.New(connData,pid)
        self.m_Connections[connData.fd] = conn

        local dbop = {
            mod = "Player",
            cmd = "GetPlayerByPid",
            cond = {pid = pid}
        }
        gamedb.LoadDb(dbop,function (tag,res)
            self:_LoginPlayer(tag,res,pid)
        end)
    end
end

--登陆玩家内部
function o:_LoginPlayer(tag,res,pid)
    local player = self.m_LoginPlayers[pid] --查看是否还在登陆
    if not player then
        return 
    end
    local fd = player:GetFd()
    if #res == 0 then
        self.m_LoginPlayers[pid] = nil
        self.m_Connections[fd] = nil
        logicdispatch.Send(".login","Login","LoginPlayerResponse",{
            pid=pid,
            fd=fd,
            retCode=gamedefines.ERROR_CODE.NoExistPlayer
        })
        return
    end
    self.m_LoginPlayers[pid] = nil
    self.m_OnlinePlayers[pid] = player

    local ins = res[1]
    player:Load(ins)
    player:LoadSucess()

    local conn = self.m_Connections[fd]
    conn:Forward()

    player:OnLogin()

    logicdispatch.Send(".login","Login","LoginPlayerResponse",{
        pid=pid,
        fd=fd,
        playerToken=player:GetPlayerToken(),
        retCode=gamedefines.ERROR_CODE.Ok
    })
end

--login end

--connection begin
function o:DelConnection(fd,reason)
    local conn = self.m_Connections[fd]
    if conn then
        local pid = conn:GetPid()
        self.m_Connections[fd] = nil
        conn:Disconnected()
        record.info(string.format("cworldmgr:DelConnection pid %s reason %s",pid,reason))
    end
end

function o:KickConnection(fd)
    local conn = self.m_Connections[fd]
    if conn then
        skynet.send(conn:GetGate(),"lua","kick",fd)
        self:DelConnection(fd,"服务器主动关闭")
    end
end

--pid登出
function o:Logout(pid)
    local player = self.m_LoginPlayers[pid]
    if player then
        local playerToken = player:GetPlayerToken()
        self.m_LoginPlayers[pid] = nil
        player:Disconnect()
        player:Release()
        self:LogoutNotifyGate(pid,playerToken)
        return 
    end
    player = self.m_OnlinePlayers[pid]
    if player then
        local playerToken = player:GetPlayerToken()
        self.m_OnlinePlayers[pid] = nil
        player:Disconnect()
        player:OnLogout()
        player:CheckSave()
        player:Release()
        self:LogoutNotifyGate(pid,playerToken)
    end
end

function o:LogoutNotifyGate(pid,playerToken)
    logicdispatch.Send(".login","Login","OnLogout",{pid=pid,playerToken = playerToken})
end

--connection end

--通过pid找player 包括login online
function o:FindPlayerAnywayByPid(pid)
    local player = self.m_LoginPlayers[pid] or self.m_OnlinePlayers[pid]
    return player
end
--获得在线玩家
function o:GetOnlinePlayerByPid(pid)
    return self.m_OnlinePlayers[pid]
end
--通过fd获得在线玩家
function o:GetOnlinePlayerByFd(fd)
    local conn = self.m_Connections[fd]
    if conn then
        return self.m_OnlinePlayers[conn:GetPid()]
    end
end

function o:CreatePlayer(connData,playerData)
    return CPlayer.New(connData,playerData)
end

return o