local skynet = require "skynet"
require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local netproto = require "base.netproto"
local logicdispatch = require "base.logicdispatch"
local netdispatch = require "base.netdispatch"

local logiccmd = import(service_path("logiccmd.init"))

skynet.start(function ()
    netproto.Init()
    logicdispatch.Dispatch(logiccmd)
    netdispatch.Dispatch(nil)
    
    g_Channels = {}
    g_Channels[gamedefines.BROADCAST_TYPE.ROOM_TYPE] = {}
    
    skynet.register ".broadcast"
end)