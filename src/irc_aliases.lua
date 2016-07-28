local self =
  { ['ug[maen]'] =
      function (ms, c, t, msg, _, s)
          local map = { ['m'] = 'Morning'
                      , ['a'] = 'Afternoon'
                      , ['e'] = 'Evening'
                      , ['n'] = 'Night'
                      }
          local _, _, l = msg:find('ug(.)')
          ms.irc.privmsg(c, t, 'Good (ugt) ' .. map[l] .. ' to all ' .. s.. '!')
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
                  ms.loader.hl(ms, k)
              end
          end
      end
  , ['listfacts'] =
      function (ms, c, t)
          local list = ''
          for k in pairs(ms.irc_factoids) do
              list = "'" .. k .. "' " .. list
          end; ms.irc.privmsg(c, t, list)
      end
  , ['listaliases'] =
      function (ms, c, t)
          local list = ''
          for k in pairs(ms.irc_aliases) do
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
          r1 = math.random(#prob)
          r2 = math.random(#case)
          r3 = math.random(#punct)
          ms.irc.privmsg(c, t, prob[r1] .. ' ' .. case[r2] .. punct[r3])
      end
  , ['say.*'] =
      function (ms, c, t, msg)
          local _, _, m = msg:find('say%s*(.*)')
          ms.irc.privmsg(c, t, m)
      end
  , ['give%s+%S+.+'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
          local thing = ms.irc_factoids[what]
          if thing ~= nil then
              ms.irc.privmsg(c, t, to .. ': ' .. thing)
          else
              ms.irc.privmsg(c, t, sndr .. ': `give` only works with factoids')
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
          --attr = attr == '' and attr or (' ' .. attr)
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
  }

return self
