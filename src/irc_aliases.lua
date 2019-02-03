local mediawiki_alias = require 'mediawiki_alias'

local aliases = {}

aliases['ug[maen]'] = function (ms, c, t, msg, _, s)
    local map = { ['m'] = 'Morning'
                , ['a'] = 'Afternoon'
                , ['e'] = 'Evening'
                , ['n'] = 'Night'
                }
    local _, _, l = msg:find('ug(.)')
    ms.irc.privmsg(c, t, s .. ' says “Good (ugt) ' .. map[l] .. ' to all!”')
end

aliases['fact count%s*.*'] = function (ms, c, t, msg)
    local _, _, key = msg:find('fact count%s*(.*)')
    ms.irc.privmsg(c, t, ms.irc_factoids.count(key))
end

aliases['fact search%s*.*'] = function (ms, c, t, msg)
    local _, _, key = msg:find('fact search%s*(.*)')
    ms.irc.privmsg(c, t, ms.irc_factoids.search(key))
end

aliases['%-?%d+%.?%d*%s*.+%s+in%s+.+'] = function (ms, c, t, msg)
    local _, _, val, src, dest = msg:find('(%-?%d+%.?%d*)%s*(.+)%s+in%s+(.+)')
    if ms.config.debug then
        print(val, src, dest)
    end

    if not tonumber(val) then
        ms.irc.privmsg(c, t, val .. ' is not a number I recognize')
        return
    end
    val = tonumber(val)

    if src == dest then
        ms.irc.privmsg(c, t, ('… %g %s… obviously…'):format(val, src))
        return
    end

    local src_unit, pos = ms.units.parse_unit(src)
    if src_unit == '' or not ms.units.conversion[src_unit] then
        ms.irc.privmsg(c, t, 'I cannot convert ' .. src)
        return
    end

    local val_adj = 1
    if pos > 1 then
        local prefix = src:sub(1, pos - 1)
        val_adj = ms.units.parse_prefix(prefix, ms.units.si_aliases, 10, ms.units.si)
        val_adj = val_adj or
        ms.units.parse_prefix(prefix, ms.units.iec_aliases, 2, ms.units.iec)
    end
    if ms.config.debug then print(val_adj) end

    local dest_unit, pos = ms.units.parse_unit(dest)

    if src_unit ~= dest_unit and (dest_unit == '' or not ms.units.conversion[src_unit][dest_unit]) then
        if ms.config.debug then print(dest_unit) end
        ms.irc.privmsg(c, t, ('I cannot convert %s to %s'):format(src, dest))
        return
    end

    local dest_adj = 1
    local dest_prefix = ''
    if pos > 1 then
        dest_prefix = dest:sub(1, pos - 1)
        dest_adj = ms.units.parse_prefix(dest_prefix, ms.units.si_aliases, 10, ms.units.si)
        dest_adj = dest_adj or
        ms.units.parse_prefix(dest_prefix, ms.units.iec_aliases, 2, ms.units.iec)
    end

    local new_val = src_unit == dest_unit
    and (val_adj * val / dest_adj)
    or (ms.units.conversion[src_unit][dest_unit](val_adj * val) / dest_adj)

    ms.irc.privmsg(c, t, ('%g %s is %g %s%s'):format(val, src, new_val, dest_prefix, dest_unit))
end

aliases['units%s*.*'] = function (ms, c, t, msg)
    local list = ''
    local _, _, what = msg:find('units%s*(.*)')

    local the_table
    if not what then
        the_table = ms.units.conversion
    else
        the_table = ms.units.conversion[what] or ms.units.conversion
    end

    for k in pairs(the_table) do
        list = "'" .. k .. "' " .. list
    end; ms.irc.privmsg(c, t, list)
end

