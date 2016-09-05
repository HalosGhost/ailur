while true do
    local ms = {}
    ms.coreload = require 'coreload'

    ms.coreload(ms, 'modlist')

    for _, v in ipairs(ms.modlist) do
        ms.coreload(ms, v)
    end

    ms.irc.bot(ms)
end
