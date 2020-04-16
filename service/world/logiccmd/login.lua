local M = {}
function M.LoginPlayerRequest(tag,data)
    g_WorldMgr:Login(data)
end

function M.DelConnection(tag,data)
    g_WorldMgr:DelConnection(data.fd,data.reason)    
end

return M