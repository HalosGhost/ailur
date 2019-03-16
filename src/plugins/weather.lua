local url = require 'socket.url'
local https = require 'ssl.https'
local json = require 'json'

local weather = {}

weather.help = 'usage: weather <location>'

weather.main = function (args)
    if args.message == '' then
        args.modules.irc.privmsg(args.connection, args.target, weather.help)
        return
    end

    if not args.modules.config.weather
        or not args.modules.config.weather.geocode_key
        or not args.modules.config.weather.darksky_key then
        args.modules.irc.privmsg(args.connection, args.target,
                                 'please set config.weather.geocode_key and config.weather.darksky_key')
        return
    end

    local geocode_url = 'https://maps.google.com/maps/api/geocode/json?address=%s&key=%s'
    local body, code = https.request(geocode_url:format(url.escape(args.message),
                                                        args.modules.config.weather.geocode_key))

    if body == nil then
        args.modules.irc.privmsg(args.connection, args.target, 'error fetching location coords: ' .. code)
        return
    end

    local coords = json.decode(body).results[1].geometry.location

    local weather_url = 'https://api.darksky.net/forecast/%s/%s,%s?units=auto'
    local body, code = https.request(weather_url:format(args.modules.config.weather.darksky_key,
                                                        coords.lat, coords.lng))

    if body == nil then
        args.modules.irc.privmsg(args.connection, args.target, 'error fetching weather: ' .. code)
        return
    end

    local j = json.decode(body)

    if j == nil then
        args.modules.irc.privmsg(args.connection, args.target, 'error decoding json')
        return
    end

    local temp_units = j.flags.units == 'us' and '°F' or '°C'
    local result = ('%s %.0f%s'):format(j.currently.summary, j.currently.temperature, temp_units)

    args.modules.irc.privmsg(args.connection, args.target, result)
end

return weather
