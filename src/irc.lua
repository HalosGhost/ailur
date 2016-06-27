local t = {}

local socket = require 'socket'

t.init = function (stbl)
    local c = socket.connect(stbl.address, stbl.port)
    return c
end

t.conn = function (c, stbl)
    c:send('NICK ' .. stbl.handle .. '\r\n')
    c:send('USER ' .. stbl.ident  .. ' * 8 :' .. stbl.gecos .. '\r\n')
end

t.joinall = function (c, stbl)
    for k,v in pairs(stbl.channels) do
        c:send('JOIN ' .. v .. '\r\n')
    end
end

t.pong = function (c, sname)
    c:send('PONG ' .. sname .. '\r\n')
end

t.privmsg = function (c, target, msg)
    c:send('PRIVMSG ' .. target .. ' :' .. msg .. '\r\n')
end

return t
