LOGIN_CONNECTION_STATUS = {
    None = 1, -- 尚未进行任何操作
    InLogin = 2, --正在进行登录
    InRegister = 3, --正在进行注册
    InLoginAccount = 4, --正在登陆游戏
    LoginAccount = 5, --已经登陆
    InLoginPlayer = 6,--正在登陆角色
    LoginPlayer = 7,--已经登陆角色
    InCreatePlayer = 8--正在创建角色
}

ERROR_CODE = {
    Ok = 0,
    Common = 1,
    ScriptError = 2,
    Token = 1001,
    PlayerToken = 1002,
    InLogin = 1003,--已经有人在登陆了
    NoExistPlayer = 1004,--不存在该角色
    ReEnter = 1005, --重入
    InvalidPlayerToken = 1006 --playerToken无效
}

BROADCAST_TYPE = {
    ROOM_TYPE = 1
}
-------------------------
--每个账号的角色最大值
ACCOUNT_PLAYER_AMOUNT = 1

--头像范围
HEAD_RANGE = {
    Min = 1,
    Max = 72
}
--开始的分数
BEGIN_SCORE = 0

--玩家
ROOM_MAX_SIZE = 5
ROOM_MIN_SIZE = 3

--游戏状态
GAME_STATUS = {
    Init = 0,
    Dispatch = 1,
    Trade = 2
}

--游戏结束类型
GAME_END_TYPE = {
    Normal = 0,
    AllOffline = 1,
    ForceLeave = 2
}

--游戏结束分数
GAME_END_SCORE = {
    Score = {
        {1500000,100},
        {1250000,80},
        {1000000,60},
        {500000,40},
        {300000,20},
        {0,0},
    },
    Punish = {
        {1500000,100},
        {1250000,50},
        {1000000,0},
        {500000,-50},
        {300000,-100},
        {0,-100},
    }
}

return _G