local irc = {}

local socket = require 'socket'
local ssl = require 'ssl'

irc.init = function (stbl)
    local bare = socket.connect(stbl.address, stbl.port)
    local conn = ssl.wrap(bare, stbl.sslparams)
    conn:dohandshake()
    return conn
end

irc.conn = function (c, stbl)
    c:send('NICK ' .. stbl.handle .. '\r\n')
    c:send('USER ' .. stbl.ident  .. ' * 8 :' .. stbl.gecos .. '\r\n')
end

irc.join = function (c, channel)
    c:send('JOIN ' .. channel .. '\r\n')
end

irc.joinall = function (c, stbl)
    for _, v in pairs(stbl.channels) do
        irc.join(c, v)
    end
end

irc.pong = function (c, sname)
    c:send('PONG ' .. sname .. '\r\n')
end

irc.privmsg = function (c, target, msg)
    c:send('PRIVMSG ' .. target .. ' :' .. msg .. '\r\n')
end

irc.modeset = function (c, target, recipient, mode)
    if target:byte() == 35 then
        c:send('MODE ' .. target .. ' ' .. mode .. ' ' .. recipient .. '\r\n')
    else
        irc.privmsg(c, target, 'Cannot set modes in query')
    end
end

irc.kick = function (c, target, recipient, message)
    if target:byte() == 35 then
        c:send('KICK ' .. target .. ' ' .. recipient .. ' :' .. message .. '\r\n')
    else
        irc.privmsg(c, target, 'Cannot kick in query')
    end
end

irc.get_sname = function (c, ms)
    local sname = ''
    while sname == '' do
        local data = c:receive('*l')
        if ms.debug then print(data) end

        if data:find('376') or data:find('422') then
            _, _, sname = data:find('(%S+)')
        end
    end

    return sname
end

irc.authorized = function (c, nw, mask)
    local authed = nil
    for k in pairs(nw.admins) do
        authed = authed or mask:find(k)
    end

    return authed
end

irc.react_to_privmsg = function (c, ms, text)
    local ptn = '^:([^!]+)(%S+) %S+ (%S+) :(.*)'
    local _, _, mask, hn, target, msg = text:find(ptn)
    local authed = irc.authorized(c, ms.irc_network, mask .. hn)

    local tgt = target:find('^#') and target or mask
    local prefix = '^' .. (tgt:find('^#') and ms.irc_network.handle .. '.?%s+' or '')

    if not msg:find(prefix) then return true end

    local _, _, key = msg:find(prefix .. '(.*)')
    if key == nil then return true end
    local basic = ms.irc_factoids[key:gsub("^%s*(.-)%s*$", "%1")]

    if basic ~= nil then
        irc.privmsg(c, tgt, basic)
    else
        for k, v in pairs(ms.irc_aliases) do
            if key:find('^%s*' .. k .. '$') then
                ret = v(ms, c, tgt, key, authed, mask)
                if ret then return false end
            end
        end
    end

    return true
end

irc.react_loop = function (c, sname, ms)
    math.randomseed(os.time())

    local keepalive = true
    while keepalive do
        local data = c:receive('*l')
        if not data then goto continue end
        if ms.debug then io.stdout:write(data .. '\n') end

        if data == ('PING ' .. sname) then
            irc.pong(c, sname)
        elseif data:find('PRIVMSG') then
            keepalive = irc.react_to_privmsg(c, ms, data)
        end
        ::continue::
    end
end

irc.bot = function (ms)
    local c = irc.init(ms.irc_network)
    if not c then
        print('failed to initialize irc network')
        return
    end

    irc.conn(c, ms.irc_network)

    local sname = irc.get_sname(c, ms)
    irc.joinall(c, ms.irc_network)

    irc.react_loop(c, sname, ms)
    c:close()
end

return irc
