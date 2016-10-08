local sql = require 'lsqlite3'

local ins = nil
local del = nil
local sel = nil

local self =
  { search = function (key)
      sel:bind_names({ ['key'] = key })
      for v in sel:urows() do
          return v
      end
    end
  , add = function (key, value)
      ins:bind_names({ ['key'] = key, ['value'] = value })
      local res = ins:step()
      return (res == 101 and 'Tada!' or db:errmsg())
    end
  , remove = function (key)
      del:bind_names({ ['key'] = key })
      local res = del:step()
      return (res == 101 and 'Tada!' or db:errmsg())
    end
  , init = function (dbpath)
      db = sql.open(dbpath)
      if db == nil then
          print('Failed to open the database')
      end
      ins = db:prepare('insert into factoids (key, value) values (:key, :value);')
      del = db:prepare('delete from factoids where key = :key;')
      sel = db:prepare('select value from factoids where key = :key;')
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
