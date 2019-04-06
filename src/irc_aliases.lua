local aliases = {}

aliases['say%s+.+'] = function (t, msg)
    local _, _, m = msg:find('say%s+(.+)')
    modules.irc.privmsg(t, m)
end

aliases['act%s+.+'] = function (t, msg)
    local _, _, m = msg:find('act%s+(.+)')
    modules.irc.privmsg(t, ('\x01ACTION %s\x01'):format(m))
end

aliases['give%s+%S+.+'] = function (t, msg, _, sndr)
    local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
    if what then
        local thing = nil
        if type(modules.plugins.fact) == 'table' and type(modules.plugins.fact.find) == 'function' then
            thing = modules.plugins.fact.find(what:gsub("^%s*(.-)%s*$", "%1"))
        end
        modules.irc.privmsg(t, to .. ': ' .. (thing or (sndr .. ' wanted you to have ' .. what)))
    end
end

return aliases
