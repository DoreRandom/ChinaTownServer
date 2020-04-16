local skynet = require "skynet"
require "skynet.manager"
local netproto = require "base.netproto"
local netdispatch = require "base.netdispatch"
local logicdispath = require "base.logicdispatch"

local logiccmd = import(service_path("logiccmd.init"))
local netcmd = import(service_path("netcmd.init"))
local CBattleMgr = import(service_path("cbattlemgr"))

skynet.start(function ()
    netproto.Init()
    netdispatch.Dispatch(netcmd)
    logicdispath.Dispatch(logiccmd)

    g_BattleMgr = CBattleMgr.New()
end)