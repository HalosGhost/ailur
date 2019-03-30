local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

local plugin = {}

plugin.help = 'Usage: mediawiki <APIURL> <search>'

plugin.main = function(args)
    local _, _, apiurl, search = args.message:find('(%S+)%s+(.+)')

    if args.conf.debug then
        print(apiurl, query)
    end

    if not apiurl then
        args.modules.irc.privmsg(args.target, 'You want me to search where?')
    end

    if not search then
        args.modules.irc.privmsg(args.target, 'You want me to search for what?')
    end

    local act = '?action=opensearch&format=json&search='
    local resp = https.request(apiurl .. act .. url.escape(search))
    if resp and resp not nil then
        if args.conf.debug then print(resp) end
        local res = json.decode(resp)
        local lnk = (res[4][1] and res[4][1] ~= '') and res[4][1] or 'No results'
        local dsc = (res[3][1] and res[3][1] ~= '') and ' - ' .. res[3][1] or ''
        args.modules.irc.privmsg(args.target, ('<%s>%s'):format(lnk, dsc))
        return
    else
        return
    end
end

return plugin
