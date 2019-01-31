local eval = {}

eval.help = 'eval <lua-expr>'

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

eval.inspect = function (thing)
    if type(thing) == 'table' then
        local formats = {
            ['table'] = '{…}',
            ['function'] = '<function>',
            ['string'] = '"%s"',
        }

        local result = ''
        for k, v in pairs(thing) do
            local value_format = formats[type(v)] or '%s'
            result = ('%s, %s = ' .. value_format):format(result, k, v)
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

    if args.message:find('while') or args.message:find('for') or args.message:find('repeat') then
        args.modules.irc.privmsg(args.connection, args.target, 'loops are currently not supported')
        return
    end

    if args.message:find('goto') then
        args.modules.irc.privmsg(args.connection, args.target, 'goto is currently not supported')
        return
    end

    local safe_env = {
        sender   = args.sender,
        target   = args.target,
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

    local status, result = pcall(load('return ' .. args.message, nil, 't', safe_env))
    if status then
        result = eval.inspect(result)
    end

    args.modules.irc.privmsg(args.connection, args.target, result)
end

return eval
