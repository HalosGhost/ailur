local url = require 'socket.url'
local https = require 'ssl.https'
local json = require 'json'

local plugin = {}

plugin.help = 'usage: weather <location>'

plugin.main = function (args)
    if args.message == '' then
        modules.irc.privmsg(args.target, plugin.help)
        return
    end

    if not args.conf.weather
        or not args.conf.weather.geocode_key
        or not args.conf.weather.darksky_key then
        modules.irc.privmsg(args.target, 'please set config.weather.geocode_key and config.weather.darksky_key')
        return
    end

    local geocode_url = 'https://maps.google.com/maps/api/geocode/json?address=%s&key=%s'
    local body, code = https.request(geocode_url:format(url.escape(args.message),
                                                        args.conf.weather.geocode_key))

    if not body then
        modules.irc.privmsg(args.target, 'error fetching location coords: ' .. code)
        return
    end

    local j = json.decode(body)
    if j.status ~= 'OK' then
        modules.irc.privmsg(args.target, 'error fetching location coords: ' .. j.status)
        return
    end

    local coords = j.results[1].geometry.location

    local weather_url = 'https://api.darksky.net/forecast/%s/%s,%s?units=auto'
    local body, code = https.request(weather_url:format(args.conf.weather.darksky_key,
                                                        coords.lat, coords.lng))

    if not body then
        modules.irc.privmsg(args.target, 'error fetching weather: ' .. code)
        return
    end

    local j = json.decode(body)

    if not j then
        modules.irc.privmsg(args.target, 'error decoding json')
        return
    end

    local temp_units = j.flags.units == 'us' and '°F' or '°C'
    local result = ('%s %.0f%s'):format(j.currently.summary, j.currently.temperature, temp_units)

    modules.irc.privmsg(args.target, result)
end

return plugin
