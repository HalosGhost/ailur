local irc = {}

local socket = require 'socket'
local ssl = require 'ssl'
local sql = require 'lsqlite3'

irc.init = function (stbl)
    local bare = socket.connect(stbl.address, stbl.port)
    local conn = ssl.wrap(bare, stbl.sslparams)
    conn:dohandshake()
    return conn
end

irc.conn = function (c, stbl)
    c:send(('NICK %s\r\n'):format(stbl.handle))
    c:send(('USER %s * 8 :%s\r\n'):format(stbl.ident, stbl.gecos))
end

irc.join = function (c, channel)
    c:send(('JOIN %s\r\n'):format(channel))
end

irc.joinall = function (c, stbl)
    for _, v in pairs(stbl.channels) do
        irc.join(c, v)
    end
end

irc.pong = function (c, sname)
    c:send(('PONG %s\r\n'):format(sname))
end

irc.privmsg = function (c, target, msg)
    c:send(('PRIVMSG %s :%s\r\n'):format(target, msg))
end

irc.modeset = function (c, target, recipient, mode)
    if target:byte() == 35 then
        c:send(('MODE %s %s %s\r\n'):format(target, mode, recipient))
    else
        irc.privmsg(c, target, 'Cannot set modes in query')
    end
end

irc.kick = function (c, target, recipient, message)
    if target:byte() == 35 then
        c:send(('KICK %s %s :%s\r\n'):format(target, recipient, message))
    else
        irc.privmsg(c, target, 'Cannot kick in query')
    end
end

irc.get_sname = function (c, ms)
    local sname = ''
    while sname == '' do
        local data = c:receive('*l')
        if ms.debug and data then print(data) end

        if data and (data:find('376') or data:find('422')) then
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
    local basic = ms.irc_factoids.find(key:gsub("^%s*(.-)%s*$", "%1"))

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

    if ms.nickpass == nil then
        irc.joinall(c, ms.irc_network)
    else
        irc.privmsg(c, 'NickServ', 'identify ' .. ms.nickpass)
    end

    local keepalive = true
    while keepalive do
        local data = c:receive('*l')
        if data then
            if ms.debug then io.stdout:write(data .. '\n') end

            if data == ('PING ' .. sname) then
                irc.pong(c, sname)
            elseif data:find('PRIVMSG') then
                keepalive = irc.react_to_privmsg(c, ms, data)
            elseif data:find('^:NickServ.*NOTICE.*You are now identified for %S+%.$') then
                irc.joinall(c, ms.irc_network)
            end
        end
    end
end

irc.main = function (ms)
    local c = irc.init(ms.irc_network)
    if not c then
        print('failed to initialize irc network')
        return
    end

    db = nil
    ms.irc_factoids.init(ms.irc_network.dbpath)

    irc.conn(c, ms.irc_network)

    local sname = irc.get_sname(c, ms)

    irc.react_loop(c, sname, ms)
    ms.irc_factoids.cleanup()
    c:close()
end

return irc
