local M = {}

function M.CreateBattle(tag,data)
    g_BattleMgr:CreateBattle(data)
end

function M.OnDisconnected(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:OnDisconnected(data)
    end
end

function M.OnLogin(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:OnLogin(data)
    end
end

function M.ForceLeave(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:ForceLeave(data)
    end
end

--协议转发
function M.C2GSSelectCard(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSSelectCard(data)
    end
end

function M.C2GSShowCacheWindow(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSShowCacheWindow(data)
    end
end

function M.C2GSNextYear(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSNextYear(data)
    end
end

function M.C2GSSignal(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSSignal(data)
    end
end

function M.C2GSSetShopToLocation(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSSetShopToLocation(data)
    end
end

function M.C2GSTrade(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSTrade(data)
    end
end

function M.C2GSCancelTrade(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSCancelTrade(data)
    end
end

function M.C2GSTradeShop(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSTradeShop(data)
    end
end

function M.C2GSTradeLocation(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSTradeLocation(data)
    end
end

function M.C2GSTradeMoney(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSTradeMoney(data)
    end
end

function M.C2GSTradeLock(tag,data)
    local bid = data.bid
    local battle = g_BattleMgr:GetBattle(bid)
    if not battle:GetPlayer(data.pid) then return end
    if battle then
        battle:C2GSTradeLock(data)
    end
end

return M