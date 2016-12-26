local https = require 'ssl.https'
local ltn12 = require 'ltn12'
local lxp   = require 'lxp'

return function (input)
  local apiurl = 'https://api.wolframalpha.com/v2/query'
  local appid = 'thestr'
  local query = ('%s?appid=%s&input=%s'):format(apiurl, appid, input)

  local body = {}
  local req =
    { url  = query
    , sink = ltn12.sink.table(body)
    }

  local _, stat = https.request(req)
  local result = ''

  wolfram_callbacks =
    { StartElement = function (parser, elName, attrs)
        if elName == 'pod' and attrs.title ~= 'Input' then
          local _, off, pos = parser:pos()
          result = body[1]:match('.-</pod>.-<plaintext>(.-)</plaintext>')
        end
      end
  }

  local p = lxp.new(wolfram_callbacks)

  if stat == 200 then
      p:parse(body[1])
  end

  p:parse()
  p:close()

  return result
end
