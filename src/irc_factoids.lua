return
  { ['ping']            = function (ms, c, t) ms['irc'].privmsg(c, t, '🐼') end
  , ['hello']           = function (ms, c, t) ms['irc'].privmsg(c, t, 'hai') end
  , ['are you a bot%?'] = function (ms, c, t) ms['irc'].privmsg(c, t, 'A bot? Me? Never!') end
  , ['ugm']             = function (ms, c, t) ms['irc'].privmsg(c, t, 'Good (ugt) morning to all!') end
  , ['ugn']             = function (ms, c, t) ms['irc'].privmsg(c, t, 'Good (ugt) night to all!') end
  , ['source']          = function (ms, c, t) ms['irc'].privmsg(c, t, 'cf. <https://github.com/HalosGhost/irc_bot>') end
  , ['jæja']            = function (ms, c, t) ms['irc'].privmsg(c, t, 'jæja') end
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
