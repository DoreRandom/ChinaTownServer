local skynet = require "skynet"
require "skynet.manager"

local record = require "base.record"
require "public.serverdefines"

skynet.start(function()
    record.info("gs start")
    for no = 1, GAMEDB_SERVICE_COUNT do
        skynet.newservice("gamedb", no)
    end
    skynet.newservice("login")
    skynet.newservice("world")
    skynet.newservice("broadcast")
    skynet.newservice("debug_console",8000)
    record.info("gs all service booted")
    skynet.exit()
end)
