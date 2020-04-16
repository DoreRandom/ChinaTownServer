--实现简单的账号创建和验证 该部分可能会实现一版http
local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))

local M = {}

--interface
function M.C2GSLogin(conn,data)
    M._Login(conn,data)
end

function M.C2GSRegister(conn,data)
    M._Register(conn,data)
end


--implement

--登录
function M._Login(conn,data)
    if conn:GetStatus() ~= gamedefines.LOGIN_CONNECTION_STATUS.None then
        return 
    end
    conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.InLogin)

    local dbop = {
        mod = "User",
        cmd = "GetUserByAccount",
        cond = {account = data.account}
    }
    local fd = conn:GetFd()
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            M._LoginCheck(conn,result,data)
        end
    end)
end
--验证
function M._LoginCheck(conn,result,data)
    if #result == 0 then
        conn:Send("GS2CLoginResult",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "没有此账号"})
        conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
        return 
    end

    local ins = result[1]
    if ins.password == data.password then
        --登录成功
        local token = g_TokenMgr:GenToken(ins.account,ins.uid)
        conn:Send("GS2CLoginResult",{retCode = gamedefines.ERROR_CODE.Ok,retMsg = "登录成功",account=ins.account,token = token})
        conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
    else
        --密码错误
        conn:Send("GS2CLoginResult",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "密码错误"})
        conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
    end
end

--注册

--检测账号密码是否合法
function M._Register(conn,data)

    local account = data.account
    local password = data.password

    local retCode = gamedefines.ERROR_CODE.Ok
    local retMsg = ""
    if string.len(account) < 6 then
        retCode = gamedefines.ERROR_CODE.Common
        retMsg = "账号不应短于6"
    elseif string.len(account) > 15 then
        retCode = gamedefines.ERROR_CODE.Common
        retMsg = "账号不应长于15"
    elseif string.len(password) < 6 then
        retCode = gamedefines.ERROR_CODE.Common
        retMsg = "密码不应短于6"
    elseif string.len(password) > 15 then
        retCode = gamedefines.ERROR_CODE.Common
        retMsg = "账号不应长于15"
    elseif string.find(account, '[^%w]+') or string.find(account, '[^%w]+') then
        retCode = gamedefines.ERROR_CODE.Common
        retMsg = "账号密码只能由数组字母组成"
    end

    if retCode ~= 0 then
        conn:Send("GS2CRegisterResult",{retCode = retCode,retMsg = retMsg})
        return
    end
    
    if conn:GetStatus() ~= gamedefines.LOGIN_CONNECTION_STATUS.None then
        return 
    end
    conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.InRegister)
    local dbop = {
        mod = "User",
        cmd = "GetUserByAccount",
        cond = {account = account}
    }
    local fd = conn:GetFd()
    gamedb.LoadDb(dbop,function (tag,result)
        local conn = g_GateMgr:GetConnection(fd)
        if conn then
            M._RegisterCheckRepeat(conn,result,data)
        end
    end)
end

--检测账号是否重复
function M._RegisterCheckRepeat(conn,result,data)
    if #result ~= 0 then
        conn:Send("GS2CRegisterResult",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "账号已存在"})
        conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
    else
        local dbop = {
            mod = "User",
            cmd = "CreateUser",
            data = {
                account = data.account,
                password = data.password
            }
        }
        local fd = conn:GetFd()
        gamedb.LoadDb(dbop,function (tag,res)
            local conn = g_GateMgr:GetConnection(fd)
            if conn then
                if res.errno == 1062 then
                    conn:Send("GS2CRegisterResult",{retCode = gamedefines.ERROR_CODE.Common,retMsg = "账号已存在"})
                else
                    conn:Send("GS2CRegisterResult",{retCode = gamedefines.ERROR_CODE.Ok,retMsg = "注册成功，请登录"})
                end
                conn:SetStatus(gamedefines.LOGIN_CONNECTION_STATUS.None)
            end
        end)
    end
end

return M