local logicdispatch = require "base.logicdispatch"
local gamedefines = import(lualib_path("public.gamedefines"))
local o = class("CChatMgr")

function o:Ctor()
    
end

--处理聊天
function o:HandleChat(player,data)
    local chanType = data.chanType
    if chanType == gamedefines.BROADCAST_TYPE.ROOM_TYPE then
        self:RoomChat(player,data.msg)
    end
end
--房间聊天
function o:RoomChat(player,msg)
    local roomId = player:RoomId()
    if not roomId then return end

    local data = {
        cmd = "GS2CChat",
        chanType = gamedefines.BROADCAST_TYPE.ROOM_TYPE,
        chanId = roomId,
        data = {
            pid = player:GetPid(),
            chanType = gamedefines.BROADCAST_TYPE.ROOM_TYPE,
            msg = msg
        }
    }
    logicdispatch.Send(".broadcast","Channel","SendChannel",data)
end

return o