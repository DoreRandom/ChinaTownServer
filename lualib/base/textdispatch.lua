
local skynet = require "skynet"

local M = {}

function M.Dispatch(textcmd)
    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        pack = skynet.pack,
		unpack = skynet.unpack
    }

    skynet.dispatch("text", function (session, address, ...)
        if textcmd then
            textcmd.Invoke(...)
        end
    end)
end

return M
