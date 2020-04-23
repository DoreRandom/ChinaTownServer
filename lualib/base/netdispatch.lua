local skynet = require "skynet"
local netproto = require "base.netproto"

local M = {}

function M.Dispatch(netcmd)
    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.tostring,
        dispatch = function (fd,source,msg,sz)
            skynet.ignoreret()
            if netcmd then
                local mod,cmd,seq,obj = netproto.Deserialize(msg,sz)
                netcmd.Invoke(mod,cmd,fd,obj,seq)
            end
            skynet.trash(msg, sz) 
        end
    }
end

function M.Send(gate,fd,cmd,obj)
    local data = netproto.Serialize(cmd,0,obj)
    M.SendRaw(gate,fd,data)
end

function M.SendRaw(gate,fd,data)
    skynet.redirect(gate, MY_ADDR, "client", fd, data)
end

return M
