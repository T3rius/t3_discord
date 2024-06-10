------------------------------------
-- support: discord.gg/yZv3F6Bhd6 --
------------------------------------
function GetDiscordUserInfo(discordId, callback)
    local endpoint = string.format("https://discord.com/api/v9/users/%s", discordId)
    PerformHttpRequest(endpoint, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data.username and data.discriminator then
                callback(data)
            else
                if Config.Debug == true then
                    print("Invalid data received: " .. response)
                end
                callback(nil)
            end
        else
            if Config.Debug == true then
                print("Failed to fetch Discord user data: " .. statusCode)
            end
            callback(nil)
        end
    end, 'GET', '', {['Authorization'] = 'Bot ' .. Config.DiscordBotToken})
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local player = source
    deferrals.defer()
    local identifiers = GetPlayerIdentifiers(player)
    local discordId = nil
    for _, identifier in ipairs(identifiers) do
        if string.sub(identifier, 1, 8) == "discord:" then
            discordId = string.sub(identifier, 9)
            break
        end
    end
    
    if not discordId then
        deferrals.done(Config.Kickmsg.discordidmsg)
        return
    end

    for _, allowedId in ipairs(Config.BypassUsers) do
        if discordId == allowedId then
            deferrals.done()
            return
        end
    end
    
    GetDiscordUserInfo(discordId, function(userInfo)
        if not userInfo then
            deferrals.done(Config.Kickmsg.discordinfomsg)
            return
        end

        local creationDate = tonumber(discordId) / 4194304 + 1420070400000
        local accountAgeInDays = (os.time() - (creationDate / 1000)) / 86400

        local discordName = userInfo.username
        if Config.Debug == true then
            print("Discord name: " .. discordName)
            print("Name in game: " .. name)
            print("Age of account in days: " .. accountAgeInDays)
        end
        
        if Config.Agecheck and accountAgeInDays < Config.Days then
            deferrals.done(Config.Kickmsg.agemsg)
        elseif Config.Namecheck and discordName ~= name then
            deferrals.done(Config.Kickmsg.namemsg)
        else
            deferrals.done()
        end
    end)
end)
