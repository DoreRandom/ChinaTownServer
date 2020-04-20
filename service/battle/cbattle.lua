local netproto = require "base.netproto"
local logicdispatch = require "base.logicdispatch"
local CObj = require "base.cobj"

local CPlayer = import(service_path("cplayer"))
local CTrade = import(service_path("ctrade"))
local gamedata = import(lualib_path("public.gamedata"))
local gamedefines = import(lualib_path("public.gamedefines"))

local DISPATCH_TIME = 60 --发牌时间

local o = class("CBattle",CObj)

function o:Ctor(args)
    CObj.Ctor(self)
    self.m_Bid = args.bid
    self.m_Players = {}
    self.m_PlayerCount = 0
    self.m_Card = 0
    self.m_Year = 0
    self.m_Status = gamedefines.GAME_STATUS.Init

    self.m_LocationLibrary = {} --地库
    self.m_ShopLibrary = {} --店库
    self.m_CardCache = {} --发牌缓存
    self.m_NextYearVote = {} --下一年投票
    self.m_TradeCache = {} --交易区

    self.m_Area2LidMap = {}
    self.m_Lid2Location = {}
    self:Init(args)
end

function o:Release()
    CObj.Release(self)
end

--初始化
function o:Init(args)
    for _,info in ipairs(args.playerInfos) do
        local player = CPlayer.New(info,self.m_Bid)
        self.m_Players[player:GetPid()] = player
    end
    --根据人数获得发卡数量
    local count = table_count(self.m_Players)
    self.m_Card = gamedata.cards[count]
    self.m_PlayerCount = count

    self:_InitLocation()
    self:_InitLibrary()
end

--初始化location相关
function o:_InitLocation()
    --记录区域的地图
    for areaId,data in ipairs(gamedata.area) do
        local id = data.startIndex - 1
        local map = {}
        for r,row in ipairs(data.map) do
            map[r] = {}
            for c,isLocation in ipairs(row) do
                if isLocation == 1 then
                    id = id + 1
                    map[r][c] = id
                else
                    map[r][c] = 0
                end
            end
        end
        self.m_Area2LidMap[areaId] = map
    end
    --lid 2 location
    for i=1,85 do
        self.m_Lid2Location[i] = {
            lid = i,
            pid = nil,
            shop = nil,
            shopTime = nil
        }
    end    
end

--初始化牌库
function o:_InitLibrary()
    --初始化商铺卡
    for shopId=1,12 do
        local point = gamedata.shop[shopId]
        local count = point + 3
        for i=1,count do
            table.insert(self.m_ShopLibrary,shopId)
        end
    end
    --初始化地卡
    for lid=1,85 do
        table.insert(self.m_LocationLibrary,lid)
    end
end

