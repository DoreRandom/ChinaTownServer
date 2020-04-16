local o = class("CMemInfo")

function o:Ctor(pid,args)
    self.m_Pid = pid
    self:Init(args)
end

function o:Release()
    
end

function o:Init(args)
    self.m_Name = args.name
    self.m_Head = args.head
    self.m_Ready = false
end

--更新属性
function o:Update(args)
    self.m_Name = args.name or self.m_Name
    self.m_Head = args.head or self.m_Head
    if args.ready ~= nil then
        self.m_Ready = args.ready
    end
    self:StatusChange()
end
--状态变化
function o:StatusChange()
    self:SendAll("GS2CRefreshMemberInfo",{memInfo = self:PackInfo()})
end

function o:GetPid()
    return self.m_Pid
end

function o:GetName()
    return self.m_Name
end

function o:GetReady()
    return self.m_Ready    
end

function o:SetReady(ready)
    if self.m_Ready ~= ready then
        self:Update({ready = ready})  
    end
end

function o:PackInfo()
    local data = {
        pid = self.m_Pid,
        name = self.m_Name,
        head = self.m_Head,
        ready = self.m_Ready
    }
    return data
end

--发送
function o:SendAll(message,data)
    local player = g_WorldMgr:GetOnlinePlayerByPid(self.m_Pid)
    local room = player:HasRoom()
    if not room then
        return 
    end
    local members = room:GetMembers()
    for _,mem in pairs(members) do
        local player = g_WorldMgr:GetOnlinePlayerByPid(mem:GetPid())
        if player then
            player:Send(message,data)
        end
    end
end

return o