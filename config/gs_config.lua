root = "./"
thread = 4
harbor = 0
bootstrap = "snlua bootstrap"

start = "gs_launcher"

server_key = "dev_gs_1"
server_local_ip = "127.0.0.1"

proto_file = "proto/proto.pb"

----------路径配置------------
luaservice = root.."service/?.lua;"..root.."service/?/main.lua;"..root.."skynet/service/?.lua;"..root.."skynet/service/?/main.lua"
lua_path = root .. "lualib/?.lua;"..root.."skynet/lualib/?.lua;"..root.."service/?.lua"
lua_cpath = root.."build/luaclib/?.so;"..root.."luaclib/?.so;"..root.."skynet/luaclib/?.so;"
cpath = root .. "build/cservice/?.so;"..root.."skynet/cservice/?.so;"
lualoader = root.."skynet/lualib/loader.lua"
preload = root .. "lualib/base/preload.lua"
