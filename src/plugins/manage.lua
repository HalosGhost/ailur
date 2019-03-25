-- bot management plugin

local plugin = {}

plugin.commands = {}

plugin.commands.update = function (args)
    if not args.authorized then return end

    local _, _, status = os.execute('git pull origin master')
    if status == 0 then
        args.modules.irc.privmsg(args.target, "Tada!")
    end
end

plugin.commands.die = function (args)
    if not args.authorized then return end
    args.modules.irc.quit('Good Bye')

    args.modules.irc.connection:close()
    os.exit()
end

plugin.commands.reload = function (args)
    if not args.authorized then return end

    local _, _, what = args.message:find('reload%s+(.+)')
    if args.modules[what] then
        if type(args.modules[what].dbcleanup) == 'function' then
            args.modules[what].dbcleanup()
        end

        args.modules.irc.privmsg(args.target, args.modules:extload(what))

        if type(args.modules[what].dbinit) == 'function' then
            args.modules[what].dbinit()
        end
    elseif args.modules.plugins[what] then
        if type(args.modules.plugins[what].dbcleanup) == 'function' then
            args.modules.plugins[what].dbcleanup()
        end

        args.modules.irc.privmsg(args.target,
                                 args.modules.extload(args.modules.plugins, what, 'plugins'))

        if type(args.modules.plugins[what].dbinit) == 'function' then
            args.modules.plugins[what].dbinit()
        end
    else
        args.modules.irc.privmsg(args.target 'no such module/plugin')
    end
end

plugin.commands.restart = function (args)
    if args.authorized then
        if args.modules.config.debug then print('restarting') end
        return true
    end
end

plugin.commands.version = function (args)
    local upt = io.popen('printf \'0.r%s.%s\' "$(git rev-list --count HEAD)" "$(git log -1 --pretty=format:%h)"')
    args.modules.irc.privmsg(args.target, upt:read())
    upt:close()
end

plugin.commands.list = function (args)
    local list = ''
    local _, _, what = args.message:find('list%s*(%S*)')

    local tables = { aliases = args.modules.irc_aliases
                   , modules = args.modules
                   , plugins = args.modules.plugins
                   , config  = args.modules.config
                   }

    local the_table = what and tables[what] or tables

    for k in pairs(the_table) do
        list = ("'%s' %s"):format(k, list)
    end

    args.modules.irc.privmsg(args.target, list)
end

plugin.commands.whoami = function (args)
    local admin = args.authorized and ', an admin' or ''
    args.modules.irc.privmsg(args.target, args.sender .. admin)
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: manage <%s>'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = plugin.commands[action]

    if f then return f(args) end

    args.modules.irc.privmsg(args.target, plugin.help)
end

return plugin
