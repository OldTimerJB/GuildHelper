# Changelog
# Review and correct all code\functions that read or write data to a LUA file to follow a standard json\sync friendly format for serializing and deserializing data.
# If the file, code or functions are not listed under the completed  ### Completed Files and Functions updates or  ### New table structure to follow for each table then we need to define the functions correctly.
# We are doing this here to avoid duplicate code in files and\or losing tract of were we are.

### to be Changed or corrected 

### To be fixed
- All tables written to LUA files need to be structured to be json and sync friendly.
- Make sure no Guildhelper code interferes with Blizz UI or any other addons.
- Make sure when creating any frames, buttons, or text fields that might affect the guild UI. If its adding any UI elements, even indirectly. Please make sure all elements stay within the addon's UI and not defined as a global element.

## [Standards]

### Lessons learned on datasync 
 - Process roster seperately and by itself.  Compare and merge on the key which is the toon's name and the lastupdated time stamp
 - Process linkedGuildGroups seperate from the News, Calendar, Info tables - Need a switch to mark as deleted for purging after 30 days.  Compare based on id and lastupdated timestamp
 - Use json to convert tables
 - Do not encode\decode
 - Limit chunking to 200
 - Track multiple syncs in a table to be restartable and timeout after 60 mins.
 - Error Handling: Add more robust error handling and logging throughout the process to catch and report issues.
 - Data Integrity: Implement checksums or hashes to verify the integrity of received data chunks.
 - Concurrency: Ensure that multiple sync processes can run concurrently without conflicts.
 - User Feedback: Provide more detailed feedback to the user about the sync status, including progress indicators.
 - Optimization: Optimize the serialization and deserialization processes to handle large data sets more efficiently.

 ### Datasync
 - Initialization: Initialize saved variables and set up the interface. Register for addon messages and send an "ONLINE" message. 
 - Starting Sync: User initiates sync via the interface. Log the start of the sync and show the sync logs window. Send a "SYNC_INITIATE" message to the target toon.
 - Sending Data: Serialize the data and split it into chunks. Send each chunk with a checksum for integrity verification. 
 - Receiving Data: Handle incoming "SYNC_DATA" messages. Verify the integrity of each chunk using the checksum. Reassemble the full data and log the progress.
 - Handling Sync Data: Merge the received data with the local data. Log the results and update the interface. 
 - Updating Interface: Update the DataSync pane to reflect the current state of online addon users and sync status. Provide detailed feedback to the user about the sync progress and results.

