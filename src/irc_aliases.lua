local self =
  { ['ug[maen]'] =
      function (ms, c, t, msg)
          local map = { ['m'] = 'Morning'
                      , ['a'] = 'Afternoon'
                      , ['e'] = 'Evening'
                      , ['n'] = 'Night'
                      }
          local _, _, l = msg:find('ug(.)')
          ms['irc'].privmsg(c, t, 'Good (ugt) ' .. map[l] .. ' to all!')
      end
  , ['die'] =
      function (ms, c, _, _, auth)
          if auth then c:close(); os.exit() end
      end
  , ['listfacts'] =
      function (ms, c, t)
          local list = ''
          for k in pairs(ms['irc_factoids']) do
              list = "'" .. k .. "' " .. list
          end; ms['irc'].privmsg(c, t, list)
      end
  , ['listaliases'] =
      function (ms, c, t)
          local list = ''
          for k in pairs(ms['irc_aliases']) do
              list = "'" .. k .. "' " .. list
          end; ms['irc'].privmsg(c, t, list)
      end
  , ['is.*'] =
      function (ms, c, t)
          math.randomseed(os.time())
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
          ms['irc'].privmsg(c, t, prob[r1] .. ' ' .. case[r2] .. punct[r3])
      end
  , ['say.*'] =
      function (ms, c, t, msg)
          local _, _, m = msg:find('say%s*(.*)')
          ms['irc'].privmsg(c, t, m)
      end
  , ['give%s+%S+.+'] =
      function (ms, c, t, msg)
          local _, _, to, what = msg:find('give%s+(%S+)%s+(.*)')
          local thing = ms['irc_factoids'][what]
          if thing ~= nil then
              ms['irc'].privmsg(c, t, to .. ': ' .. thing)
          end
      end
  }

return self
