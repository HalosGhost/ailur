local eval = {}

eval.help = 'eval <lua-expr>'

-- Thouroughly copy tables to the safe env so that the
-- sandbox can't change code outside of its environment.
eval.deepcopy = function (orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[eval.deepcopy(orig_key)] = eval.deepcopy(orig_value)
        end
        setmetatable(copy, eval.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- A simple pretty printer for lua values.
eval.inspect = function (thing)
    if type(thing) == 'table' then
        local formats = {
            ['table'] = '{…}',
            ['function'] = '<function>',
            ['string'] = '%q',
        }

        local result = ''
        for k, v in pairs(thing) do
            result = ('%s, %s = ' .. (formats[type(v)] or '%s')):format(result, k, v)
        end

        return ('{ %s }'):format(result:sub(3))
    else
        return tostring(thing)
    end
end

eval.main = function (args)
    if args.message == '' then
        args.modules.irc.privmsg(args.connection, args.target, eval.help)
        return
    end

    local safe_env = {
        sender   = args.sender,
        target   = args.target,
        message  = args.message,
        args     = args.authorized and eval.deepcopy(args) or nil,
        bit32    = eval.deepcopy(bit32),
        math     = eval.deepcopy(math),
        os       = { clock=os.clock, date=os.date, difftime=os.difftime, time=os.time },
        string   = eval.deepcopy(string),
        table    = eval.deepcopy(table),
        tonumber = tonumber,
        tostring = tostring,
        type     = type,
        unpack   = unpack,
    }

    local chunk = ('return ' .. (args.message:find(';') and '(function() %s; end)()' or '%s')):format(args.message)

    local naughty_statements = { 'while', 'for', 'repeat', 'goto' }

    for _, pattern in pairs(naughty_statements) do
        local _, _, statement = chunk:find('(' .. pattern .. ')[%(%s]')
        if statement then
            args.modules.irc.privmsg(args.connection, args.target,
                                     statement .. ' statements are not currently supported')
            return
        end
    end

    -- use pcall so we can catch errors that would otherwise kill the bot
    local status, result = pcall(load(chunk, nil, 't', safe_env))
    if status then
        result = eval.inspect(result)
    end

    args.modules.irc.privmsg(args.connection, args.target, result)
end

return eval
