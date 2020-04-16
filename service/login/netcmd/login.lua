local M = {}
--interface
function M.C2GSLoginAccount(conn,data)
    conn:LoginAccount(data)
end

function M.C2GSLoginPlayer(conn,data)
    conn:LoginPlayer(data)
end

function M.C2GSCreatePlayer(conn,data)
    conn:CreatePlayer(data)
end

function M.C2GSReLoginPlayer(conn,data)
    conn:ReLoginPlayer(data)
end

return M