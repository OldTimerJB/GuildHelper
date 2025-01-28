-- Manages the workflow control and management of the syncing process for each table independently.
-- Handles confirmation requests and waits for responses.

GuildHelper = GuildHelper or {}
GuildHelper.WorkflowManager = GuildHelper.WorkflowManager or {}
GuildHelper.UserSyncTable = {}

function GuildHelper.WorkflowManager:SendSaveUser()
    local user = GuildHelper.UserSyncTable.user
    local payload = GuildHelper.json:json_stringify(GuildHelper.UserSyncTable)
    C_ChatInfo.SendAddonMessage("GUILDHELPER", "SAVE_USER;" .. payload, "WHISPER", user)
    GuildHelper:AddLogEntry("Sending SAVE_USER data to " .. user)
    print("Sending SAVE_USER data to", user)
end

function GuildHelper.WorkflowManager:RequestRemoteMetadata()
    local user = GuildHelper.UserSyncTable.user
    local mode = GuildHelper.UserSyncTable.mode
    local days = GuildHelper.UserSyncTable.days
    local tableName = GuildHelper.UserSyncTable.tableName
    local payload = mode .. ";" .. days .. ";" .. tableName
    C_ChatInfo.SendAddonMessage("GUILDHELPER", "REQUEST_METADATA;" .. payload, "WHISPER", user)
    -- print("Requesting metadata for table", tableName, "from", user)
end

function GuildHelper.WorkflowManager:StartSync(user, mode, N)
    -- List of tables to sync
    local tablesToSync = { "setup", "news", "guildInfo", "calendar", "roster" } --"roster", 
    local currentIndex = 1
    GuildHelper.UserSyncTable = {user = user, mode = mode, days = N, tableName = "na"}

    -- Federated guild check
    if not self:IsFederatedGuild() then
        print("Not a federated guild. Only syncing current guild content.")
        tablesToSync = { "setup" }  -- Only sync current guild content
    end

    local function syncNextTable()
        if currentIndex > #tablesToSync then
            GuildHelper_SavedVariables.sharedData.UserStatus = {
                userNameRealm = UnitName("player") .. "-" .. GetRealmName(),
                lastSync = date(),
                status = "available"
            }
            return
        end

        local tableName = tablesToSync[currentIndex]
        GuildHelper.UserSyncTable.tableName = tableName
        print("Starting sync with user:", GuildHelper.UserSyncTable.user, "table:", GuildHelper.UserSyncTable.tableName, "mode:", GuildHelper.UserSyncTable.mode, "N:", GuildHelper.UserSyncTable.days)

        -- Request remote metadata before proceeding with sync
        GuildHelper.WorkflowManager:RequestRemoteMetadata()

        -- Move to the next table after processing the current one
        currentIndex = currentIndex + 1
    end

    GuildHelper.WorkflowManager.syncNextTable = syncNextTable

    -- Send SAVE_USER message once at the beginning
    GuildHelper.WorkflowManager:SendSaveUser()

    -- Start syncing the first table
    syncNextTable()
end

function GuildHelper.WorkflowManager:HandleLocalSyncCompletion()
    GuildHelper.WorkflowManager:syncNextTable()
end

function GuildHelper.WorkflowManager:IsFederatedGuild()
    -- Call the function to check if the guild is federated
    return GuildHelper:isGuildFederatedMember()
end

function GuildHelper.WorkflowManager:SyncActiveUsers()
    GuildHelper:GetOnlineAddonUsers()
    local mode, days = "DAYS", 7  -- Adjust as needed

    C_Timer.After(2, function()
        local activeUsers = {}
        local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
        for _, user in ipairs(GuildHelper.onlineAddonUsers) do
            if user.sender ~= currentPlayer then
                table.insert(activeUsers, user)
            end
        end

        local function processUser(index)
            if index > #activeUsers then return end
            local user = activeUsers[index].sender
            self:StartSync(user, mode, days)
            -- Wait for the current sync to finish, then proceed
            C_Timer.After(1, function()
                processUser(index + 1)
            end)
        end

        processUser(1)
    end)
end
