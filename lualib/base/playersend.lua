local net = require "base.netdispatch"
local netproto = require "base.netproto"
local M = {}
local mailMap = {}

--更新角色的地址
function M.UpdatePlayerMail(pid,mail)
    mailMap[pid] = mail
end
--获得角色地址
function M.GetPlayerMail(pid)
    return mailMap[pid]
end
--发送
function M.Send(pid,cmd,data)
    local mail = mailMap[pid]
    if not mail then return end
    net.Send(mail.gate,mail.fd,cmd,data)
end
--发送给列表
--发送
function M.SendRaw(pid,msg)
    local mail = mailMap[pid]
    if not mail then return end
    net.SendRaw(mail.gate,mail.fd,msg)
end
--打包数据
function M.PackData(cmd,data)
    return netproto.Serialize(cmd,0,data)
end

return M