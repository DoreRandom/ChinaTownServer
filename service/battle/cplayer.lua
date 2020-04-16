local netproto = require "base.netproto"
local playersend = require "base.playersend"
local gamedata = import(lualib_path("public.gamedata"))
local o = class("CPlayer")

function o:Ctor(args,bid)
    self.m_Bid = bid

    self.m_Pid = args.pid
    self.m_Name = args.name 
    self.m_Head = args.head

    self.m_Data = {} --需要同步的数据

    self.m_Data["money"] = gamedata.startMoney --钱数
    self.m_Data["lastMoney"] = 0 --去年营收
    self.m_Data["tid"] = 0 --交易id
    self.m_Data["shopList"] = {0,0,0,0,0,0,0,0,0,0,0,0} --商铺列表
    self.m_Data["online"] = 0 --0 在线 1 离线 
    
end

function o:GetBattle()
    return g_BattleMgr:GetBattle(self.m_Bid)
end

function o:GetPid()
    return self.m_Pid
end

function o:GetName()
    return self.m_Name
end

function o:GetHead()
    return self.m_Head
end

function o:SetData(key,value)
    self.m_Data[key] = value
    self:StatusChange(key)
end

function o:GetData(key,default)
    return self.m_Data[key] or default
end
--检查店铺是否重组
function o:CheckShopList(changeList)
    local shopList = self:GetData("shopList")
    for shop,num in pairs(shopList) do
        if num + changeList[shop] < 0 then
            return false  
        end
    end  
    return true
end

--更新商铺列表
function o:UpdateShopList(changeList)
    local shopList = self:GetData("shopList")
    for shop,num in pairs(changeList) do
        shopList[shop] = shopList[shop] + num
    end

    self:SetData("shopList",shopList)
end

function o:GetStatus(m)
    if not m then
        m = self.m_Data
    end
    local data = {}
    for k,_ in pairs(m) do
        data[k] = self.m_Data[k]
    end
    return data
end

function o:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _, v in ipairs(l) do
        m[v] = true
    end
    local status = self:GetStatus(m)
    local battle = self:GetBattle()
    battle:SendAll("GS2CRefreshPlayerStatus",{
        bid = self.m_Bid,
        pid = self.m_Pid,
        status = status
    })
end

function o:PackInfo()
    local data = {
        pid = self.m_Pid,
        name = self.m_Name,
        head = self.m_Head,
        status = self:GetStatus() 
    }
    return data
end

function o:Send(cmd,data)
    playersend.Send(self.m_Pid,cmd,data)
end

function o:SendRaw(msg)
    playersend.SendRaw(self.m_Pid,msg)
end


function o:Notify(msg,window)
    self:Send("GS2CNotify",{
        msg = msg,
        window = window
    })
end


return o