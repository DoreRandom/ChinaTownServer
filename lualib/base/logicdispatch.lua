--为了避免过多协程的产生，这里使用skynet.send 代替 skynet.call的逻辑
local skynet = require "skynet"
local extype = require "base.extype"

local M = {}

local SEND_TYPE = 1
local REQUEST_TYPE = 2
local RESPONSE_TYPE = 3

M.SEND_TYPE = 1
M.REQUEST_TYPE = 2
M.RESPONSE_TYPE = 3

local cbMap = {}  --用于存放请求的回调函数
local infoMap = {} --用于存放请求的信息

local sessionIdx = 1


function M.GetSession()
    sessionIdx = sessionIdx + 1
    if sessionIdx >= 100000000 then
        sessionIdx = 1
    end
    return sessionIdx
end

function M.Send(addr,mod,cmd,data)
    data = data or {}
    skynet.send(addr,"logic", {source = MY_ADDR, mod = mod, cmd = cmd, session = 0, type =SEND_TYPE}, data)
end

function M.Request(addr, mod, cmd,data,cb)
    data = data or {}
    local session = M.GetSession()
    cbMap[session] = cb
    infoMap[session] = {
        time = skynet.time(),
        addr = addr,
        mod = mod,
        cmd = cmd
    }
    skynet.send(addr,"logic",{source = MY_ADDR,mod = mod,cmd = cmd,session = session,type = REQUEST_TYPE},data)
end

function M.Response(addr,session,data)
    data = data or {}
    skynet.send(addr,"logic",{source = MY_ADDR,session = session,type = RESPONSE_TYPE},data)
end


local function HandleCmd(logicCmd,tag,data)
    local eType = tag.type
    if eType == RESPONSE_TYPE then
        local session = tag.session
        local f = cbMap[session]
        if f then
            cbMap[session] = nil
            infoMap[session] = nil
            f(tag,data)
        end
    else
        if logicCmd then
            logicCmd.Invoke(tag.mod,tag.cmd,tag,data)
        end
    end
end


function M.Dispatch(logicCmd)
    skynet.register_protocol {
        name = "logic",
        id = extype.LOGIC_TYPE,
        pack = skynet.pack,
        unpack = skynet.unpack
    }

    skynet.dispatch("logic",function (session,address,tag,data)
        HandleCmd(logicCmd,tag,data)
    end)

    --检测session
    local checkSession
    checkSession = function ()  --2s检测一次
        local nowTime = skynet.time()
        for k,v in pairs(infoMap) do
            local diff = nowTime - v.time --将调用时间和现在比较，超过10s报warrning 超过300s直接删除
            if diff >= 300 then
                print(string.format("warning: logicdispatch check delay(%s sec) session:%d time:%s addr:%s mod:%s cmd:%s",
                    diff, k, v.time, v.addr, v.mod, v.cmd)
                )
                cbMap[k] = nil
                infoMap[k] = nil
            elseif diff >= 10 then
                print(string.format("warning: logicdispatch check delay(%s sec) session:%d time:%s addr:%s mod:%s cmd:%s",
                    diff, k, v.time, v.addr, v.mod, v.cmd)
                )
            end
        end
        skynet.timeout(2*100,checkSession)
    end
    checkSession()
end


return M