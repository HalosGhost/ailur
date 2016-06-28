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

    if msg:find(prefix .. 'reload .+') and authed then
        local _, _, what = msg:find('reload (.+)')
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
    elseif msg:find(prefix .. 'die') and authed then
        c:close()
        os.exit()
    elseif msg:find(prefix .. 'listfacts') then
        local list = ''
        for k in pairs(ms['irc_factoids']) do
            list = "'" .. k .. "' " .. list
        end
        irc.privmsg(c, tgt, list)
    else
        for k, v in pairs(ms['irc_factoids']) do
            if msg:find(prefix .. k .. '$') then
                v(ms, c, tgt, msg)
            end
        end
    end

    return true
end

irc.react_loop = function (c, nw, sname, ms, hotload)
    local keepalive = true
    while keepalive do
        local data = c:receive('*l')

        if data == ('PING ' .. sname) then
            irc.pong(c, sname)
        elseif data:find('PRIVMSG') then
            keepalive = irc.react_to_privmsg(c, nw, ms, hotload, data)
        end
    end
end

irc.bot = function (ms, hotload)
    local nw = ms['irc_network']
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
