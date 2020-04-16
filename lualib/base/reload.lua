local hotfix = require("base.hotfix")
--用于对于热更新脚本的加载与重载

--通过load导入模块
function import(sModule)
    return hotfix.hotfix_module(sModule)
end
--重新读取模块
function reload(sModule)
    return hotfix.hotfix_module(sModule)
end
