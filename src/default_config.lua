local config = {}

config.debug = false
config.dbpath = 'bot.db'

config.irc = { name = 'freenode'
             , address = 'chat.freenode.net'
             , port = 7000
             , handle = 'pandactl'
             , ident = 'pandactl'
             , gecos = '🐼'
             , channels =
                 { '##meskarune'
                 }
             , sslparams =
                 { mode = 'client'
                 , protocol = 'tlsv1_2'
                 , verify = 'none'
                 , options = { 'all' }
                 }
             }

return config
