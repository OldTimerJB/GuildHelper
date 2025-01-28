## DataSyncComs Module

### SendData
- **Inputs:**
  - `sessionId` (string)
  - `dataChunk` (string)
  - `tableName` (string)
  - `chunkIndex` (number)
  - `totalChunks` (number)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `C_ChatInfo.SendAddonMessage` (string, string, string, string)

### SendSyncConfirm
- **Inputs:**
  - `sessionId` (string)
  - `tableName` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `C_ChatInfo.SendAddonMessage` (string, string, string, string)

### ReceiveData
- **Inputs:**
  - `prefix` (string)
  - `message` (string)
  - `channel` (string)
  - `sender` (string)
- **Calls:**
  - `GuildHelper.DataSyncHandler.json.parse` (string)
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSync:AddReceiverLogEntry` (string)
  - `GuildHelper.WorkflowManager:HandleSyncConfirm` (string, string)
  - `GuildHelper.DataSyncManager:HandleSyncTable` (string, string)
  - `GuildHelper.WorkflowManager:HandleConfirmationRequest` (string)
  - `GuildHelper.DataSyncManager:StartSync` (string)
  - `strsplit` (string, string, number)
  - `GuildHelper.DataSyncManager:HandleSyncData` (string, string, string, number, number)

## WorkflowManager Module

### Initialize
- **Inputs:** None
- **Calls:**
  - `GuildHelper.DataSyncManager:StartSync` (string)
  - `self:NotifyReceiver` ()
  - `self:PrepareDataChunks` ()
  - `self:SendDataChunks` ()
  - `self:WaitForConfirmation` ()
  - `self:ProcessConfirmation` ()
  - `GuildHelper.DataSyncManager:UpdateInterface` (string)

### StartWorkflow
- **Inputs:**
  - `targetToon` (string)
- **Calls:**
  - `GuildHelper.DataSyncManager:GenerateSessionId` (string)
  - `GuildHelper.DataSyncManager:GetDataTables` ()
  - `GuildHelper:AddLogEntry` (string)
  - `self:ExecuteStep` ()

### NotifyReceiver
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `C_ChatInfo.SendAddonMessage` (string, string, string, string)
  - `self:RequestConfirmation` ()

### PrepareDataChunks
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncManager:PrepareDataChunks` (string, string)
  - `self:NextStep` ()

### SendDataChunks
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncComs:SendData` (string, string, string, number, number)
  - `self:RequestConfirmation` ()

### RequestConfirmation
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `C_ChatInfo.SendAddonMessage` (string, string, string, string)
  - `self:WaitForConfirmation` ()

### WaitForConfirmation
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `C_Timer.After` (number, function)

### ProcessConfirmation
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `self:NotifyReceiver` ()
  - `self:NextStep` ()

### NextStep
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `self.steps[self.currentStep]` ()

### ExecuteStep
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `self.steps[self.currentStep]` ()

### HandleSyncConfirm
- **Inputs:**
  - `sessionId` (string)
  - `tableName` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `self:ProcessConfirmation` ()

### HandleConfirmationRequest
- **Inputs:**
  - `sessionId` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.DataSyncComs:SendSyncConfirm` (string, string)

## DataSyncManager Module

### Initialize
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

### LogSessionData
- **Inputs:**
  - `sessionId` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

### StartSync
- **Inputs:**
  - `targetToon` (string)
- **Calls:**
  - `self:GenerateSessionId` (string)
  - `self:LogSessionData` (string)
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `C_ChatInfo.SendAddonMessage` (string, string, string, string)
  - `GuildHelper:AddLogEntry` (string)
  - `GuildHelper.WorkflowManager:NextStep` ()

### HandleSyncData
- **Inputs:**
  - `sessionId` (string)
  - `dataChunk` (string)
  - `tableName` (string)
  - `chunkIndex` (number)
  - `totalChunks` (number)
- **Calls:**
  - `GuildHelper.DataSync:AddReceiverLogEntry` (string)
  - `self:LogSessionData` (string)
  - `self:AllChunksReceived` (table, number)
  - `self:MergeReceivedData` (table, string)
  - `GuildHelper.DataSyncComs:SendSyncConfirm` (string, string)
  - `GuildHelper:AddLogEntry` (string)

### AllChunksReceived
- **Inputs:**
  - `session` (table)
  - `totalChunks` (number)
- **Returns:** (boolean)

### MergeReceivedData
- **Inputs:**
  - `session` (table)
  - `tableName` (string)
- **Calls:**
  - `self:ReassembleData` (table)
  - `self:MergeRosterData` (table)
  - `self:MergeLinkedGuildGroupsData` (table)
  - `self:MergeNewsData` (table)
  - `self:MergeGuildInfoData` (table)
  - `self:MergeCalendarData` (table)
  - `GuildHelper.DataSync:AddReceiverLogEntry` (string)

### ReassembleData
- **Inputs:**
  - `dataChunks` (table)
- **Calls:**
  - `GuildHelper.DataSyncHandler.base64_decode` (string)
  - `GuildHelper.DataSyncHandler.json.parse` (string)
- **Returns:** (table)

### MergeNewsData
- **Inputs:**
  - `receivedNews` (table)
- **Returns:** (number)

### MergeGuildInfoData
- **Inputs:**
  - `receivedGuildInfo` (table)
- **Returns:** (number)

### MergeCalendarData
- **Inputs:**
  - `receivedCalendar` (table)
- **Returns:** (number)

### GenerateSessionId
- **Inputs:**
  - `targetToon` (string)
- **Returns:** (string)

### GetOnlineAddonUsers
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)
- **Returns:** (table)

### SetUserStatus
- **Inputs:**
  - `user` (string)
  - `status` (boolean)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

