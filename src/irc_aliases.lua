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
      function (ms, c, t, msg)
          local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
          local thing = ms.irc_factoids[what]
          if thing ~= nil then
              ms.irc.privmsg(c, t, to .. ': ' .. thing)
          end
      end
  , ['hatroulette'] =
      function (ms, c, t, _, _, sndr)
          local ar = { '-', '+' }
          local md = { 'q', 'b', 'v', 'o' }
          local res = ar[math.random(#ar)] .. md[math.random(#md)]

          if t:byte() == 35 then
              ms.irc.privmsg(c, t, sndr .. ' rolls for a ' .. res .. '!')
          end

          ms.irc.modeset(c, t, sndr, res)
      end
  , ['..%s+.+'] =
      function (ms, c, t, msg, authed)
          local _, _, mode, recipient = msg:find('(..)%s+(.+)')

          if authed then
              ms.irc.modeset(c, t, recipient, mode)
              ms.irc.privmsg(c, t, "Tada!")
          end
      end
  , ['kick%s+.+'] =
      function (ms, c, t, msg, authed)
          local _, _, recipient, message = msg:find('kick%s+(.+)%s+(.*)')
          message = message or recipient

          if authed then
              ms.irc.kick(c, t, recipient, message)
          end
      end
  , ['you%s*.*'] =
      function (ms, c, t, msg, _, sndr)
          local _, _, attr = msg:find('you%s*(.*)')
          attr = attr == '' and attr or (' ' .. attr)
          ms.irc.privmsg(c, t, sndr .. ': No, \x1Dyou\x1D' .. attr .. '!')
      end
  }

return self
