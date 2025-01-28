-- Functions.lua
-- This file contains reusable functions for the GuildHelper addon

local changelogKey = "GuildHelper_Changelog"

function GuildHelper:ValidateDateFormat(dateText)
    return dateText:match("^%d%d%d%d%-%d%d%-%d%d$")
end

function GuildHelper:SaveCharacterInfo(globalInfo, characterInfo)
    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {}
    end
    if not GuildHelper_SavedVariables.sharedData.roster then
        GuildHelper_SavedVariables.sharedData.roster = {}
    end

    -- Ensure no nil values are passed
    for key, value in pairs(globalInfo) do
        if value == nil or value == "" then
            globalInfo[key] = "NA"
        end
    end

    for key, value in pairs(characterInfo) do
        if value == nil or value == "" then
            characterInfo[key] = "NA"
        end
    end

    -- Add a lastUpdated timestamp
    local timestamp = date("%Y%m%d%H%M%S")
    globalInfo.lastUpdated = timestamp
    characterInfo.lastUpdated = timestamp

    -- Ensure guild name and realm name are captured
    local fullName = characterInfo.pt_name  -- Ensure fullName is defined

    GuildHelper_SavedVariables.globalInfo = globalInfo
    GuildHelper_SavedVariables.characterInfo[fullName] = characterInfo  -- Save with full name

    GuildHelper:AddLogEntry("Character information saved: " .. fullName)

    -- Update the shared roster with the character information without overwriting existing data
    if not GuildHelper_SavedVariables.sharedData.roster[fullName] then
        GuildHelper_SavedVariables.sharedData.roster[fullName] = {
            id = fullName,
            tableType = "roster",
            guildName = GuildHelper:GetCombinedGuildName(),
            lastUpdated = timestamp,
            deleted = false,
            data = {}
        }
    end

    -- Merge characterInfo into sharedData.roster
    for key, value in pairs(characterInfo) do
        GuildHelper_SavedVariables.sharedData.roster[fullName].data[key] = value
    end

    -- Merge globalInfo into sharedData.roster
    for key, value in pairs(globalInfo) do
        GuildHelper_SavedVariables.sharedData.roster[fullName].data[key] = value
    end
end

function GuildHelper:MergeGlobalInfoToRoster()
    local globalInfo = GuildHelper_SavedVariables.globalInfo
    local roster = GuildHelper_SavedVariables.sharedData.roster

    for toonName, toonData in pairs(roster) do
        for key, value in pairs(globalInfo) do
            roster[toonName].data[key] = value
        end
    end
end

function GuildHelper:ClearMemberInfo(toonName)
    GuildHelper_SavedVariables.characterInfo[toonName] = nil
end

function GuildHelper:ClearAllMemberInfo()
    GuildHelper_SavedVariables.characterInfo = {}
end

function GuildHelper:SaveSharedData(dataType, data)
    -- Ensure no nil values are passed
    for key, value in pairs(data) do
        if value == nil then
            data[key] = "NA"
        end
    end

    -- Add a lastUpdated timestamp
    local timestamp = date("%Y%m%d%H%M%S")
    data.lastUpdated = timestamp

    -- Ensure guild name is captured
    data.guildName = GetGuildInfo("player") or "NA"

    -- Ensure each news article has a unique ID
    if dataType == "news" then
        for _, article in ipairs(data) do
            article.id = article.id or date("%Y%m%d%H%M%S") .. random(1000, 9999)
        end
    end

    GuildHelper_SavedVariables.sharedData[dataType] = data
    GuildHelper:AddLogEntry(dataType .. " data saved.")

    -- Add a changelog entry for the shared data
end

function GuildHelper:IsToonOnline(toonName)
    if type(toonName) ~= "string" then return false end  -- Ensure toonName is a string
    local fullName = toonName
    if not toonName:find("-") then
        fullName = toonName .. "-" .. GetRealmName()
    end
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name == fullName then
            return online
        end
    end
    return false
end

function GuildHelper:GetGuildMemberLastLogin(toonName)
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, lastOnline = GetGuildRosterInfo(i)
        if name == toonName then
            return lastOnline
        end
    end
    return nil
end

function GuildHelper:tContains(table, item)
    if type(table) ~= "table" then return false end  -- Ensure table is a table
    for _, value in pairs(table) do
        if value == item then
            return true
        end
    end
    return false
end

function GuildHelper:GetCombinedGuildName()
    local guildName = GetGuildInfo("player") or "NA"
    local guildLeaderRealm = "NA"
    for i = 1, GetNumGuildMembers() do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if rankIndex == 0 and name then  -- Ensure name is not nil
            local _, realm = strsplit("-", name)
            guildLeaderRealm = realm or "NA"
            break
        end
    end
    return guildName .. "-" .. guildLeaderRealm
end

function GuildHelper:ValidateToonData(toonData)
    return toonData.pt_name and toonData.pt_level and toonData.pt_class
end

function GuildHelper:isGuildFederatedMember()
    local combinedGuildName = GuildHelper:GetCombinedGuildName()
    local setupData = GuildHelper_SavedVariables.sharedData.setup
    local currentGroup = nil

    -- Loop through all setup entries to find the group containing the current guild
    for _, data in pairs(setupData) do
        for _, guild in ipairs(data.data.guilds) do
            if guild.name == combinedGuildName then
                currentGroup = data.data.guilds
                break
            end
        end
        if currentGroup then
            break
        end
    end

    -- If no group is found, use the current guild as the only member
    currentGroup = currentGroup or {{name = combinedGuildName}}

    return currentGroup
end
