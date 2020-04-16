local playersend = require "base.playersend"
local logicdispatch = require "base.logicdispatch"
local o = class("CMailMgr")

function o:Ctor()
    
end

--获得需要更新的服务
function o:GetUpdateService()
    local services = {".broadcast"}
    for i,addr in ipairs(g_BattleRemotes) do
        table.insert(services,addr)
    end
    return services
end

--连接改变时
function o:OnConnectionChange(pid,mail)
    local services = self:GetUpdateService()
    playersend.UpdatePlayerMail(pid,mail)
    for _,service in ipairs(services) do
        logicdispatch.Send(service,"PlayerSend","UpdatePlayerMail",{pid = pid,mail = mail})
    end
end
return o