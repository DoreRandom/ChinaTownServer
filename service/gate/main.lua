local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local socketdriver = require "skynet.socketdriver"

local socket_manager = nil
local socket_forwards = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = function (fd,source,msg)
		skynet.ignoreret()
		socketdriver.send(fd,msg)
	end
}

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	pack = skynet.pack,
	unpack = skynet.unpack
}


local handler = {}

function handler.open(source, conf)
	socket_manager = conf.watchdog or source
end

function handler.message(fd, msg, sz)
	local forward = socket_forwards[fd]
	if forward then
		skynet.redirect(forward, MY_ADDR, "client", fd, msg, sz)
	end
end

function handler.connect(fd, addr)
	gateserver.openclient(fd)
	skynet.send(socket_manager, "text","open",MY_ADDR, fd, addr)
end

function handler.disconnect(fd)
	skynet.send(socket_manager, "text", "close",MY_ADDR,fd)
end

local CMD = {}

function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end
function CMD.forward(source,fd)
	socket_forwards[fd] = source
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
