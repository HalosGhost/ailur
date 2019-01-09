local units = {}

units['°C'] = {}
units['°C']['°F'] = function(n) return n * 1.8 + 32 end
units['°C']['K']  = function(n) return n + 273.15 end

units['°F'] = {}
units['°F']['°C'] = function(n) return (n - 32) / 1.8 end
units['°F']['K']  = function(n) return units['°C']['K'](units['°F']['°C'](n)) end

units['K'] = {}
units['K']['°C']  = function(n) return n - 273.15 end
units['K']['°F']  = function(n) return units['°C']['°F'](units['K']['°C'](n)) end

units['km'] = {}
units['km']['mi'] = function(n) return n * 0.62137 end

units['mi'] = {}
units['mi']['km'] = function(n) return n / 0.62137 end

return units
