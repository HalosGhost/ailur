local lfs = require 'lfs'

while true do
    modules = {}
    modules.extload = require 'extload'

    local cwd = lfs.currentdir()

    for f in lfs.dir(cwd) do
        local _, _, mod = f:find('(.+)%.lua$')
        if mod and mod ~= 'main' and not modules[mod] then
            modules:extload(mod)
        end
    end

    modules.plugins = {}
    local stat = lfs.chdir('plugins')
    if stat then
        for f in lfs.dir(lfs.currentdir()) do
            local _, _, plugin = f:find('(.+)%.lua')
            if plugin and not modules.plugins[plugin] then
                modules.extload(modules.plugins, plugin)
            end
        end
        lfs.chdir(cwd)
    end

    local main = nil
    for m in pairs(modules) do
        main = type(modules[m]) == 'table' and modules[m].main or nil
        if main then break end
    end

    if not main then
        print('no main function found')
        os.exit()
    end

    main()
end
