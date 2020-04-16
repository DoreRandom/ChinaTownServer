--用于简单的创建验证token
local cjson = require "cjson"
local o = class("CTokenMgr")
local EXPECT_TIME = 30*24*3600
local MAX_PLAYER_TOKEN =10000 --一秒钟最多的token数
function o:Ctor() 
    self.m_PlayerTokenCache = {}
    self.m_PlayerTokenIndex = 0
end
--verify start
--生成一个token
function o:GenToken(account,uid)
    assert(account)
    assert(uid)
    local obj = {
        account = account,
        uid = uid,
        time = os.time() + EXPECT_TIME
    }
    return cjson.encode(obj)
end
--验证一个token
function o:VerifyToken(token,account)
    local obj = cjson.decode(token)
    if obj.time >= os.time() and account == obj.account then
        return true
    else
        return false
    end
end

--verify end
--login  start todo 考虑redis
function o:GenPlayerToken()
    self.m_PlayerTokenIndex = self.m_PlayerTokenIndex + 1
    if self.m_PlayerTokenIndex >= MAX_PLAYER_TOKEN then
        self.m_PlayerTokenIndex = 1
    end
    local token = os.time() * MAX_PLAYER_TOKEN + self.m_PlayerTokenIndex
    return tostring(token)
end

--保存用户的token
function o:SaveByPlayerToken(pid,token,data)
    data.token = token
    self.m_PlayerTokenCache[pid] = data
end

--获得数据
function o:LoadByPlayerToken(pid,token)
    local data = self.m_PlayerTokenCache[pid]
    if not data then
        return
    end
    if data.token ~= token then
        return
    end
    return data
end

--清除缓存数据
function o:ClearByPlayerToken(pid,token)
    local data = self.m_PlayerTokenCache[pid]
    if data and data.token == token then
        self.m_PlayerTokenCache[pid] = nil
    end
end

--login end

return o