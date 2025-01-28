GuildHelper_SavedVariables = {
    globalInfo = {},
    characterInfo = {},
    sharedData = {
        roster = {},
        news = {},
        guildInfo = {},
        calendar = {},
        setup = {}
    },
    exclusionList = {},
    changeLog = {}
}

function GuildHelper:ResetSavedVariables()
    GuildHelper_SavedVariables = {
        globalInfo = {},
        characterInfo = {},
        sharedData = {
            roster = {},
            news = {},
            guildInfo = {},
            calendar = {},
            setup = {}
        },
        exclusionList = {},
        changeLog = {}
    }
end

function GuildHelper:ValidateSavedData()
    local roster = GuildHelper_SavedVariables.sharedData.roster
    local characterInfo = GuildHelper_SavedVariables.characterInfo

    for toonName, toonData in pairs(characterInfo) do
        if not roster[toonName] then
            roster[toonName] = {
                id = toonName,
                tableType = "roster",
                guildName = GuildHelper:GetCombinedGuildName(),
                lastUpdated = date("%Y%m%d%H%M%S"),
                deleted = false,
                data = toonData
            }
        else
            for key, value in pairs(toonData) do
                roster[toonName].data[key] = value
            end
        end
    end

    GuildHelper_SavedVariables.sharedData.roster = roster
end

function GuildHelper:UpdateOrAddMember(toonData)
    local fullName = toonData.data.name  -- Use full name as constructed in the form
    local existingData = GuildHelper_SavedVariables.sharedData.roster[fullName]

    if existingData then
        -- Update existing member if the new data is more recent and valid
        if toonData.lastUpdated > existingData.lastUpdated and self:ValidateToonData(toonData) then
            GuildHelper_SavedVariables.sharedData.roster[fullName] = toonData
        end
    else
        -- Add new member if the data is valid
        if self:ValidateToonData(toonData) then
            GuildHelper_SavedVariables.sharedData.roster[fullName] = toonData
        end
    end
end

function GuildHelper:SyncGuildRoster()
    local numGuildMembers = GetNumGuildMembers()

    for i = 1, numGuildMembers do
        local name, rank, _, level, class, _, _, _, _, _, _, _, _, _, _, _, _, lastOnline = GetGuildRosterInfo(i)

        local toonData = {
            id = name,
            tableType = "roster",
            guildName = GetGuildInfo("player"),
            deleted = false,
            data = {
                name = name,
                class = class,
                level = level,
                rank = rank,
                itemLevel = 0,  -- Default item level
                battletag = "NA",
                roles = {},
                guildJoinDate = date("%Y-%m-%d"),
                professions = {},
                mainCharacter = "NA",
                interests = {},
                birthdate = "NA",
                faction = UnitFactionGroup("player")
            }
        }

        GuildHelper:UpdateOrAddMember(toonData)
    end

    GuildHelper:WriteLog("Guild roster synced.")
end

function GuildHelper:UpdateRosterData(guildRoster, sharedData)
    for toonName, toonData in pairs(guildRoster) do
        if sharedData.roster[toonName] then
            -- Ensure correct assignment of item level values
            sharedData.roster[toonName].data.itemLevel = toonData.data.itemLevel
        else
            sharedData.roster[toonName] = toonData
        end
    end
end

function GuildHelper:SyncMissingToons()
    print("SyncMissingToons function called")

    -- Initialize the roster if it doesn't exist
    if not GuildHelper_SavedVariables.sharedData.roster then
        GuildHelper_SavedVariables.sharedData.roster = {}
    end
    local roster = GuildHelper_SavedVariables.sharedData.roster
    local numGuildMembers = GetNumGuildMembers()

    -- Get the guild leader's realm and build the guild name once
    local guildLeaderRealm = "NA"
    local guildName = GetGuildInfo("player") or "NA"
    for i = 1, numGuildMembers do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if rankIndex == 0 then  -- Rank index 0 is the guild leader
            local _, realm = strsplit("-", name)
            guildLeaderRealm = realm or "NA"
            break
        end
    end
    local fullGuildName = guildName .. "-" .. guildLeaderRealm

    -- Populate the current guild roster
    local currentGuildRoster = {}
    for i = 1, numGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation, guid = GetGuildRosterInfo(i)

        -- Retrieve faction information from saved data if available
        local faction = roster[name] and roster[name].data.faction or "Unknown"

        if name and guildName then
            currentGuildRoster[name] = true  -- Mark toon as present in the current guild roster

            if not roster[name] then
                -- Add new toon to the roster
                roster[name] = {
                    id = name,
                    tableType = "roster",
                    guildName = fullGuildName,
                    lastUpdated = "19990101000000",
                    deleted = false,
                    data = {
                        name = name,
                        class = class or "Unknown",
                        level = level or 0,
                        rank = rank,
                        itemLevel = 0,  -- Default item level
                        battletag = "NA",
                        roles = {},
                        guildJoinDate = date("%Y-%m-%d"),
                        professions = {},
                        mainCharacter = "NA",
                        interests = {},
                        birthdate = "NA",
                        faction = faction
                    }
                }
            else
                -- Update existing toon's information
                roster[name].data.class = class or roster[name].data.class
                roster[name].data.level = level or roster[name].data.level
                roster[name].guildName = fullGuildName
                roster[name].data.rank = rank
                roster[name].deleted = false  -- Ensure the toon is marked as not deleted
            end
        end
    end

    -- Mark toons as deleted if they are no longer in the current guild's roster
    for toonName, toonData in pairs(roster) do
        if toonData.guildName == fullGuildName and not currentGuildRoster[toonName] then
            toonData.deleted = true
            --print("Toon marked as deleted: " .. toonName)
        end
    end

    -- Update the filtered roster
    self:FilterGuildData2()
end

function GuildHelper:FilterGuildData2()
    local currentGroup = GuildHelper:isGuildFederatedMember()

    local filteredRoster = {}
    local roster = GuildHelper_SavedVariables.sharedData.roster or {}

    for toonName, toonData in pairs(roster) do
        if toonData.deleted == false then -- Filter out entries marked as deleted
            for _, guild in ipairs(currentGroup) do
                if toonData.guildName == guild.name then
                    filteredRoster[toonName] = toonData
                    break
                end
            end
        end
    end

    GuildHelper_SavedVariables.filteredRoster = filteredRoster
end

function GuildHelper:ValidateToonData(toonData)
    -- Add validation logic here
    return true
end
