local logicdispatch = require "base.logicdispatch"
require "public.serverdefines"
local record = require "base.record"
local M = {}
local serviceNames = {}
local turn = 0
function M.Init()
    for no=1,GAMEDB_SERVICE_COUNT do
        table.insert(serviceNames,".gamedb"..no)
    end
end

function M.GetHashService()
    turn = turn +1
    local ret = serviceNames[turn % GAMEDB_SERVICE_COUNT +1]
    return ret
end

function M.SaveDb(dbop,func)
    if func then
        logicdispatch.Request(M.GetHashService(),"","",dbop,func)
    else
        logicdispatch.Send(M.GetHashService(),"","",dbop)
    end
end

function M.LoadDb(dbop,func)
    logicdispatch.Request(M.GetHashService(),"","", dbop,func)
end


M.Init()

return M

