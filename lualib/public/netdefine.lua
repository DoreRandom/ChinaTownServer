local M = {}

local C2GS = {}
local GS2C = {}
M.C2GS = C2GS
M.GS2C = GS2C

local C2GSByName = {}
local GS2CByName = {}
M.C2GSByName = C2GSByName
M.GS2CByName = GS2CByName

-----C2GS-----
local C2GS_DEFINE = {}
C2GS_DEFINE.Verify = {
    C2GSLogin = 1001,
    C2GSRegister = 1002
} 

C2GS_DEFINE.Login = {
    C2GSLoginAccount = 2001,
    C2GSLoginPlayer = 2002,
    C2GSCreatePlayer = 2003,
    C2GSReLoginPlayer = 2004
}

C2GS_DEFINE.Other = {
    C2GSHeartBeat = 3001,
}

C2GS_DEFINE.Room = {
    C2GSCreateRoom = 4001,
    C2GSJoinRoom = 4002,
    C2GSKickRoom = 4003,
    C2GSLeaveRoom = 4004,
    C2GSSetReady = 4005,
    C2GSStartGame = 4006
}

C2GS_DEFINE.Chat = {
    C2GSChat = 5001
}

C2GS_DEFINE.Battle = {
    C2GSSelectCard = 6001,
    C2GSShowCacheWindow = 6002,
    C2GSNextYear = 6003,
    C2GSSignal = 6004,
    C2GSSetShopToLocation = 6005,
    C2GSTrade = 6006,
    C2GSCancelTrade = 6007,
    C2GSTradeShop = 6008,
    C2GSTradeLocation = 6009,
    C2GSTradeMoney = 6010,
    C2GSTradeLock = 6011,
    C2GSForceLeave = 6012
}

C2GS_DEFINE.Player = {
    C2GSBackToTeam = 7001,
    C2GSBackToHall = 7002
}
-----GS2C-----
local GS2C_DEFINE = {}

GS2C_DEFINE.Verify = {
    GS2CLoginResult = 1001,
    GS2CRegisterResult = 1002
}

GS2C_DEFINE.Login = {
    GS2CLoginAccount = 2001,
    GS2CLoginPlayer = 2002,
    GS2CCreatePlayer = 2003,
    GS2CLoginError = 2004
}

GS2C_DEFINE.Other = {
    GS2CHeartBeat = 3001,
    GS2CNotify = 3002
}

GS2C_DEFINE.Room = {
    GS2CAddRoom = 4001,
    GS2CDelRoom = 4002,
    GS2CAddRoomMember = 4003,
    GS2CChangeLeader = 4004,
    GS2CRefreshRoomStatus = 4005,
    GS2CRefreshMemberInfo = 4006
}

GS2C_DEFINE.Chat = {
    GS2CChat = 5001
}

GS2C_DEFINE.Battle = {
    GS2CCreateBattle = 6001,
    GS2CRefreshYear = 6002,
    GS2CDispatchCard = 6003,
    GS2CRefreshLocation = 6004,
    GS2CRefreshPlayerStatus = 6005,
    GS2CSelectCard = 6006,
    GS2CSignal = 6007,
    GS2CTrade = 6008,
    GS2CRefreshTradeInfo = 6009,
    GS2CRankInfo = 6010
}

GS2C_DEFINE.Player = {
    GS2CRefreshPlayer = 7001,
}
for mod,m in pairs(C2GS_DEFINE) do
    for name,id in pairs(m) do
        C2GS[id] = {mod=mod,cmd=name}
        C2GSByName[name] = id 
    end
end

for mod,m in pairs(GS2C_DEFINE) do
    for name,id in pairs(m) do
        GS2C[id] = {mod=mod,cmd=name}
        GS2CByName[name] = id
    end
end

return M