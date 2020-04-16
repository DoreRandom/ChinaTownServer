local CChannel = import(service_path("cchannel"))

local M = {}
--加入频道，如果没有该频道，则创建
function M.JoinChannel(_,data)
    local pid = data.pid
    local channelType = data.chanType
    local chanId= data.chanId

    local channel = g_Channels[channelType][chanId]
    if not channel then
        --新建一个
        channel = CChannel.New(channelType)
        g_Channels[channelType][chanId] = channel
    end
    channel:Add(pid)
end
--离开频道
function M.LeaveChannel(_,data)
    local pid = data.pid
    local channelType = data.chanType
    local chanId= data.chanId

    local channel = g_Channels[channelType][chanId]
    if not channel then
        return
    end
    channel:Del(pid)
    if channel:GetCount() <= 0 then
        g_Channels[channelType][chanId] = nil
    end
end
--向channel发送信息
function M.SendChannel(_,data)
    local channelType = data.chanType
    local chanId= data.chanId
    local channel = g_Channels[channelType][chanId]
    if channel then
        channel:Send(data.cmd,data.data,data.exclude)
    end
end

return M