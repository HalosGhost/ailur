local https = require 'ssl.https'

local plugin = {}
plugin.commands = {}

local function astro_sign(birth_day, birth_month)
    local months = {
        [01] = birth_day < 20 and "Capricorn" or "Aquarius",
        [02] = birth_day < 19 and "Aquarius" or "Pisces",
        [03] = birth_day < 21 and "Pisces" or "Aries",
        [04] = birth_day < 20 and "Aries" or "Taurus",
        [05] = birth_day < 21 and "Taurus" or "Gemini",
        [06] = birth_day < 21 and "Gemini" or "Cancer",
        [07] = birth_day < 23 and "Cancer" or "Leo",
        [08] = birth_day < 23 and "Leo" or "Virgo",
        [09] = birth_day < 23 and "Virgo" or "Libra",
        [10] = birth_day < 23 and "Libra" or "Scorpio",
        [11] = birth_day < 22 and "Scorpio" or "Sagittarius",
        [12] = birth_day < 22 and "Sagittarius" or "Capricorn",
    }
    local sign = months[birth_month]
    if sign then
        return months[birth_month]
    else
        return false
    end
end

local signs = { "capricorn", "aquarius", "pisces", "aries", "taurus", "gemini",
                "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius" }

local function get_horoscope(birth_sign)
    local url = ("https://www.astrology.com/horoscope/daily.html?sign=%s"):format(birth_sign)
    local response = https.request(url)
    if response then
        local _, _, horoscope = response:find('<p.-><span class="date">.-</span> (.-)</p>')
        return ("Today's horoscope - %s - %s"):format(string.sub(horoscope, 1, 220), url) or "No Results"
    end
    return "Something went wrong with the request"
end

plugin.commands.sign = function(args)
    local _, _, day, month = args.message:find("sign%s+(%d%d)%-(%d%d)")
    if not day or not month then
        modules.irc.privmsg(args.target,
            ('%s: Please give me `astrology sign DD-MM` replacing DD with a 2 digit day and MM with a two digit month.')
            :format(args.sender))
        return
    end
    if args.conf.debug then
        print(day .. " " .. month)
    end
    local birth_day = tonumber(day)
    local birth_month = tonumber(month)
    if args.conf.debug then
        print(birth_day .. " " .. birth_month)
    end
    local sign = astro_sign(birth_day, birth_month)
    if sign then
        modules.irc.privmsg(args.target,
            ("%s: Your astrological sign is %s."):format(args.sender, sign))
    else
        modules.irc.privmsg(args.target,
            ("%s: Please use the gregorian calendar system."):format(args.sender))
    end
end

plugin.commands.list = function(args)
    modules.irc.privmsg(args.target,
        ("%s: The 12 astrological signs are: Capricorn, Aquarius, Pisces, Aries, Taurus, Gemini, Cancer, Leo, Virgo, Libra Scorpio and Sagittarius."):format(args.sender))
end

plugin.commands.horoscope = function(args)
    local _, _, sign = args.message:find("horoscope%s+(%S+)")
    if not sign then
        modules.irc.privmsg(args.target,
            ("%s: Please give me `astrology <astrological sign>` You can list all the signs with `astrology list`")
            :format(args.sender))
        return
    end
    local astro_sign = sign:lower()
    if args.conf.debug then
        print(astro_sign)
    end
    for _, value in pairs(signs) do
        if value == astro_sign then
            local horoscope = get_horoscope(astro_sign)
            modules.irc.privmsg(args.target, ("%s: %s"):format(args.sender, horoscope))
            return
        end
    end
    modules.irc.privmsg(args.target, ("%s: Not a valid astrological sign. List signs with `astrology list`"):format(args.sender))
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end

plugin.help = ('usage: astrology <%s>'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = plugin.commands[action]
    if f then return f(args) end
    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
