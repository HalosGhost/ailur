return
  { ['name']     = 'freenode'
  , ['address']  = 'chat.freenode.net'
  , ['port']     = 7000
  , ['handle']   = 'hgctl'
  , ['ident']    = 'hgctl'
  , ['gecos']    = '🐼'
  , ['admins']   =
      { '.*@.*%.halosgho%.st'
      , '.*@unaffiliated/meskarune'
      }
  , ['channels'] =
      { '##meskarune'
      }
  , ['sslparams'] =
      { ['mode']     = 'client'
      , ['protocol'] = 'tlsv1_2'
      , ['verify']   = 'none'
      , ['options']  = { 'all' }
      }
  }
