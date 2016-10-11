local sql = require 'lsqlite3'

local ins = nil
local cnt = nil
local del = nil
local sel = nil

local self =
  { search = function (key)
      sel:reset()
      sel:bind_names({ ['key'] = key })
      for v in sel:urows() do
          return v
      end
    end
  , count = function (key)
      cnt:reset()
      local key = key and '%' .. key .. '%' or '%'
      cnt:bind_names({ ['key'] = key })
      for c in cnt:urows() do
          return (c > 0 and c or 'Found no results')
      end
    end
  , add = function (key, value)
      del:reset()
      del:bind_names({ ['key'] = key })
      local res = del:step()

      ins:reset()
      ins:bind_names({ ['key'] = key, ['value'] = value })
      res = ins:step()
      return (res == 101 and 'Tada!' or db:errmsg())
    end
  , remove = function (key)
      del:reset()
      del:bind_names({ ['key'] = key })
      local res = del:step()
      return (res == 101 and 'Tada!' or db:errmsg())
    end
  , init = function (dbpath)
      db = sql.open(dbpath)
      if db == nil then
          print('Failed to open the database')
      end
      ins = db:prepare('insert or replace into factoids (key, value) values (:key, :value);')
      cnt = db:prepare('select count(*) from factoids where key like :key;')
      del = db:prepare('delete from factoids where key = :key;')
      sel = db:prepare('select value from factoids where key = :key;')
    end
  , cleanup = function ()
      ins:finalize()
      cnt:finalize()
      del:finalize()
      sel:finalize()
      db:close()
    end
  }

return self
