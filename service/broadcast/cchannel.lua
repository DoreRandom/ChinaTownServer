local playersend  = require "base.playersend"
local o = class("CChannel")

function o:Ctor(channelType)
    self.m_ChannelType = channelType
    self.m_Members = {}
end

function o:Add(pid)
    self.m_Members[pid] = true
end

function o:Del(pid)
    self.m_Members[pid] = nil
end

function o:GetCount()
    return table_count(self.m_Members)
end
--发送
function o:SendRaw(msg,exclude)
    for pid,_ in pairs(self.m_Members) do
        if not exclude[pid] then
            playersend.SendRaw(pid,msg)
        end
    end
end

--发送
function o:Send(cmd,data,exclude)
    local msg = playersend.PackData(cmd,data)
    exclude = exclude or {}
    for pid,_ in pairs(self.m_Members) do
        if not exclude[pid] then
            playersend.SendRaw(pid,msg)
        end
    end
end

return o