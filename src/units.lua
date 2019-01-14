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

return units
