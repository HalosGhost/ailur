return function (input)
  local https = require 'ssl.https'
  local ltn12 = require 'ltn12'
  local lxp   = require 'lxp'

  local apiurl = 'https://api.wolframalpha.com/v2/query'
  local appid = 'thestr'
  local query = ('%s?appid=%s&input=%s'):format(apiurl, appid, input)

  local body = {}
  local req =
    { url  = apirul
    , sink = ltn12.sink.table(body)
    }

  local _, stat = https.request(req)

  if stat == 200 then
      -- do the parsing
  end
end
