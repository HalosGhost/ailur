-- bot management plugin

local modules = modules
local plugin = {}

plugin.commands = {}

plugin.commands.update = function (args)
    if not args.authorized then return end

    local _, _, status = os.execute('git pull origin master')
    if status == 0 then
        modules.irc.privmsg(args.target, "Tada!")
    end
end

plugin.commands.die = function (args)
    if not args.authorized then return end

    modules.irc.connection:close()
    os.exit()
end

plugin.commands.reload = function (args)
    if not args.authorized then return end

    local _, _, what = args.message:find('reload%s+(.+)')
    if modules[what] then
        if type(modules[what].dbcleanup) == 'function' then
            modules[what].dbcleanup()
        end

        modules.irc.privmsg(args.target, modules:extload(what))

        if type(modules[what].dbinit) == 'function' then
            modules[what].dbinit()
        end
    elseif modules.plugins[what] then
        if type(modules.plugins[what].dbcleanup) == 'function' then
            modules.plugins[what].dbcleanup()
        end

        modules.irc.privmsg(args.target, modules.extload(modules.plugins, what, 'plugins'))

        if type(modules.plugins[what].dbinit) == 'function' then
            modules.plugins[what].dbinit()
        end
    else
        modules.irc.privmsg(args.target, 'no such module/plugin')
    end
end

plugin.commands.restart = function (args)
    if args.authorized then
        if args.conf.debug then print('restarting') end
        return true
    end
end

plugin.commands.version = function (args)
    local upt = io.popen('printf \'0.r%s.%s\' "$(git rev-list --count HEAD)" "$(git log -1 --pretty=format:%h)"')
    modules.irc.privmsg(args.target, upt:read())
    upt:close()
end

plugin.commands.list = function (args)
    local list = ''
    local _, _, what = args.message:find('list%s*(%S*)')

    local tables = { aliases = modules.irc_aliases
                   , modules = modules
                   , plugins = modules.plugins
                   , config  = args.conf
                   }

    local the_table = what and tables[what] or tables

    for k in pairs(the_table) do
        list = ("'%s' %s"):format(k, list)
    end

    modules.irc.privmsg(args.target, list)
end

plugin.commands.whoami = function (args)
    local admin = args.authorized and ', an admin' or ''
    modules.irc.privmsg(args.target, ('%s!%s@%s%s'):format(args.sender, args.sender_user, args.sender_host, admin))
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

    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
