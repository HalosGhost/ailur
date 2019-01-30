-- bot management plugin

local manage = {}

manage.commands = {}

manage.commands.update = function (args)
    if not args.authorized then return end

    local _, _, status = os.execute('git pull origin master')
    if status == 0 then
        args.modules.irc.privmsg(args.connection, args.target, "Tada!")
    end
end

manage.commands.die = function (args)
    if not args.authorized then return end

    args.connection:close()
    os.exit()
end

manage.commands.reload = function (args)
    if not args.authorized then return end

    local _, _, what = args.message:find('reload%s+(.+)')
    for k in pairs(args.modules) do
        if what == k then
            args.modules.irc.privmsg(args.connection, args.target, args.modules:extload(k))
            return
        end
    end

    for k in pairs(args.modules.plugins) do
        if what == k then
            args.modules.irc.privmsg(args.connection, args.target,
                                     args.modules.extload(args.modules.plugins, k, 'plugins'))
            return
        end
    end
end

manage.commands.restart = function (args)
    if args.authorized then
        if args.modules.config.debug then print('restarting') end
        return true
    end
end

manage.commands.version = function (args)
    local upt = io.popen('printf \'0.r%s.%s\' "$(git rev-list --count HEAD)" "$(git log -1 --pretty=format:%h)"')
    args.modules.irc.privmsg(args.connection, args.target, upt:read())
    upt:close()
end

manage.commands.list = function (args)
    local list = ''
    local _, _, what = args.message:find('list%s*(%S*)')

    local tables = {}
    tables.all      = tables
    tables.aliases  = args.modules.irc_aliases
    tables.modules  = args.modules
    tables.plugins  = args.modules.plugins
    tables.config   = args.modules.config

    local the_table = what and tables[what] or tables

    for k in pairs(the_table) do
        list = ("'%s' %s"):format(k, list)
    end

    args.modules.irc.privmsg(args.connection, args.target, list)
end

manage.commands.whoami = function (args)
    local admin = args.authorized and ', an admin' or ''
    args.modules.irc.privmsg(args.connection, args.target, args.sender .. admin)
end

local h = ''
for k in pairs(manage.commands) do
    h = ('%s|%s'):format(h, k)
end
manage.help = ('usage: <%s>'):format(h:sub(2))

manage.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = manage.commands[action]

    if f then return f(args) end

    args.modules.irc.privmsg(args.connection, args.target, manage.help)
end

return manage
