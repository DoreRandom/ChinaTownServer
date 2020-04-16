local o = class("CNoifyMgr")

function o:Ctor()
end

function o:Notify(pid,msg,window)
    local player = g_WorldMgr:GetOnlinePlayerByPid(pid)
    if player then
        player:Send("GS2CNotify",{
            msg = msg,
            window = window
        })
    end
end


return o