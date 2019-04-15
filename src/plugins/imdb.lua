local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

local plugin = {}

plugin.help = 'Usage: imdb <search>'

plugin.main = function(args)
    local _, _, search = args.message:find('(.+)')

    if args.message == '' then
        modules.irc.privmsg(args.target, plugin.help)
        return
    end

    if not args.conf.imdb or not args.conf.imdb.omdb_key then
        modules.irc.privmsg(args.target, ('%s: Please set config.imdb.omdb_key'):format(args.sender))
        return
    end

    local apikey = args.conf.imdb.omdb_key
    local omdb_url = ('http://www.omdbapi.com/?apikey=%s&t=%s'):format(apikey, url.escape(search))

    if args.conf.debug then print(omdb_url) end
    local response = https.request(omdb_url)
    if response then
        local results = json.decode(response)
        if results.Error then
            local err = results.Error
            modules.irc.privmsg(args.target, ('%s: error: %s'):format(args.sender, err))
            return
        else
            local title = results.Title
            local year = results.Year and ('(%s):'):format(results.Year) or ''
            local description = results.Plot or ''
            local description = (results.Plot and results.Plot ~= '') and results.Plot or 'No plot information.'
            local movID = results.imdbID
            modules.irc.privmsg(args.target, ('%s: %s %s %s - https://www.imdb.com/title/%s'):format(args.sender, title, year, description, movID))
        end
    end
end

return plugin
