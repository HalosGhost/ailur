-- fun but pointless games

local invalid_num = function (n)
    return not (math.type(n) == 'integer' and n >= 1)
end

local plugin = {}

plugin.commands = {}

plugin.commands.test = function (args)
    local _, _, message = args.message:find('test%s+(.*)')
    local prob = math.random()
    local rest = { '3PASS', '5FAIL', '5\x02PANIC\x02' }
    local res = prob < 0.01 and rest[3] or
    prob < 0.49 and rest[2] or rest[1]
    args.modules.irc.privmsg(args.target, ('%s: Testing %s: [\x03%s\x03]'):format(args.sender, message, res))
end

plugin.commands.roll = function (args)
    local _, _, numdice, numsides = args.message:find('roll%s+(%d+)d(%d+)')
    local rands = ''

    numdice = math.tointeger(numdice)
    numsides = math.tointeger(numsides)

    if invalid_num(numdice) or invalid_num(numsides) then 
        --args.modules.irc.privmsg(args.target, ('%s: Please tell me the number of dice and the number of sides, ie: "2d6" for two six sided dice'):format(args.sender))
        return
    end

    for i=1,numdice do
        rands = ('%d %s'):format(math.random(numsides), rands)
        if rands:len() > 510 then break end
    end

    args.modules.irc.privmsg(args.target, ('%s: %s'):format(args.sender, rands))
end

plugin.commands.coinflip = function (args)
    local _, _, numflips = args.message:find('coinflip%s+(%d+)')

    if numflips and numflips:len() > 4 then
        --args.modules.irc.privmsg(args.target, 'Please give me a number less than 5 digits long.')
        return
    end

    if not numflips or numflips == ' ' then
        numflips = 1
    else
        numflips = math.tointeger(numflips)
    end

    if invalid_num(numflips) then
        --args.modules.irc.privmsg(args.target, ('%s: Tell me how many coinflips you want'):format(args.sender))
        return
    end

    local heads = 0
    local tails = 0

    for i=1, numflips do
        flip = math.random(2)
        if flip == 1 then
            heads = heads + 1
        else
            tails = tails + 1
        end
    end

    args.modules.irc.privmsg(args.target, ('%s: heads: %d tails: %d'):format(args.sender, heads, tails))
end

plugin.commands.magic8ball = function (args)
    local _, _, message = args.message:find('magic8ball%s+(.*)')
    local predictions = {
        positive = {
            'It is possible.', 'Yes!', 'Of course.', 'Naturally.',
            'Obviously.', 'It shall be.', 'The outlook is good.',
            'It is so.', 'One would be wise to think so.',
            'The answer is certainly yes.'
        },
        negative = {
            'In your dreams.', 'I doubt it very much.', 'No chance.',
            'The outlook is poor.', 'Unlikely.', 'Categorically no.',
            "You're kidding, right?", 'No!', 'No.', 'The answer is a resounding no.'
        },
        unknown = {
            'Maybe...', 'No clue.', "_I_ don't know.",
            'The outlook is hazy.', 'Not sure, ask again later.',
            'What are you asking me for?',
            'Come again?', 'The answer is in the stars.',
            'You know the answer better than I.',
            'The answer is def-- oooh shiny thing!'
        }
    }
    if not message then
        --args.modules.irc.privmsg(args.target, ('%s: Ask me a question.'):format(args.sender))
        return
    end

    if message and message:len() % 3 == 0 then
        reply = predictions.positive[math.random(10)]
    elseif message and message:len() % 3 == 1 then
        reply = predictions.negative[math.random(10)]
    else
        reply = predictions.unknown[math.random(10)]
    end
    args.modules.irc.privmsg(args.target, ('%s: %s'):format(args.sender, reply))
end

plugin.commands.is = function (args)
    local prob = { 'certainly', 'possibly', 'categorically', 'negatively'
                 , 'positively', 'without-a-doubt', 'maybe', 'perhaps', 'doubtfully'
                 , 'likely', 'definitely', 'greatfully', 'thankfully', 'undeniably'
                 , 'arguably'
                 }

    local case = { 'so', 'not', 'true', 'false' }
    local punct = { '.', '!', '…' }

    local r1 = math.random(#prob)
    local r2 = math.random(#case)
    local r3 = math.random(#punct)
    args.modules.irc.privmsg(args.target, ('%s: %s %s%s'):format(args.sender, prob[r1], case[r2], punct[r3]))
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end

plugin.help = ('usage: play <%s>'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = plugin.commands[action]

    if f then return f(args) end
    args.modules.irc.privmsg(args.target, plugin.help)
end

return plugin
