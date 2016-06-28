self =
  { ['ping']            = function (ms, c, t) ms['irc'].privmsg(c, t, '🐼') end
  , ['hello']           = function (ms, c, t) ms['irc'].privmsg(c, t, 'hai') end
  , ['are you a bot%?'] = function (ms, c, t) ms['irc'].privmsg(c, t, 'A bot? Me? Never!') end
  , ['ug[maen]']        =
      function (ms, c, t, msg)
          local map = { ['m'] = 'Morning'
                      , ['a'] = 'Afternoon'
                      , ['e'] = 'Evening'
                      , ['n'] = 'Night'
                      }
          local _, _, l = msg:find('ug(.)')
          ms['irc'].privmsg(c, t, 'Good (ugt) ' .. map[l] .. ' to all!')
      end
  , ['source']          = function (ms, c, t) ms['irc'].privmsg(c, t, 'cf. <https://github.com/HalosGhost/irc_bot>') end
  , ['jæja']            = function (ms, c, t) ms['irc'].privmsg(c, t, 'jæja') end
  , ['die']             =
      function (ms, c, _, _, auth)
          if auth then
              c:close()
              os.exit()
          end
      end
  , ['listfacts']       =
      function (ms, c, t)
          local list = ''
          for k in pairs(self) do
              list = "'" .. k .. "' " .. list
          end; ms['irc'].privmsg(c, t, list)
      end
  , ['is.*']            =
      function (ms, c, t)
          math.randomseed(os.time())
          local prob = { 'certainly', 'possibly', 'categorically' }
          local case = { 'so', 'not', 'true', 'false' }
          r1 = math.random(#prob)
          r2 = math.random(#case)
          ms['irc'].privmsg(c, t, prob[r1] .. ' ' .. case[r2])
      end
  , ['say.*']           =
      function (ms, c, t, msg)
          local _, _, m = msg:find('say%s*(.*)')
          ms['irc'].privmsg(c, t, m)
      end
  }

return self
