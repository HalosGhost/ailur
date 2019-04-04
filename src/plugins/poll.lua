local plugin = {}
plugin.commands = {}

plugin.polls = {}

plugin.commands.open =  function (args)
    -- poll open <poll name> <response1, response2, ...>
    local _, _, pollid, responses = args.message:find("open%s+(%S+)%s+(.+)")

    if not pollid or not responses then
        args.modules.irc.privmsg(args.target, plugin.help)
        return
    end

    if polls.pollid then
        args.modules.irc.privmsg(args.target, ('%s: Poll %s already exists.'):format(args.sender, pollid))
        return
    end

    polls.pollid = {poll_creator = args.sender, choices = {}, votes = {}}

    for i in responses:gmatch('([^,%s]+)') do
        plugin.polls.pollid.choices[#plugin.polls.pollid.choices + 1] = i
    end

    args.modules.irc.privmsg(args.target, ('%s: Poll %s created by %s'):format(args.sender, pollid, plugin.polls.pollid.poll_creator))
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
    -- poll vote <poll name> <response>
    local _, _, pollid, vote = args.message:find("vote%s+(%S+)%s+(%S+)")

    plugin.polls.pollid.votes[args.sender] = vote
end

plugin.commands.tally =  function (args)
    -- poll tally <poll name>
    local _, _, pollid = args.message:find("tally%s+(%S+)")
end

plugin.commands.close =  function (args)
    -- poll close <poll name>
    local _, _, pollid = args.message:find("close%s+(%S+)")
    if plugin.polls[pollid].poll_creator then
        if plugin.polls[pollid].poll_creator == args.sender then
            plugin.polls[pollid] = nil
        else
            args.modules.irc.privmsg(args.target, ('%s: %s is the poll creator, you don\'t have permission to do that.'):format(args.sender, plugin.polls[pollid].poll_creator))
        end
    else
        args.modules.irc.privmsg(args.target, ('%s: That poll doesn\'t exist.'):format(args.sender))
   end
    local authed = polls[1].testpoll.poll_creator
    -- print the results of the poll and delete the table
    -- only the user who started the poll can close it
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
