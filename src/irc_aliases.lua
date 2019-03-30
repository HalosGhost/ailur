local mediawiki_alias = require 'mediawiki_alias'

local aliases = {}

aliases['ug[maen]'] = function (ms, t, msg, _, s)
    local map = { ['m'] = 'Morning'
                , ['a'] = 'Afternoon'
                , ['e'] = 'Evening'
                , ['n'] = 'Night'
                }
    local _, _, l = msg:find('ug(.)')
    ms.irc.privmsg(t, ('%s says “Good (ᴜɢᴛ) %s to all!”'):format(s, map[l]))
end

aliases['%-?%d+%.?%d*%s*.+%s+in%s+.+'] = function (ms, t, msg)
    local _, _, val, src, dest = msg:find('(%-?%d+%.?%d*)%s*(.+)%s+in%s+(.+)')
    local config =  ms.config or ms.default_config
    if config.debug then
        print(val, src, dest)
    end

    if not tonumber(val) then
        ms.irc.privmsg(t, val .. ' is not a number I recognize')
        return
    end
    val = tonumber(val)

    if src == dest then
        ms.irc.privmsg(t, ('… %g %s… obviously…'):format(val, src))
        return
    end

    local src_unit, pos = ms.units.parse_unit(src)
    if src_unit == '' or not ms.units.conversion[src_unit] then
        ms.irc.privmsg(t, 'I cannot convert ' .. src)
        return
    end

    local val_adj = 1
    if pos > 1 then
        local prefix = src:sub(1, pos - 1)
        val_adj = ms.units.parse_prefix(prefix, ms.units.si_aliases, 10, ms.units.si)
        val_adj = val_adj or
        ms.units.parse_prefix(prefix, ms.units.iec_aliases, 2, ms.units.iec)
    end
    if config.debug then print(val_adj) end

    local dest_unit, pos = ms.units.parse_unit(dest)

    if src_unit ~= dest_unit and (dest_unit == '' or not ms.units.conversion[src_unit][dest_unit]) then
        if config.debug then print(dest_unit) end
        ms.irc.privmsg(t, ('I cannot convert %s to %s'):format(src, dest))
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

    ms.irc.privmsg(t, ('%g %s is %g %s%s'):format(val, src, new_val, dest_prefix, dest_unit))
end

aliases['units%s*.*'] = function (ms, t, msg)
    local list = ''
    local _, _, what = msg:find('units%s*(.*)')

    local the_table
    if not what then
        the_table = ms.units.conversion
    else
        the_table = ms.units.conversion[what] or ms.units.conversion
    end

    for k in pairs(the_table) do
        list = ("'%s' %s"):format(k, list)
    end; ms.irc.privmsg(t, list)
end

aliases['say%s+.+'] = function (ms, t, msg)
    local _, _, m = msg:find('say%s+(.+)')
    ms.irc.privmsg(t, m)
end

aliases['act%s+.+'] = function (ms, t, msg)
    local _, _, m = msg:find('act%s+(.+)')
    ms.irc.privmsg(t, ('\x01ACTION %s\x01'):format(m))
end

aliases['give%s+%S+.+'] = function (ms, t, msg, _, sndr)
    local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
    if what then
        local thing = nil
        if type(ms.plugins.fact) == 'table' and type(ms.plugins.fact.find) == 'function' then
            thing = ms.plugins.fact.find(what:gsub("^%s*(.-)%s*$", "%1"))
        end
        ms.irc.privmsg(t, to .. ': ' .. (thing or (sndr .. ' wanted you to have ' .. what)))
    end
end

aliases['you.*'] = function (ms, t, msg, _, sndr)
    local _, _, attr = msg:find('you(.*)')
    ms.irc.privmsg(t, ('%s: No, \x1Dyou\x1D%s!'):format(sndr, attr or ''))
end

aliases['bloat%s*.*'] = function (ms, t, msg, _, sndr)
    local _, _, target = msg:find('bloat%s*(.*)')
    target = target == '' and sndr or target
    ms.irc.privmsg(t, target .. ' is bloat.')
end

aliases['[ <]?https?://[^> ]+.*'] = function (ms, t, msg)
    local _, _, url = msg:find('[ <]?(https?://[^> ]+).*')
    if url then
        local title = ms.get_url_title(url)
        ms.irc.privmsg(t, title)
    end
end

aliases['rot13%s.*'] = function (ms, t, msg)
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

        ms.irc.privmsg(t, rotted)
    end
end

aliases['judges'] = function (ms, t, _, _, sndr)
    ms.irc.privmsg(t, ('So close, but %s won by a nose!'):format(sndr))
end

aliases['wiki%s+.+'] = mediawiki_alias('wiki%s+(.+)', 'https://en.wikipedia.org/w/api.php')

aliases['archwiki%s+.+'] = mediawiki_alias('archwiki%s+(.+)', 'https://wiki.archlinux.org/api.php')

aliases["pick%s+.+"] = function (ms, t, msg)
    local _, _, str = msg:find("pick%s+(.+)")
    local words = {}
    if str then
        for i in str:gmatch("%S+") do
            words[#words + 1] = i
        end
    end
    local r = math.random(#words)
    ms.irc.privmsg(t, words[r])
end

return aliases
