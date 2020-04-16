local M = {}
--选择卡
function M.C2GSSelectCard(player, data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSSelectCard",data)
    end
end
--显示缓存窗口
function M.C2GSShowCacheWindow(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSShowCacheWindow",data)
    end
end
--下一年
function M.C2GSNextYear(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSNextYear",data)
    end
end
--信号
function M.C2GSSignal(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSSignal",data)
    end
end
--放置店铺
function M.C2GSSetShopToLocation(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSSetShopToLocation",data)
    end
end
--发起交易
function M.C2GSTrade(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSTrade",data)
    end
end
--取消交易
function M.C2GSCancelTrade(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSCancelTrade",data)
    end
end
--交易店铺
function M.C2GSTradeShop(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSTradeShop",data)
    end
end
--交易地
function M.C2GSTradeLocation(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSTradeLocation",data)
    end
end
--交易钱
function M.C2GSTradeMoney(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSTradeMoney",data)
    end
end
--交易锁定
function M.C2GSTradeLock(player,data)
    local battle = player:GetBattle()
    if battle and data.bid == battle:GetBid() then
        data.pid = player:GetPid()
        battle:Forward("C2GSTradeLock",data)
    end
end
--强制退出
function M.C2GSForceLeave(player,data)
    g_BattleMgr:ForceLeave(player)
end

return M