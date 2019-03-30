-- URL announcements - follows http->https redirects but not www

local https = require 'ssl.https'
local ltn12 = require 'ltn12'

local plugin = {}

plugin.help = 'Usage: announce <url>'

plugin.main = function(args)
    local _, _, url = args.message:find('(.+)')

    if args.modules.config.debug then
        print(url)
    end

    if not url then
        args.modules.irc.privmsg(args.target, ('%s: Please give me a url.'):format(args.sender))
        return
    end

    if url:find('^.-[ <]?https?://[^> ]+.*') then
        _, _, url = url:find('^.-[ <]?(https?://[^> ]+).*')
    else
        url = 'http://' .. url
    end
    if url then
        local body = {}
        local options = { ['url']  = url, ['sink'] = ltn12.sink.table(body) }
        local resp, code, headers, status = https.request(options)
        if resp then
            title = body and body[1] and body[1]:match('<title.*>(.-)</title>') or 'Could not grab title'
            if args.modules.config.debug then print(title) end
            if code == 200 then
                args.modules.irc.privmsg(args.target, ('%s: %s'):format(args.sender, title))
                return
            else
                args.modules.irc.privmsg(args.target, ('%s: %s'):format(args.sender, status))
                return
            end
            return
        else
            args.modules.irc.privmsg(args.target, ('%s: Something went wrong with the request'):format(args.sender))
            return
        end
        return
    end
end

return plugin