### RestartSync
- **Inputs:**
  - `sessionId` (string)
- **Calls:**
  - `self:StartSync` (string)
  - `GuildHelper:AddLogEntry` (string)

### FilterDataForSync
- **Inputs:**
  - `data` (table)
  - `targetToon` (string)
- **Returns:** (table)

### ClearAllSessions
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

### UpdateInterface
- **Inputs:**
  - `targetToon` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

### HandleSyncTable
- **Inputs:**
  - `sessionId` (string)
  - `tableName` (string)
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

## DataSyncHandler Module

### json.stringify
- **Inputs:**
  - `obj` (table)
  - `as_key` (boolean)
- **Calls:**
  - `kind_of` (table)
  - `escape_str` (string)
- **Returns:** (string)

### json.parse
- **Inputs:**
  - `str` (string)
  - `pos` (number)
  - `end_delim` (string)
- **Calls:**
  - `skip_delim` (string, number, string, boolean)
  - `parse_str_val` (string, number)
  - `parse_num_val` (string, number)
- **Returns:** (table, number)

### base64_encode
- **Inputs:**
  - `data` (string)
- **Returns:** (string)

### base64_decode
- **Inputs:**
  - `data` (string)
- **Returns:** (string)

### resetSyncSessions
- **Inputs:** None
- **Calls:**
  - `GuildHelper:AddLogEntry` (string)

## DataSyncManager2 Module

### GetDataToSync
- **Inputs:** None
- **Returns:** (table)

### GetDataTables
- **Inputs:** None
- **Returns:** (table)

### PrepareDataChunks
- **Inputs:**
  - `sessionId` (string)
  - `tableName` (string)
- **Calls:**
  - `GuildHelper.DataSyncHandler.json.stringify` (table)
  - `GuildHelper.DataSyncHandler.base64_encode` (string)
  - `GuildHelper:AddLogEntry` (string)
- **Returns:** (table)

### MergeRosterData
- **Inputs:**
  - `receivedRoster` (table)
- **Returns:** (number)

### MergeLinkedGuildGroupsData
- **Inputs:**
  - `receivedLinkedGuildGroups` (table)
- **Returns:** (number)

### MergeNewsData
- **Inputs:**
  - `receivedNews` (table)
- **Returns:** (number)

### MergeGuildInfoData
- **Inputs:**
  - `receivedGuildInfo` (table)
- **Returns:** (number)

### MergeCalendarData
- **Inputs:**
  - `receivedCalendar` (table)
- **Returns:** (number)

### ReassembleData
- **Inputs:**
  - `dataChunks` (table)
- **Calls:**
  - `GuildHelper.DataSyncHandler.base64_decode` (string)
  - `GuildHelper.DataSyncHandler.json.parse` (string)
- **Returns:** (table)

### AllChunksReceived
- **Inputs:**
  - `session` (table)
  - `totalChunks` (number)
- **Returns:** (boolean)

# GuildHelper Functions

## `GuildHelper:AddLogEntry(entry)`
Adds a log entry to the log viewer.

- **Parameters:**
  - `entry` (string): The log message to add.

## `GuildHelper:InitializeSavedVariables()`
Initializes and migrates the saved variables for GuildHelper, ensuring all necessary tables are set up.

## `GuildHelper:CreateInterface()`
Creates the main interface for the GuildHelper addon, including frames, buttons, and navigation elements.

## `GuildHelper:ShowPane(paneName)`
Displays the specified pane in the main interface.

- **Parameters:**
  - `paneName` (string): The name of the pane to display (e.g., "NewsPane", "DataSyncPane").

## `GuildHelper:ShowLogViewer()`
Opens the log viewer window to display synchronization logs.

## `GuildHelper:ToggleSelfTest()`
Toggles the self-synchronization feature for testing purposes.

## `GuildHelper:WipeAllData()`
Resets all saved data for the GuildHelper addon, including shared data and exclusion lists.

## `GuildHelper:RegisterSlashCommands()`
Registers slash commands for interacting with the addon via the chat interface.

## `GuildHelper:SaveCharacterInfo(globalInfo, characterInfo)`
Saves character-specific information, ensuring no nil values are stored.

- **Parameters:**
  - `globalInfo` (table): Global information about the guild.
  - `characterInfo` (table): Information about the specific character.

## `GuildHelper:InitializeModules()`
Initializes all necessary modules, including DataSyncManager and WorkflowManager.

## `GuildHelper:StartFullDataSync(toonName)`
Initiates a full data synchronization process with the specified toon.

- **Parameters:**
  - `toonName` (string): The name of the target toon to sync with.

## `GuildHelper.PurgeRoster()`
Clears the saved roster data.

## `GuildHelper:LoadGuildBanner(frame)`
Loads the guild banner into the specified frame. *(Currently empty as the banner code has been moved.)*

## `GuildHelper:FilterGuildData2()`
Filters guild data based on the current guild groups. *(Implementation details needed.)*

## `GuildHelper:MigrateSavedVariables()`
Handles the migration of saved variables from older versions to the current structure.

## `GuildHelper:SyncMissingToons()`
Synchronizes toons that are missing from the current data set.

## `GuildHelper:GetCombinedGuildName()`
Retrieves the combined guild name including the realm.

## `GuildHelper:GetGuildId()`
Retrieves the guild ID for the current guild.

## `GuildHelper:GetOnlineAddonUsers()`
Fetches a list of online users who have the GuildHelper addon enabled.

## `GuildHelper:ResetSyncSessions()`
Resets all active synchronization sessions.

## `GuildHelper.SyncManager:ClearAllSessions()`
Clears all synchronization sessions managed by the SyncManager.
