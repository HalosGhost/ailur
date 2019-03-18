local sql = require 'lsqlite3'

local wl_ins = nil
local wl_del = nil
local wl_sel = nil

local qg_ins = nil
local qg_sel_nick = nil
local qg_sel_id = nil
local qg_sel_rand = nil
local qg_search = nil
local qg_del = nil

local QUOTE_FMT = '#%d: <%s> %s'

local plugin = {}

-- table to keep track of each nick's last message
plugin.last_msgs = {}

-- database initialization
plugin.dbinit = function ()
    local quoteinit = [=[
      create table if not exists quotegrabs (
          id integer primary key not null,
          nick text not null,
          message text not null
      );
    ]=]

    local whitelistinit = [=[
      create table if not exists qg_whitelist (
          nick text not null
      );
    ]=]

    if db:exec(quoteinit) ~= sql.OK then
        print('Failed to create table quotegrabs')
    end

    if db:exec(whitelistinit) ~= sql.OK then
        print('Failed to create table qg_whitelist')
    end

    wl_ins = db:prepare('insert or ignore into qg_whitelist (nick) values (:nick);')
    wl_del = db:prepare('delete from qg_whitelist where nick = :nick;')
    wl_sel = db:prepare('select count(*) from qg_whitelist where nick = :nick;')

    qg_ins      = db:prepare('insert or ignore into quotegrabs (nick, message) values (:nick, :message);')
    qg_sel_nick = db:prepare('select id, nick, message from quotegrabs where nick like :nick order by id desc;')
    qg_sel_id   = db:prepare('select id, nick, message from quotegrabs where id = :id limit 1;')
    qg_sel_rand = db:prepare('select id, nick, message from quotegrabs where nick like :nick order by random();')
    qg_search   = db:prepare('select id, nick, message from quotegrabs where message like :search order by id asc;')
    qg_del      = db:prepare('delete from quotegrabs where id = :id;')
end

-- database cleanup
plugin.dbcleanup = function ()
    wl_ins:finalize()
    wl_del:finalize()
    wl_sel:finalize()
    qg_ins:finalize()
    qg_sel_nick:finalize()
    qg_sel_id:finalize()
    qg_sel_rand:finalize()
    qg_search:finalize()
    qg_del:finalize()
end

plugin.whitelist_status = function (nick)
    wl_sel:reset()
    wl_sel:bind_names({ ['nick'] = nick })

    for c in wl_sel:urows() do
        return c > 0
    end
end

plugin.commands = {}

plugin.commands.status = function (args, nick)
    if nick == '' then nick = args.sender end

    local result = plugin.whitelist_status(nick)
    args.modules.irc.privmsg(args.connection, args.target,
                             ('%s is opted-%s for quotegrabs.'):format(nick, result and 'in' or 'out'))
end

plugin.commands.optin = function (args)
    wl_ins:reset()
    wl_ins:bind_names({ ['nick'] = args.sender })
    local res = wl_ins:step()
    args.modules.irc.privmsg(args.connection, args.target,
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

plugin.commands.optout = function (args)
    wl_del:reset()
    wl_del:bind_names({ ['nick'] = args.sender })
    local res = wl_del:step()
    args.modules.irc.privmsg(args.connection, args.target,
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

plugin.commands.grab = function (args, nick)
    if nick == args.sender then return end

    local last_msg = plugin.last_msgs[args.target][nick]
    if not last_msg then return end

    qg_ins:reset()
    qg_ins:bind_names({ ['nick'] = nick, ['message'] = last_msg })
    local res = qg_ins:step()
    args.modules.irc.privmsg(args.connection, args.target,
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

plugin.commands.last = function (args, nick)
    nick = ('%%%s%%'):format(nick)
    qg_sel_nick:reset()
    qg_sel_nick:bind_names({ ['nick'] = nick })
    for id, nick, msg in qg_sel_nick:urows() do
        args.modules.irc.privmsg(args.connection, args.target,
                                 QUOTE_FMT:format(id, nick, msg))
        return
    end
end

plugin.commands.id = function (args, id)
    if id == '' then return end

    qg_sel_id:reset()
    qg_sel_id:bind_names({ ['id'] = id })
    for id, nick, msg in qg_sel_id:urows() do
        args.modules.irc.privmsg(args.connection, args.target,
                                 QUOTE_FMT:format(id, nick, msg))
        return
    end
end

plugin.commands.random = function (args, nick)
    nick = ('%%%s%%'):format(nick)
    qg_sel_rand:reset()
    qg_sel_rand:bind_names({ ['nick'] = nick })
    for id, nick, msg in qg_sel_rand:urows() do
        args.modules.irc.privmsg(args.connection, args.target,
                                 QUOTE_FMT:format(id, nick, msg))
        return
    end
end

plugin.commands.search = function (args, search)
    search = ('%%%s%%'):format(search)
    qg_search:reset()
    qg_search:bind_names({ ['search'] = search })

    local list = ''
    for id, nick, msg in qg_search:urows() do
        msg = (msg:len() > 40) and (msg:sub(1,40) .. '…') or msg
        list = (QUOTE_FMT .. ', %s'):format(id, nick, msg, list)
    end

    args.modules.irc.privmsg(args.connection, args.target, list)
end

plugin.commands.delete = function (args, id)
    if not args.authorized or id == '' then return end

    qg_del:reset()
    qg_del:bind_names({ ['id'] = id })
    local res = qg_del:step()
    args.modules.irc.privmsg(args.connection, args.target,
                             (res == sql.DONE and 'Tada!' or db:errmsg()))
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end
plugin.help = ('usage: quote [%s] [target]'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action, target = args.message:find('(%S+)%s*(%S*)')
    local f = plugin.commands[action]

    if f then return f(args, target) end

    args.modules.irc.privmsg(args.connection, args.target, plugin.help)
end

return plugin
