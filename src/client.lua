irc = require 'irc'

function bot_fload (ms, m)
    package.loaded[m] = nil
    ms[m] = require(m)
end

function bot_dispatch (c, mask, target, msg, resp)
    local tgt = ''
    if target:find('^#') then
        tgt = target
    else
        _, _, tgt = mask:find(':([^!]+)')
    end

    local prefix = tgt:find('^#') and ':hgctl.%s*' or ''
    for k,v in pairs(resp) do
        if msg:find('^' .. prefix .. k .. '$') then
            irc.privmsg(c, tgt, v)
        end
    end
end

function bot_run (server, responses)
    local client = irc.init(server)
    if not client then os.exit() end
    irc.conn(client, server)

    local sname = ''
    while sname == '' do
        local data = client:receive('*l')

        if data:find('376') or data:find('422') then
            print('Connected; joining channels')
            _, _, sname = data:find('(%S+)')
            irc.joinall(client, server)
        end
    end

    while true do
        local data = client:receive('*l')

        if data:find('PING') then
            irc.pong(client, sname)
        elseif data:find('PRIVMSG ' .. server.handle .. ' :reload') then
            break
        elseif data:find('PRIVMSG ' .. server.handle .. ' :die') then
            client:close()
            os.exit()
        elseif data:find('PRIVMSG') then
            local ptn = '(%S+) (%S+) (%S+) (.*)'
            local _, _, mask, _, target, text = data:find(ptn)
            bot_dispatch(client, mask, target, text, responses)
        end
    end

    client:close()
end

mods =
  { 'hgbot_network'
  , 'hgbot_factoids'
  }

while true do
    local ms = {}

    for _, v in ipairs(mods) do
        bot_fload(ms, v)
    end

    bot_run(ms['hgbot_network'], ms['hgbot_factoids'])
end
