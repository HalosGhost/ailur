local modules = modules
local sql = require 'lsqlite3'

local plugin = {}

local fetch_all = nil
local insert = nil
local delete = nil

plugin.loaded = {}

local refresh = function ()
    plugin.loaded = nil
    plugin.loaded = {}

    fetch_all:reset()
    for _, p, s in fetch_all:urows() do
        plugin.loaded[#plugin.loaded + 1] = { pattern = p, substitution = s }
    end
end

plugin.dbinit = function ()
    local init = [=[
      create table if not exists macros (
          id integer primary key not null,
          pattern text not null,
          substitution text not null
      );
    ]=]

    if db:exec(init) ~= sql.OK then
        print('Failed to create table macros')
    end

    fetch_all = db:prepare('select id, pattern, substitution from macros order by id')
    insert = db:prepare('insert or replace into macros (pattern, substitution) values (:pattern, :substitution);')
    delete = db:prepare('delete from macros where pattern like :pattern')

    refresh()
end

plugin.dbcleanup = function ()
    fetch_all:finalize()
    insert:finalize()
    delete:finalize()
end

plugin.commands = {}

plugin.commands.add = function (args)
    local _, _, pat, sub = args.message:find("add%s+'(.+)'%s+'(.+)'")

    insert:reset()
    insert:bind_names{ pattern = pat, substitution = sub }
    local res = insert:step()

    modules.irc.privmsg(args.target, res == sql.DONE and 'Tada!' or db:errmsg())
end

plugin.commands.delete = function (args)
    local _, _, pat = args.message:find("delete%s+'(.+)'")

    delete:reset()
    delete:bind_names{ pattern = pat }
    local res = delete:step()

    modules.irc.privmsg(args.target, res == sql.DONE and 'Tada!' or db:errmsg())
end

plugin.commands.clear = function (args)
    plugin.loaded = nil
    plugin.loaded = {}

    modules.irc.privmsg(args.target, 'Tada!')
end

plugin.commands.refresh = function (args)
    refresh()

    modules.irc.privmsg(args.target, 'Tada!')
end

plugin.commands.list = function (args)
    local l = ''
    for i, m in ipairs(plugin.loaded) do
        local tmp = ("'%s' => '%s'"):format(m.pattern, m.substitution)
        l = l == '' and tmp or ('%s | %s'):format(tmp, l)
    end

    l = l ~= '' and l or 'No macros loaded'

    modules.irc.privmsg(args.target, l)
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: macro <%s> [pattern] [substitution]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action, target = args.message:find('(%S+)%s*(%S*)')
    local f = plugin.commands[action]

    if args.authorized and f then return f(args, target) end

    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
