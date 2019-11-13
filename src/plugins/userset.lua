local modules = modules

local plugin = {}

plugin.commands = {}

-- Get the value of a user setting
plugin.commands.get = function (args, plugin_name, setting)
    if plugin_name == '' or setting == '' then
        modules.irc.privmsg(args.target, plugin.help)
        return
    end

    local res, err = modules.users.get_setting(args.usermask, plugin_name, setting)
    modules.irc.privmsg(args.target, res or ('error: ' .. err))
end

-- Set a user setting. The user does not need to already exist in the users table.
plugin.commands.set = function (args, plugin_name, setting, value)
    if plugin_name == '' or setting == '' or value == '' then
        modules.irc.privmsg(args.target, plugin.help)
        return
    end

    if value == 'true' or value == 'on' then
        value = true
    elseif value == 'false' or value == 'off' then
        value = false
    elseif tonumber(value) then
        value = tonumber(value)
    end

    local res, err = modules.users.set_setting(args.usermask, plugin_name, setting, value)
    modules.irc.privmsg(args.target, res or ('error: ' .. err))
end

-- List available user settings
plugin.commands.list = function (args, plugin_name)
    local tgt_plugin = modules.plugins[plugin_name]
    if plugin_name ~= '' and not tgt_plugin then
        modules.irc.privmsg(args.target, 'no such plugin')
        return
    end

    -- if the user supplied a plugin, just look at those
    local list_plugin_settings = tgt_plugin and type(tgt_plugin.user_settings) == 'table'
    if list_plugin_settings then
        local settings = {}
        for _, setting in pairs(tgt_plugin.user_settings) do
            local value = modules.users.get_setting(args.usermask, plugin_name, setting)
            if value then
                setting = setting .. (' = %s'):format(value)
            end

            settings[#settings+1] = setting
        end

        settings = table.concat(settings, ', ')
        modules.irc.privmsg(args.target, settings)
        return
    end

    local settings = {}
    for plugin_name, tgt_plugin in pairs(modules.plugins) do
        if type(tgt_plugin.user_settings) == 'table' then
            for _, setting in pairs(tgt_plugin.user_settings) do
                local element = ('%s.%s'):format(plugin_name, setting)
                local value = modules.users.get_setting(args.usermask, plugin_name, setting)
                if value then
                    element = element .. (' = %s'):format(value)
                end

                settings[#settings+1] = element
            end
        end
    end

    settings = table.concat(settings, ', ')
    modules.irc.privmsg(args.target, settings)
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: userset <%s> [plugin [setting [value]]]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action, plugin_name, setting, value =
        args.message:find('(%S+)%s*(%S*)%s*(%S*)%s*(.*)')

    if action then
        local f = plugin.commands[action]
        if f then return f(args, plugin_name, setting, value) end
    end

    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
