local sql = require 'lsqlite3'

db = nil -- global database handle

local database = {}

database.init = function (config)
    db = sql.open(config.dbpath)

    if not db then
        print('Failed to open the database')
    end

    -- run the dbinit() function that any module exposes
    for _, module in pairs(modules) do
        if type(module) == 'table' and type(module.dbinit) == 'function' then
            module.dbinit()
        end
    end

    -- run the dbinit() function that any plugin exposes
    for _, plugin in pairs(modules.plugins) do
        if type(plugin) == 'table' and type(plugin.dbinit) == 'function' then
            plugin.dbinit()
        end
    end
end

database.cleanup = function ()
    -- run the dbcleanup() function that any module exposes
    for _, module in pairs(modules) do
        if type(module) == 'table' and type(module.dbcleanup) == 'function' then
            module.dbcleanup()
        end
    end

    -- run the dbcleanup() function that any plugin exposes
    for _, plugin in pairs(modules.plugins) do
        if type(plugin) == 'table' and type(plugin.dbcleanup) == 'function' then
            plugin.dbcleanup()
        end
    end

    db:close()
end

return database
