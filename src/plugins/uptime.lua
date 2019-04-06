STARTTIME = STARTTIME or os.time()

local plugin = {}

plugin.main = function (args)
    if not STARTTIME then
        modules.irc.privmsg(args.target, 'error: STARTTIME global var not defined')
        return
    end

    local conversions = { {'year',      60*60*24*7*52}
                        , {'week',      60*60*24*7}
                        , {'day',       60*60*24}
                        , {'hour',      60*60}
                        , {'minute',    60}
                        , {'second',    1}
                        }

    local uptime = {}
    local diff = os.difftime(os.time(), STARTTIME)

    for _, v in pairs(conversions) do
        local conversion = diff // v[2]
        if conversion ~= 0 then
            table.insert(uptime, ('%d %s%s'):format(conversion, v[1], conversion == 1 and '' or 's'))
            diff = diff - conversion * v[2]
        end
    end

    modules.irc.privmsg(args.target, 'up ' .. table.concat(uptime, ', '))
end

return plugin
