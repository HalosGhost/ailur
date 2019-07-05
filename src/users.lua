local modules = modules
local plugins = modules.plugins
local sql = require 'lsqlite3'

local user_sel
local user_ins
local admin_ins
local ignore_ins
local settings_sel -- note the 's'!
local setting_sel
local setting_ins

local in_table = function (t, elem)
    for _, v in pairs(t) do
        if v == elem then return true end
    end
end

local check = function (code)
    if code == sql.OK or code == sql.DONE then
        return 'Tada!'
    else
        return nil, db:errmsg()
    end
end

local users = {}

users.dbinit = function ()
    local init = [=[
        create table if not exists users (
            usermask    text    primary key not null,
            admin       bool    not null default false,
            ignore      bool    not null default false
        );
    ]=]

    if db:exec(init) ~= sql.OK then
        error('failed to create table usersettings')
    end

    init = [=[
        create table if not exists settings (
            usermask    text    not null,
            plugin      text    not null,
            key         text    not null,
            value,
            primary key (usermask, plugin, key),
            foreign key (usermask) references users(usermask)
        );
    ]=]

    if db:exec(init) ~= sql.OK then
        error('failed to create table usersettings')
    end

    user_sel = db:prepare[[     select * from users where usermask = :usermask; ]]
    user_ins = db:prepare[[     insert into users (usermask) values (:usermask); ]]

    admin_ins = db:prepare[[    insert or replace into users (usermask, admin)
                                values (:usermask, :value); ]]

    ignore_ins = db:prepare[[   insert or replace into users (usermask, ignore)
                                values (:usermask, :value); ]]

    settings_sel = db:prepare[[ select plugin, key, value from settings
                                where usermask = :usermask; ]]

    setting_sel = db:prepare[[  select value from settings
                                where usermask = :usermask
                                    and plugin = :plugin
                                    and key = :key; ]]

    setting_ins = db:prepare[[  insert or replace into settings
                                values (:usermask, :plugin, :key, :value); ]]
end

users.dbcleanup = function ()
    user_sel:finalize()
    user_ins:finalize()
    admin_ins:finalize()
    ignore_ins:finalize()
    settings_sel:finalize()
    setting_sel:finalize()
    setting_ins:finalize()
end

users.add_user = function (usermask)
    user_ins:reset()
    user_ins:bind_names{ usermask=usermask}
    return check(user_ins:step())
end

users.user_exists = function (usermask)
    user_sel:reset()
    user_sel:bind_names{ usermask=usermask }
    for _ in user_sel:urows() do return true end
end

users.is_admin = function (usermask)
    user_sel:reset()
    user_sel:bind_names{ usermask=usermask }
    for _, v, _ in user_sel:urows() do return v == 1 end
end

users.set_admin = function (usermask, value)
    admin_ins:reset()
    admin_ins:bind_names{ usermask=usermask, value=value and 1 or 0 }
    return check(admin_ins:step())
end

users.is_ignored = function (usermask)
    user_sel:reset()
    user_sel:bind_names{ usermask=usermask }
    for _, _, v in user_sel:urows() do return v == 1 end
end

users.set_ignore = function (usermask, value)
    ignore_ins:reset()
    ignore_ins:bind_names{ usermask=usermask, value=value and 1 or 0 }
    return check(ignore_ins:step())
end

users.get_settings = function (usermask)
    settings_sel:reset()
    settings_sel:bind_names{ usermask=usermask }

    local res = {}
    for plugin, key, value in settings_sel:urows() do
        res[#res+1] = ('%s.%s = %s'):format(plugin, key, value)
    end

    return res
end

users.get_setting = function (usermask, plugin, key)
    setting_sel:reset()
    setting_sel:bind_names{ usermask=usermask, plugin=plugin, key=key }
    for v in setting_sel:urows() do return v end
end

users.set_setting = function (usermask, plugin_name, key, value)
    if not users.user_exists(usermask) then
        users.add_user(usermask)
    end

    local plugin = plugins[plugin_name]
    if not (plugin and plugin.user_settings and in_table(plugin.user_settings, key)) then
        return nil, 'no such setting'
    end

    setting_ins:reset()
    setting_ins:bind_names{ usermask=usermask, plugin=plugin_name, key=key, value=value }
    return check(setting_ins:step())
end

return users
