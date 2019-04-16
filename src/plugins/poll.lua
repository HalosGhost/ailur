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

local function list_polls()
    current_polls = ''
    for k,v in pairs(plugin.polls) do
        current_polls = current_polls .. ('%s '):format(k)
    end
    if current_polls == '' then
        return 'none'
    else
        return current_polls
    end
end

local function get_tally(poll_name)
    local results = {}
    for k,v in pairs(plugin.polls[poll_name].choices) do
        results[v] = 0
    end
    for k,v in pairs(plugin.polls[poll_name].votes) do
        if results[v] then
            results[v] = results[v] + 1
        end
    end
    local tally = ''
    for k,v in pairs(results) do
        tally = tally .. ('%s[%d] '):format(k, v)
    end
    return tally
end

plugin.polls = {}

plugin.commands.open =  function (args)
    local _, _, pollid, responses = args.message:find("open%s+(%S+)%s+(.+)")
    if not pollid or not responses then
        modules.irc.privmsg(args.target,
            ('%s: Please give me `poll open <pollname> <choice1 choice2 ...>`')
            :format(args.sender))
        return
    end
    if plugin.polls[pollid] then
        modules.irc.privmsg(args.target,
            ('%s: Poll %s already exists.'):format(args.sender, pollid))
        return
    end
    plugin.polls[pollid] = {poll_creator = args.sender, choices = {}, votes = {}}
    for i in responses:gmatch('([^,%s]+)') do
        plugin.polls[pollid].choices[#plugin.polls[pollid].choices + 1] = i
    end
    modules.irc.privmsg(args.target,
        ('%s: Poll %s created by %s')
        :format(args.sender, pollid, plugin.polls[pollid].poll_creator))
end

plugin.commands.info = function (args)
    local _, _, pollid = args.message:find("info%s+(%S+)")
    if not pollid then
        modules.irc.privmsg(args.target,
            ('%s: Please give me the name of a poll. Current polls: %s')
            :format(args.sender, list_polls()))
        return
    end
    if not plugin.polls[pollid] then
        modules.irc.privmsg(args.target,
            ('%s: Poll %s does not exist. Current polls: %s')
            :format(args.sender, pollid, list_polls()))
        return
    end
    modules.irc.privmsg(args.target,
        ('%s: Poll %s created by %s. Tally: %s')
        :format(args.sender, pollid, plugin.polls[pollid].poll_creator, get_tally(pollid)))
end

plugin.commands.vote =  function (args)
    local _, _, pollid, vote = args.message:find("vote%s+(%S+)%s+(%S+)")
    local voter = args.sender
    if not pollid or not vote then
        modules.irc.privmsg(args.target,
            ('%s: Please give me `poll vote <poll name> <response>`')
            :format(args.sender))
        return
    end
    if not plugin.polls[pollid] then
        modules.irc.privmsg(args.target,
            ('%s: Poll %s does not exist. Current polls: %s')
            :format(args.sender, pollid, list_polls()))
        return
    end
    if not table_contains(plugin.polls[pollid].choices, vote) then
        local ballot = ''
        for k,v in pairs(plugin.polls[pollid].choices) do
            ballot = ballot .. ('%s '):format(v)
        end
        modules.irc.privmsg(args.target,
            ('%s: You cannot vote for that option. Ballot: %s')
            :format(args.sender, ballot))
        return
    end
    local reply = ''
    if not plugin.polls[pollid].votes[voter] then
        reply = ('%s: Vote %s added for poll %s')
                :format(args.sender, vote, pollid)
    else
        reply = ('%s: Vote updated for poll %s')
                :format(args.sender, pollid)
    end
    plugin.polls[pollid].votes[voter] = vote
    modules.irc.privmsg(args.target, reply)
end

plugin.commands.close =  function (args)
    local _, _, pollid = args.message:find("close%s+(%S+)")
    if not pollid then
        modules.irc.privmsg(args.target,
            ('%s: Please give me the name of a poll. Current polls: %s')
            :format(args.sender, list_polls()))
        return
    end
    if not plugin.polls[pollid] then
        modules.irc.privmsg(args.target,
            ('%s: That poll doesn\'t exist. Current polls: %s')
            :format(args.sender, list_polls()))
        return
    end
    if plugin.polls[pollid].poll_creator == args.sender or args.authorized then
        modules.irc.privmsg(args.target,
            ('%s: Poll %s closed. Tally: %s')
            :format(args.sender, pollid, get_tally(pollid)))
        plugin.polls[pollid] = nil
    else
        modules.irc.privmsg(args.target,
            ('%s: %s is the poll creator, you don\'t have permission to do that.')
            :format(args.sender, plugin.polls[pollid].poll_creator))
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
    modules.irc.privmsg(args.target, plugin.help)
end

return plugin
