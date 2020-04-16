local CEventMgr = require "base.ceventmgr"
local o = class("CObj")

function o:Ctor()
    self.m_Timer = nil
    self.m_Event = nil
end

function o:Release()
    if self.m_Timer then
        self.m_Timer:Release()
    end
    if self.m_Event then
        self.m_Event:Release()
    end
end

function o:AddTimer(name,second,func)
    if not self.m_Timer then
        self.m_Timer = g_TimerMgr:NewTimer()
    end
    self.m_Timer:DelayCall(name,second,func)
end

function o:DelTimer(name)
    if self.m_Timer then
        self.m_Timer:Cancel(name)
    end
end

function o:AddEvent(obj,eventType,func)
    if not self.m_Event then
        self.m_Event = CEventMgr.New()
    end
    self.m_Event:AddEvent(obj,eventType,func)
end

function o:DelEvent(obj,eventType)
    if self.m_Event then
        self.m_Event:DelEvent(obj,eventType)
    end
end

function o:TriggerEvent(eventType,data)
    if self.m_Event then
        self.m_Event:TriggerEvent(eventType,data)
    end
end

return o