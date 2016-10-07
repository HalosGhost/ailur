local sql = require 'lsqlite3'

local self =
  { search = function (key)
      local preamble = 'select value from factoids where key = "'
      for v in db:urows( preamble .. key .. '"') do
          return v
      end
    end
  , add = function (key, value)
      local preamble = 'insert into factoids values ("' .. key
      local res = db:exec(preamble .. '","' .. value .. '")')
      if res == 0 then
          return 'Tada!'
      else
          return db:errmsg()
      end
    end
  , remove = function (key)
      local preamble = 'delete from factoids where key = "'
      local res = db:exec(preamble .. key .. '"')
    end
  , init = function (dbpath)
      db = sql.open(dbpath)
      repeat until db:isopen()
    end
  , cleanup = function ()
      db:close()
    end
  }

--local self =
--  { ['ping']           = '🐼'
--  , ['hello']          = 'hai'
--  , ['are you a bot?'] = 'A bot? Me? Never!'
--  , ['source']         = 'cf. <https://github.com/HalosGhost/irc_bot>'
--  , ['jæja']           = 'jæja'
--  , ['help']           = 'see `list all`'
--  , ['﻿']         = 'Halp! I\'ze been haXXed!'
--  , ['stahp']          = 'ಠ_ಠ'
--  , ['best']           = 'Use what is best for \x1Dyou!\x1D'
--  , ['halosghost']     = 'Do what feels right!'
--  , ['ugt']            = '<http://www.total-knowledge.com/~ilya/mips/ugt.html>'
--  , ['when']           = 'Should Happen Any Day Now™'
--  , ['thanks']         = "You're welcome, meatbag."
--  , ['next']           = 'Another satisfied customer. \x1DNext!\x1D'
--  , ['how do I panda?'] = '<https://2.bp.blogspot.com/-Ctjx0gkGz3s/T-ouomdvt7I/AAAAAAAAGL8/DDk7I33PbOM/s1600/how+to+be+a+panda.jpg>'
--  , ['stats']          = 'Friendly Reminder: personal experience is not equivalent to statistical relevance'
--  , ['skynet']         = "Just keep adding factoids; I'll get there eventually"
--  }

return self
