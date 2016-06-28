return
  { ['ping']            = function (c, t) c:send('PRIVMSG ' .. t .. ' :🐼\r\n') end
  , ['hello']           = function (c, t) c:send('PRIVMSG ' .. t .. ' :hai\r\n') end
  , ['are you a bot%?'] = function (c, t) c:send('PRIVMSG ' .. t .. ' :A bot? Me? Never!\r\n') end
  , ['ugm']             = function (c, t) c:send('PRIVMSG ' .. t .. ' :Good (ugt) morning to all!\r\n') end
  , ['ugn']             = function (c, t) c:send('PRIVMSG ' .. t .. ' :Good (ugt) night to all!\r\n') end
  , ['source']          = function (c, t) c:send('PRIVMSG ' .. t .. ' :cf. <https://github.com/HalosGhost/irc_bot>\r\n') end
  , ['is.*']            =
      function (c, t)
          math.randomseed(os.time())
          local prob = { 'certainly', 'possibly', 'categorically' }
          local case = { 'so', 'not', 'true', 'false' }
          c:send('PRIVMSG ' .. t .. ' :' .. prob[math.random(#prob)] .. ' ' .. case[math.random(#prob)] .. '\r\n')
      end
  }
