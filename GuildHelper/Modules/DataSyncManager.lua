GuildHelper = GuildHelper or {}
GuildHelper.DataSyncManager = GuildHelper.DataSyncManager or {}
function GuildHelper.DataSyncManager:CalculateDaysDifference(lastUpdated, days)
    local currentTime = time()  -- This captures the current time at the moment this line runs
    local year = tonumber(lastUpdated:sub(1, 4))
    local month = tonumber(lastUpdated:sub(5, 6))
    local day = tonumber(lastUpdated:sub(7, 8))
    local hour = tonumber(lastUpdated:sub(9, 10))
    local min = tonumber(lastUpdated:sub(11, 12))
    local sec = tonumber(lastUpdated:sub(13, 14))
    
    local lastUpdatedTime = time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    })

    local differenceInSeconds = currentTime - lastUpdatedTime
    local differenceInDays = differenceInSeconds / 86400  -- Number of seconds in a day

    -- Log the output for debugging
    GuildHelper:AddLogEntry(string.format("CalculateDaysDifference: lastUpdated=%s, currentTime=%s, differenceInDays=%.2f", lastUpdated, date("%Y%m%d%H%M%S", currentTime), differenceInDays))

    return differenceInDays
end

local syncQueue = {}
local isSyncing = false

function GuildHelper.DataSyncManager:QueueSync(callback)
    user = GuildHelper.UserSyncTable.user
    tableName = GuildHelper.UserSyncTable.tableName
    table.insert(syncQueue, { user = user, tableName = tableName, callback = callback })
    self:ProcessQueue()
end

function GuildHelper.DataSyncManager:ProcessQueue()
    if isSyncing or #syncQueue == 0 then return end

    isSyncing = true
    local task = table.remove(syncQueue, 1)
    self:SendData(task.user, task.tableName, function()
        isSyncing = false
        if task.callback then
            task.callback()
        end
        self:ProcessQueue()
    end)
end

function GuildHelper.DataSyncManager:ProcessMetadataComparison()
    local tableName = GuildHelper.UserSyncTable.tableName
    local localMetadata = GuildHelper_SavedVariables.sharedData.metadata[tableName]
    local remoteMetadata = GuildHelper.UserSyncTable.metadata and GuildHelper.UserSyncTable.metadata[tableName]

    -- Ensure localMetadata is initialized
    if not localMetadata then
        GuildHelper_SavedVariables.sharedData.metadata[tableName] = {}
        localMetadata = GuildHelper_SavedVariables.sharedData.metadata[tableName]
    end

    -- Ensure remoteMetadata is initialized
    if not GuildHelper.UserSyncTable.metadata then
        GuildHelper.UserSyncTable.metadata = {}
    end
    if not remoteMetadata then
        GuildHelper.UserSyncTable.metadata[tableName] = {}
        remoteMetadata = GuildHelper.UserSyncTable.metadata[tableName]
    end

    -- Filter local metadata the same way as remote metadata
    local filteredLocalMetadata = GuildHelper.DataSyncHandler:FilterMetadata(tableName, GuildHelper.UserSyncTable.mode, GuildHelper.UserSyncTable.days)

    local updatesNeededLocally, updatesNeededRemotely = GuildHelper.DataSyncManager:CompareMetadata(filteredLocalMetadata, remoteMetadata)
    GuildHelper.DataSyncManager:HandleUpdatesNeeded(updatesNeededLocally, updatesNeededRemotely)
end

function GuildHelper.DataSyncManager:CompareMetadata(localMetadata, remoteMetadata)
    local updatesNeededLocally = {}
    local updatesNeededRemotely = {}

    -- If both local and remote metadata are nil, move on to the next table
    if not localMetadata and not remoteMetadata then
        GuildHelper:AddLogEntry("Both local and remote metadata are nil. Moving on to the next table.")
        GuildHelper.WorkflowManager:syncNextTable()
        return updatesNeededLocally, updatesNeededRemotely
    end

    -- If local metadata is nil but remote metadata is not, add/update entries locally
    if not localMetadata and remoteMetadata then
        for key, remoteEntry in pairs(remoteMetadata) do
            table.insert(updatesNeededLocally, remoteEntry)
        end
        return updatesNeededLocally, updatesNeededRemotely
    end

    -- If remote metadata is nil but local metadata is not, add/update entries remotely
    if localMetadata and not remoteMetadata then
        for key, localEntry in pairs(localMetadata) do
            table.insert(updatesNeededRemotely, localEntry)
        end
        return updatesNeededLocally, updatesNeededRemotely
    end

    -- Compare local and remote metadata
    for key, remoteEntry in pairs(remoteMetadata) do
        local localEntry = localMetadata[key]
        if not localEntry then
            table.insert(updatesNeededLocally, remoteEntry)
        elseif remoteEntry.lastUpdated and localEntry.lastUpdated then
            if remoteEntry.lastUpdated > localEntry.lastUpdated then
                table.insert(updatesNeededLocally, remoteEntry)
            elseif localEntry.lastUpdated > remoteEntry.lastUpdated then
                table.insert(updatesNeededRemotely, localEntry)
            else
                -- Skip entries with matching lastUpdated timestamps
                GuildHelper:AddLogEntry(string.format("Skipping entry %s with matching lastUpdated timestamp.", key))
            end
        else
            GuildHelper:AddLogEntry(string.format("Skipping comparison for key %s due to missing lastUpdated field.", key))
        end
    end

    for key, localEntry in pairs(localMetadata) do
        if not remoteMetadata[key] then
            table.insert(updatesNeededRemotely, localEntry)
        end
    end

    -- Log the updates needed for debugging
    GuildHelper:AddLogEntry("CompareMetadata: updatesNeededLocally=" .. GuildHelper.json:json_stringify(updatesNeededLocally) .. ", updatesNeededRemotely=" .. GuildHelper.json:json_stringify(updatesNeededRemotely))

    return updatesNeededLocally, updatesNeededRemotely
end

function GuildHelper.DataSyncManager:HandleUpdatesNeeded(updatesNeededLocally, updatesNeededRemotely)
    if #updatesNeededRemotely > 0 then
        GuildHelper.DataSyncHandler:SendDataRemote(updatesNeededRemotely, function()
            for _, entry in ipairs(updatesNeededRemotely) do
                GuildHelper:AddLogEntry("Sent data for entry: " .. entry.id)
            end
            -- only proceed if there's nothing left to request locally
            if #updatesNeededLocally == 0 then
                GuildHelper.WorkflowManager:syncNextTable()
            end
        end)
    else
        -- Proceed if no remote updates needed
        if #updatesNeededLocally == 0 then
            GuildHelper.WorkflowManager:syncNextTable()
        end
    end

    if #updatesNeededLocally > 0 then
        GuildHelper.DataSyncHandler:RequestEntriesFromRemote(updatesNeededLocally)
    else
        -- if no local updates are needed, the callback above will move on
    end

    -- removed the unconditional syncNextTable() call
end

