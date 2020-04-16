--获得server key
get_server_key = function ()
    return MY_SERVER_KEY
end
--获得生产环境
get_server_env = function ()
    return string.match(MY_SERVER_KEY, "(%w+)_%a+_%d*")
end
--获得服务器类型
get_server_type = function ()
    return string.match(MY_SERVER_KEY, "%w+_(%a+)_%d*")
end
--获得服务器id
get_server_id = function ()
    return tonumber(string.match(MY_SERVER_KEY, "%w+_%a+_(%d*)"))
end

--将文件以mode模式读取到env中
loadfile_ex = function (sFileName, sMode, mEnv)
    sMode = sMode or "bt"
    mEnv = mEnv or _ENV
    local h = io.open(sFileName, "rb")
    assert(h, string.format("loadfile_ex fail %s", sFileName))
    local sData = h:read("*a")
    h:close()
    local f, s = load(sData, sFileName, sMode, mEnv)
    assert(f, string.format("loadfile_ex fail %s", s))
    return f
end
--获得该服务下的路径
service_path = function (sPath)
    return string.format("service.%s.%s", MY_SERVICE_NAME, sPath)
end
--获得lualib路径
lualib_path = function (sPath)
    return string.format("lualib.%s", sPath)
end
--设置释放
set_release = function (obj)
    obj.__release = true
end
--判断是否释放
is_release = function (obj)
    return obj.__release
end