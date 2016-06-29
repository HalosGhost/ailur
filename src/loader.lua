function hotload (ms, m)
    package.loaded[m] = nil
    ms[m] = require(m)
end

while true do
    local ms = {}

    hotload(ms, 'modlist')

    for _, v in ipairs(ms.modlist) do
        hotload(ms, v)
    end

    ms.irc.bot(ms, hotload)
end
