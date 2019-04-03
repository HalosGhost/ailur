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

aliases['judges'] = function (ms, t, _, _, sndr)
    ms.irc.privmsg(t, ('So close, but %s won by a nose!'):format(sndr))
end

return aliases
