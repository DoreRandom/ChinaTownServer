local CObj = require("base.cobj")
local o = class("CData",CObj)

function o:Ctor()
    CObj.Ctor(self)
    self.m_Data = {}
    self.m_IsDirty = false
    self.m_Loaded = false
    self.m_LoadedSuccess = false
    self.m_LoadedFuncs = {}

    self.m_Save = nil
    
end

function o:Release()
    if self.m_Save then
        self.m_Save:Release()
    end
    CObj.Release(self)
end

--设置数据
function o:SetData(k,v)
    self.m_Data[k] = v
    self:StatusChange(k)
    self:Dirty()
end

--获得数据
function o:GetData(k,default)
    return self.m_Data[k] or default
end

function o:StatusChange(...)
    
end

function o:SetSaveFunc(func,second)
    assert(not self.m_Save,"已经有save了")
    self.m_Save = g_SaveMgr:NewSave(func,second)
end

function o:DelSaveFunc()
    if self.m_Save then
        self.m_Save:Release()
        self.m_Save = nil
    end
end

function o:CheckSave()
    assert(self.m_Save)
    self.m_Save:CheckSave()
end

--加载数据
function o:Load(m)
    
end

--保存
function o:Save()
    
end

--是否被修改了
function o:IsDirty()
    return self.m_IsDirty
end

--标记被修改了
function o:Dirty()
    self.m_IsDirty = true
end
--取消标记
function o:UnDirty()
    self.m_IsDirty = false
end
--加载成功
function o:LoadSucess()
    self.m_Loaded = true
    self.m_LoadedSuccess = true
    self:ConfigSaveFunc()
    self:AfterLoad()
end
--加载失败
function o:LoadFail()
    self.m_Loaded = true
    self.m_LoadedSuccess = false
    self:AfterLoad()
end
--配置保存函数
function o:ConfigSaveFunc()
    
end
--设置读取后的函数
function o:SetLoadedFunc(func)
    table.insert(self.m_LoadedFuncs,func)
end
--读取数据后执行
function o:AfterLoad()
    for _,f in ipairs(self.m_LoadedFuncs) do
        f(self.m_LoadedSuccess)
    end
end

return o