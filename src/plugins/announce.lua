-- URL announcements - follows http->https redirects but not www

local https = require 'ssl.https'

local plugin = {}

local entitySwap = function (orig, n, s)
    local entityMap = { lt='<', gt='>', amp='&', quot='"', apos='\'' }

    return (n == '' and entityMap[s])
           or (n == '#' and tonumber(s)) and string.char(s)
           or (n == '#x' and tonumber(s, 16)) and string.char(tonumber(s, 16))
           or orig
end

local html_unescape = function (str)
    return str:gsub('(&(#?x?)([%d%a]+);)', entitySwap)
end

plugin.help = 'Usage: announce <url>'

plugin.main = function(args)
    local _, _, url = args.message:find('(.+)')

    if not url then
        args.modules.irc.privmsg(args.target, plugin.help)
        return
    end

    if url:find('^.-[ <]?https?://[^> ]+.*') then
        _, _, url = url:find('^.-[ <]?(https?://[^> ]+).*')
    else
        url = 'http://' .. url
    end

    local body, headers
    local status = 300
    local redirects = 0

    while status // 100 == 3 and redirects < 3 do
        if not url then return end
        body, status, headers = https.request(url)

        if not body or not status or (status ~= 200 and status // 100 ~= 3) then
            args.modules.irc.privmsg(args.target, ('error: %s'):format(status))
            return
        end

        if status // 100 == 3 then
            url = headers.location
            redirects = redirects + 1
        end
    end

    if redirects == 3 then
        args.modules.irc.privmsg(args.target, 'error: too many redirects')
    end

    local title = html_unescape(body:match('<title.->(.-)</title>')) or 'Could not grab title'

    args.modules.irc.privmsg(args.target, ('[%s]'):format(title))
end

return plugin
