local M = {}
function M.C2GSCreateRoom(player,data)
    g_RoomMgr:CreateRoom(player)
end

function M.C2GSJoinRoom(player,data)
    g_RoomMgr:JoinRoom(player,data.roomId)

end

function M.C2GSKickRoom(player,data)
    g_RoomMgr:KickRoom(player,data.targetPid)

end

function M.C2GSLeaveRoom(player,data)
    g_RoomMgr:LeaveRoom(player)

end

function M.C2GSSetReady(player,data)
    g_RoomMgr:SetReady(player,data.ready)

end

function M.C2GSStartGame(player,data)
    g_RoomMgr:StartGame(player)

end

return M