--洗牌
function o:Shuffle(list)
    math.randomseed(os.time())

	for i=1,#list do
		local j = math.random(#list)
		local data = list[j]
		list[j] = list[i]
		list[i] = data
	end
end

--分配
function o:Alloc(list,count)
    assert(#list >= count,"卡牌数量不足")
    local ret = {}
    for i=1,count do
        local data = table.remove(list)
        table.insert(ret,data)
    end
    return ret
end

--获得bid
function o:GetBid()
    return self.m_Bid
end
--获得交易信息
function o:GetTrade(tid)
    return self.m_TradeCache[tid]
end

--游戏 begin
--开始游戏 
function o:Start()

    self:SendAll("GS2CCreateBattle",self:GS2CCreateBattle())
    self:SendAll("GS2CRefreshLocation",self:GS2CRefreshLocation())

    self:StartYear()
end

--开始一年
function o:StartYear()
    self:DelTimer("AutoDispatch")

    --进入下一年
    self.m_Year = self.m_Year + 1
    self.m_NextYearVote = {}
    self:GS2CRefreshYear()

    self.m_Status = gamedefines.GAME_STATUS.Dispatch
    --进行洗牌
    self:Shuffle(self.m_ShopLibrary)
    self:Shuffle(self.m_LocationLibrary)
    --发牌
    local dispatchTime = DISPATCH_TIME     
    local n = gamedata.cards[self.m_PlayerCount][self.m_Year]
    for pid,player in pairs(self.m_Players) do
        local shopList =  self:Alloc(self.m_ShopLibrary,n)
        local locationList = self:Alloc(self.m_LocationLibrary,n)
        local cache = {
            bid = self.m_Bid,
            shopList = shopList,
            locationList = locationList,
            expTime = math.floor(g_TimerMgr:GetTime()) + dispatchTime,
            nowTime = math.floor(g_TimerMgr:GetTime())
        }
        self.m_CardCache[pid] = cache
        player:Send("GS2CDispatchCard",cache)
    end

    self:AddTimer("AutoDispatch",dispatchTime,function ()
        self:AutoDispatch()
    end)
end

--开始交易
function o:StartTrade()
    self:DelTimer("AutoDispatch")
    self.m_Status = gamedefines.GAME_STATUS.Trade
end

--获得连体店铺数量
function o:GetShopCount(map,lidScanned,pid,shop,row,col,r,c)
    --超出边界
    if r <=0 or c <= 0 or r > row or c > col then
        return 0
    end
    --是否被统计过
    local lid = map[r][c]
    if lid == 0 or lidScanned[lid] then
        return 0
    end

    --获得上下左右
    local location = self.m_Lid2Location[lid]
    if location.pid == pid and location.shop == shop then
        lidScanned[lid] = true
        local count = 1
        count = count + self:GetShopCount(map,lidScanned,pid,shop,row,col,r-1,c) + 
        self:GetShopCount(map,lidScanned,pid,shop,row,col,r,c-1) + 
        self:GetShopCount(map,lidScanned,pid,shop,row,col,r+1,c) + 
        self:GetShopCount(map,lidScanned,pid,shop,row,col,r,c+1)
        return count
    else
        return 0
    end
end

--获得收益
function o:CalInCome(shop,count)
    local point = gamedata.shop[shop]
    local income = 0
    while(count > 0) do
        local num = count
        if num > point then
            num = point
        end

        if num == point then
            income = income + gamedata.income[num].complete
        else
            income = income + gamedata.income[num].incomplete
        end

        count = count - num
    end
    return income
end

--结束一年
function o:EndYear()
    self.m_Status = gamedefines.GAME_STATUS.Init

    --收入置为0
    local pidToIncome = {}
    for pid,_ in pairs(self.m_Players) do
        pidToIncome[pid] = 0
    end

    local lidScanned = {}
    for lid,_ in pairs(self.m_Lid2Location) do
        lidScanned[lid] = false
    end
    --遍历区域获得商铺数
    for _,map in pairs(self.m_Area2LidMap) do
        local row = #map
        local col = #map[1]

        for r,list in ipairs(map) do
            for c,lid in ipairs(list) do
                local location = self.m_Lid2Location[lid] or {}
                local pid,shop = location.pid,location.shop
                
                if pid ~= nil and shop ~= nil then
                    local count = self:GetShopCount(map,lidScanned,pid,shop,row,col,r,c)
                    if count > 0 then
                        local income =  self:CalInCome(shop,count)
                        pidToIncome[pid] = pidToIncome[pid] + income
                    end
                end
            end
        end
    end

    local cnNum = {"一","二","三","四","五","六","七","八","九","十"}

    --同步数据
    for pid,player in pairs(self.m_Players) do
        local income = pidToIncome[pid]
        player:SetData("money",player:GetData("money") + income)
        player:SetData("lastMoney",income)
        if self.m_Year ~= 6 then
            player:Notify(string.format("您在第%s年收益为 %s",cnNum[self.m_Year],income),true)
        end
    end

    --结束游戏
    if self.m_Year == 6 then
        self:EndBattle(gamedefines.GAME_END_TYPE.Normal,nil)
        return
    else
        --下一年
        self:StartYear()
    end
end

--更新location
function o:UpdateLocation(map)
    local list = {}
    for lid,pid in pairs(map) do
        local location = self.m_Lid2Location[lid]
        location.pid = pid
        table.insert(list,location)
    end
    self:SendAll("GS2CRefreshLocation",self:GS2CRefreshLocation(list))
end


--Timer 
--自动发卡
function o:AutoDispatch()
    for pid,cache in pairs(self.m_CardCache) do
        local cacheShopListCopy = table_copy(cache.shopList)
        local cacheLocationListCopy = table_copy(cache.locationList)
        
        for i=1,2 do
            table.remove(cacheShopListCopy)
            table.remove(cacheLocationListCopy)
        end

        local data = {
            bid = self.m_Bid,
            pid = pid,
            shopList = cacheShopListCopy,
            locationList = cacheLocationListCopy
        }

        self:C2GSSelectCard(data)
    end
end

--结束战斗
function o:EndBattle(gameEndType,args)
    local data = {
        bid = self.m_Bid
    }

    --根据收益进行排序
    local rankInfos = {}

    for _,player in pairs(self.m_Players) do
        local money = player:GetData("money")
        local rankInfo = {
            pid = player:GetPid(),
            name = player:GetName(),
            head = player:GetHead(),
            score = table_in_range(gamedefines.GAME_END_SCORE.Score,money,0),
            money = money
        }
        table.insert(rankInfos,rankInfo)
    end

    table.sort(rankInfos,function (a,b)
        if a.money > b.money then
            return true
        end
    end)

    data.rankInfos = rankInfos

    if gameEndType == gamedefines.GAME_END_TYPE.Normal then
        
        --发送排行榜
        self:SendAll("GS2CRankInfo",data)

    elseif gameEndType == gamedefines.GAME_END_TYPE.AllOffline then
        --不需要做任何事情
    elseif gameEndType == gamedefines.GAME_END_TYPE.ForceLeave then
        local player = self.m_Players[args.pid]
        local name = player:GetName()
        local msg = string.format("%s 逃跑了，游戏结束",name)
        self:SendAll("GS2CNotify",{
            msg = msg,
            window = true
        })
        --TODO 给逃跑玩家一些惩罚
        for _,rankInfo in ipairs(rankInfos) do
            if rankInfo.pid == args.pid then
                rankInfo.score = table_in_range(gamedefines.GAME_END_SCORE.Punish,rankInfo.money,0)
            end
        end
        --发送排行榜
        self:SendAll("GS2CRankInfo",data)
    end

    g_BattleMgr:RemoveBattle(self.m_Bid)
    --发送给world 结束信息
    logicdispatch.Send(".world","Battle","EndBattle",data)
end
--游戏 end

function o:SendAll(cmd,data)
    local msg = netproto.Serialize(cmd,0,data)
    for _,player in pairs(self.m_Players) do
        player:SendRaw(msg)
    end
end

--离线
function o:OnDisconnected(data)
    local pid = data.pid
    local player = self.m_Players[pid]
    if player then
        player:SetData("online",1)
    end

    --检查是否所有玩家都离线了，如果是这样，那么结束游戏
    for _,player in pairs(self.m_Players) do
        if player:GetData("online") == 0 then
            return
        end
    end
  
    self:EndBattle(gamedefines.GAME_END_TYPE.AllOffline,{})
end

--重入
function o:OnLogin(data)
    local pid = data.pid
    local player = self.m_Players[pid]

    player:Send("GS2CCreateBattle",self:GS2CCreateBattle())
    player:Send("GS2CRefreshLocation",self:GS2CRefreshLocation())
    self:GS2CRefreshYear() --TODO 多一点冗余信息 暂时不改

    self:C2GSShowCacheWindow({pid = pid})

    player:SetData("online",0)

end

--离开
function o:ForceLeave(data)
    local pid = data.pid
    local player = self.m_Players[pid]
    if player then
        self:EndBattle(gamedefines.GAME_END_TYPE.ForceLeave,{pid = pid})
    end
end
--协议
--C2GS--
function o:C2GSSelectCard(data)
    local pid = data.pid
    local player = self.m_Players[pid]
    local shopList = data.shopList
    local locationList = data.locationList
    if not player then
        return
    end

    local cache = self.m_CardCache[pid]
    if not cache then
        return
    end

    local cacheShopListCopy = table_copy(cache.shopList)
    local cacheLocationListCopy = table_copy(cache.locationList)
    
    --查看数量
    if #shopList + 2 ~= #cacheShopListCopy or #locationList + 2 ~= #cacheLocationListCopy then
        return
    end
    --开始分发
    local changeList = {0,0,0,0,0,0,0,0,0,0,0,0}
    for _,shop in ipairs(shopList) do
        local index = table_key(cacheShopListCopy,shop)
        if not index then  --如果没找到该店铺
            return
        else
            --移除
            table.remove(cacheShopListCopy,index)
        end
        changeList[shop] = changeList[shop] + 1
    end
    player:UpdateShopList(changeList)


    local lidMap = {}
    for _,lid in ipairs(locationList) do
        local index = table_key(cacheLocationListCopy,lid)
        if not index then
            return
        else
            --移除
            table.remove(cacheLocationListCopy,index)
        end
        lidMap[lid] = pid
    end
    self:UpdateLocation(lidMap)

    --将剩余地卡牌放回卡库
    for _,v in ipairs(cacheShopListCopy) do
        table.insert(self.m_ShopLibrary,v)
    end
    for _,v in ipairs(cacheLocationListCopy) do
        table.insert(self.m_LocationLibrary,v) 
    end
    --将缓存清空
    self.m_CardCache[pid] = nil
    
    --将已选卡发送给客户端
    player:Send("GS2CSelectCard",{bid = self.m_Bid})

    --判断是否所有人都选择完成
    if table_count(self.m_CardCache) == 0 then
        self:StartTrade()
    end
end
--显示
function o:C2GSShowCacheWindow(data)
    local pid = data.pid
    local player = self.m_Players[pid]
    if self.m_CardCache[pid] then
        local cache = self.m_CardCache[pid]
        cache.nowTime = math.floor(g_TimerMgr:GetTime())
        player:Send("GS2CDispatchCard",cache)
        return
    end

    local tid = player:GetData("tid")
    if tid ~= 0 then
        local trade = self.m_TradeCache[tid]
        player:Send("GS2CTrade",trade:PackInfo())
    end
end
--下一年投票
function o:C2GSNextYear(data)
    local pid = data.pid

    local player = self.m_Players[pid]
    --不在交易阶段
    if self.m_Status ~= gamedefines.GAME_STATUS.Trade then
        player:Notify("有玩家尚未选卡完毕，请稍后重试",true)
        return
    end

    if player:GetData("tid",0) ~= 0 then
        player:Notify("尚在交易中，请完成或取消交易后重试",true)
        return
    end
    --让其可以自己调整
    if self.m_NextYearVote[pid] then
        self.m_NextYearVote[pid] = nil
    else
        self.m_NextYearVote[pid] = true
    end
    
    self:GS2CRefreshYear()
    if table_count(self.m_NextYearVote) == table_count(self.m_Players) then
        --进入下一年
        self:EndYear()
    end

end
--发送信号
function o:C2GSSignal(data)
    self:SendAll("GS2CSignal",data)
end
--取消店铺
function o:_CancelShopInLocation(pid,lid)
    local location = self.m_Lid2Location[lid]
    local player = self.m_Players[pid]
    if not location then --没有该位置
        player:Notify("没有该位置")
        return
    end
    if location.pid ~= pid then --属主不对
        player:Notify("属主不对")
        return
    end
    if player:GetData("tid",0) ~= 0 then
        player:Notify("尚在交易中，请完成或取消交易后重试",true)
        return
    end
    if location.shop == nil then
        player:Notify("该处并无店铺")
        return
    end
    if location.shopTime ~= self.m_Year then
        player:Notify("只能撤销本年度的店铺",true)
        return
    end

    local changeList = {0,0,0,0,0,0,0,0,0,0,0,0}
    changeList[location.shop] = 1

    --设置店铺
    location.shop = nil
    location.shopTime = nil

    --修改手牌
    player:UpdateShopList(changeList)
    --修改场地
    self:SendAll("GS2CRefreshLocation",self:GS2CRefreshLocation({location}))
end
--设置店铺
function o:C2GSSetShopToLocation(data)
    local pid,lid,shop = data.pid,data.lid,data.shop
    if shop == nil or shop == 0 then
        self:_CancelShopInLocation(pid,lid)
        return
    end
    local location = self.m_Lid2Location[lid]
    local player = self.m_Players[pid]
    if not location then --没有该位置
        player:Notify("没有该位置")
        return
    end
    if location.pid ~= pid then --属主不对
        player:Notify("属主不对")
        return
    end
    if player:GetData("tid",0) ~= 0 then
        player:Notify("尚在交易中，请完成或取消交易后重试",true)
        return
    end
    --检查手牌
    local changeList = {0,0,0,0,0,0,0,0,0,0,0,0}
    changeList[shop] = -1
    if not player:CheckShopList(changeList) then
        player:Notify("手牌不足")
        return
    end
    --设置店铺
    location.shop = shop
    --记录设置店铺的时间，如果在本年修改位置，则会被视为是允许地
    location.shopTime = self.m_Year

    --修改手牌
    player:UpdateShopList(changeList)
    --修改场地
    self:SendAll("GS2CRefreshLocation",self:GS2CRefreshLocation({location}))
end

--发起交易
function o:C2GSTrade(data)

    local sourcePid = data.pid 
    local targetPid = data.targetPid
    local source = self.m_Players[sourcePid]
    local target = self.m_Players[targetPid]

    if self.m_Status ~= gamedefines.GAME_STATUS.Trade then
        source:Notify("有玩家尚未选择手牌,无法交易",true)
        return
    end

    if sourcePid == targetPid then
        source:Notify("不能自己跟自己交易",true)
        return
    end

    local sourceTid = source:GetData("tid",0)
    local targetTid = target:GetData("tid",0)
    if sourceTid ~= 0 then
        --已在交易中
        --如果原来就是跟该玩家交易，则打开交易面板
        if sourceTid == targetTid then
            self:C2GSShowCacheWindow({pid = sourcePid})
            return
        else
        --否则取消交易
            self:C2GSCancelTrade({pid=sourcePid})
        end
    end
    if targetTid ~= 0 then
        source:Notify("对方还在交易中",true)
        return
    end
    
    local trade = CTrade.New(self.m_Bid,{sourcePid,targetPid})
    local tid = trade:GetTid()

    source:SetData("tid",tid)
    target:SetData("tid",tid)

    local data = trade:PackInfo()
    source:Send("GS2CTrade",data)
    target:Send("GS2CTrade",data)

    self.m_TradeCache[tid] = trade
end
--取消交易
function o:C2GSCancelTrade(data)
    local pid = data.pid
    local player = self.m_Players[pid]
    local tid = player:GetData("tid",0)
    if tid == 0 then
        return
    end

    local trade = self.m_TradeCache[tid]
    local pids = trade:GetPids()
    for apid,_ in pairs(pids) do
        local aplayer = self.m_Players[apid]
        if apid ~= pid then
            aplayer:Notify(string.format("%s 已取消交易",player:GetName()),true)
        end
        aplayer:Send("GS2CTrade",{
            bid = self.m_Bid,
            tid = 0
        })
        aplayer:SetData("tid",0)
    end
    self.m_TradeCache[tid] = nil
end
--交易店
function o:C2GSTradeShop(data)
    local tid = data.tid
    local pid = data.pid
    local player = self.m_Players[pid]
    if tid ~= player:GetData("tid",0) or tid ==0 then
        return
    end

    local trade = self.m_TradeCache[tid]
    local tradeInfo = trade:GetTradeInfo(pid)
    local tradeShopList = tradeInfo:GetData("shopList")
    local shopList = player:GetData("shopList")
    local shop = data.shop
    if not shop then return end
    local num = tradeShopList[shop] + data.num
    if num < 0 then
        num = 0 
    elseif num > shopList[shop] then
        num = shopList[shop]
    end
    tradeShopList[shop] = num
    tradeInfo:SetData("shopList",tradeShopList)
end
--交易地
function o:C2GSTradeLocation(data)
    local tid = data.tid
    local pid = data.pid
    local player = self.m_Players[pid]
    if tid ~= player:GetData("tid",0) or tid ==0 then
        return
    end

    local trade = self.m_TradeCache[tid]
    local tradeInfo = trade:GetTradeInfo(pid)
    local lid = data.lid
    local location = self.m_Lid2Location[lid]
    if not location then
        return 
    end
    --属主不对
    if location.pid ~= pid then
        return
    end
    local tradeLocationStatus = tradeInfo:GetLocation(lid)
    tradeInfo:UpdateLocationList(lid,not tradeLocationStatus)
end
--交易钱
function o:C2GSTradeMoney(data)
    local tid = data.tid
    local pid = data.pid
    local player = self.m_Players[pid]
    if tid ~= player:GetData("tid",0) or tid ==0 then
        return
    end

    local trade = self.m_TradeCache[tid]
    local tradeInfo = trade:GetTradeInfo(pid)
    local money = data.money
    local maxMoney = player:GetData("money")
    if money < 0 then money = 0 end
    if money > maxMoney then money = maxMoney end
    tradeInfo:SetData("money",money)
end
--交易锁
function o:C2GSTradeLock(data)
    local tid = data.tid
    local pid = data.pid
    local player = self.m_Players[pid]
    if tid ~= player:GetData("tid",0) or tid ==0 then
        return
    end

    local trade = self.m_TradeCache[tid]
    local tradeInfo = trade:GetTradeInfo(pid)
    local tradeLock = tradeInfo:GetData("locked")
    tradeLock = 1 - tradeLock
    tradeInfo:SetData("locked",tradeLock)
    
    --如果完成交易
    if trade:IsComplete() then
        self:CompleteTrade(tid)
    end
end
--交易结算
function o:CompleteTrade(tid)
    local trade = self.m_TradeCache[tid]
    for pid,tradeInfo in pairs(trade:GetTradeInfoMap()) do
        local player = self.m_Players[pid]

        player:SetData("money",player:GetData("money") - tradeInfo:GetData("money"))
        player:UpdateShopList(table_negative(tradeInfo:GetData("shopList")))

        local otherPid = trade:GetOtherPid(pid)
        local otherPlayer = self.m_Players[otherPid]

        otherPlayer:SetData("money",otherPlayer:GetData("money") + tradeInfo:GetData("money"))
        otherPlayer:UpdateShopList(tradeInfo:GetData("shopList"))

        local locationList = tradeInfo:GetData("locationList")
        local locationMap = {}
        for _,lid in ipairs(locationList) do
            locationMap[lid] = otherPid
        end

        self:UpdateLocation(locationMap)

        player:Send("GS2CTrade",{
            bid = self.m_Bid,
            tid = 0
        })
        player:SetData("tid",0)
    end
end
--GS2C--
--创建对战
function o:GS2CCreateBattle()
    local data = {}
    data.bid = self.m_Bid
    local playerInfos = {}
    for pid,player in pairs(self.m_Players) do
        table.insert(playerInfos,player:PackInfo())
    end
    data.playerInfos = playerInfos
    return data
end
--更新地点
function o:GS2CRefreshLocation(list)
    if not list then
        list = self.m_Lid2Location
    end
    local data = {}
    data.bid = self.m_Bid
    local locations = {}
    for _,location in pairs(list) do
        table.insert(locations,{
            lid = location.lid,
            pid = location.pid,
            shop = location.shop
        })
    end
    data.locations = locations
    return data
end

--更新年的信息
function o:GS2CRefreshYear()
    local data = {
        bid = self.m_Bid,
        year = self.m_Year,
        vote = table_count(self.m_NextYearVote)
    }

    for pid,player in pairs(self.m_Players) do
        data.nextYear = self.m_NextYearVote[pid] or false
        player:Send("GS2CRefreshYear",data)
    end
end

return o