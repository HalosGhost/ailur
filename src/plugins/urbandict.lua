local modules = modules
local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

local plugin = {}

plugin.help = 'Usage: urbandict <search>'

plugin.main = function(args)
    local _, _, search = args.message:find('(.+)')

    if args.message == '' then
        args.modules.irc.privmsg(args.target, plugin.help)
        return
    end

    local ud_url = ('https://api.urbandictionary.com/v0/define?term=%s'):format(url.escape(search))

    if args.conf.debug then print(ud_url) end
    local response = https.request(ud_url)
    if response then
        local results = json.decode(response)
        if not results.list[1] then
            modules.irc.privmsg(args.target, ('%s: no results'):format(args.sender))
            return
        else
            local definition = string.gsub(results.list[1].definition, '\r\n', '')
            modules.irc.privmsg(args.target, ('%s: %s - %s'):format(args.sender, search, definition))
        end
    end
end

return plugin
