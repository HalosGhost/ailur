local plugin = {}

plugin.help = 'usage: help <plugin>'

plugin.main = function(args)
    local _, _, mod, subarg = args.message:find('(%S+)%s*(%S*)')

    if not mod then
        args.modules.irc.privmsg(args.target, plugin.help)
        return
    end

    local usage = type(args.modules.plugins[mod]) == 'table'
        and args.modules.plugins[mod].help
        or 'No help available on that topic'

    local res = usage
    if type(usage) == 'function' then
        res = usage(subarg)
    elseif type(usage) == 'table' then
        res = usage[subarg or mod]
    end

    if args.conf.debug then
        print(mod, args.modules.plugins[mod], usage, res)
    end

    args.modules.irc.privmsg(args.target, res)
end

return plugin
