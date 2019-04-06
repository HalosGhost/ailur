local url = require("socket.url")
local https = require("ssl.https")


local plugin = {}

local messages = { "The webserver hasn't sent a final response, status %s",
                   "The website is up status %s",
                   "The website is up with a %s redirect",
                   "Client error, webserver returned status %s",
                   "Server returning error %s" }

plugin.help = 'Usage: isup <website>'

plugin.main = function(args)
    local website = args.message
    if args.conf.debug then
        print(website)
    end
    if not website then
        modules.irc.privmsg(args.target, 'Give me a website or hostname to check')
        return
    end
    local address = website:find('^https?://') and website or ('http://%s'):format(website)
    local response, httpcode = https.request(address)
    if response then
        local code = string.sub(tostring(httpcode), 1, 1)
        local reply = messages[tonumber(code)]:format(httpcode)
        modules.irc.privmsg(args.target, reply)
    else
        modules.irc.privmsg(args.target, "The website is currently down")
    end
end

return plugin