aliases['is.*'] = function (ms, c, t)
    local prob = { 'certainly', 'possibly', 'categorically', 'negatively'
                 , 'positively', 'without-a-doubt', 'maybe', 'perhaps', 'doubtfully'
                 , 'likely', 'definitely', 'greatfully', 'thankfully', 'undeniably'
                 , 'arguably'
                 }

    local case = { 'so', 'not', 'true', 'false' }
    local punct = { '.', '!', '…' }

    local r1 = math.random(#prob)
    local r2 = math.random(#case)
    local r3 = math.random(#punct)
    ms.irc.privmsg(c, t, prob[r1] .. ' ' .. case[r2] .. punct[r3])
end

aliases['say%s+.+'] = function (ms, c, t, msg)
    local _, _, m = msg:find('say%s+(.+)')
    ms.irc.privmsg(c, t, m)
end

aliases['act%s+.+'] = function (ms, c, t, msg)
    local _, _, m = msg:find('act%s+(.+)')
    ms.irc.privmsg(c, t, ('\x01ACTION %s\x01'):format(m))
end

aliases['give%s+%S+.+'] = function (ms, c, t, msg, _, sndr)
    local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
    if what then
        local thing = ms.irc_factoids.find(what:gsub("^%s*(.-)%s*$", "%1"))
        ms.irc.privmsg(c, t, to .. ': ' .. (thing or (sndr .. ' wanted you to have ' .. what)))
    end
end

aliases['hatroulette'] = function (ms, c, t, _, _, sndr)
    local ar = { '-', '+' }
    local md = { 'q', 'b', 'v', 'o', 'kick'}
    local mode_roll = md[math.random(#md)]

    if mode_roll == 'kick' then
        ms.irc.privmsg(c, t, sndr .. ' rolls for a kick!')
        ms.irc.kick(c, t, sndr, 'You asked for this')
        return
    end

    local res = ar[math.random(#ar)] .. mode_roll

    if t:byte() == 35 then
        ms.irc.privmsg(c, t, sndr .. ' rolls for a ' .. res .. '!')
    end

    ms.irc.modeset(c, t, sndr, res)
end

aliases['you.*'] = function (ms, c, t, msg, _, sndr)
    local _, _, attr = msg:find('you(.*)')
    ms.irc.privmsg(c, t, ('%s: No, \x1Dyou\x1D%s!'):format(sndr, attr or ''))
end

aliases['test%s*.*'] = function (ms, c, t, msg)
    local _, _, test = msg:find('test%s*(.*)')
    test = test == '' and test or (' ' .. test)

    local prob = math.random()
    local rest = { '3PASS', '5FAIL', '5\x02PANIC\x02' }
    local res = prob < 0.01 and rest[3] or
    prob < 0.49 and rest[2] or rest[1]

    ms.irc.privmsg(c, t, ('Testing%s: [\x03%s\x03]'):format(test, res))
end

aliases['roll%s+%d+d%d+'] = function (ms, c, t, msg, _, sndr)
    local _, _, numdice, numsides = msg:find('roll%s*(%d+)d(%d+)')
    local rands = ''

    numdice = math.tointeger(numdice)
    numsides = math.tointeger(numsides)
    local invalid = function (n)
        return not (math.type(n) == 'integer' and n >= 1)
    end

    if invalid(numdice) or invalid(numsides) then return end

    for i=1,numdice do
        rands = ('%d %s'):format(math.random(numsides), rands)
        if rands:len() > 510 then break end
    end

    ms.irc.privmsg(c, t, ('%s: %s'):format(sndr, rands))
end

aliases['bloat%s*.*'] = function (ms, c, t, msg, _, sndr)
    local _, _, target = msg:find('bloat%s*(.*)')
    target = target == '' and sndr or target
    ms.irc.privmsg(c, t, target .. ' is bloat.')
end

aliases['[ <]?https?://[^> ]+.*'] = function (ms, c, t, msg)
    local _, _, url = msg:find('[ <]?(https?://[^> ]+).*')
    if url then
        local title = ms.get_url_title(url)
        ms.irc.privmsg(c, t, title)
    end
end

aliases['rot13%s.*'] = function (ms, c, t, msg)
    local _, _, text = msg:find('rot13%s(.*)')
    if text then
        local chars = {}
        for i=1,text:len() do
            chars[i] = text:byte(i)
        end

        local rotted = ""
        for i=1,#chars do
            local letter = chars[i]
            if letter >= 65 and letter < 91 then
                local offset = letter - 65
                letter = string.char(65 + ((offset + 13) % 26))
            elseif letter >= 97 and letter < 123 then
                local offset = letter - 97
                letter = string.char(97 + ((offset + 13) % 26))
            else
                letter = string.char(chars[i])
            end
            rotted = rotted .. letter
        end

        ms.irc.privmsg(c, t, rotted)
    end
end

aliases['judges'] = function (ms, c, t, _, _, sndr)
    ms.irc.privmsg(c, t, ('So close, but %s won by a nose!'):format(sndr))
end

aliases['join%s+%S+'] = function (ms, c, t, msg, authed)
    if authed then
        local _, _, chan = msg:find('join%s+(%S+)')
        if chan then
            ms.irc.join(c, chan)
            ms.irc.privmsg(c, t, 'Tada!')
        end
    end
end

aliases['wiki%s+.+'] = mediawiki_alias('wiki%s+(.+)', 'https://en.wikipedia.org/w/api.php')

aliases['archwiki%s+.+'] = mediawiki_alias('archwiki%s+(.+)', 'https://wiki.archlinux.org/api.php')

aliases["'.+' is '.+'"] = function (ms, c, t, msg)
    local _, _, key, val = msg:find("'(.+)' is '(.+)'")
    if not key or not val then
        ms.irc.privmsg(c, t, '… what?')
    else
        ms.irc_factoids.add(key, val)
        ms.irc.privmsg(c, t, 'Tada!')
    end
end

aliases["'.+' is nothing"] = function (ms, c, t, msg)
    local _, _, key = msg:find("'(.+)' is nothing")
    if not key then
        ms.irc.privmsg(c, t, '… what?')
    else
        ms.irc_factoids.remove(key)
        ms.irc.privmsg(c, t, 'Tada!')
    end
end

aliases["pick%s+.+"] = function (ms, c, t, msg)
    local _, _, str = msg:find("pick%s+(.+)")
    local words = {}
    if str then
        for i in str:gmatch("%S+") do
            words[#words + 1] = i
        end
    end
    local r = math.random(#words)
    ms.irc.privmsg(c, t, words[r])
end

aliases['uptime'] = function (ms, c, t)
    local upt = io.popen('uptime -p')
    ms.irc.privmsg(c, t, upt:read())
    upt:close()
end

aliases['config%s+%S+%s+%S+%s*%S*'] = function (ms, c, t, msg, authed)
    if not authed then return end

    local _, _, action, setting, value = msg:find('config%s+(%S+)%s+(%S+)%s*(%S*)')

    if action == 'toggle' and type(ms.config[setting]) == 'boolean' then
        ms.config[setting] = not ms.config[setting]
        ms.irc.privmsg(c, t, ('set %s to %s. Tada!'):format(setting, ms.config[setting]))
    elseif action == 'get' then
        ms.irc.privmsg(c, t, tostring(ms.config[setting]))
    elseif action == 'type' then
        ms.irc.privmsg(c, t, type(ms.config[setting]))
    elseif action == 'set' then
        if value == 'true' then
            ms.config[setting] = true
        elseif value == 'false' then
            ms.config[setting] = false
        elseif tonumber(value) ~= nil then
            ms.config[setting] = tonumber(value)
        else
            ms.config[setting] = value
        end

        ms.irc.privmsg(c, t, 'Tada!')
    end
end

aliases['whitelist%s+%S+%s*%S*'] = function (ms, c, t, msg, _, sender)
    local _, _, action, nick = msg:find('whitelist%s+(%S+)%s*(%S*)')

    if action == 'status' and nick == '' then
        local result = ms.irc_quotegrabs.whitelist_status(sender) and 'in' or 'out'
        ms.irc.privmsg(c, t, ('%s: you are opted-%s for quotegrabs.'):format(sender, result))
    elseif action == 'status' and nick ~= '' then
        local result = ms.irc_quotegrabs.whitelist_status(nick) and 'in' or 'out'
        ms.irc.privmsg(c, t, ('%s is opted-%s for quotegrabs.'):format(nick, result))
    elseif action == 'optin' then
        ms.irc_quotegrabs.whitelist_add(sender)
        ms.irc.privmsg(c, t, sender .. ': Tada! You opted-in for quotegrabs.')
    elseif action == 'optout' then
        ms.irc_quotegrabs.whitelist_del(sender)
        ms.irc.privmsg(c, t, sender .. ': Tada! You opted-out of quotegrabs.')
    else
        ms.irc.privmsg(c, t, 'whitelist [status|optin|optout]')
    end
end

aliases['grab%s+%S+'] = function (ms, c, t, msg, _, sender)
    local _, _, nick = msg:find('grab%s+(%S+)')
    if nick == sender then return end

    local last_msg = ms.irc_quotegrabs.last_msgs[t][nick]
    if not last_msg then return end

    ms.irc_quotegrabs.add(nick, last_msg)
    ms.irc.privmsg(c, t, 'Tada!')
end

aliases['q%S*%s*%S*'] = function (ms, c, t, msg, authed)
    local _, _, action, target = msg:find('q(%S*)%s*(%S*)')
    local id, nick, quote

    if action == '' then
        id, nick, quote = ms.irc_quotegrabs.quote_nick(target)
    elseif (action == 'id' or action == 'i') and target ~= '' then
        id, nick, quote = ms.irc_quotegrabs.quote_id(target)
    elseif (action == 'rand' or action == 'r') then
        id, nick, quote = ms.irc_quotegrabs.quote_rand(target)
    elseif (action == 'search' or action == 's') then
        ms.irc.privmsg(c, t, ms.irc_quotegrabs.quote_search(target))
    elseif (action == 'delete' or action == 'd') and target ~= '' then
        if not authed then return end
        ms.irc.privmsg(c, t, ms.irc_quotegrabs.delete(target))
    else
        ms.irc.privmsg(c, t, 'q[id|rand|search|delete|help] [target]')
    end

    if id and nick and quote then
        ms.irc.privmsg(c, t, ('<%s> %s'):format(nick, quote))
    end
end

return aliases
