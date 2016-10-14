local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'

return
  function (grammar, apiurl)
      return
        function (ms, c, t, msg)
            local _, _, search = msg:find(grammar)
            if not search then
                ms.irc.privmsg(c, t, 'You want me to search for what?')
            end

            local act = '?action=opensearch&format=json&search='
            local resp = https.request(apiurl .. act .. url.escape(search))
            if resp then
                if ms.debug then print(resp) end
                local res = json.decode(resp)
                local lnk = (res[4][1] and res[4][1] ~= '') and res[4][1] or 'No results'
                local dsc = (res[3][1] and res[3][1] ~= '') and ' - ' .. res[3][1] or ''
                ms.irc.privmsg(c, t, '<' .. lnk .. '>' .. dsc)
                return
            end
        end
  end
