local playersend = require "base.playersend"
local gamedb = import(lualib_path("public.gamedb"))

local CData = require("base.cdata")
local o = class("CPlayer",CData)

function o:Ctor()
    CData.Ctor(self)
    self.m_Timer = g_TimerMgr:NewTimer()
    self.m_Bid = nil
end

function o:Release()
    CData.Release(self)
end

function o:SetConn(t)
    if t then
        self.m_DisconnectedTime = nil
        self.m_Gate = t.gate
        self.m_Fd = t.fd
    else
        self.m_DisconnectedTime = g_TimerMgr:GetTime()
        self:OnDisconnected()
        self.m_Gate = nil
        self.m_Fd = nil
    end
    --TODO 连接发生变化
    g_MailMgr:OnConnectionChange(self.m_Pid,t)
end
--初始化登陆数据
function o:InitClientData(connData,playerData)
    self.m_Fd = connData.fd
    self.m_Addr = connData.addr
    self.m_Account = playerData.account
    self.m_AccountToken = playerData.accountToken
    self.m_PlayerToken = playerData.playerToken
    self.m_Pid = playerData.pid
end

function o:GetFd()
    return self.m_Fd
end

function o:GetConn()
    return g_WorldMgr:GetConnection(self.m_Fd)
end

function o:GetPlayerToken()
    return self.m_PlayerToken
end

function o:GetPid()
    return self.m_Pid
end

function o:IsInGame()
    return self.m_Bid ~= nil
end

function o:SetBid(bid)
    self.m_Bid =  bid
end

function o:GetBid()
    return self.m_Bid
end

function o:GetBattle()
    return g_BattleMgr:GetBattle(self.m_Bid)
end

--结束战斗
function o:EndBattle()
    --离开战斗状态
    self:SetBid(nil)

    local room = self:HasRoom()
    if room then
        room:EndBattle(self.m_Pid)
    end
end

--当被断开连接时触发
function o:OnDisconnected()
    g_RoomMgr:OnDisconnected(self)
    g_BattleMgr:OnDisconnected(self)
end

--主动断开连接
function o:Disconnect()
    local conn = self:GetConn()
    if conn then
        g_WorldMgr:KickConnection(self.m_Fd)
    end
end

--data begin 
function o:GetStatus(m)
    if not m then
        m = self.m_Data
    end
    local data = {}
    for k,_ in pairs(m) do
        data[k] = self.m_Data[k]
    end
    return data
end

function o:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _, v in ipairs(l) do
        m[v] = true
    end
    local status = self:GetStatus(m)
    status.pid = self.m_Pid
    self:Send("GS2CRefreshPlayer",{
        status = status
    })
end

function o:Load(m)
    self:SetData("name",m.name)
    self:SetData("head",m.head)
    self:SetData("score",m.score)
    self:UnDirty()
end

function o:Save()
    local data = {}
    data.score = self:GetData("score")
    return data
end

--配置保存函数
function o:ConfigSaveFunc()
    local pid = self.m_Pid
    self:SetSaveFunc(function ()
        local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
        if player then
            player:SaveDb()
        end
    end)
end

--保存数据到db
function o:SaveDb(force)
    if self:IsDirty() or force then
        local data = self:Save()
        local dbop = {
            mod = "Player",
            cmd = "SavePlayer",
            cond = {pid = self.m_Pid},
            data = data
        }
        gamedb.SaveDb(dbop)
        self:UnDirty()
    end
end

--data end
-- login out
function o:OnLogin(reEnter)
    self.m_HeartBeatTime = g_TimerMgr:GetTime()

    self:_OnLogin(reEnter)

    self:Schedule()
end

--模块登录
function o:_OnLogin(reEnter)
    self:GS2CLoginPlayer()
    g_RoomMgr:OnLogin(self,reEnter)
    g_BattleMgr:OnLogin(self,reEnter)
end

function o:OnLogout()
    g_RoomMgr:OnLogout(self)
    g_BattleMgr:OnLogout(self)
end

-- login out

--常驻的定时器调度 begin
function o:Schedule()
    local pid = self.m_Pid
    --心跳包检测
    local f1 
    f1 = function ()
        local player = g_WorldMgr:FindPlayerAnywayByPid(pid)
        if player then
            player:DelTimer("_CheckHeartBeat")
            player:AddTimer("_CheckHeartBeat",10,f1)
            player:_CheckHeartBeat()
        end
    end
    f1()
end

function o:ClientHeartBeat()
    self.m_HeartBeatTime = g_TimerMgr:GetTime()
    self:Send("GS2CHeartBeat", {time = math.floor(self.m_HeartBeatTime)})
end

function o:_CheckHeartBeat()
    assert(not is_release(self))
    local now = g_TimerMgr:GetTime()
    local maxTime = 180
    if now - self.m_HeartBeatTime > maxTime then
        if not self:IsInGame() then --TODO 这里如果在游戏中，则暂时不会释放 而是调用强制退出游戏
            g_WorldMgr:Logout(self.m_Pid)
        else
            g_BattleMgr:ForceLeave(self)
        end
    end
end

--常驻的定时器调度 end

--获得玩家信息
function o:PlayerInfo()
    local data = {
        pid = self.m_Pid,
        name = self:GetData("name"),
        head = self:GetData("head"),
        score = self:GetData("score")
    }
    return data
end

--对战信息
function o:BattleInfo()
    local data = {
        pid = self.m_Pid,
        name = self:GetData("name"),
        head = self:GetData("head")
    }
    return data
end

--net
function o:C2GSBackToTeam()
    self:_OnLogin(true)
end

function o:C2GSBackToHall()
    g_RoomMgr:LeaveRoom(self)
    self:_OnLogin(true)
end

--玩家登陆信息
function o:GS2CLoginPlayer()
    local data = {
        account = self.m_Account,
        player = self:PlayerInfo(),
        playerToken = self.m_PlayerToken
    }
    self:Send("GS2CLoginPlayer",data)
end

function o:Send(cmd,obj)
    playersend.Send(self.m_Pid,cmd,obj)
end

function o:SendRaw(msg)
    playersend.SendRaw(self.m_Pid,msg)
end


--room start
function o:RoomId()
    return g_RoomMgr:GetRoomIdByPid(self.m_Pid)
end
--是否在房间中，是则返回房间obj
function o:HasRoom()
    return g_RoomMgr:GetRoomByPid(self.m_Pid)
end
--获得房间成员
--room end
return o