local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

local plugin = {}

plugin.help = 'Usage: duckduckgo <search>'

local plain = function(resp)
    local _, _, link = resp:find('</table>.-</table>.-<a rel="nofollow" href="(.-)" class=\'result%-link\'>')
    return link or 'No Results'
end

local bang = function(resp)
    local data = json.decode(resp)
    return data and data.Redirect and data.Redirect ~= '' and data.Redirect or 'No Results'
end

plugin.main = function(args)
    local _, _, search = args.message:find('(.+)')

    if args.conf.debug then
        print(search)
    end

    if not search then
        args.modules.irc.privmsg(args.target, 'You want me to search for what?')
        return
    end

    local target = search:find('^!')
        and 'https://api.duckduckgo.com/?q=%s&format=json&no_html=1&no_redirect=1'
        or  'https://duckduckgo.com/lite/?q=%s&kl=us-en&k1=-1&kd=-1&kp=1'

    local resp = https.request(target:format(url.escape(search)))
    if resp then
        if args.conf.debug then print(resp) end
        args.modules.irc.privmsg(args.target, search:find('^!') and bang(resp) or plain(resp))
        return
    end

    args.modules.irc.privmsg(args.target, 'something went wrong with the request')
end

return plugin
