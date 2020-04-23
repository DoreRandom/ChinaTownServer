local record = require "base.record"
local logicdispatch = require "base.logicdispatch"
local gamedefines = import(lualib_path("public.gamedefines"))
local CRoom = import(service_path("room/croom"))
local CMemInfo = import(service_path("room/cmeminfo"))

local o = class("CRoomMgr")

function o:Ctor()
    self.m_RoomIndex = 0
    self.m_Id2Room = {}
    self.m_Pid2RoomId = {}
    self.m_IdCaches = {}
end
--分配id
function o:DispatchId()
    if #self.m_IdCaches > 0 then
        return table.remove(self.m_IdCaches)
    end
    self.m_RoomIndex = self.m_RoomIndex + 1
    return self.m_RoomIndex
end
--添加到pid
function o:AddPid2RoomId(pid,roomId)
    if self.m_Pid2RoomId[pid] and self.m_Pid2RoomId[pid] ~= roomId then
        record.warning(string.format("repeat add room %s %s %s",self.m_Pid2RoomId[pid],roomId,pid))
        record.warning(debug.traceback())
    end
    self.m_Pid2RoomId[pid] = roomId
    self:OnEnter(pid,roomId)
end
--移除
function o:RemovePid2RoomId(pid,roomId)
    local id = self.m_Pid2RoomId[pid]
    if id == roomId then
        self.m_Pid2RoomId[pid] = nil
        self:OnLeave(pid,roomId)
    end
end
--移除房间
function o:RemoveRoom(roomId)
    local room = self.m_Id2Room[roomId]
    if room then
        self.m_Id2Room[roomId] = nil
        table.insert(self.m_IdCaches,roomId)
        room:Release()
    end
end
--通过pid获得room
function o:GetRoomByPid(pid)
    local roomId = self.m_Pid2RoomId[pid]
    if roomId then
        return self.m_Id2Room[roomId]
    end
end
--通过pid获得roomid 
function o:GetRoomIdByPid(pid)
    return self.m_Pid2RoomId[pid]
end
--当进入房间时
function o:OnEnter(pid,roomId)
    --聊天
    logicdispatch.Send(".broadcast","Channel","JoinChannel",{
        pid=pid,
        chanType=gamedefines.BROADCAST_TYPE.ROOM_TYPE,
        chanId=roomId })
end

--当离开房间时
function o:OnLeave(pid,roomId)
    --聊天
    logicdispatch.Send(".broadcast","Channel","LeaveChannel",{
        pid=pid,
        chanType=gamedefines.BROADCAST_TYPE.ROOM_TYPE,
        chanId=roomId })
end
--创建房间
function o:CreateRoom(player)
    local pid = player:GetPid()
    if player:HasRoom() then
        g_NotifyMgr:Notify(pid,"你已经有房间了，无法创建",true)
        return 
    end
    local roomId = self:DispatchId()
    local room = CRoom.New(pid,roomId)

    local args = {
        name = player:GetData("name"),
        head = player:GetData("head")
    }

    local member = CMemInfo.New(pid,args)
    room:AddMember(member)
    self.m_Id2Room[roomId] = room
    g_NotifyMgr:Notify(pid,"创建房间成功")
end
--加入房间
function o:JoinRoom(player,roomId)
    local room = self.m_Id2Room[roomId]
    local pid = player:GetPid()
    if not room then
        g_NotifyMgr:Notify(pid,"不存在该房间",true)
        return
    end
    if room:IsInGame() then
        g_NotifyMgr:Notify(pid,"该房间游戏已开始",true)
        return 
    end
    if room:RoomSize() >= room:RoomMaxSize() then
        g_NotifyMgr:Notify(pid,"房间已满",true)
        return 
    end
    if room:CheckInBlack(pid) then
        g_NotifyMgr:Notify(pid,"无法加入该房间(您已在黑名单中)",true)
        return 
    end
    local args = {
        name = player:GetData("name"),
        head = player:GetData("head")
    }
    local member = CMemInfo.New(pid,args)
    room:AddMember(member)

    local name = player:GetData("name")
    self:RoomNotify(room,string.format("欢迎 %s 加入房间",name))

end
--请离房间
function o:KickRoom(player,targetPid)
    local room = player:HasRoom()
    local pid = player:GetPid()
    if pid == targetPid then return end
    if not room then return end
    if not room:IsLeader(pid) then return end
    local mem = room:GetMember(targetPid)
    if not mem then return end
    if room:IsInGame() then return end

    room:Leave(targetPid,true)
    local targetName = mem:GetName()
    g_NotifyMgr:Notify(targetPid,"您已被移除房间",true)
    g_NotifyMgr:Notify(pid,string.format("%s 已被您移除房间",targetName))
end

--离开房间
function o:LeaveRoom(player)
    local room = player:HasRoom()
    local pid = player:GetPid()
    if not room then return end
    if room:IsInGame() then return end
    room:Leave(pid,false)
end

--设置准备
function o:SetReady(player,ready)
    local room = player:HasRoom()
    local pid = player:GetPid()
    if not room then return end
    if room:IsLeader(pid) then return end
    if room:IsInGame() then return end
    local mem = room:GetMember(pid)
    if not mem then return end
    mem:SetReady(ready)
end

--开始游戏
function o:StartGame(player)
    local room = player:HasRoom()
    local pid = player:GetPid()
    if not room:IsLeader(pid) then return end
    if room:IsInGame() then return end
    local roomSize = room:RoomSize() 
    local roomMiniSize = room:RoomMinSize()
    if roomSize < roomMiniSize then
        g_NotifyMgr:Notify(pid,string.format("开始游戏人数不足,至少%d人",roomMiniSize),true)
        return 
    end
    local members = room:GetMembers()
    for _,mem in ipairs(members) do
        if mem:GetPid() ~= pid and not mem:GetReady()  then
            g_NotifyMgr:Notify(pid,"有玩家尚未准备",true)
            return 
        end
    end
    --TODO 开始游戏
    local players = {}
    for _,mem in ipairs(members) do
        local pid = mem:GetPid()
        players[pid] = g_WorldMgr:GetOnlinePlayerByPid(pid)
    end
    
    g_BattleMgr:CreateBattle(players)
end

--对房间内所用人进行通知
function o:RoomNotify(room,msg)
    local members = room:GetMembers()
    for _,mem in ipairs(members) do
        local pid = mem:GetPid()
        g_NotifyMgr:Notify(pid,msg)
    end
end

--Login begin
function o:OnLogin(player,reEnter)
    local pid = player:GetPid()
    local room = self:GetRoomByPid(pid)
    if room then
        room:OnLogin(player,reEnter)
    end
end

function o:OnLogout(player)
    local pid = player:GetPid()
    local room = self:GetRoomByPid(pid)
    if room then
        room:OnLogout(player)
    end
end

--断开连接
--在OnDisconnected后有可能还可以对player的数据进行访问操作，因此在游戏中时不进行移除
function o:OnDisconnected(player)
    local room = player:HasRoom()
    if room then
        room:OnDisconnected(player)
    end
end

--Login end

return o