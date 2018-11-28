local lfs = require 'lfs'

while true do
    local ms = {}
    ms.coreload = require 'coreload'

    for f in lfs.dir(lfs.currentdir()) do
        local _, _, mod = f:find('(.+)%.lua$')
        if mod and mod ~= 'main' and not ms[mod] then
            ms.coreload(ms, mod)
        end
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
