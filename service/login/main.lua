
local skynet = require "skynet"
require "skynet.manager"
require "public.serverdefines"
local netproto = require "base.netproto"
local netdispatch = require "base.netdispatch"
local textdispatch = require "base.textdispatch"
local logicdispatch = require "base.logicdispatch"

local CGateMgr = import(service_path("cgatemgr"))
local CTokenMgr = import(service_path("ctokenmgr"))
local CGate = import(service_path("cgate"))

local textcmd = import(service_path("textcmd.init"))
local netcmd = import(service_path("netcmd.init"))
local logiccmd = import(service_path("logiccmd.init"))



skynet.start(function ()
    netproto.Init()
    textdispatch.Dispatch(textcmd)
    netdispatch.Dispatch(netcmd)
    logicdispatch.Dispatch(logiccmd)

    
    g_GateMgr = CGateMgr.New()
    g_GateMgr:Init()
    
    g_TokenMgr = CTokenMgr.New()
    
    for _,port in pairs(GS_GATEWAY_PORTS) do
        local gate = CGate.New(port)
        g_GateMgr:AddGate(gate)
    end
    skynet.register ".login"
end)