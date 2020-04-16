require "public.serverdefines"

local M = {}

local GS_INFO = {
    ["dev_gs_1"] = {name="测试服务器",master_db_ip="127.0.0.1",master_db_port=3306}
}

function M.get_local_dbs()
    local host = "127.0.0.1"
    local port = 3306
    local database = GAME_NAME
    if get_server_type() == "gs" then
        host = GS_INFO[get_server_key()]["master_db_ip"]
        port = GS_INFO[get_server_key()]["master_db_port"]
    end
    return {
        game = {host = host,port=port,user=MYSQL_USER,password=MYSQL_PWD,database=database}
    }
end

return M