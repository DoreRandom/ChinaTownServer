local record = require "base.record"
local gamedefines = import(lualib_path("public.gamedefines"))
local o = class("CRoom")

function o:Ctor(pid,roomId)
    self.m_RoomId = roomId
    self.m_Leader = pid
    self.m_Members = {}
    self.m_BlackMap = {}

    self.m_OfflineMap = {}
end

function o:Release()
    
end

function o:RoomId()
    return self.m_RoomId
end

function o:Leader()
    return self.m_Leader
end

function o:IsLeader(pid)
    return self.m_Leader == pid
end

function o:GetMembers()
    return self.m_Members
end

function o:RoomSize()
    return #self.m_Members
end

function o:RoomMaxSize()
    return gamedefines.ROOM_MAX_SIZE
end

function o:RoomMinSize()
    return gamedefines.ROOM_MIN_SIZE
end

--判断是否在游戏中
function o:IsInGame()
    local leader = g_WorldMgr:GetOnlinePlayerByPid(self.m_Leader)
    if not leader then return end
    return leader:IsInGame()
end

--获得pid在room中的角色信息
function o:GetMember(pid)
    for _,mem in ipairs(self.m_Members) do
        if mem:GetPid() == pid then
            return mem
        end
    end
end

--检查是否在黑名单中
function o:CheckInBlack(pid)
    local time = self.m_BlackMap[pid]
    if not time then
        return false
    end
    --已经超时
    if time > g_TimerMgr:GetTime() then
        return true
    else
        self.m_BlackMap[pid] = nil
        return false
    end
end

--添加到黑名单五分钟
function o:AddToBlack(pid)
    self.m_BlackMap[pid] = g_TimerMgr:GetTime() + (5 *60)
end

--添加成员
function o:AddMember(member)
    local pid = member:GetPid()
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    
    g_RoomMgr:AddPid2RoomId(pid,self.m_RoomId)
    table.insert(self.m_Members,member)
    --给该成员发送房间信息
    self:GS2CAddRoom(pid)
    --给其他成员发送该成员信息
    for _,mem in ipairs(self.m_Members) do
        local memPid = mem:GetPid()
        if memPid ~= pid then
            self:GS2CAddRoomMember(member,memPid)
            self:GS2CRefreshRoomStatus(memPid)
        end
    end
end

--结束战斗
function o:EndBattle(pid)
    --如果已经是不在线状态，则踢掉该玩家
    if self.m_OfflineMap[pid] then
        self:Leave(pid,false)
    else
        --否则取消玩家的准备状态
        local mem = self:GetMember(pid)
        if not mem then return end
        mem:SetReady(false) 
    end
end

--离开房间
function o:Leave(pid,isKicked)
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player and not isKicked then
        g_NotifyMgr:Notify(pid,string.format("离开房间 %s",self.m_RoomId))
    end

    local mem = nil
    for i,m in ipairs(self.m_Members) do
        if m:GetPid() == pid then
            mem = m
            table.remove(self.m_Members,i)
            break
        end
    end
    self.m_OfflineMap[pid] = nil
    if mem then
        mem:Release()
    else
        return
    end
    --如果是被踢除的，则五分钟内不允许加入
    if isKicked then
        self:AddToBlack(pid)
    end

    g_RoomMgr:RemovePid2RoomId(pid,self.m_RoomId)
    
    self:OnLeave(pid)
end

--当有人离开时触发
function o:OnLeave(pid)
    if #self.m_Members >= 1 then
        if self.m_Leader == pid then
            local mem = self.m_Members[1]
            self.m_Leader = mem:GetPid()
            mem:SetReady(false) -- 房主取消准备标识
            self.m_BlackMap = {}
            for i,mem in ipairs(self.m_Members) do
                self:GS2CChangeLeader(mem:GetPid())
            end
        end
    else
        self:ReleaseNotify(pid)
        self:ReleaseRoom()
    end

    for _,mem in ipairs(self.m_Members) do
        self:GS2CRefreshRoomStatus(mem:GetPid())
    end
    self:GS2CDelRoom(pid)
end

--通知房间解散
function o:ReleaseNotify(pid)
    g_NotifyMgr:Notify(pid,"房间解散",true)
end

--解散队伍
function o:ReleaseRoom()
    for i,mem in ipairs(self.m_Members) do
        local pid = mem:GetPid()
        mem:Release()
        g_RoomMgr:RemovePid2RoomId(pid,self.m_RoomId)
        self:ReleaseNotify(pid)
    end
    self.m_Members = {}
    g_RoomMgr:RemoveRoom(self.m_RoomId)
end

function o:OnLogin(player,reEnter)
    local pid = player:GetPid()
    if self:GetMember(pid) then
        self:GS2CAddRoom(pid)
        self.m_OfflineMap[pid] = nil --从offline中移除
    else
        record.warning(string.format("room login error %s %s",pid,self.m_RoomId))
        record.warning(table_tostring(g_RoomMgr))
    end    
end

function o:OnDisconnected(player)
    local pid = player:GetPid()
    if self:IsInGame() then
        self.m_OfflineMap[pid] = true
    else
        self:Leave(pid,false)
    end
end

function o:OnLogout(player)
    local pid = player:GetPid()
    self:Leave(pid,false)
end

--打包队伍信息
function o:PackRoomInfo()
    local data = {}
    data["roomId"] = self.m_RoomId
    data["leader"] = self.m_Leader
    local members = {}
    for _,mem in ipairs(self.m_Members) do
        table.insert(members,mem:PackInfo())
    end
    data["members"] = members
    return data
end

--协议
--更新房间的位置和状态
function o:GS2CRefreshRoomStatus(pid)
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        local data = {}
        local status = {}
        for _,mem in ipairs(self.m_Members) do
            table.insert(status,mem:GetPid())
        end
        data["roomStatus"] = status
        player:Send("GS2CRefreshRoomStatus",data)
    end
end

--向新加入的房间的成员发送房间信息
function o:GS2CAddRoom(pid)
    local data = self:PackRoomInfo()
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        player:Send("GS2CAddRoom",data)
    end
end
--离开某房间
function o:GS2CDelRoom(pid)
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        player:Send("GS2CDelRoom",{})
    end
end

--通知玩家们改变房主
function o:GS2CChangeLeader(pid)
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        player:Send("GS2CChangeLeader",{leader = self.m_Leader})
    end
end

--向其他成语发送新加入的成员信息
function o:GS2CAddRoomMember(mem,pid)
    local data = {
        memInfo = mem:PackInfo()
    }
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        player:Send("GS2CAddRoomMember",data)
    end
end

return o