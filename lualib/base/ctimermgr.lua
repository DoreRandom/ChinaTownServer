local skynet = require "skynet"
local ltimer = require "ltimer"

local CTimer = class("CTimer")
function CTimer:Ctor(mgr)
    self.m_Mgr = mgr
    self.m_Name2Id = {}
end

function CTimer:Release()
    for k,v in ipairs(self.m_Name2Id) do
        self.m_Mgr:Cancel(v)
    end
    self.m_Name2Id = {}
    self.m_Mgr = nil
end
--对外提供一个供name使用的接口
function CTimer:DelayCall(name,second,func)
    local oldId = self.m_Name2Id[name]
    if oldId then
        self.m_Mgr:Cancel(oldId)
    end
    local f = function ()
        local id = self.m_Name2Id[name]
        if not id then
            return
        end
        self.m_Name2Id[name] = nil
        func()
    end
    local newId = self.m_Mgr:DelayCall(second,f)
    self.m_Name2Id[name] = newId
end
--对外提供一个供name使用的接口
function CTimer:Cancel(name)
    local oldId = self.m_Name2Id[name]
    if oldId then
        self.m_Mgr:Cancel(oldId)
    end
end

local MAX_LIMIT = 2^32
local mfloor = math.floor

local CTimerMgr = class("CTimerMgr")
function CTimerMgr:Ctor()
    self.m_CbMap = {} --用于存储添加的timer
    self.m_CbIndex = 0 -- 用于分配cb的id
    self.m_CbWatingProcess = {} --等待处理的回调id
    self.m_Execute = false --是否正在处理回调

    self.m_StartTime = skynet.starttime()
    self:RefreshTime()
    self.m_LTimer = ltimer.ltimer_create(self.m_NowTime)
    self:Init()
end

--更新当前时间
function CTimerMgr:RefreshTime()
    self.m_Now = skynet.now() 
    self.m_NowTime = self.m_StartTime * 100 + self.m_Now --s 0.01s
end
--分配一个id
function CTimerMgr:DispatchId()
    self.m_CbIndex = self.m_CbIndex + 1
    return self.m_CbIndex
end
--延迟执行 delay的单位为秒
function CTimerMgr:DelayCall(delay,func)
    delay = mfloor(delay * 100)
    assert(delay>0,string.format("timermgr.DelayCall delay time is small %s",delay))
    assert(delay<MAX_LIMIT,string.format("timermgr.DelayCall delay time is big %s",delay))

    local id = self:DispatchId()
    self.m_CbMap[id] = func
    self.m_LTimer:ltimer_add_time(id,delay)
    return id
end
--取消定时器
function CTimerMgr:Cancel(id)
    self.m_CbMap[id] = nil
end

--进行执行
function CTimerMgr:Process()
    for _,id in pairs(self.m_CbWatingProcess) do
        local f = self.m_CbMap[id]
        if f then
            self.m_CbMap[id] = nil
            f()
        end
    end
    self.m_CbWatingProcess = {}
end

--新建一个定时器
function CTimerMgr:NewTimer()
    return CTimer.New(self)
end

function CTimerMgr:GetTime()
    return self.m_NowTime/100
end

function CTimerMgr:GetNow()
    return self.m_Now
end

function CTimerMgr:GetStartTime()
    return self.m_StartTime
end

function CTimerMgr:Init()
    local update = nil
    update = function ()
        if not self.m_Execute  then --如果尚未在执行
            self.m_Execute = true
            self:RefreshTime()
            self.m_LTimer:ltimer_update(self.m_NowTime,self.m_CbWatingProcess)
            self:Process()
            self.m_Execute = false
            skynet.timeout(1, update)
        end
    end
    skynet.timeout(1,update)
end

return CTimerMgr