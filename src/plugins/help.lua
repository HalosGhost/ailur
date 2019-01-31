local help = {}

help.help = 'usage: help <plugin>'

help.main = function(args)
    local _, _, mod = args.message:find('(%S+)')

    if not mod then
        args.modules.irc.privmsg(args.connection, args.target, help.help)
        return
    end

    local usage = type(args.modules.plugins[mod]) == 'table'
        and args.modules.plugins[mod].help
        or 'No help available on that topic'

    if args.modules.config.debug then
        print(mod, args.modules.plugins[mod], usage)
    end

    args.modules.irc.privmsg(args.connection, args.target, usage)
end

return help
