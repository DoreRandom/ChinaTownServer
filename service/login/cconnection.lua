local o = class("CConnection")
local netdispatch = require "base.netdispatch"
local logicdispatch = require "base.logicdispatch"
local record = require "base.record"
local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))

function o:Ctor(gate,fd,addr)
    self.m_Gate = gate
    self.m_Fd = fd
    self.m_Addr = addr
    self.m_Status = gamedefines.LOGIN_CONNECTION_STATUS.None

    self.m_AccountToken = nil
    self.m_Account = nil
end

function o:Release()
    
end

function o:GetGate()
    return self.m_Gate
end

function o:GetFd()
    return self.m_Fd
end

function o:GetAddr()
    return self.m_Addr
end
--状态
function o:SetStatus(s)
    self.m_Status = s
end

function o:GetStatus()
    return self.m_Status
end

function o:Send(cmd,obj)
    netdispatch.Send(self.m_Gate,self.m_Fd,cmd,obj)
end

function o:SendRaw(msg)
    netdispatch.SendRaw(self.m_Gate,self.m_Fd,msg)
end

--logic
--登陆账号获得角色列表
function o:LoginAccount(data)

    local account,token = data.account,data.token
    if not g_TokenMgr:VerifyToken(token,account) then
        self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.Token,retMsg = "token已失效"})
        self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
        return
    end

    if self:GetStatus() ~= gamedefines.LOGIN_CONNECTION_STATUS.None then
        return 
    end
    self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.InLoginAccount)

    --保存用户信息
    self.m_Account = account
    self.m_AccountToken = token

    --获得角色信息
    local dbop = {
       mod = "Player",
       cmd = "GetPlayerByAccount",
       cond = {account = account} 
    }
    local fd = self.m_Fd
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            conn:_LoginAccountResponse(result)
        end
    end)
end
--登陆账号梳理回复信息
function o:_LoginAccountResponse(result)
    local ret = {}
    ret.account = self.m_Account
    ret.playerList = {}
    for i,v in pairs(result) do
        local player = {
            pid = v.pid,
            name = v.name,
            head = v.head
        }
        table.insert(ret.playerList,player)
    end
    self:Send("GS2CLoginAccount",ret)
    self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount) --已经登陆账号
end

--角色创建
function o:CreatePlayer(data)
    local name = data.name or ""
    local head = data.head or 0
    if string.len(name) >10 or string.len(name) <=2 then
        self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "名字长度违规,长度应在 3-10之间"})
        return 
    end

    if gamedefines.HEAD_RANGE.Min > head or head > gamedefines.HEAD_RANGE.Max then
        print("cconnection:CreatePlayer error data %s from %s",table_tostring(data),self.m_Addr)
        g_GateMgr:KickConnection(self.m_Fd)
        return 
    end

    if self:GetStatus() ~= gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount then
        return 
    end
    self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.InCreatePlayer)
    
    self:_CreatePlayerCheckName(head,name)
end
--检测名字是否重复
function o:_CreatePlayerCheckName(head,name)
    local dbop = {
        mod = "Player",
        cmd = "GetPlayerByName",
        cond = {name = name}
    }
    local fd = self.m_Fd
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            if #result > 0 then
                self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "名字重复"})
                self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount)                    
            else
                self:_CreatePlayerCheckAmount(head,name)
            end
        end
    end)
end

--检测数量
function o:_CreatePlayerCheckAmount(head,name)
    local dbop = {
        mod = "Player",
        cmd = "GetPlayerByAccount",
        cond = {account = self.m_Account}
    }
    local fd = self.m_Fd
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            if #result >= gamedefines.ACCOUNT_PLAYER_AMOUNT then
                self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "角色过多"})
                self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount)                    
            else
                self:_CreatePlayerTrue(head,name)
            end
        end
    end)
end

--创建账号
function o:_CreatePlayerTrue(head,name)
    local dbop = {
        mod = "Player",
        cmd = "CreatePlayer",
        data = {
            account = self.m_Account,
            name = name,
            head = head,
            score = gamedefines.BEGIN_SCORE
        }
    }
    local fd = self.m_Fd
    gamedb.SaveDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            self:_CreatePlayerGetPid(result,name)
        end
    end)
end
--获得pid
function o:_CreatePlayerGetPid(result,name)
    if result.errno == 1062 then --tofix 其他错误暂时不考虑 
        self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "名字重复?"})
        self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount)
        return 
    end
    
    local fd = self.m_Fd
    local dbop = {
        mod = "Player",
        cmd = "GetPlayerByName",
        cond = {name = name}
    }
    gamedb.LoadDb(dbop,function (tag,res)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            self:_CreatePlayerResponse(res)
        end
    end)
end
--回复
function o:_CreatePlayerResponse(result)
    local ins = result[1]
    local ret = {}
    ret.account = self.m_Account
    ret.player = {
        pid = ins.pid,
        name = ins.name,
        head = ins.head
    }
    self:Send("GS2CCreatePlayer",ret)
    self:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount)
end

--角色重连
function o:ReLoginPlayer(data)
    local pid = data.pid
    local playerToken = data.playerToken
    local playerInfo = g_TokenMgr:LoadByPlayerToken(pid,playerToken)
    if not playerInfo then
        self:Send("GS2CLoginError",{retCode = gamedefines.ERROR_CODE.InvalidPlayerToken,retMsg = "token无效"})
        return 
    end
    self.m_Account = playerInfo.account
    self.m_AccountToken = playerInfo.accountToken
    
    self.m_Status = gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount

    local data = {pid = pid}
    self:LoginPlayer(data)
end

--角色登陆
function o:LoginPlayer(data)
    if self.m_Status ~= gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount then
        g_GateMgr:KickConnection(self.m_Fd)
        return 
    end
    self.m_Status = gamedefines.LOGIN_CONNECTION_STATUS.InLoginPlayer

    local pid = data.pid
    local fd = self.m_Fd
    local dbop = {
        mod = "Player",
        cmd = "GetPlayerByPid",
        cond = {pid = pid}
    }
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            self:_LoginPlayerToLoginWorld(result,data)
        end
    end)
end
--去登陆世界 或者 大厅服务器
function o:_LoginPlayerToLoginWorld(res,data)
    if #res == 0 then
        g_GateMgr:KickConnection(self.m_Fd)
        return
    end
    local playerToken = g_TokenMgr:GenPlayerToken()
    local pid = data.pid
    local data = {
        conn = {
            fd = self.m_Fd,
            gate = self.m_Gate,
            addr = self.m_Addr
        },
        player = {
            account = self.m_Account,
            accountToken = self.m_AccountToken,
            playerToken = playerToken,
            pid = pid
        }
    }
    logicdispatch.Send(".world","Login","LoginPlayerRequest",data) --如果数据较多则处理会慢，因此这里使用send
end

--这里则为返回处理
function o:LoginPlayerResponse(data)
    local pid = data.pid
    local retCode = data.retCode
    local playerToken = data.playerToken
    if retCode == gamedefines.ERROR_CODE.Ok then
        self.m_Status = gamedefines.LOGIN_CONNECTION_STATUS.LoginPlayer
        local playerInfo = {
            pid = pid,
            account = self.m_Account,
            accountToken = self.m_AccountToken
        }
        g_TokenMgr:SaveByPlayerToken(pid,playerToken,playerInfo)
    else
        self.m_Status = gamedefines.LOGIN_CONNECTION_STATUS.LoginAccount
        self:Send("GS2CLoginError",{retCode = retCode,retMsg = "错误"})
    end
end

return o