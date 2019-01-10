local convert = {}

convert['°C'] = {}
convert['°C']['°F'] = function(n) return n * 1.8 + 32 end
convert['°C']['K']  = function(n) return n + 273.15 end

convert['°F'] = {}
convert['°F']['°C'] = function(n) return (n - 32) / 1.8 end
convert['°F']['K']  = function(n) return convert['°C']['K'](convert['°F']['°C'](n)) end

convert['K'] = {}
convert['K']['°C']  = function(n) return n - 273.15 end
convert['K']['°F']  = function(n) return convert['°C']['°F'](convert['K']['°C'](n)) end

convert['m'] = {}
convert['m']['mi'] = function(n) return n * 0.00062137 end

convert['mi'] = {}
convert['mi']['m'] = function(n) return n / 0.00062137 end

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

local units = {
    convert = convert,
    si = si,
    iec = iec,
    unit_aliases = unit_aliases,
    si_aliases = si_aliases,
    iec_aliases = iec_aliases,
}

return units
