-- channel moderation

local moderate = {}

moderate.kick = function (args)
    local _, _, recipient, message = args.message:find('kick%s+(%S+)%s*(.*)')

    if args.modules.config.debug then print(('kicking %s'):format(recipient)) end
    args.modules.irc.kick(args.connection, args.target, recipient, message or recipient)
end

moderate['set-mode'] = function (args)
    local _, _, mode, recipient = args.message:find('([+-][bqvo])%s+(.+)')

    if args.modules.config.debug then print(('setting %s to %s'):format(recipient, mode)) end
    args.modules.irc.modeset(args.connection, args.target, recipient, mode)
end

local h = ''
for k in pairs(moderate) do
    h = ('%s|%s'):format(h, k)
end
moderate.help = ('usage: moderate <%s>'):format(h:sub(2))

moderate.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = moderate[action]

    if args.authorized and f then return f(args) end

    args.modules.irc.privmsg(args.connection, args.target, moderate.help)
end

return moderate
