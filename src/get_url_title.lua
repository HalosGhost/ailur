return function (url)
  local https = require 'ssl.https'
  local ltn12 = require 'ltn12'

  local body = {}
  local request =
  { ['url']  = url
  , ['sink'] = ltn12.sink.table(body)
  }

  local _, status_code = https.request(request)

  if status_code == 200 then
      local _, _, title = body[1]:find('<title>(.-)</title>')
      if title ~= nil then
          return title
      end
  end

  return 'Could not grab title'
end
