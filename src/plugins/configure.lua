local plugin = {}

plugin.commands = {}

plugin.commands.get = function (args)
    local _, _, setting = args.message:find('get%s+(%S+)')
    args.modules.irc.privmsg(args.target, tostring(args.modules.config[setting]))
end

plugin.commands.type = function (args)
    local _, _, setting = args.message:find('type%s+(%S+)')
    args.modules.irc.privmsg(args.target, type(args.modules.config[setting]))
end

plugin.commands.set = function (args)
    local _, _, setting, value = args.message:find("set%s+(%S+)%s*(%S*)")

    if value == 'true' then
        args.modules.config[setting] = true
    elseif value == 'false' then
        args.modules.config[setting] = false
    elseif tonumber(value) then
        args.modules.config[setting] = tonumber(value)
    else
        args.modules.config[setting] = value
    end

    args.modules.irc.privmsg(args.target, 'Tada!')
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: configure <%s> [setting] [value]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = plugin.commands[action]

    if args.authorized and f then return f(args) end

    args.modules.irc.privmsg(args.target, plugin.help)
end

return plugin
