local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

local plugin = {}

plugin.help = 'Usage: mediawiki <APIURL> <search>'

plugin.main = function(args)
    local _, _, apiurl, search = args.message:find('^[ ]?(https?://[^> ]+)%s+(.+)')

    if args.conf.debug then
        print(apiurl, query)
    end

    if not apiurl then
        args.modules.irc.privmsg(args.target, ('%s: Please give me a mediawiki API url, it should have api.php somewhere on the end.'):format(args.sender))
        return
    end

    if not search then
        args.modules.irc.privmsg(args.target, ('%s: Please give me a search term.'):format(args.sender))
        return
    end

    local act = '?action=opensearch&format=json&search='
    local resp = https.request(apiurl .. act .. url.escape(search))
    if not resp or resp == nil then
        args.modules.irc.privmsg(args.target, ('%s: Network request failed.'):format(args.sender))
        return
    else
        if args.conf.debug then print(resp) end
        local res = json.decode(resp)
        if not res or res == nil then
            args.modules.irc.privmsg(args.target, ('%s: Please give me a working API url.'):format(args.sender))
            return
        elseif res["error"] then
            args.modules.irc.privmsg(args.target, ('%s: API error: %s'):format(args.sender, res["error"].code))
            return
        else
            local lnk = (res[4][1] and res[4][1] ~= '') and res[4][1] or 'No results'
            local dsc = (res[3][1] and res[3][1] ~= '') and ' - ' .. res[3][1] or ''
            args.modules.irc.privmsg(args.target, ('%s: <%s>%s'):format(args.sender, lnk, dsc))
        end
    end
end

return plugin
