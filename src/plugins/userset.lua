local plugin = {}

plugin.commands = {}

plugin.commands.get = function (args, plugin, setting)
    local res, err = modules.users.get_setting(args.usermask, plugin, setting)
    modules.irc.privmsg(args.target, res or ('error: ' .. err))
end

plugin.commands.set = function (args, plugin, setting, value)
    if value == 'true' then
        value = true
    elseif value == 'false' then
        value = false
    elseif tonumber(value) then
        value = tonumber(value)
    end

    local res, err = modules.users.set_setting(args.usermask, plugin, setting, value)
    modules.irc.privmsg(args.target, res or ('error: ' .. err))
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: userset <%s> [plugin.setting [value]]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action, plugin_name, setting, value = args.message:find('(%S+)%s+(%S+)%.(%S+)%s*(.*)')
    if not args.authorized then return end

    local f = plugin.commands[action]
    if f then return f(args, plugin_name, setting, value) end

    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
