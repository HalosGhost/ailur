local irc = {}

local socket = require 'socket'
local ssl = require 'ssl'

irc.init = function (irc_config)
    local bare = socket.connect(irc_config.address, irc_config.port)
    local conn = ssl.wrap(bare, irc_config.sslparams)
    conn:dohandshake()
    return conn
end

irc.conn = function (irc_config)
    irc.connection:send(('NICK %s\r\n'):format(irc_config.handle))
    irc.connection:send(('USER %s * 8 :%s\r\n'):format(irc_config.ident, irc_config.gecos))
end

irc.join = function (channel)
    irc.connection:send(('JOIN %s\r\n'):format(channel))
end

irc.joinall = function (channels)
    for _, v in pairs(channels) do
        irc.join(v)
    end
end

irc.pong = function (sname)
    irc.connection:send(('PONG %s\r\n'):format(sname))
end

irc.privmsg = function (target, msg)
    irc.connection:send(('PRIVMSG %s :%s\r\n'):format(target, msg))
end

irc.modeset = function (target, recipient, mode)
    if target:byte() == 35 then
        irc.connection:send(('MODE %s %s %s\r\n'):format(target, mode, recipient))
    else
        irc.privmsg(target, 'Cannot set modes in query')
    end
end

irc.kick = function (target, recipient, message)
    if target:byte() == 35 then
        irc.connection:send(('KICK %s %s :%s\r\n'):format(target, recipient, message))
    else
        irc.privmsg(target, 'Cannot kick in query')
    end
end

irc.get_sname = function (ms, config)
    local sname = ''
    while sname == '' do
        local data = irc.connection:receive('*l')
        if config.debug and data then print(data) end

        if data and (data:find('376') or data:find('422')) then
            _, _, sname = data:find('(%S+)')
        end
    end

    return sname
end

irc.authorized = function (irc_config, mask)
    local authed = nil
    for k in pairs(irc_config.admins) do
        authed = authed or mask:find(k)
    end

    return authed
end

irc.react_to_privmsg = function (ms, config, text)
    local ptn = '^:([^!]+)(%S+) %S+ (%S+) :(.*)'
    local _, _, mask, hn, target, msg = text:find(ptn)
    local authed = irc.authorized(config.irc, mask .. hn)
    local from_channel = target:find('^#')

    -- if whitelisted, put nick's last message in quotegrabs table
    if ms.plugins.quote and from_channel and ms.plugins.quote.whitelist_status(mask) then
        -- create the table for the channel if it doesn't exist
        if not ms.plugins.quote.last_msgs[target] then
            ms.plugins.quote.last_msgs[target] = {}
        end

        ms.plugins.quote.last_msgs[target][mask] = msg
    end

    local tgt = from_channel and target or mask
    local prefix = '^' .. (tgt:find('^#') and config.irc.handle .. '.?%s+' or '')

    if not msg:find(prefix) and ms.plugins.macro then
        for _, macro in ipairs(ms.plugins.macro.loaded or {}) do
            msg = msg:gsub(macro.pattern, macro.substitution)
        end
    end

    if not msg:find(prefix) then return true end

    local _, _, key = msg:find(prefix .. '(.-)%s*$')
    if not key then return true end

    local _, _, namespace, command = key:find('%s*(%S+)%s*(.*)')
    local basic = nil
    if type(ms.plugins.fact) == 'table' and type(ms.plugins.fact.find) == 'function' then
        basic = ms.plugins.fact.find(key:gsub("^%s*(.-)%s*$", "%1"))
    end

    local plugin = nil
    for k in pairs(ms.plugins) do
        if k == namespace then
            plugin = ms.plugins[namespace]
            break
        end
    end

    if plugin then
        local ret = plugin.main { modules = ms
                                , target = tgt
                                , message = command
                                , authorized = authed
                                , sender = mask
                                }

        if ret then return false end
    elseif basic ~= nil then
        irc.privmsg(tgt, basic)
    else
        for k, v in pairs(ms.irc_aliases) do
            if key:find('^%s*' .. k .. '$') then
                local ret = v(ms, tgt, key, authed, mask)
                if ret then return false end
            end
        end
    end

    return true
end

irc.react_loop = function (sname, ms, config)
    math.randomseed(os.time())

    if ms.nickpass then
        irc.privmsg('NickServ', 'identify ' .. ms.nickpass)
        ms.nickpass = nil -- make it harder to accidentally expose the nickpass, like with eval
    else
        irc.joinall(config.irc.channels)
    end

    local keepalive = true
    while keepalive do
        local data = irc.connection:receive('*l')
        if data then
            if config.debug then io.stdout:write(data .. '\n') end

            if data == ('PING ' .. sname) then
                irc.pong(sname)
            elseif data:find('PRIVMSG') then
                keepalive = irc.react_to_privmsg(ms, config, data)
            elseif data:find('^:NickServ.*NOTICE.*You are now identified for %S+%.$') then
                irc.joinall(config.irc.channels)
            end
        end
    end
end

irc.main = function (ms)
    local config = ms.config or ms.default_config

    irc.connection = irc.init(config.irc)

    if not irc.connection then
        print('failed to initialize irc network')
        return
    end

    ms.database.init(ms, config)

    irc.conn(config.irc)

    local sname = irc.get_sname(ms, config)

    irc.react_loop(sname, ms, config)
    ms.database.cleanup(ms)
    irc.connection:close()
end

return irc
