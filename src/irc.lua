local irc = {}

local modules = modules
local plugins
local socket = require 'socket'
local ssl = require 'ssl'

irc.init = function (irc_config)
    local bare = socket.connect(irc_config.address, irc_config.port)
    if irc_config.use_ssl then
        local conn = ssl.wrap(bare, irc_config.sslparams)
        conn:dohandshake()
        return conn
    else
        print("WARNING: You have not configured TLS; Your connection will be insecure!")
        return bare
    end
end

irc.conn = function (irc_config)
    irc.connection:send(('NICK %s\r\n'):format(irc_config.handle))
    irc.connection:send(('USER %s * 8 :%s\r\n'):format(irc_config.ident, irc_config.gecos))
end

irc.action = function (target, msg)
    irc.connection:send(('PRIVMSG %s :\x01ACTION %s\x01\r\n'):format(target, msg))
end

irc.ctcp = function (client, query)
    -- VERSION, PING, SOURCE, CLIENTINFO, USERINFO, TIME, DCC are common
    -- clients can also add their own.
    -- https://tools.ietf.org/id/draft-oakley-irc-ctcp-01.html#rfc.appendix.A.2
    irc.connection:send(('PRIVMSG %s :\x01%s\x01\r\n'):format(target, query))
end

irc.invite = function (recipient, channel)
    irc.connection:send(('INVITE %s %s\r\n'):format(recipient, channel))
end

irc.join = function (channel)
    irc.connection:send(('JOIN %s\r\n'):format(channel))
end

irc.joinall = function (channels)
    for _, v in pairs(channels) do
        irc.join(v)
    end
end

irc.kick = function (target, recipient, message)
    if target:byte() == 35 then
        irc.connection:send(('KICK %s %s :%s\r\n'):format(target, recipient, message))
    else
        irc.privmsg(target, 'Cannot kick in query')
    end
end

irc.mode = function (target, recipient, mode)
    if target:byte() == 35 then
        irc.connection:send(('MODE %s %s %s\r\n'):format(target, mode, recipient))
    else
        irc.privmsg(target, 'Cannot set modes in query')
    end
end

irc.names = function (channel)
    irc.connection:send(('NAMES %s\r\n'):format(channel))
end

irc.nick = function (nickname)
    irc.connection:send(('NICK %s\r\n'):format(nickname))
end

irc.notice = function (target, msg)
    irc.connection:send(('NOTICE %s :%s\r\n'):format(target, msg))
end

irc.part = function (channel)
    irc.connection:send(('PART %s\r\n'):format(channel))
end

irc.pong = function (sname)
    irc.connection:send(('PONG %s\r\n'):format(sname))
end

irc.privmsg = function (target, msg)
    irc.connection:send(('PRIVMSG %s :%s\r\n'):format(target, msg))
end

irc.quit = function (msg)
    irc.connection:send(('QUIT %s\r\n'):format(msg))
    irc.connection:close()
end

irc.topic = function (channel, msg)
    irc.connection:send(('TOPIC %s %s\r\n'):format(channel, msg))
end

irc.get_sname = function (config)
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

irc.react_to_privmsg = function (config, text)
    local ptn = '^:(%S-)!(%S-)@(%S-) %S+ (%S+) :(.*)'
    local _, _, nick, user, host, target, msg = text:find(ptn)
    local usermask = ('%s@%s'):format(user, host)
    local authed = modules.users.is_admin(usermask)
    local from_channel = target:find('^#')

    -- if whitelisted, put nick's last message in quotegrabs table
    if plugins.quote and from_channel and plugins.quote.whitelist_status(nick) then
        -- create the table for the channel if it doesn't exist
        if not plugins.quote.last_msgs[target] then
            plugins.quote.last_msgs[target] = {}
        end

        plugins.quote.last_msgs[target][nick] = msg
    end

    local tgt = from_channel and target or nick
    local prefix = '^' .. (tgt:find('^#') and config.irc.handle .. '.?%s+' or '')

    if not msg:find(prefix) and plugins.macro then
        for _, macro in ipairs(plugins.macro.loaded or {}) do
            msg = msg:gsub(macro.pattern, macro.substitution)
        end
    end

    if not msg:find(prefix) then return true end

    local _, _, key = msg:find(prefix .. '(.-)%s*$')
    if not key then return true end

    local _, _, namespace, command = key:find('%s*(%S+)%s*(.*)')
    local basic = nil
    if type(plugins.fact) == 'table' and type(plugins.fact.find) == 'function' then
        basic = plugins.fact.find(key:gsub("^%s*(.-)%s*$", "%1"))
    end

    local plugin = plugins[namespace]
    if plugin then
        -- catch lua errors for poorly-written plugins
        local lua_success, data = pcall(plugin.main, { conf = config
                                                     , target = tgt
                                                     , message = command
                                                     , authorized = authed
                                                     , sender = nick
                                                     , sender_user = user
                                                     , sender_host = host
                                                     , usermask = usermask
                                                     })

        if not lua_success then
            -- display lua error message
            irc.privmsg(tgt, data)
        elseif data then
            -- restart bot
            return false
        end
    elseif basic ~= nil then
        irc.privmsg(tgt, basic)
    end

    return true
end

irc.react_loop = function (sname, config)
    math.randomseed(os.time())

    if modules.nickpass then
        irc.privmsg('NickServ', 'identify ' .. modules.nickpass)
        modules.nickpass = nil -- make it harder to accidentally expose the nickpass, like with eval
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
                keepalive = irc.react_to_privmsg(config, data)
            elseif data:find('^:NickServ.*NOTICE.*You are now identified for %S+%.$') then
                irc.joinall(config.irc.channels)
            end
        end
    end
end

irc.main = function ()
    local config = modules.config or modules.default_config
    plugins = modules.plugins

    irc.connection = irc.init(config.irc)

    if not irc.connection then
        print('failed to initialize irc network')
        return
    end

    modules.database.init(config)

    irc.conn(config.irc)

    local sname = irc.get_sname(config)

    irc.react_loop(sname, config)
    modules.database.cleanup()
    irc.connection:close()
end

return irc
