local lfs = require 'lfs'

while true do
    local ms = {}
    ms.extload = require 'extload'

    local cwd = lfs.currentdir()

    for f in lfs.dir(cwd) do
        local _, _, mod = f:find('(.+)%.lua$')
        if mod and mod ~= 'main' and not ms[mod] then
            ms.extload(ms, mod)
        end
    end

    ms.plugins = {}
    local stat = lfs.chdir('plugins')
    if stat then
        for f in lfs.dir(lfs.currentdir()) do
            local _, _, plugin = f:find('(.+)%.lua')
            if plugin and not ms.plugins[plugin] then
                ms.extload(ms.plugins, plugin)
            end
        end
        lfs.chdir(cwd)
    end

    local main = nil
    for m in pairs(ms) do
        main = type(ms[m]) == 'table' and ms[m].main or nil
        if main then break end
    end

    if not main then
        print('no main function found')
        os.exit()
    end

    main(ms)
end
