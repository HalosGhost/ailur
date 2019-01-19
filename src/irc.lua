local irc = {}

local socket = require 'socket'
local ssl = require 'ssl'
local sql = require 'lsqlite3'

irc.init = function (irc_config)
    local bare = socket.connect(irc_config.address, irc_config.port)
    local conn = ssl.wrap(bare, irc_config.sslparams)
    conn:dohandshake()
    return conn
end

irc.conn = function (c, irc_config)
    c:send(('NICK %s\r\n'):format(irc_config.handle))
    c:send(('USER %s * 8 :%s\r\n'):format(irc_config.ident, irc_config.gecos))
end

irc.join = function (c, channel)
    c:send(('JOIN %s\r\n'):format(channel))
end

irc.joinall = function (c, channels)
    for _, v in pairs(channels) do
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
        if ms.config.debug and data then print(data) end

        if data and (data:find('376') or data:find('422')) then
            _, _, sname = data:find('(%S+)')
        end
    end

    return sname
end

irc.authorized = function (c, irc_config, mask)
    local authed = nil
    for k in pairs(irc_config.admins) do
        authed = authed or mask:find(k)
    end

    return authed
end

irc.react_to_privmsg = function (c, ms, text)
    local ptn = '^:([^!]+)(%S+) %S+ (%S+) :(.*)'
    local _, _, mask, hn, target, msg = text:find(ptn)
    local authed = irc.authorized(c, ms.config.irc, mask .. hn)

    local tgt = target:find('^#') and target or mask
    local prefix = '^' .. (tgt:find('^#') and ms.config.irc.handle .. '.?%s+' or '')

    if not msg:find(prefix) then return true end

    local _, _, key = msg:find(prefix .. '(.*)')
    if not key then return true end
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

    if ms.nickpass then
        irc.privmsg(c, 'NickServ', 'identify ' .. ms.nickpass)
    else
        irc.joinall(c, ms.config.irc.channels)
    end

    local keepalive = true
    while keepalive do
        local data = c:receive('*l')
        if data then
            if ms.config.debug then io.stdout:write(data .. '\n') end

            if data == ('PING ' .. sname) then
                irc.pong(c, sname)
            elseif data:find('PRIVMSG') then
                keepalive = irc.react_to_privmsg(c, ms, data)
            elseif data:find('^:NickServ.*NOTICE.*You are now identified for %S+%.$') then
                irc.joinall(c, ms.config.irc.channels)
            end
        end
    end
end

irc.main = function (ms)
    local c = irc.init(ms.config.irc)
    if not c then
        print('failed to initialize irc network')
        return
    end

    db = nil
    ms.irc_factoids.init(ms.config.dbpath)

    irc.conn(c, ms.config.irc)

    local sname = irc.get_sname(c, ms)

    irc.react_loop(c, sname, ms)
    ms.irc_factoids.cleanup()
    c:close()
end

return irc
