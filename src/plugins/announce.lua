-- URL announcements - follows http->https redirects but not www

local modules = modules
local https = require 'ssl.https'

local plugin = {}

local entitySwap = function (orig, n, s)
    local entityMap = { lt='<', gt='>', amp='&', quot='"', apos='\'' }

    return (n == '' and entityMap[s])
           or (n == '#' and tonumber(s)) and utf8.char(s)
           or (n == '#x' and tonumber(s, 16)) and utf8.char(tonumber(s, 16))
           or orig
end

local html_unescape = function (str)
    return str:gsub('(&(#?x?)([%d%a]+);)', entitySwap)
end

plugin.help = 'Usage: announce <url>'

plugin.main = function(args)
    local _, _, target = args.message:find('(.+)')

    if not target then
        modules.irc.privmsg(args.target, plugin.help)
        return
    end

    local _, _, url = target:find('^.-[ <]?(https?://[^> ]+).*')
    url = url or 'http://' .. target

    -- remove possible text anchor
    url = url:gsub('#[^/]+$', '')

    local body, headers
    local status = 300
    local redirects = 0

    while status // 100 == 3 and redirects < 3 do
        if not url then return end
        body, status, headers = https.request(url)

        if not body or not status or (status ~= 200 and status // 100 ~= 3) then
            modules.irc.privmsg(args.target, ('error: %s'):format(status))
            return
        end

        if status // 100 == 3 then
            url = headers.location
            redirects = redirects + 1
        end
    end

    if redirects >= 3 then
        modules.irc.privmsg(args.target, 'error: too many redirects')
        return
    end

    -- remove optional spaces from the tags
    body = body:gsub('\n', ' ')
    body = body:gsub(' *< *', '<')
    body = body:gsub(' *> *', '>')

    -- put all tags in lowercase
    body = body:gsub('(<[^ >]+)', string.lower)

    local title = body:match('<title>(.+)</title>')
    if not title then return end

    modules.irc.privmsg(args.target, ('[%s]'):format(html_unescape(title)))
end

return plugin
