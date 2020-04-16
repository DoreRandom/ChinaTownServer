local logicdispatch = require "base.logicdispatch"

local CBattle = class("CBattle")
function CBattle:Ctor(bid,remote)
    self.m_Bid = bid
    self.m_RemoteAddr = remote
    self.m_Players = {}
end

function CBattle:Release()
    
end

function CBattle:GetBid()
    return self.m_Bid
end
--转发
function CBattle:Forward(cmd,data)
    logicdispatch.Send(self.m_RemoteAddr,"Battle",cmd,data)
end

--获得玩家
function CBattle:GetPlayers()
    return self.m_Players
end

--玩家进入
function CBattle:EnterPlayer(pid)
    self.m_Players[pid] = true
end

--玩家离开
function CBattle:LeavePlayer(pid)
    self.m_Players[pid] = nil
end

local CBattleMgr = class("CBattleMgr")

function CBattleMgr:Ctor(remotes)
    self.m_DispatchIndex = 0
    self.m_Battles = {}
    self.m_SelectHash = 0
    self.m_Remotes = remotes
end

function CBattleMgr:Release()
    
end
--分配id
function CBattleMgr:DispatchId()
    self.m_DispatchIndex = self.m_DispatchIndex + 1
    if self.m_DispatchIndex > 10000000 then
        self.m_DispatchIndex = 1
    end
    return self.m_DispatchIndex
end
--选择游戏服务
function CBattleMgr:SelectRemote()
    if self.m_SelectHash >= #self.m_Remotes then
        self.m_SelectHash = 1
    else
        self.m_SelectHash = self.m_SelectHash + 1
    end
    return self.m_Remotes[self.m_SelectHash]
end
--创建战斗
function CBattleMgr:CreateBattle(players)
    local bid = self:DispatchId()
    local remote = self:SelectRemote()
    local battle = CBattle.New(bid,remote)
    self.m_Battles[bid] = battle

    local data = {}
    data.bid = bid
    local infos = {}
    for pid,player in pairs(players) do
        --给player设置正在游戏状态
        player:SetBid(bid)
        --打包玩家对战需要的信息
        table.insert(infos,player:BattleInfo())
        battle:EnterPlayer(pid)
    end
    data.playerInfos = infos

    battle:Forward("CreateBattle",data)
    return battle
end
--获得战斗
function CBattleMgr:GetBattle(bid)
    return self.m_Battles[bid]
end
--断线回调
function CBattleMgr:OnDisconnected(player)
    local bid = player:GetBid()
    local pid = player:GetPid()
    local battle = self.m_Battles[bid]
    if battle then
        battle:Forward("OnDisconnected",{bid = bid,pid = pid})
    end
end
--登入回调
function CBattleMgr:OnLogin(player,reEnter)
    local bid = player:GetBid()
    local pid = player:GetPid()
    local battle = self.m_Battles[bid]
    if battle then
        battle:Forward("OnLogin",{bid = bid,pid = pid})
    end
end
--登入回调
function CBattleMgr:OnLogout(player)
    
end
--离开回调
function CBattleMgr:ForceLeave(player)
    local bid = player:GetBid()
    local pid = player:GetPid()
    local battle = self.m_Battles[bid]
    if battle then
        battle:Forward("ForceLeave",{bid = bid,pid = pid})
    end
end

--from logic
function CBattleMgr:EndBattle(data)
    local bid = data.bid 
    local battle = self.m_Battles[bid]

    if not battle then
        return
    end

    --积分机制
    local rankInfos = data.rankInfos
    for _,rankInfo in ipairs(rankInfos) do
        local pid = rankInfo.pid
        local score = rankInfo.score
        local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
        if player then 
            local allScore = player:GetData("score")
            player:SetData("score",allScore + score)
        end
    end

    --所有玩家离开战斗
    local players = battle:GetPlayers()
    for pid,_ in pairs(players) do
        local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
        if player then
            player:EndBattle()
        end
    end

    battle:Release()
    self.m_Battles[bid] = nil
end

return CBattleMgr