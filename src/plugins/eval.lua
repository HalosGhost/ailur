local plugin = {}

plugin.help = 'eval <lua-expr>'

-- Thouroughly copy tables to the safe env so that the
-- sandbox can't change code outside of its environment.
plugin.deepcopy = function (orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[plugin.deepcopy(orig_key)] = plugin.deepcopy(orig_value)
        end
        setmetatable(copy, plugin.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- A simple pretty printer for lua values.
plugin.inspect = function (thing)
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

plugin.main = function (args)
    if args.message == '' then
        args.modules.irc.privmsg(args.connection, args.target, plugin.help)
        return
    end

    local safe_env = {
        sender   = args.sender,
        target   = args.target,
        message  = args.message,
        args     = args.authorized and plugin.deepcopy(args) or nil,
        bit32    = plugin.deepcopy(bit32),
        math     = plugin.deepcopy(math),
        os       = { clock=os.clock, date=os.date, difftime=os.difftime, time=os.time },
        string   = plugin.deepcopy(string),
        table    = plugin.deepcopy(table),
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
        result = plugin.inspect(result)
    end

    args.modules.irc.privmsg(args.connection, args.target, result)
end

return plugin
