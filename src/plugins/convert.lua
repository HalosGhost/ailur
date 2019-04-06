local plugin = {}

local conversion = {}

conversion['°C'] = {}
conversion['°C']['°F'] = function(n) return n * 1.8 + 32 end
conversion['°C']['K']  = function(n) return n + 273.15 end

conversion['°F'] = {}
conversion['°F']['°C'] = function(n) return (n - 32) / 1.8 end
conversion['°F']['K']  = function(n) return conversion['°C']['K'](conversion['°F']['°C'](n)) end

conversion['K'] = {}
conversion['K']['°C']  = function(n) return n - 273.15 end
conversion['K']['°F']  = function(n) return conversion['°C']['°F'](conversion['K']['°C'](n)) end

conversion['m'] = {}
conversion['m']['mi']  = function(n) return n * 0.00062137 end

conversion['mi'] = {}
conversion['mi']['m']  = function(n) return n / 0.00062137 end

local si = {
   ['y']  = -24,
   ['z']  = -21,
   ['a']  = -18,
   ['f']  = -15,
   ['p']  = -12,
   ['n']  =  -9,
   ['µ']  =  -6,
   ['m']  =  -3,
   ['c']  =  -2,
   ['d']  =  -1,
   ['da'] =   1,
   ['h']  =   2,
   ['k']  =   3,
   ['M']  =   6,
   ['G']  =   9,
   ['T']  =  12,
   ['P']  =  15,
   ['E']  =  18,
   ['Z']  =  21,
   ['Y']  =  24,
}

local iec = {
   Ki =  3,
   Mi =  6,
   Gi =  9,
   Ti = 12,
   Pi = 15,
   Ei = 18,
   Zi = 21,
   Yi = 24,
}

local unit_aliases = {
    ['°C'] = { '°C', 'degrees? Celsius', 'degrees? C' },
    ['°F'] = { '°F', 'degrees? Fahrenheit', 'degrees? F' },
    ['K']  = { 'K', 'kelvins?' },
    ['m'] =  { 'm', 'meters?' },
    ['mi'] = { 'mi', 'miles?' },
}

local si_aliases = {
    ['y']  = { 'y', 'yocto' },
    ['z']  = { 'z', 'zepto' },
    ['a']  = { 'a', 'atto' },
    ['f']  = { 'f', 'femto' },
    ['p']  = { 'p', 'pico' },
    ['n']  = { 'n', 'nano' },
    ['µ']  = { 'µ', 'micro' },
    ['m']  = { 'm', 'milli' },
    ['c']  = { 'c', 'centi' },
    ['d']  = { 'd', 'deci' },
    ['da'] = { 'da', 'deca' },
    ['h']  = { 'h', 'hecto' },
    ['k']  = { 'k', 'kilo' },
    ['M']  = { 'M', 'mega' },
    ['G']  = { 'G', 'giga' },
    ['T']  = { 'T', 'tera' },
    ['P']  = { 'P', 'peta' },
    ['E']  = { 'E', 'exa' },
    ['Z']  = { 'Z', 'zetta' },
    ['Y']  = { 'Y', 'yotta' },
}

local iec_aliases = {
    ['Ki'] = { 'Ki', 'kibi' },
    ['Mi'] = { 'Mi', 'mebi' },
    ['Gi'] = { 'Gi', 'gibi' },
    ['Ti'] = { 'Ti', 'tebi' },
    ['Pi'] = { 'Pi', 'pebi' },
    ['Ei'] = { 'Ei', 'exbi' },
    ['Zi'] = { 'Zi', 'zebi' },
    ['Yi'] = { 'Yi', 'yobi' },
}

local parse_unit = function(src)
    local pos = 0
    for k, v in pairs(unit_aliases) do
        for _, u in ipairs(v) do
            pos = src:find('(' .. u .. ')$')
            if pos ~= nil then return k, pos end
        end
    end
end

local parse_prefix = function(prefix, aliases, base, magnitudes)
    for k, v in pairs(aliases) do
        for _, p in ipairs(v) do
            if prefix == p then return base ^ magnitudes[k] end
        end
    end
end

local units = {
    conversion = conversion,
    si = si,
    iec = iec,
    unit_aliases = unit_aliases,
    si_aliases = si_aliases,
    iec_aliases = iec_aliases,
    parse_unit = parse_unit,
    parse_prefix = parse_prefix,
}

plugin.help = 'Usage: convert <number> <from-unit> <to-unit>'

plugin.main = function(args)
    local _, _, val, src, dest = args.message:find('(%-?%d+%.?%d*)%s*(.+)%s+(.+)')
    if args.conf.debug then
        print(val, src, dest)
    end

    if not val or not src or not dest then
        modules.irc.privmsg(args.target, ('%s: Give me a request in the format <number> <from-unit> <to-unit>'):format(args.sender))
        return
    end

    if not tonumber(val) and val then
        modules.irc.privmsg(args.target, ('%s: %s is not a number I recognize'):format(args.sender, val))
        return
    end
    val = tonumber(val)

    if src == dest then
        modules.irc.privmsg(args.target, ('%s: … %g %s… obviously…'):format(args.sender, val, src))
        return
    end

    local src_unit, pos = parse_unit(src)
    if src_unit == '' or not conversion[src_unit] then
        modules.irc.privmsg(args.target, ('%s: I cannot convert %s to %s'):format(args.sender, src, dest))
        return
    end

    local val_adj = 1
    if pos > 1 then
        local prefix = src:sub(1, pos - 1)
        val_adj = parse_prefix(prefix, si_aliases, 10, si)
        val_adj = val_adj or
        parse_prefix(prefix, iec_aliases, 2, iec)
    end
    if args.conf.debug then print(val_adj) end
    if val_adj == nil then
        modules.irc.privmsg(args.target, ('%s: I cannot convert that number'):format(args.sender))
        return
    end

    local dest_unit, pos = parse_unit(dest)

    if src_unit ~= dest_unit and (dest_unit == '' or not conversion[src_unit][dest_unit]) then
        if args.conf.debug then print(dest_unit) end
        modules.irc.privmsg(args.target, ('%s: I cannot convert %s to %s'):format(args.sender, src, dest))
        return
    end

    local dest_adj = 1
    local dest_prefix = ''
    if pos > 1 then
        dest_prefix = dest:sub(1, pos - 1)
        dest_adj = parse_prefix(dest_prefix, si_aliases, 10, si)
        dest_adj = dest_adj or
        parse_prefix(dest_prefix, iec_aliases, 2, iec)
    end

    local new_val = src_unit == dest_unit
    and (val_adj * val / dest_adj)
    or (conversion[src_unit][dest_unit](val_adj * val) / dest_adj)

    modules.irc.privmsg(args.target, ('%s: %g %s is %g %s%s')
                             :format(args.sender, val, src, new_val, dest_prefix, dest_unit))
end

return plugin
