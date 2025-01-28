GuildHelper = GuildHelper or {}
GuildHelper.DataSyncHandler = GuildHelper.DataSyncHandler or {}

local CHUNK_SIZE = 190  -- Reduced to avoid partial truncation
local SYNC_INTERVAL = 0.1  -- Interval between sending chunks (in seconds)

function GuildHelper.DataSyncHandler:SendDataLocal(entries, callback)
    local user = GuildHelper.UserSyncTable.user
    local tableName = GuildHelper.UserSyncTable.tableName
    local data = {}

    -- Collect only the entries that need to be sent
    for _, entry in ipairs(entries) do
        data[entry.id] = GuildHelper_SavedVariables.sharedData[tableName][entry.id]
    end

    GuildHelper:AddLogEntry(string.format("Sending %s data to %s.", tableName, user))

    local function sendChunk(i, entry, totalChunks, jsonData)
        if i > totalChunks then
            if callback then callback() end
            return
        end

        local chunk = jsonData:sub((i - 1) * CHUNK_SIZE + 1, i * CHUNK_SIZE)
        local message = string.format("ENTRY_CHUNK_L;%s;%s;%d;%d;%s", tableName, entry.id, i, totalChunks, chunk)
        C_ChatInfo.SendAddonMessage("GUILDHELPER", message, "WHISPER", user)
        GuildHelper:AddLogEntry(string.format("Sent chunk %d/%d to %s: %s", i, totalChunks, user, chunk))

        C_Timer.After(SYNC_INTERVAL, function()
            sendChunk(i + 1, entry, totalChunks, jsonData)
        end)
    end

    for _, entry in ipairs(entries) do
        local jsonData = GuildHelper.json:json_stringify({ [entry.id] = data[entry.id] })
        local totalChunks = math.ceil(#jsonData / CHUNK_SIZE)
        sendChunk(1, entry, totalChunks, jsonData)
    end
end

function GuildHelper.DataSyncHandler:SendDataRemote(entries, callback)
    local user = GuildHelper.UserSyncTable.user
    local tableName = GuildHelper.UserSyncTable.tableName
    local data = {}

    -- Collect only the entries that need to be sent
    for _, entry in ipairs(entries) do
        data[entry.id] = GuildHelper_SavedVariables.sharedData[tableName][entry.id]
    end

    GuildHelper:AddLogEntry(string.format("Sending %s data to %s.", tableName, user))

    local function sendChunk(i, entry, totalChunks, jsonData)
        if i > totalChunks then
            if callback then callback() end
            return
        end

        local chunk = jsonData:sub((i - 1) * CHUNK_SIZE + 1, i * CHUNK_SIZE)
        local message = string.format("ENTRY_CHUNK_R;%s;%s;%d;%d;%s", tableName, entry.id, i, totalChunks, chunk)
        C_ChatInfo.SendAddonMessage("GUILDHELPER", message, "WHISPER", user)
        GuildHelper:AddLogEntry(string.format("Sent chunk %d/%d to %s: %s", i, totalChunks, user, chunk))

        C_Timer.After(SYNC_INTERVAL, function()
            sendChunk(i + 1, entry, totalChunks, jsonData)
        end)
    end

    for _, entry in ipairs(entries) do
        local jsonData = GuildHelper.json:json_stringify({ [entry.id] = data[entry.id] })
        local totalChunks = math.ceil(#jsonData / CHUNK_SIZE)
        sendChunk(1, entry, totalChunks, jsonData)
    end
end

function GuildHelper.DataSyncHandler:RequestDataChunk(entry)
    local user = GuildHelper.UserSyncTable.user
    local tableName = GuildHelper.UserSyncTable.tableName
    local entryId = entry.id
    local payload = tableName .. ";" .. entryId
    C_ChatInfo.SendAddonMessage("GUILDHELPER", "REQUEST_ENTRY;" .. payload, "WHISPER", user)
    GuildHelper:AddLogEntry("Requesting data chunk for entry: " .. entryId .. " from " .. user)
end

function GuildHelper.DataSyncHandler:FetchAndSendEntries(user, tableName, entryId)
    local data = GuildHelper_SavedVariables.sharedData[tableName][entryId]
    if data then
        GuildHelper.UserSyncTable = { user = user, tableName = tableName }
        GuildHelper.DataSyncHandler:SendDataRemote({data}, function()
            GuildHelper:AddLogEntry("Sent data for entry: " .. entryId .. " to " .. user)
        end)
    else
        GuildHelper:AddLogEntry("No data found for entry: " .. entryId .. " in table " .. tableName)
    end
end

function GuildHelper.DataSyncHandler:RequestEntriesFromRemote(entries)
    for _, entry in ipairs(entries) do
        self:RequestDataChunk(entry)
    end
end

local dataChunksRemote = {}
local dataChunksLocal = {}
local partialChunksRemote = {}
local partialChunksLocal = {}

function GuildHelper.DataSyncHandler:HandleDataChunkRemote(message)
    local tableName, entryId, index, total, chunk = message:match("ENTRY_CHUNK_R;([^;]+);([^;]+);(%d+);(%d+);(.+)")
    index = tonumber(index)
    total = tonumber(total)

    GuildHelper:AddLogEntry(string.format("Received chunk %d/%d for table %s: %s", index, total, tableName, chunk))

    if not dataChunksRemote[tableName] then dataChunksRemote[tableName] = {} end
    if not dataChunksRemote[tableName][entryId] then dataChunksRemote[tableName][entryId] = {} end

    if not partialChunksRemote[tableName] then partialChunksRemote[tableName] = {} end
    if not partialChunksRemote[tableName][entryId] then partialChunksRemote[tableName][entryId] = {} end

    partialChunksRemote[tableName][entryId][index] = (partialChunksRemote[tableName][entryId][index] or "") .. chunk
    dataChunksRemote[tableName][entryId][index] = partialChunksRemote[tableName][entryId][index]
    partialChunksRemote[tableName][entryId][index] = nil

    for i = 1, total do
        if not dataChunksRemote[tableName][entryId][i] then
            return
        end
    end

    local jsonData = table.concat(dataChunksRemote[tableName][entryId])
    GuildHelper:AddLogEntry("Reassembled data for table " .. tableName .. ": " .. jsonData)  -- Log the reassembled data
    local success, receivedData = pcall(GuildHelper.json.json_parse, GuildHelper.json, jsonData)
    if success then
        local existingData = GuildHelper_SavedVariables.sharedData[tableName] or {}

        -- Merge received data with existing data
        for key, entry in pairs(receivedData) do
            existingData[key] = entry
        end

        GuildHelper_SavedVariables.sharedData[tableName] = existingData
        GuildHelper:AddLogEntry(string.format("%s data synced successfully.", tableName))
    else
        GuildHelper:AddLogEntry("Error parsing JSON: " .. receivedData)
    end

    dataChunksRemote[tableName][entryId] = nil
end

function GuildHelper.DataSyncHandler:HandleDataChunkLocal(message)
    local tableName, entryId, index, total, chunk = message:match("ENTRY_CHUNK_L;([^;]+);([^;]+);(%d+);(%d+);(.+)")
    index = tonumber(index)
    total = tonumber(total)

    GuildHelper:AddLogEntry(string.format("Received chunk %d/%d for table %s: %s", index, total, tableName, chunk))

    if not dataChunksLocal[tableName] then dataChunksLocal[tableName] = {} end
    if not dataChunksLocal[tableName][entryId] then dataChunksLocal[tableName][entryId] = {} end

    if not partialChunksLocal[tableName] then partialChunksLocal[tableName] = {} end
    if not partialChunksLocal[tableName][entryId] then partialChunksLocal[tableName][entryId] = {} end

    partialChunksLocal[tableName][entryId][index] = (partialChunksLocal[tableName][entryId][index] or "") .. chunk
    dataChunksLocal[tableName][entryId][index] = partialChunksLocal[tableName][entryId][index]
    partialChunksLocal[tableName][entryId][index] = nil

    for i = 1, total do
        if not dataChunksLocal[tableName][entryId][i] then
            return
        end
    end

    local jsonData = table.concat(dataChunksLocal[tableName][entryId])
    GuildHelper:AddLogEntry("Reassembled data for table " .. tableName .. ": " .. jsonData)  -- Log the reassembled data
    local success, receivedData = pcall(GuildHelper.json.json_parse, GuildHelper.json, jsonData)
    if success then
        local existingData = GuildHelper_SavedVariables.sharedData[tableName] or {}

        -- Merge received data with existing data
        for key, entry in pairs(receivedData) do
            existingData[key] = entry
        end

        GuildHelper_SavedVariables.sharedData[tableName] = existingData
        GuildHelper:AddLogEntry(string.format("%s data synced successfully.", tableName))
    else
        GuildHelper:AddLogEntry("Error parsing JSON: " .. receivedData)
    end

    dataChunksLocal[tableName][entryId] = nil

    -- Call syncNextTable after completing the data sync for the current table
    GuildHelper.WorkflowManager:syncNextTable()
end

-- Function to filter metadata based on mode and days
-- Called by function GuildHelper:HandleAddonMessage
function GuildHelper.DataSyncHandler:FilterMetadata(tableName, mode, days)
    local metadata = GuildHelper_SavedVariables.sharedData.metadata[tableName]
    local filteredMetadata = {}

    -- Always send setup entries
    if tableName == "setup" then
        return metadata
    end

    local currentGuildName = GetGuildInfo("player")
    local federatedGuilds = GuildHelper:isGuildFederatedMember()

    if mode == "ALL" then
        for key, entry in pairs(metadata) do
            for _, guild in ipairs(federatedGuilds) do
                if entry.guildName == guild.name then
                    filteredMetadata[key] = entry
                    break
                end
            end
        end
    elseif mode == "DAYS" then
        local currentTime = time()
        for key, entry in pairs(metadata) do
            local lastUpdatedTime = time({
                year = tonumber(entry.lastUpdated:sub(1, 4)),
                month = tonumber(entry.lastUpdated:sub(5, 6)),
                day = tonumber(entry.lastUpdated:sub(7, 8)),
                hour = tonumber(entry.lastUpdated:sub(9, 10)),
                min = tonumber(entry.lastUpdated:sub(11, 12)),
                sec = tonumber(entry.lastUpdated:sub(13, 14))
            })
            local differenceInDays = (currentTime - lastUpdatedTime) / 86400
            for _, guild in ipairs(federatedGuilds) do
                if differenceInDays <= days and entry.guildName == guild.name then
                    filteredMetadata[key] = entry
                    break
                end
            end
        end
    end

    return filteredMetadata
end

-- Function to send metadata in chunks
-- Called by function GuildHelper:HandleAddonMessage
function GuildHelper.DataSyncHandler:SendMetadataChunks(user, tableName, metadata)
    local jsonData = GuildHelper.json:json_stringify(metadata)
    local totalChunks = math.ceil(#jsonData / CHUNK_SIZE)

    local function sendChunk(i)
        if i > totalChunks then
            return
        end

        local chunk = jsonData:sub((i - 1) * CHUNK_SIZE + 1, i * CHUNK_SIZE)
        local message = string.format("META_CHUNK;%s;%d;%d;%s", tableName, i, totalChunks, chunk)
        C_ChatInfo.SendAddonMessage("GUILDHELPER", message, "WHISPER", user)
        GuildHelper:AddLogEntry(string.format("Sent metadata chunk %d/%d for table %s to %s: %s", i, totalChunks, tableName, user, chunk))

        C_Timer.After(SYNC_INTERVAL, function()
            sendChunk(i + 1)
        end)
    end

    sendChunk(1)
end

-- Function to handle metadata request
-- Called by function GuildHelper:HandleAddonMessage
function GuildHelper.DataSyncHandler:HandleMetadataRequest(user, mode, days, tableName)
    local metadata = self:FilterMetadata(tableName, mode, days)
    if next(metadata) then
        self:SendMetadataChunks(user, tableName, metadata)
    else
        C_ChatInfo.SendAddonMessage("GUILDHELPER", "NO_META;" .. tableName, "WHISPER", user)
        GuildHelper:AddLogEntry("No metadata to send for table " .. tableName .. " to " .. user)
    end
end

-- Function to handle metadata chunk
-- Called by function GuildHelper:HandleAddonMessage
function GuildHelper.DataSyncHandler:HandleMetadataChunk(message)
    local tableName, index, total, chunk = message:match("META_CHUNK;([^;]+);(%d+);(%d+);(.+)")
    index = tonumber(index)
    total = tonumber(total)

    GuildHelper.receivedChunks = GuildHelper.receivedChunks or {}
    GuildHelper.receivedChunks[tableName] = GuildHelper.receivedChunks[tableName] or {}
    GuildHelper.receivedChunks[tableName][index] = chunk

    GuildHelper:AddLogEntry(string.format("Received metadata chunk %d/%d for table %s: %s", index, total, tableName, chunk))

    if #GuildHelper.receivedChunks[tableName] == total then
        local jsonData = table.concat(GuildHelper.receivedChunks[tableName])
        GuildHelper:AddLogEntry("Reassembled metadata for table " .. tableName .. ": " .. jsonData)  -- Log the reassembled data
        local metadata = GuildHelper.json:json_parse(jsonData)
        GuildHelper.UserSyncTable.metadata = GuildHelper.UserSyncTable.metadata or {}
        GuildHelper.UserSyncTable.metadata[tableName] = metadata
        GuildHelper.receivedChunks[tableName] = nil

        -- Proceed with metadata comparison and sync
        GuildHelper.DataSyncManager:ProcessMetadataComparison()
    end
end