### Table Structure Standards
- Make sure all GuildHelper functions start with GH.
- All tables should have a `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
- Tables representing characters should include fields: `pt_name`, `pt_level`, `pt_class`, `pt_guildName`, `pt_faction`, `pt_guildJoinDate`, `pt_itemLevel`, `pt_roles`, `pt_interests`, `pt_professions`, `gb_mainCharacter`, `gb_birthdate`, `gb_battletag`, `pt_rank`, `pt_notes`, `pt_OfficersNotes`.
- Tables representing guilds should include fields: `guildName`, `guildLeaderRealm`, `linkedGuildGroups`.
- Need a shared table for each guild and the last time it was sync from the guild roster. Any sync or merge functions of the guild roster need to update these entries.
- Need a shared table that tracks when the last time a toon was updated in the characterinfo and globalinfo tables. So that data can be sync'd when outdated.
- News, info, calendar tables should be overwritten if the 
- Ensure no nil values are passed; replace nil with "NA".
- All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.
- **Linked Guild Groups**: Filters for linked guilds should be looked up in the setup table under a parent guild. When checking to see if another guild is part of a linked guild, refer to the `linkedGuildGroups` in the setup table. Child guilds should look themselves up in the parent entry of the setup table when synced and should not set themselves up as a parent if they are a child.
- Default hardcoded date of "19000101000000" for first time loads of the addon need to have a old date so they are not sync'd

### Recommendations for Avoiding Blizzard UI Interference
- **Global Variables and Functions**: Ensure all variables and functions are scoped locally within your addon. Avoid using global variables or functions that might conflict with Blizzard's UI or other addons.
- **Event Listeners**: Check if your addon is registering for any global events that might be related to guild activities. Ensure that event listeners are properly scoped and not interfering with other UI elements.
- **UI Elements**: Verify that all UI elements created by your addon are properly parented to your addon's frames and not to global frames like `UIParent`. This ensures that they do not interfere with Blizzard's UI.
- **Minimap Button**: If your addon creates a minimap button, ensure it is properly registered and does not conflict with other minimap buttons.
- **Slash Commands**: Ensure that any slash commands registered by your addon are unique and do not conflict with Blizzard's commands or other addons.
- **Libraries**: If your addon uses external libraries, ensure they are properly included and do not introduce global variables or functions.
- **Functions**: Functions MUST be defined as module function - example: function GuildHelper:WriteToChangelog(entry) and not function WriteToChangelog(entry)

### Files and Functions to be validated and updated
- `Modules/DataSyncComs.lua`
- `Modules/DataSyncHandler.lua`
- `Modules/DataSyncManager.lua`

### Completed Files and Functions updates
- `Interface/MemberPane.lua`
  - Updated `GHSaveCharacterInfo` function to ensure no `nil` values are passed and added `lastUpdated` field.
  - Updated `GHUpdateToonList` function to ensure `GHGetSavedToons` function is prefixed correctly.
- `Interface/SetupPane.lua`
  - Updated `GHSaveSetupInfo` function to ensure no `nil` values are passed and added `lastUpdated` field.
  - Updated `GHLoadSetupInfo` function to ensure it is prefixed correctly.
- `Interface/CalendarPane.lua`
  - Updated `GHSaveEventInfo` function to ensure no `nil` values are passed and added `lastUpdated` field.
  - Updated `GHLoadEventInfo` function to ensure it is prefixed correctly.
  - Updated `GHUpdateEventInfo` function to ensure it is prefixed correctly.
  - Ensured default event follows the standard structure with an old `lastUpdated` date to prevent syncing.
- `Interface/InfoPane.lua`
  - Updated `GHSaveInfo` function to ensure no `nil` values are passed and added `lastUpdated` field.
  - Updated `GHLoadInfo` function to ensure it is prefixed correctly.
  - Updated `GHUpdateInfo` function to ensure it is prefixed correctly.
- `Interface/NewsPane.lua`
  - Updated `GHSaveNews` function to ensure no `nil` values are passed and added `lastUpdated` field.
  - Updated `GHLoadNews` function to ensure it is prefixed correctly.
  - Updated `GHUpdateNews` function to ensure it is prefixed correctly.
- `Core/Functions.lua`
  - Updated `GHInitializeSavedVariables` function to ensure no `nil` values are passed and added `lastUpdated` field.
- `Core/Functions2.lua`
  - Updated `Serialize` function to ensure it handles serialization correctly.
  - Updated `Deserialize` function to ensure it handles deserialization correctly.
  - Updated `ResetSavedVariables` function to ensure it resets saved variables correctly.
  - Updated `ToggleMinimapIcon` function to ensure it toggles the minimap icon correctly.

### New table structure to follow for each table - to be formatted in LUA sync friendly structure.
- Character Information Table:
  - Fields: `pt_name`, `pt_level`, `pt_class`, `pt_guildName`, `pt_faction`, `pt_guildJoinDate`, `pt_itemLevel`, `pt_roles`, `pt_interests`, `pt_professions`, `gb_mainCharacter`, `gb_birthdate`, `gb_battletag`, `pt_rank`, `pt_notes`, `pt_OfficersNotes`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- Guild Roster Table:
  - Fields: `guildName`, `members`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- Guild Information Table:
  - Fields: `guildName`, `linkedGuildGroups`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- Setup Information Table:
  - Fields: `guildName`, `guildLeaderRealm`, `linkedGuildGroups`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- Event Information Table:
  - Fields: `eventId`, `eventName`, `eventDate`, `eventTime`, `eventDescription`, `eventLocation`, `eventOrganizer`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- Info Table:
  - Fields: `infoId`, `infoName`, `infoDescription`, `infoDetails`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.

- News Table:
  - Fields: `newsId`, `newsTitle`, `newsContent`, `newsDate`, `newsAuthor`, `lastUpdated`.
  - Ensure no `nil` values are passed; replace `nil` with `"NA"`.
  - Add `lastUpdated` field with a timestamp in the format `YYYYMMDDHHMMSS`.
  - All table structures need to support a standard structure for serialization, chunking, and deserialization so it can be compared and merged.


## Standard functions for syncing data
function SerializeTable(tbl)
    return LibSerialize:Serialize(tbl)
end

function DeserializeTable(serializedData)
    local success, tbl = LibSerialize:Deserialize(serializedData)
    if success then
        return tbl
    else
        return nil, "Deserialization failed"
    end
end

function ChunkTable(tbl, chunkSize)
    local chunks = {}
    for i = 1, #tbl, chunkSize do
        table.insert(chunks, {unpack(tbl, i, i + chunkSize - 1)})
    end
    return chunks
end

function MergeTables(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        tbl1[k] = v
    end
    return tbl1
end