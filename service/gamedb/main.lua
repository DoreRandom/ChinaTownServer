local skynet = require "skynet"
require "skynet.manager"
local mysql = require "skynet.db.mysql"
local record = require "base.record"
local serverinfo = import(lualib_path("public.serverinfo"))
local no = ...

local logicdispath = require "base.logicdispatch"

local logiccmd = import(service_path("logiccmd.init"))


local function InitDB()
    local m = serverinfo.get_local_dbs()
    local config = m.game
    local connected = false
    config.on_connect = function ( ... )
        connected = true
        record.info(string.format("gamedb.main connected mysql host %s port %s",config.host,config.port))
    end
    g_GameDB = mysql.connect(config)
    while true do
        skynet.sleep(1)
        if connected then
            break
        end
    end
end

skynet.start(function ()
    logicdispath.Dispatch(logiccmd)

    InitDB()

    skynet.register(".gamedb"..no)
end)