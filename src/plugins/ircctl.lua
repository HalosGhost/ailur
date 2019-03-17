-- channel moderation

local ircctl = {}

ircctl.commands = {}

ircctl.commands.kick = function (args)
    local _, _, recipient, message = args.message:find('kick%s+(%S+)%s*(.*)')

    if args.modules.config.debug then print(('kicking %s'):format(recipient)) end
    args.modules.irc.kick(args.connection, args.target, recipient, message or recipient)
end

ircctl.commands['set-mode'] = function (args)
    local _, _, mode, recipient = args.message:find('([+-][bqvo])%s+(.+)')

    if args.modules.config.debug then print(('setting %s to %s'):format(recipient, mode)) end
    args.modules.irc.modeset(args.connection, args.target, recipient, mode)
end

ircctl.commands.join = function (args)
    local _, _, channel = args.message:find('join%s+(%S+)')

    if channel then
        args.modules.irc.join(args.connection, channel)
        args.modules.irc.privmsg(args.connection, args.target, ('Joined %s'):format(channel))
    end
end

ircctl.commands.hatroulette = function (args)
    local md = { 'q', 'b', 'v', 'o', 'kick'}
    local mode_roll = md[math.random(#md)]

    local ar = { '-', '+' }
    local mode_dir = mode_roll == 'kick' and '' or ar[math.random(#ar)]

    local mode = ('%s%s'):format(mode_dir, mode_roll)

    args.modules.irc.privmsg(args.connection, args.target, ('%s rolls for a %s!'):format(args.sender, mode))
    args.modules.irc[mode == 'kick' and 'kick' or 'modeset'](args.connection, args.target, args.sender, mode)
end

local h = ''
for k in pairs(ircctl.commands) do
    h = ('%s|%s'):format(h, k)
end
ircctl.help = ('usage: ircctl <%s>'):format(h:sub(2))

ircctl.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = ircctl.commands[action]

    if (args.authorized or f == 'hatroulette') and f then return f(args) end

    args.modules.irc.privmsg(args.connection, args.target, ircctl.help)
end

return ircctl
