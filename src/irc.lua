local irc = {}

local socket = require 'socket'

irc.init = function (stbl)
    local c = socket.connect(stbl.address, stbl.port)
    return c
end

irc.conn = function (c, stbl)
    c:send('NICK ' .. stbl.handle .. '\r\n')
    c:send('USER ' .. stbl.ident  .. ' * 8 :' .. stbl.gecos .. '\r\n')
end

irc.joinall = function (c, stbl)
    for _, v in pairs(stbl.channels) do
        c:send('JOIN ' .. v .. '\r\n')
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

irc.get_sname = function (c)
    local sname = ''
    while sname == '' do
        local data = c:receive('*l')

        if data:find('376') or data:find('422') then
            _, _, sname = data:find('(%S+)')
        end
    end

    return sname
end

irc.authorized = function (c, nw, mask)
    local authed = nil
    for _, v in pairs(nw.admins) do
        authed = authed or mask:find(v)
    end

    return authed
end

irc.react_to_privmsg = function (c, nw, ms, hotload, text)
    local ptn = '^:([^!]+)(%S+) %S+ (%S+) :(.*)'
    local _, _, mask, hn, target, msg = text:find(ptn)
    local authed = irc.authorized(c, nw, mask .. hn)

    local tgt = target:find('^#') and target or mask
    local prefix = tgt:find('^#') and '^hgctl.%s*' or '^'

    if not msg:find(prefix) then return true end

    local _, _, key = msg:find(prefix .. '(.*)')
    local basic = ms.irc_factoids[key]

    if basic ~= nil then
        irc.privmsg(c, tgt, basic)
    elseif key:find('^%s*reload .+') and authed then
        local _, _, what = key:find('reload (.+)')
        if what == 'all' then
            irc.privmsg(c, tgt, 'Tada!')
            return false
        else
            for k in pairs(ms) do
                if what == k then
                    irc.privmsg(c, tgt, 'Tada!')
                    hotload(ms, k)
                end
            end
        end
    else
        for k, v in pairs(ms.irc_aliases) do
            if key:find('^%s*' .. k .. '$') then
                v(ms, c, tgt, key, authed, mask)
            end
        end
    end

    return true
end

irc.react_loop = function (c, nw, sname, ms, hotload)
    math.randomseed(os.time())

    local keepalive = true
    while keepalive do
        local data = c:receive('*l')
        io.stdout:write(ms.debug and data .. '\n' or '')

        if data == ('PING ' .. sname) then
            irc.pong(c, sname)
        elseif data:find('PRIVMSG') then
            keepalive = irc.react_to_privmsg(c, nw, ms, hotload, data)
        end
    end
end

irc.bot = function (ms, hotload)
    local nw = ms.irc_network
    local c = irc.init(nw)
    if not c then
        print('failed to initialize irc network')
        return
    end

    irc.conn(c, nw)

    local sname = irc.get_sname(c)
    irc.joinall(c, nw)

    irc.react_loop(c, nw, sname, ms, hotload)
    c:close()
end

return irc
