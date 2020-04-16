local M = {}
--通过账号获得用户
function M.GetUserByAccount(cond,data)
    local sql = string.format("select * from user where account = '%s'",cond.account)
    return g_GameDB:query(sql)
end

--创建用户
function M.CreateUser(cond,data)
    local sql = string.format("insert into user set account = '%s',password = '%s'",data.account,data.password)
    return g_GameDB:query(sql)
end

return M