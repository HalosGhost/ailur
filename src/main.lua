while true do
    local ms = {}
    ms.loader = require 'loader'

    ms.loader.hl(ms, 'modlist')

    for _, v in ipairs(ms.modlist) do
        ms.loader.hl(ms, v)
    end

    ms.irc.bot(ms)
end
