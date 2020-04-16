local playersend = require "base.playersend"

local M = {}

function M.UpdatePlayerMail(tag,data)
    playersend.UpdatePlayerMail(data.pid,data.mail)
end

return M