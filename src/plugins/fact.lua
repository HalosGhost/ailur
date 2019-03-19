local sql = require 'lsqlite3'

local ins = nil
local cnt = nil
local del = nil
local sel = nil
local sim = nil

local plugin = {}

-- database initialization
plugin.dbinit = function ()
    local init = [=[
      create table if not exists factoids (
          key text not null,
          value text not null,
          locked_by text null
      );
    ]=]

    if db:exec(init) ~= sql.OK then
        print('Failed to create table factoids')
    end

    ins = db:prepare('insert or replace into factoids (key, value) values (:key, :value);')
    cnt = db:prepare('select count(*) from factoids where key like :key;')
    del = db:prepare('delete from factoids where key = :key;')
    sel = db:prepare('select value from factoids where key = :key;')
    sim = db:prepare('select key from factoids where key like :key;')
end

-- database cleanup
plugin.dbcleanup = function ()
    ins:finalize()
    cnt:finalize()
    del:finalize()
    sel:finalize()
    sim:finalize()
end

plugin.find = function (key)
    sel:reset()
    sel:bind_names{ ['key'] = key }
    for v in sel:urows() do
        return v
    end
end

plugin.commands = {}

plugin.commands.print = function (args)
    local _, _, key = args.message:find('print%s+(.+)')

    args.modules.irc.privmsg(args.connection, args.target, plugin.find(key))
end

plugin.commands.search = function (args)
    local _, _, key = args.message:find('search%s+(.+)')

    key = key and '%' .. key .. '%' or '%'
    sim:reset()
    sim:bind_names{ ['key'] = key }
    local list = ''
    for v in sim:urows() do
        list = ("'%s' %s"):format(v, list)
    end

    args.modules.irc.privmsg(args.connection, args.target, list)
end

plugin.commands.count = function (args)
    local _, _, key = args.message:find('count%s+(.+)')

    cnt:reset()
    local key = key and '%' .. key .. '%' or '%'
    cnt:bind_names{ ['key'] = key }
    for c in cnt:urows() do
        return args.modules.irc.privmsg(args.connection, args.target,
                                        ('Found %d result%s'):format(c or '0', c == 1 and '' or 's'))
    end
end

plugin.commands.add = function (args)
    local _, _, key, value = args.message:find("add%s+'(.+)'%s+'(.+)'")

    del:reset()
    del:bind_names{ ['key'] = key }
    local res = del:step()

    ins:reset()
    ins:bind_names{ ['key'] = key, ['value'] = value }
    res = ins:step()

    args.modules.irc.privmsg(args.connection, args.target, 
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

plugin.commands.remove = function (args)
    local _, _, key = args.message:find("remove%s+'(.+)'")

    del:reset()
    del:bind_names{ ['key'] = key }
    local res = del:step()

    args.modules.irc.privmsg(args.connection, args.target, 
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: fact <%s> [key] [value]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action, target = args.message:find('(%S+)%s*(%S*)')
    local f = plugin.commands[action]

    if f then return f(args, target) end

    args.modules.irc.privmsg(args.connection, args.target, plugin.help)
end

return plugin
