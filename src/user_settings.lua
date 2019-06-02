local sql = require 'lsqlite3'

local user_setting_sel
local user_setting_ins
local column_check
local column_add

local user_settings = {}

user_settings.dbinit = function ()
    local init = [=[
        create table if not exists users (
            usermask text primary key not null,
            admin bool not null default false
        );
    ]=]

    if db:exec(init) ~= sql.OK then
        print('failed to create table usersettings')
    end
end

user_settings.add = function (setting, definition)
    column_check = db:prepare(('select %s from users limit 1'):format(setting))
    column_add = db:prepare(('alter table users add column %s %s'):format(setting, definition))

    if not column_check then
        local res = column_add:step()
        if res ~= sql.DONE then
            print(('failed to add user setting \'%s\': %s'):format(setting, db:errmsg()))
        end
    end

    if column_check then column_check:finalize() end
    if column_add then column_add:finalize() end
end

user_settings.get = function (mask, setting)
    user_setting_sel = db:prepare(('select %s from users where usermask = :mask'):format(setting))
    user_setting_sel:bind_names{ mask = mask }
    for v in user_setting_sel:urows() do
        user_setting_sel:finalize()
        return v
    end
end

user_settings.set = function (mask, setting, value)
    if type(value) == 'string' then
        user_setting_ins = db:prepare(('update users set %s = \'%s\' where usermask = \'%s\''):format(setting, value, mask))
    else
        -- should cover other used types for now
        user_setting_ins = db:prepare(('update users set %s = %s where usermask = \'%s\''):format(setting, value, mask))
    end

    local res = user_setting_ins:step()

    if res ~= sql.DONE then
        print(('failed to set user setting \'%s\' to \'%s\': %s'):format(setting, value, db:errmsg()))
    end

    user_setting_ins:finalize()
    return res
end

return user_settings
