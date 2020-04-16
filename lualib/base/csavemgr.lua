local CSave = class("CSave")

--[[
    构造函数
    id 从savemgr那里分配来的id
    func 用于保存的函数
    second 备份时间，以秒计
]]
function CSave:Ctor(id,second,func,mgr)
    self.m_Timer = g_TimerMgr:NewTimer()
    self.m_Id = id
    self.m_SaveTime = math.min(20*60, math.max(60, second or 60))
    self.m_SaveFunc = func
    self.m_Mgr = mgr
end

function CSave:Release()
    self.m_Mgr:DelSave(self.m_Id)
    self.m_Timer:Release()
end

function CSave:GetSaveID()
    return self.m_Id
end
--[[
    更新保存定时器
]]
function CSave:UpdateSaveTimer()
    self.m_Timer:Cancel("CheckSave")
    self.m_Timer:DelayCall("CheckSave",self.m_SaveTime,function ()
        self.m_Mgr:_CheckSave(self.m_Id)
    end)
end
--[[
    调用保存函数
]]
function CSave:CheckSave()
    self.m_SaveFunc()
    self:UpdateSaveTimer()
end

local CSaveMgr = class("CSaveMgr")

function CSaveMgr:Ctor()
   self.m_SaveMap = {}
   self.m_SaveIndex = 0
end

--分配一个id
function CSaveMgr:DispatchId()
    self.m_SaveIndex = self.m_SaveIndex + 1
    return self.m_SaveIndex
end
--新建一个save对象
function CSaveMgr:NewSave(func,second)
    local id = self:DispatchId()
    local obj = CSave.New(id,second,func,self)
    obj:UpdateSaveTimer()
    self.m_SaveMap[id] = obj
    return obj
end
--检测saveobj
function CSaveMgr:_CheckSave(id)
    local save = self.m_SaveMap[id]
    if save then
        save:CheckSave()
    end
end
--删除saveobj
function CSaveMgr:DelSave(id)
    self.m_SaveMap[id] = nil
end


return CSaveMgr