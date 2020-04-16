local CBattle = import(service_path("cbattle"))
local o = class("CBattleMgr")

function o:Ctor()
    self.m_Battles = {}
end

function o:Release()
    
end
--创建战斗
function o:CreateBattle(data)
    local battle = CBattle.New(data)
    self.m_Battles[battle:GetBid()] = battle
    battle:Start()
end

--获得战斗
function o:GetBattle(bid)
    return self.m_Battles[bid]
end

--移除battle
function o:RemoveBattle(bid)
    local battle = self.m_Battles[bid]
    self.m_Battles[bid] = nil
    if battle then
        battle:Release()
    end
end
return o