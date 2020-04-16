local M = {}
function M.LoginPlayerResponse(tag,data)
    local conn = g_GateMgr:GetConnection(data.fd)
    if conn then
        conn:LoginPlayerResponse(data)
    end
end

function M.OnLogout(tag,data)
    g_GateMgr:OnLogout(data)
end

return M