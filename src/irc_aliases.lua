local json = require 'json'
local url = require 'socket.url'
local https = require 'ssl.https'
local mediawiki_alias = require 'mediawiki_alias'

local self =
  { ['ug[maen]'] =
      function (ms, c, t, msg, _, s)
          local map = { ['m'] = 'Morning'
                      , ['a'] = 'Afternoon'
                      , ['e'] = 'Evening'
                      , ['n'] = 'Night'
                      }
          local _, _, l = msg:find('ug(.)')
          ms.irc.privmsg(c, t, s .. ' says “Good (ugt) ' .. map[l] .. ' to all!”')
      end
  , ['die'] =
      function (_, c, _, _, auth)
          if auth then c:close(); os.exit() end
      end
  , ['reload%s+.+'] =
      function (ms, c, t, msg, authed)
          if not authed then return end

          local _, _, what = msg:find('reload%s+(.+)')
          for k in pairs(ms) do
              if what == k then
                  ms.irc.privmsg(c, t, 'Tada!')
                  ms.coreload(ms, k)
              end
          end
      end
  , ['fact count%s*.*'] =
      function (ms, c, t, msg)
          local _, _, key = msg:find('fact count%s*(.*)')
          ms.irc.privmsg(c, t, ms.irc_factoids.count(key))
      end
  , ['fact search%s*.*'] =
      function (ms, c, t, msg)
          local _, _, key = msg:find('fact search%s*(.*)')
          ms.irc.privmsg(c, t, ms.irc_factoids.search(key))
      end
  , ['list%s*%S*'] =
      function (ms, c, t, msg)
          local list = ''
          local _, _, what = msg:find('list%s*(%S*)')

          local tables = { ['all']      = tables
                         , ['aliases']  = ms.irc_aliases
                         , ['modules']  = ms
                         , ['admins']   = ms.irc_network.admins
                         }

          local the_table = {}
          if what == nil then
              the_table = tables
          else
              the_table = tables[what] or tables
          end

          for k in pairs(the_table) do
              list = "'" .. k .. "' " .. list
          end; ms.irc.privmsg(c, t, list)
      end
  , ['%-?%d+%.?%d*%s*.+%s+in%s+.+'] =
      function (ms, c, t, msg)
          local _, _, val, src, dest = msg:find('(%-?%d+%.?%d*)%s*(.+)%s+in%s+(.+)')
          if ms.debug then
              print(val, src, dest)
          end

          if src == dest then
              ms.irc.privmsg(c, t, '… ' .. val .. src .. '… obviously…')
              return
          end

          if ms.unit_conversion[src] == nil then
              ms.irc.privmsg(c, t, 'I cannot convert ' .. src)
              return
          end

          if ms.unit_conversion[src][dest] == nil then
              ms.irc.privmsg(c, t, 'I cannot convert ' .. src .. ' to ' .. dest)
              return
          end

          ms.irc.privmsg(c, t, val .. src .. ' is ' .. ms.unit_conversion[src][dest](tonumber(val)) .. dest)
      end
  , ['units%s*.*'] =
      function (ms, c, t, msg)
          local list = ''
          local _, _, what = msg:find('units%s*(.*)')

          local the_table = {}
          if what == nil then
              the_table = ms.unit_conversion
          else
              the_table = ms.unit_conversion[what] or ms.unit_conversion
          end

          for k in pairs(the_table) do
              list = "'" .. k .. "' " .. list
          end; ms.irc.privmsg(c, t, list)
      end
  , ['is.*'] =
      function (ms, c, t)
          local prob =
            { 'certainly', 'possibly', 'categorically', 'negatively'
            , 'positively', 'without-a-doubt', 'maybe', 'perhaps', 'doubtfully'
            , 'likely', 'definitely', 'greatfully', 'thankfully', 'undeniably'
            , 'arguably' }
          local case = { 'so', 'not', 'true', 'false' }
          local punct = { '.', '!', '…' }
          local r1 = math.random(#prob)
          local r2 = math.random(#case)
          local r3 = math.random(#punct)
          ms.irc.privmsg(c, t, prob[r1] .. ' ' .. case[r2] .. punct[r3])
      end
  , ['say%s+.+'] =
      function (ms, c, t, msg)
          local _, _, m = msg:find('say%s+(.+)')
          ms.irc.privmsg(c, t, m)
      end
  , ['act%s+.+'] =
      function (ms, c, t, msg)
          local _, _, m = msg:find('act%s+(.+)')
          ms.irc.privmsg(c, t, '\x01ACTION ' .. m .. '\x01')
      end
  , ['give%s+%S+.+'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
          if what ~= nil then
              local thing = ms.irc_factoids.find(what:gsub("^%s*(.-)%s*$", "%1"))
              ms.irc.privmsg(c, t, to .. ': ' .. (thing or (sndr .. ' wanted you to have ' .. what)))
          end
      end
  , ['hatroulette'] =
      function (ms, c, t, _, _, sndr)
          local ar = { '-', '+' }
          local md = { 'q', 'b', 'v', 'o', 'kick'}
          local mode_roll = md[math.random(#md)]

          if mode_roll == 'kick' then
              ms.irc.privmsg(c, t, sndr .. ' rolls for a kick!')
              ms.irc.kick(c, t, sndr, 'You asked for this')
              return
          end

          local res = ar[math.random(#ar)] .. mode_roll

          if t:byte() == 35 then
              ms.irc.privmsg(c, t, sndr .. ' rolls for a ' .. res .. '!')
          end

          ms.irc.modeset(c, t, sndr, res)
      end
  , ['[+-][bqvo]%s+.+'] =
      function (ms, c, t, msg, authed)
          local _, _, mode, recipient = msg:find('([+-][bqvo])%s+(.+)')

          if authed then
              ms.irc.modeset(c, t, recipient, mode)
              ms.irc.privmsg(c, t, "Tada!")
          end
      end
  , ['kick%s+%S+%s*.*'] =
      function (ms, c, t, msg, authed)
          local _, _, recipient, message = msg:find('kick%s+(%S+)%s*(.*)')
          message = message or recipient

          if authed then
              ms.irc.kick(c, t, recipient, message)
          end
      end
  , ['you.*'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, attr = msg:find('you(.*)')
          attr = attr == nil and '' or attr
          ms.irc.privmsg(c, t, sndr .. ': No, \x1Dyou\x1D' .. attr .. '!')
      end
  , ['test%s*.*'] =
      function (ms, c, t, msg)
          local _, _, test = msg:find('test%s*(.*)')
          test = test == '' and test or (' ' .. test)

          local prob = math.random()
          local rest = { '3PASS', '5FAIL', '5\x02PANIC\x02' }
          local res = prob < 0.01 and rest[3] or
                      prob < 0.49 and rest[2] or rest[1]

          ms.irc.privmsg(c, t, 'Testing' .. test .. ': [\x03' .. res .. '\x03]')
      end
  , ['roll%s+%d+d%d+'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, numdice, numsides = msg:find('roll%s*(%d+)d(%d+)')
          local rands = ''

          numdice = math.tointeger(numdice)
          numsides = math.tointeger(numsides)
          local invalid = function (n)
              return not (math.type(n) == 'integer' and n >= 1)
          end

          if invalid(numdice) or invalid(numsides) then return end

          for i=1,numdice do
              rands = math.random(numsides) .. ' ' .. rands
              if rands:len() > 510 then break end
          end

          ms.irc.privmsg(c, t, sndr .. ': ' .. rands)
      end
  , ['bloat%s*.*'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, target = msg:find('bloat%s*(.*)')
          target = target == '' and sndr or target
          ms.irc.privmsg(c, t, target .. ' is bloat.')
      end
  , ['[ <]?https?://[^> ]+.*'] =
      function (ms, c, t, msg)
          local _, _, url = msg:find('[ <]?(https?://[^> ]+).*')
          if url ~= nil then
              title = ms.get_url_title(url)
              ms.irc.privmsg(c, t, title)
          end
      end
  , ['rot13%s.*'] =
      function (ms, c, t, msg)
          local _, _, text = msg:find('rot13%s(.*)')
          if text ~= nil then
              chars = {}
              for i=1,text:len() do
                  chars[i] = text:byte(i)
              end

              rotted = ""
              for i=1,#chars do
                  letter = chars[i]
                  if letter >= 65 and letter < 91 then
                      offset = letter - 65
                      letter = string.char(65 + ((offset + 13) % 26))
                  elseif letter >= 97 and letter < 123 then
                      offset = letter - 97
                      letter = string.char(97 + ((offset + 13) % 26))
                  else
                      letter = string.char(chars[i])
                  end
                  rotted = rotted .. letter
              end

              ms.irc.privmsg(c, t, rotted)
          end
      end
  , ['restart'] =
      function (_, _, _, _, authed)
          if authed then return true end
      end
  , ['update'] =
      function (ms, c, t, _, authed)
          if authed then
              _, _, status = os.execute('git pull origin master')
              if status == 0 then
                  ms.irc.privmsg(c, t, "Tada!")
              end
          end
      end
  , ['judges'] =
      function (ms, c, t, _, _, sndr)
          ms.irc.privmsg(c, t, "So close, but " .. sndr .. " won by a nose!")
      end
  , ['join%s+%S+'] =
      function (ms, c, t, msg, authed)
          if authed then
              local _, _, chan = msg:find('join%s+(%S+)')
              if chan then
                  ms.irc.join(c, chan)
                  ms.irc.privmsg(c, t, 'Tada!')
              end
          end
      end
  , ['wiki%s+.+'] =
      mediawiki_alias('wiki%s+(.+)', 'https://en.wikipedia.org/w/api.php')
  , ['archwiki%s+.+'] =
      mediawiki_alias('archwiki%s+(.+)', 'https://wiki.archlinux.org/api.php')
  , ["'.+' is '.+'"] =
      function (ms, c, t, msg)
          local _, _, key, val = msg:find("'(.+)' is '(.+)'")
          if not key or not val then
              ms.irc.privmsg(c, t, '… what?')
          else
              ms.irc_factoids.add(key, val)
              ms.irc.privmsg(c, t, 'Tada!')
          end
      end
  , ["'.+' is nothing"] =
      function (ms, c, t, msg)
          local _, _, key = msg:find("'(.+)' is nothing")
          if not key then
              ms.irc.privmsg(c, t, '… what?')
          else
              ms.irc_factoids.remove(key)
              ms.irc.privmsg(c, t, 'Tada!')
          end
      end
  , ["pick%s+.+"] =
      function (ms, c, t, msg)
          local _, _, str = msg:find("pick%s+(.+)")
          words = {}
          if str then
              for i in str:gmatch("%S+") do
                  words[#words + 1] = i
              end
          end
          local r = math.random(#words)
          ms.irc.privmsg(c, t, words[r])
      end
  , ['uptime'] =
      function (ms, c, t)
          local upt = io.popen('uptime -p')
          ms.irc.privmsg(c, t, upt:read())
          upt:close()
      end
  , ['sysstats'] =
      function (ms, c, t)
          local disk = 'df /dev/sda1 --output=pcent | tail -n 1'
          local pipe = io.popen(disk)
          local du = pipe:read('*number') .. '%'
          pipe:close()
          pipe = io.popen('free | tail -n 2')
          local ram = pipe:read()
          pipe:close()
          local rampat = 'Mem:%s+(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)'
          local _, _, tot, fre = ram:find(rampat)
          fre = fre or 0
          tot = tot or 1
          local ru = ('%.f%%'):format(fre / tot * 100)
          ms.irc.privmsg(c, t, ('HDD: %s full; RAM: %s free'):format(du, ru))
      end
  , ['wa%s+.+'] =
      function (ms, c, t, msg)
          local _, _, cmd = msg:find('wa%s+(.+)')
          ms.irc.privmsg(c, t, ms.query_wa(cmd))
      end
  , ['weather%s+.+'] =
      function (ms, c, t, msg)
          local _, _, loc = msg:find('weather%s+(.+)')
          local cmd = 'shaman -ml "%s"'
          local pipe = io.popen(cmd:format(loc))
          local res = pipe:read()
          pipe:close()
          if res and res ~= '' then ms.irc.privmsg(c, t, res) end
      end
  }

return self
