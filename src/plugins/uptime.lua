STARTTIME = STARTTIME or os.time()

local plugin = {}

plugin.main = function (args)
    if not STARTTIME then
        args.modules.irc.privmsg(args.target, 'error: STARTTIME global var not defined')
        return
    end

    local conversions = { {'second', 60}, {'minute', 60}, {'hour', 24}, {'day', 7}, {'week', 52} }

    local uptime = ''
    local diff = os.difftime(os.time(), STARTTIME)

    for _, v in pairs(conversions) do
        local next_diff = diff // v[2]
        diff = diff - next_diff * v[2]
        uptime = ('%d %s%s, %s'):format(diff, v[1], diff == 1 and '' or 's', uptime)

        if next_diff == 0 then break end
        diff = next_diff
    end

    args.modules.irc.privmsg(args.target, ('up %s'):format(uptime:sub(0, #uptime-2)))
end

return plugin
