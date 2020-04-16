local M = {}
--通过账号获得用户
function M.GetPlayerByAccount(cond,data)
    local sql = string.format("select * from player where account = '%s'",cond.account)
    return g_GameDB:query(sql)
end
--通过名字获得用户
function M.GetPlayerByName(cond,data)
    local sql = string.format("select * from player where name = '%s'",cond.name)
    return g_GameDB:query(sql)
end
--通过pid获得玩家
function M.GetPlayerByPid(cond,data)
    local sql = string.format("select * from player where pid = %s",cond.pid)
    return g_GameDB:query(sql)
end
--保存玩家数据
function M.SavePlayer(cond,data)
    local sql = string.format("update player set score = %s where pid = %s",data.score,cond.pid)
    return g_GameDB:query(sql)
end
--创建玩家
function M.CreatePlayer(cond,data)
    local sql = string.format("insert into player set account = '%s',name = '%s',head = %d,score = %d",data.account,data.name,data.head,data.score)
    return g_GameDB:query(sql)
end

return M