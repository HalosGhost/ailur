return function (url)
  local https = require 'ssl.https'
  local ltn12 = require 'ltn12'

  local body = {}
  local request =
  { ['url']  = url
  , ['sink'] = ltn12.sink.table(body)
  }

  local _, status_code = https.request(request)
  local _, _, title = body[1]:find('<title>(.-)</title>')

  return status_code == 200 and title or 'Could not grab title'
end
