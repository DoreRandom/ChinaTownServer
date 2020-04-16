local skynet = require "skynet"

MY_ADDR = skynet.self()
MY_SERVER_KEY = skynet.getenv("server_key")
MY_SERVER_LOCAL_IP = skynet.getenv("server_local_ip")
MY_SERVICE_NAME = ...

require "base.reload"
require "base.class"
require "base.commonop"
require "base.tableop"

local CTimerMgr = require "base.ctimermgr"
local CSaveMgr = require "base.csavemgr"
g_TimerMgr = CTimerMgr.New()
g_SaveMgr = CSaveMgr.New()