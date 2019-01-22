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

local quotegrabs = {}

-- table to keep track of each nick's last message
quotegrabs.last_msgs = {}

quotegrabs.whitelist_status = function (nick)
    wl_sel:reset()
    wl_sel:bind_names({ ['nick'] = nick })
    for c in wl_sel:urows() do
        return c > 0
    end
end

quotegrabs.whitelist_add = function (nick)
    wl_ins:reset()
    wl_ins:bind_names({ ['nick'] = nick })
    local res = wl_ins:step()
    return (res == sql.DONE and 'Tada!' or db:errmsg())
end

quotegrabs.whitelist_del = function (nick)
    wl_del:reset()
    wl_del:bind_names({ ['nick'] = nick })
    local res = wl_del:step()
    return (res == sql.DONE and 'Tada!' or db:errmsg())
end

quotegrabs.add = function (nick, msg)
    qg_ins:reset()
    qg_ins:bind_names({ ['nick'] = nick, ['message'] = msg })
    local res = qg_ins:step()
    return (res == sql.DONE and 'Tada!' or db:errmsg())
end

quotegrabs.quote_nick = function (nick)
    nick = ('%%%s%%'):format(nick or '')
    qg_sel_nick:reset()
    qg_sel_nick:bind_names({ ['nick'] = nick })
    for id, nick, msg in qg_sel_nick:urows() do
        return id, nick, msg
    end
end

quotegrabs.quote_id = function (id)
    qg_sel_id:reset()
    qg_sel_id:bind_names({ ['id'] = id })
    for id, nick, msg in qg_sel_id:urows() do
        return id, nick, msg
    end
end

quotegrabs.quote_rand = function (nick)
    nick = ('%%%s%%'):format(nick or '')
    qg_sel_rand:reset()
    qg_sel_rand:bind_names({ ['nick'] = nick })
    for id, nick, msg in qg_sel_rand:urows() do
        return id, nick, msg
    end
end

quotegrabs.quote_search = function (search)
    search = ('%%%s%%'):format(search or '')
    qg_search:reset()
    qg_search:bind_names({ ['search'] = search })

    local list = ''
    for id, nick, msg in qg_search:urows() do
        msg = (msg:len() > 40) and (msg:sub(1,40) .. '…') or msg
        list = ('#%s: %s: %s, %s'):format(id, nick, msg, list)
    end

    return list
end

quotegrabs.delete = function (id)
    qg_del:reset()
    qg_del:bind_names({ ['id'] = id })
    local res = qg_del:step()
    return (res == sql.DONE and 'Tada!' or db:errmsg())
end

quotegrabs.dbinit = function ()
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

quotegrabs.dbcleanup = function ()
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

return quotegrabs
