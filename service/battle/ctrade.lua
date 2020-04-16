local netproto = require "base.netproto"
local playersend = require "base.playersend"
local CTradeInfo = class("CTradeInfo")

function CTradeInfo:Ctor(pid,tid,bid)
    self.m_Pid = pid
    self.m_Tid = tid
    self.m_Bid = bid
    self.m_Data = {}
    self.m_Data["locked"] = 0
    self.m_Data["money"] = 0
    self.m_Data["shopList"] = {0,0,0,0,0,0,0,0,0,0,0,0}
    self.m_Data["locationList"] = {}
    self.m_LocationMap = {}
end

function CTradeInfo:GetPid()
    return self.m_Pid
end

function CTradeInfo:UpdateLocationList(lid,add)
    self.m_LocationMap[lid] = add or nil
    local locationList = {} 
    for lid,_ in pairs(self.m_LocationMap) do
        table.insert(locationList,lid)
    end

    if #locationList == 0 then
        self.m_Data["locationList"] = locationList
        self:SetData("locationList",{0}) --防止默认值被缺省
    else
        self:SetData("locationList",locationList)
    end
end

function CTradeInfo:GetLocation(lid)
    return self.m_LocationMap[lid]
end

function CTradeInfo:SetData(key,value)
    self.m_Data[key] = value
    self:StatusChange(key)
end

function CTradeInfo:GetData(key,default)
    return self.m_Data[key] or default
end

function CTradeInfo:GetStatus(m)
    if not m then
        m = self.m_Data
    end
    local data = {}
    for k,_ in pairs(m) do
        data[k] = self.m_Data[k]
    end
    return data
end

function CTradeInfo:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _,v in ipairs(l) do
        m[v] = true
    end
    local tradeInfo = self:GetStatus(m)
    
    local battle = g_BattleMgr:GetBattle(self.m_Bid)
    local trade = battle:GetTrade(self.m_Tid)

    tradeInfo.pid = self.m_Pid

    trade:SendAll("GS2CRefreshTradeInfo",{
        bid = self.m_Bid,
        tid = self.m_Tid,
        tradeInfo = tradeInfo
    })
end

local CTrade = class("CTrade")

local TradeIndex = 1

function CTrade:Ctor(bid,pids)
    self.m_Bid = bid
    self.m_Tid = self:DispatchId() 
    self.m_TradeInfoMap = {}
    for _,pid in ipairs(pids) do
        self.m_TradeInfoMap[pid] = CTradeInfo.New(pid,self.m_Tid,bid)
    end
end

function CTrade:GetTid()
    return self.m_Tid
end

function CTrade:DispatchId()
    TradeIndex = TradeIndex + 1
    return TradeIndex
end

--是否包含某玩家
function CTrade:ContainPid(pid)
    return self.m_TradeInfoMap[pid] 
end
--获得所有玩家
function CTrade:GetPids()
    return self.m_TradeInfoMap
end
--获得交易信息
function CTrade:GetTradeInfo(pid)
    return self.m_TradeInfoMap[pid]
end
--获得所有交易信息
function CTrade:GetTradeInfoMap()
    return self.m_TradeInfoMap
end
--获得另外一个玩家pid
function CTrade:GetOtherPid(myPid)
    for pid,_ in pairs(self.m_TradeInfoMap) do
        if myPid ~= pid then
            return pid
        end
    end
end
--交易是否完成
function CTrade:IsComplete()
    for _,tradeInfo in pairs(self.m_TradeInfoMap) do
        if tradeInfo:GetData("locked") ~= 1 then
            return false
        end
    end
    return true
end
--打包信息
function CTrade:PackInfo()
    local data = {
        bid = self.m_Bid,
        tid = self.m_Tid,
    }

    local tradeInfos = {}

    for pid,v in pairs(self.m_TradeInfoMap) do
        local tradeInfo = v:GetStatus()
        tradeInfo.pid = pid
        table.insert(tradeInfos,tradeInfo)
    end
    data.tradeInfos = tradeInfos
    return data
end

--发送给所有人
function CTrade:SendAll(cmd,data)
    local msg = netproto.Serialize(cmd,0,data)
    for pid,_ in pairs(self.m_TradeInfoMap) do
        playersend.SendRaw(pid,msg)
    end
end

return CTrade