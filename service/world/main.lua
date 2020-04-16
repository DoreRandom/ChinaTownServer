
local skynet = require "skynet"
require "skynet.manager"
require "public.serverdefines"
local netproto = require "base.netproto"
local netdispatch = require "base.netdispatch"
local logicdispatch = require "base.logicdispatch"

local netcmd = import(service_path("netcmd.init"))
local logiccmd = import(service_path("logiccmd.init"))

local CWorldMgr = import(service_path("cworldmgr"))
local CRoomMgr = import(service_path("croommgr"))
local CNotifyMgr = import(service_path("cnotifymgr"))
local CMailMgr = import(service_path("cmailmgr"))
local CChatMgr = import(service_path("cchatmgr"))
local CBattleMgr = import(service_path("cbattlemgr"))


skynet.start(function ()
    netproto.Init()
    netdispatch.Dispatch(netcmd)
    logicdispatch.Dispatch(logiccmd)

    g_WorldMgr = CWorldMgr.New()
    g_RoomMgr = CRoomMgr.New()
    g_NotifyMgr = CNotifyMgr.New()
    g_MailMgr = CMailMgr.New()
    g_ChatMgr = CChatMgr.New()

    local battleRemotes = {}
    for i=1,BATTLE_SERVICE_COUNT do
        local addr = skynet.newservice("battle")
        table.insert(battleRemotes,addr)
    end

    g_BattleMgr = CBattleMgr.New(battleRemotes)


    g_BattleRemotes = battleRemotes

    skynet.register ".world"
end)