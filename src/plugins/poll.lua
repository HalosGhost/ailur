local plugin = {}
plugin.commands = {}

local function table_contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

plugin.polls = {}

plugin.commands.open =  function (args)
    local _, _, pollid, responses = args.message:find("open%s+(%S+)%s+(.+)")
    if not pollid or not responses then
        args.modules.irc.privmsg(args.target,
            ('%s: Please give me `poll open <pollname> <choice1 choice2 ...>`')
            :format(args.sender))
        return
    end
    if polls.pollid then
        args.modules.irc.privmsg(args.target,
            ('%s: Poll %s already exists.'):format(args.sender, pollid))
        return
    end
    polls.pollid = {poll_creator = args.sender, choices = {}, votes = {}}
    for i in responses:gmatch('([^,%s]+)') do
        plugin.polls.pollid.choices[#plugin.polls.pollid.choices + 1] = i
    end
    args.modules.irc.privmsg(args.target,
        ('%s: Poll %s created by %s')
        :format(args.sender, pollid, plugin.polls.pollid.poll_creator))
end

plugin.commands.info = function (args)
    local _, _, pollid = args.message:find("info%s+(%S+)")
    if not pollid then
        args.modules.irc.privmsg(args.target, ('%s: Please give me the name of a poll.'):format(args.sender))
        return
    end
    if not plugin.polls.pollid then
        args.modules.irc.privmsg(args.target, ('%s: Poll %s does not exist.'):format(args.sender, pollid))
        return
    else
        local ballot = ''
        for i in plugin.polls.pollid.choices do ballot = ballot .. ('%s '):format(i) end
        args.modules.irc.privmsg(args.target,
            ('%s: Poll %s created by %s. Ballot: %s')
            :format(args.sender, pollid, plugin.polls.pollid.poll_creator, ballot))
    end
end

plugin.commands.vote =  function (args)
    local _, _, pollid, vote = args.message:find("vote%s+(%S+)%s+(%S+)")
    local voter = args.sender
    if not pollid or not vote then
        args.modules.irc.privmsg(args.target,
            ('%s: Please give me `poll vote <poll name> <response>`')
            :format(args.sender))
        return
    end
    if not plugin.polls.pollid then
        args.modules.irc.privmsg(args.target,
            ('%s: Poll %s does not exist.'):format(args.sender, pollid))
        return
    end
    if not table.contains(polls.pollid.choices, vote) then
        local ballot = ''
        for i in plugin.polls.pollid.choices do
            ballot = ballot .. ('%s '):format(i)
        end
        args.modules.irc.privmsg(args.target,
            ('%s: You cannot vote for that option. Ballot: %s')
            :format(args.sender, ballot))
        return
    end
    local reply = ''
    if not plugin.polls.pollid.votes.voter then
        reply = ('%s: Vote %s added for poll %s')
                :format(args.sender, vote, pollid)
    else
        reply = ('%s: Vote updated for poll %s')
                :format(args.sender, pollid)
    end
    plugin.polls.pollid.votes.voter = vote
    args.modules.irc.privmsg(args.target, reply)
end

plugin.commands.tally =  function (args)
    local _, _, pollid = args.message:find("tally%s+(%S+)")
    if not pollid then
        args.modules.irc.privmsg(args.target,
            ('%s: Please give me the name of a poll.'):format(args.sender))
        return
    end
    if not plugin.polls.pollid then
        args.modules.irc.privmsg(args.target,
        ('%s: That poll doesn\'t exist.'):format(args.sender))
        return
    end
    -- function to figure out the tally and print it
end

plugin.commands.close =  function (args)
    local _, _, pollid = args.message:find("close%s+(%S+)")
    if not pollid then
        args.modules.irc.privmsg(args.target,
            ('%s: Please give me the name of a poll.'):format(args.sender))
        return
    end
    if not plugin.polls.pollid then
        args.modules.irc.privmsg(args.target,
        ('%s: That poll doesn\'t exist.'):format(args.sender))
        return
    end
    -- function to figure out the tally and print it
    if plugin.polls[pollid].poll_creator == args.sender then
        plugin.polls[pollid] = nil
        args.modules.irc.privmsg(args.target,
        ('%s: Poll %s closed.'):format(args.sender, pollid))
    else
        args.modules.irc.privmsg(args.target,
        ('%s: %s is the poll creator, you don\'t have permission to do that.')
        :format(args.sender, plugin.polls.pollid.poll_creator))
    end
end

local h = ''
for k in pairs(plugin.commands) do
    h = ('%s|%s'):format(h, k)
end

plugin.help = ('usage: poll <%s>'):format(h:sub(2))

plugin.main = function (args)
    local _, _, action = args.message:find('(%S+)')
    local f = plugin.commands[action]
    if f then return f(args) end
    args.modules.irc.privmsg(args.target, plugin.help)
end

return plugin
