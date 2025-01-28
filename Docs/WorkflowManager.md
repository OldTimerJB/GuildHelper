





Rules:
- Purpose of this sync process is to sync entries of data between users of the addon local and remote. The goal is to make sure the out of date entries the source exactly in table structure.
- No duplicating functions.
- Make sure every function has a comment of what function(s) calls it.
- Make sure all functions are passing the required values through to the end like remoteUser, mode, days, etc.
- Use JSON-like Serialization and deserialization handling of tables with nested tables. Deserialization must wait for unchunking\reassemble to complete before processing the tables.
- Chunk\unchunk handling needs to include tracking of indexes, totals and the order of the chunks to reassemble them in order.  Use a table and wait for all chunks to be received before unchunking in order of index.
- Process users loops one at a time with callbacks to make sure only one users is processed at a time
- Make sure within the user loop one table is processed at a time before the next starts.  Use callbacks. Order of tables (setup, news, guildinfo, calendar, roster)
- Make all message sending is throttled and sent in order.  Like chunks.
- Make sure logs include the data they are working with so during troubleshoot w can determine if the data s not being handled correctly.

Comparison of metadata: for a two-way sync support for mode, days (i.e. all,0 or days,N)
- DO NOT Delete entries, only set their deleted flag to true
- Missing entries need to be added not mark for deletion.  Deleted entries will have the deleted = true flag
- mode days - changes in the past N days
	- Local requests mode, days (days, N) of metadata from remote
	- Not always will the local or remote have metadata with changes to share\compare
	- In this mode of days, N both side get metadata with changes in the past N days. If remote has nothing to send then send a message indicating it so local sends adds\updates, deleted entries to be processed remotely.
	- Same if remote has metadata changes in the past N days and local does not then request those entries to be updated locally.
- mode all - Request all metadata from remote
	- Its two-way comparison handled locally.  Send no metadata to remote. 
	- DO NOT Delete.  Missing entries are add\updates for either local or remote.
- Compare based on ID and lastupdated timestamp.
- Timestamps that match are in sync and to be ignored.


High level sync management flow
2.1 [local] Click sync all >> calls and passes available users to startsync function
2.2 [local] Loops per user at a time
2.2.1 [local] Request metadata per table loop in order of setup, news, guildinfo, calendar, roster
2.3 [local] Loop per metadata table - one at a time
2.3.1 [local] Request\send remote user a request for metadata table per table
2.3.2 [Remote] listener receive message >> calls RemoteMetaData(user,table)
2.3.3 [Remote] Table created of the metadata table requested
2.3.4 [Remote] Calls SendMetaDataTable(user,table,metadata) function >> Calls SerializeMetaData(table,user,metadata) >> Calls ChunkMetaData(table,user,serialmetadata) >> sends chunks with table:user:index:total:chunkdata
2.4 [local] user receives Metadata chunk messages >> sends to MetaChunkCollector(table,user,index,total,chunkdata) function
2.4.1 [local] MetaChunkCollector collects all the total chunks and then reassembles them >> send to MetaDeserialization(table,user,metadata) function
2.4.2 [local] MetaDeserialization reassembled data back into table >> sends to compareMetaData(table,user,metadatatable) function
2.4.3 [local] compareMetaData Compares the local metadate to the remote metadata
2.4.3.1 [local] Compares if entries are missing for both local and remote user to be added
2.4.3.2 [local] If entries are newer for the local or remote user based on lastupdated timestamp to be replaced
2.4.3.3 [local] if entries are flagged deleted for local or remote user to be marked deleted flag true
2.4.3.4 [local] if lastupdated timestamps match then ignore it.
2.4.4 [local] Results go into the compareResults table
2.4.5 [local] compareResults sent to ProcessMetaDataResults function
3.1 [local] ProcessMetaDataResults(table,user,compareResults)
3.1.1 [local] Breaks results down into localAction and remoteAction tables
3.2 [local] Loop through local actions
3.2.1 [local] if remote had entry marked deleted = true, mark it true locally 
3.2.2 [local] Add local missing and update entries
3.2.2.1 [local] Send request to remote user >> RequestEntryData(table,user,entryID) >> [Remote] listener >> SerializeEntryData(table,user,EntryIDData) >> ChunkEntryData(table,user,EntryIDData) >> SendEntryData(table,user,index,total,ChunkEntryIDData)
3.3 [local] user receives Entry chunk messages >> EntryChunkCollector(table,user,index,total,chunkdata) function
3.3.1 [local] EntryChunkCollector collects all the total chunks and then reassembles them >> EntryDeserialization(table,user,metadata) function
3.3.2 [local] EntryDeserialization reassembled data back into table >> EntryProcessData(table,user,metadata)
3.3.3 [local] EntryProcessData adds missing entry or replace existing outdated entry
3.4 [local] Ends Local action loop when last action in local table processed
4.2 [local] Loop remote actions
4.2.1 [local] Sends one message(table,user,entryID,deleted,true) per entry to mark deleted flag = true >> remote user listener receives message >> DeleteEntry(table,user,entryID) function processes by marking entry's deleted flag true in table 
4.2.2 [local] Function SendEntryData(table,user,entryID) gets entry from table >> SerializeEntry(table,use,entrdata) >> chunk
4.2.3 [local] Sends one message(table,user,entryID,index,total,chunkdata)
4.2.4 [Remote] listener receives chunks >> EntryChunkCollector(table,user,entryID,index,total,chunkdata) until all chunks are collected >> DeserializeEntry(table,user,entryID,entryData) >> ProcessEntryData(table,user,entryID,entryData) adds or overwrites entry
5. [local] Update status for table as completed
5.1 [local] returns table loop - next table
6. [local] Update status for user completed and update users lastsync timestamp in userstatus table
6.1 [local] returns user loop - next user



To simplify the synchronization process and reduce complexity, it's essential to standardize your data schema across all data types. By defining a unified structure with consistent naming conventions and required fields, you can implement generic functions for serialization, deserialization, comparison, and synchronization. Here's how you can design the perfect Lua table schema for your needs:
Unified Data Schema
Create a unified data schema where each entry follows the same structure, regardless of its tableType. This schema should include:
•	Common Fields: Fields that are present in every entry, such as id, tableType, guildName, lastUpdated, and deleted.
•	Specific Fields: Fields unique to each tableType, encapsulated within a data subtable.
Schema Structure
{
  [id] = {
    id = "unique_identifier",              -- Unique identifier for the entry
    tableType = "roster" | "news" | ...,   -- Type of data
    guildName = "Guild Name",              -- Associated guild
    lastUpdated = "YYYYMMDDHHMMSS",        -- Timestamp of last update
    deleted = false,                       -- Deletion flag
    data = {                               -- Subtable containing specific fields
      -- Specific fields depending on tableType
    }
  },
  -- More entries...
}
Naming Conventions and Required Fields
Common Fields (Required for All Entries)
•	id (string): A unique identifier for the entry. For player entries, this could be the format "PlayerName-Realm". For other entries, use a unique ID like a timestamp or UUID.
•	tableType (string): Specifies the type of the data. Example values: "roster", "news", "setup", "guildInfo", "calendar".
•	guildName (string): Name of the guild associated with the entry.
•	lastUpdated (string): Timestamp of the last update in the format "YYYYMMDDHHMMSS" for easy string comparison.
•	deleted (boolean): Indicates if the entry has been marked as deleted.
•	data (table): A subtable containing fields specific to the tableType.
Specific Fields by tableType
•	Roster Entries (tableType = "roster")
o	name (string): Player's name with realm.
o	class (string): Player's class.
o	level (number): Player's level.
o	rank (string): Guild rank.
o	itemLevel (number): Player's item level.
o	battletag (string): Player's BattleTag.
o	roles (table): Player's roles.
o	guildJoinDate (string): Date the player joined the guild.
o	professions (table): Player's professions.
o	mainCharacter (string): Name of the main character if this is an alt.
o	interests (table): Player's interests.
o	birthdate (string): Player's birthdate.
o	faction (string): Player's faction.
•	News Entries (tableType = "news")
o	title (string): Title of the news item.
o	content (string): Content of the news item.
o	category (string): Category (e.g., "General").
o	date (string): Date of the news item.
•	Setup Entries (tableType = "setup")
o	guilds (table): List of linked guilds.
o	Additional setup-specific fields as needed.
•	Guild Info Entries (tableType = "guildInfo")
o	title (string): Title of the guild info item.
o	content (string): Content of the guild info item.
o	category (string): Category.
o	date (string): Date of the info item.
•	Calendar Entries (tableType = "calendar")
o	title (string): Title of the event.
o	content (string): Content or description of the event.
o	category (string): Category (e.g., "Birthday", "Raid").
o	eventDate (string): Date and time of the event.
Example Entries
Roster Entry
["Sakarra-Skywall"] = {
  id = "Sakarra-Skywall",
  tableType = "roster",
  guildName = "No Rest For The Wicked-Eonar",
  lastUpdated = "20241215085707",
  deleted = false,
  data = {
    name = "Sakarra-Skywall",
    class = "Shaman",
    level = 80,
    rank = "Member",
    itemLevel = 0,
    battletag = "NA",
    roles = {},
    guildJoinDate = "2024-12-15",
    professions = {},
    mainCharacter = "NA",
    interests = {},
    birthdate = "NA",
    faction = "Unknown",
  }
},
News Entry
["199901010000001234"] = {
  id = "199901010000001234",
  tableType = "news",
  guildName = "No Rest For The Wicked-Eonar",
  lastUpdated = "20241215085906",
  deleted = false,
  data = {
    title = "Welcome to the Guild! NEWS2",
    content = "Welcome to our guild! We are glad to have you here. Please check the guild News for more details.",
    category = "General",
    date = "2024-12-15 08:59:06",
  }
},
Setup Entry
["norestforthewickedeonar"] = {
  id = "norestforthewickedeonar",
  tableType = "setup",
  guildName = "No Rest For The Wicked-Eonar",
  lastUpdated = "20241215085839",
  deleted = false,
  data = {
    guilds = {
      { name = "No Rest For The Wicked-Alleria" },
      { name = "No Rest For The Wicked-Eonar" }, 
      -- Additional guilds...
    },
  }
},
Metadata Table
Maintain a unified metadata table to track the lastUpdated and deleted status for each entry. This simplifies comparison and synchronization.
metadata = {
  ["roster"] = {
    ["Sakarra-Skywall"] = {
      id = "Sakarra-Skywall",
      tableType = "roster",
      guildName = "No Rest For The Wicked-Eonar",
      lastUpdated = "20241215085707",
      deleted = false,
    },
    -- More roster entries...
  },
  ["news"] = {
    ["199901010000001234"] = {
      id = "199901010000001234",
      tableType = "news",
      guildName = "No Rest For The Wicked-Eonar",
      lastUpdated = "20241215085906",
      deleted = false,
    },
    -- More news entries...
  },
  -- More tableTypes...
}
Simplified Synchronization Process
With this standardized schema, you can implement a single manager function to control the synchronization flow:
1.	Start with the setup table to ensure all linked guilds are recognized.
2.	Retrieve and Compare Metadata Tables:
o	Exchange metadata tables with other clients.
o	Compare lastUpdated timestamps for each entry.
o	Determine which entries need to be added, updated, or deleted.
3.	Synchronize Entries:
o	For each entry that requires synchronization, serialize the data subtable.
o	Transmit the serialized data in chunks if necessary.
o	On the receiving end, deserialize the data and update the entry.
Serialization and Deserialization
Implement generic serialization and deserialization functions that work with any tableType.
Serialization
function SerializeEntry(entry)
  local serialized = ""
  for key, value in pairs(entry) do
    if type(value) == "table" then
      value = SerializeTable(value) -- Recursive serialization for subtables
    end
    serialized = serialized .. tostring(value) .. ";"
  end
  return serialized
end
function SerializeTable(tbl)
  local serialized = "{"
  for key, value in pairs(tbl) do
    serialized = serialized .. "[" .. SerializeValue(key) .. "]=" .. SerializeValue(value) .. ","
  end
  return serialized .. "}"
end
Deserialization
function DeserializeEntry(serialized)
  -- Implement deserialization logic to reconstruct the entry table
end
Chunking
To handle large data entries, implement a generic chunking mechanism:
•	Chunk Size: Define a standard chunk size.
•	Chunking Function: Split serialized data into chunks.
•	Unchunking Function: Reassemble chunks into the original serialized data.
Manager Function
Implement a manager function to oversee the synchronization process:
function SyncManager:SynchronizeData()
  -- Start with setup table
  self:SynchronizeTable("setup")
  -- Synchronize other tables
  local tableTypes = { "roster", "news", "guildInfo", "calendar" }
  for _, tableType in ipairs(tableTypes) do
    self:SynchronizeTable(tableType)
  end
end
function SyncManager:SynchronizeTable(tableType)
  -- Exchange metadata
  local localMetadata = metadata[tableType]
  local remoteMetadata = self:GetRemoteMetadata(tableType)
  -- Compare metadata and identify differences
  local entriesToSync = self:CompareMetadata(localMetadata, remoteMetadata)
  -- Synchronize entries
  for id, action in pairs(entriesToSync) do
    if action == "update" or action == "add" then
      self:SendEntry(tableType, id)
    elseif action == "delete" then
      self:DeleteEntry(tableType, id)
    end
  end
end
Error Handling and Validation
•	Ensure that all required fields are present when creating or updating entries.
•	Validate data types and formats (e.g., timestamps, IDs).
•	Implement error handling in serialization, deserialization, and synchronization functions.
Benefits of This Schema
•	Consistency: A unified structure makes it easier to manage and synchronize data.
•	Scalability: Adding new tableTypes or fields requires minimal changes.
•	Simplicity: Generic functions can handle multiple data types, reducing code duplication.
•	Maintainability: Clear naming conventions and required fields improve readability and maintainability.
Next Steps
•	Rebuild Panes: Update each pane to use the new schema, accessing data through the standardized structure.
•	Update Functions: Modify existing functions for serialization, deserialization, chunking, and synchronization to be generic.
•	Testing: Thoroughly test synchronization between clients to ensure data integrity.
•	Documentation: Document the new schema, conventions, and any changes made to the functions.
Conclusion




















### Lessons learned
1. We had it close on the 12th try but we let the steps get out of order or not fully complete before moving on to the next function.
2. We need a better way to control the order of functions and steps.  Everything must happen in sequence.
  - All three table types below must be handled in their own workflows and in order.  Each one MUST fully complete before the next starts.
  - Setup must be processed first and by itself and sync differently.
    - Does either user have linked guilds for the guild they are in?  If yes, then move on.
    - If one is no, then sync entries to match the one with the newest lastupdated timestamp.
    - example setup table with linkedGuildGroups below in file to reference.  
  - news, guildInfo and calendar must be sync separately from setup and roster
  - roster must be processed last and by itself.
3. Syncing the setup table must absolutely happen first and by itself in order for future steps to determine what other guilds in the linkedGuildGroups table both parties belong in oder to know what to sync
4. There needs to be 2 metadata tables to completely separate out the 2 table types to make sure they are handled correctly according to their data structures
  - the 2 metadata table functions for the below need to start at addon load
  - metadata-information for (news, guildInfo and calendar)
    - fields are id, date, guildname, deleted
  - metadata-roster
    - fields are the key, lastUpdated, pt_guildName, deleted
5. Stop putting everything in the workflowmanager.lua file.  Its only for controlling the tracking of sessions, users, and the sequence of functions.  The task functions need to be created in their related files DataSyncComs, DataSyncHandler, DataSyncManger and Maintenance.  No file should grow beyond 350-400 lines of code.  Balance them out.
6. Again all function names MUST be defined for tabletypes and do not share others functions.  We do not want to break any other sync flows



### Guildlines
1. DO NOT Change any existing datatables structures\schemas like roster, news, guildinfo, calendar, setup like injecting checksum objects into them.  It will break other parts of the addon.
2. Do not duplicate code of functions
3. Keep everything in order
4. log to the correct sender \ receiver popup windows and table with the Step numbers.
5. To clarify that serialization/deserialization and chunking/unchunking are only necessary when sending/receiving data from the tables


### The datasync.lua syncall button will kick off the StartSync function in the workflowmanager.lua file.  

-- The workflow manager file will control the flow of the entire sync process
-- It starts every function and every function will report back to it with data.  That data will then be handled off to the next step and so on.
-- Nothing happens wihtout the StartSync orchestration knowing about it.
-- The reciever steps are also controled in the workflowmanager file.
-- All sender and receiver functions need to be named separately and logged to their own logs.
-- Each table type need to be process separately.  
    - Setup = by itself
    - (news, guildinfo, and calendar) can be processed the same.  
    - Roster = by itself
    - this include the way they are handled in the chucksum table, sync process and compare
    -- This whole sync process needs to be easy to follow and organized.
-- We will start with each step one at a time and fully testing that its working before writing the next step in code.
-- There is only two functions allowed in the workflowmanager.lua file.  The startSync with will be the Serber flow and a Receiver's flow.  Everything in those two functions will be calls to other functions in other files.
-- These two functione will control all other functions as a workflow of functions.  Meaning we will pass them toon information from the datasync.lua StartSync(OnlineToons) online toon list with lastsyncdates so we can exclude toons sync'd with the the past 24 hours.

#############################################################################################################
### Sync Process Flow
############################################################################################################


### **Sync Initialization**:

1. **Sender**:
   - Checks if the **Receiver** is ready (not in a party/raid).
   - **Creates a session ID** for tracking the sync session.

2. **Receiver**:
   - Acknowledges **readiness** to sync.

---

### **Metadata Comparison (Pre-Sync)**:

1. **Sender** requests the **Receiver’s metadata**.
2. **Receiver** sends its **metadata** to the **Sender**.
3. **Sender** compares each table’s metadata separately (one table at a time).
   - **Tables involved**: `setup`, `news`, `guildInfo`, `calendar`, `roster`.

4. **Sender** creates a table to track:
   - **Missing entries**
   - **Updated entries**
   - **Entries marked as deleted** (`deleted: true`)

5. **Receiver** does not compare its metadata; **Sender handles all comparisons**.

---

### **Request Missing/Outdated Data**:

1. **Setup Table**: If the **`lastUpdated` timestamp** of **`linkedGuildGroups`** changes, all its entries under **`guilds`** are replaced entirely.
   - **Example Setup Table**:
     ```lua
     ["setup"] = {
         ["linkedGuildGroups"] = {
             ["lastUpdated"] = "20241130194258",
             ["guilds"] = {
                 { ["name"] = "No Reset For The Wicked-Eonar" },
                 { ["name"] = "No Reset For The Wicked-Alleria" },
                 { ["name"] = "No Rest For The Wicked-Eonar" },
                 { ["name"] = "No Rest For The Wicked-Alleria" },
             },
         },
     }
     ```

2. **Sender** requests only the **missing or outdated data** from the **Receiver**:
   - **News**, **GuildInfo**, and **Calendar**: One entry at a time.
   - **Roster**: One entry at a time.

3. **Sender** includes **deleted entries** in the request (flagged as `deleted: true`).

4. **Receiver** responds with:
   - **Missing data**.
   - **Updates** for outdated entries.
   - **Entries marked as deleted**.

5. **Sender** updates the **status flag** to indicate that the update for local tables is complete.
6. **Sender** notifies the **Receiver** that incoming updates are ready to be processed.
7. **Sender** waits for an **acknowledgment** from the **Receiver**.

---

### **Sending Data**:

1. **Sender** sends data per table with actions to be performed:
   - **Update** entries.
   - **Add** new entries.
   - **Delete** (mark as deleted).

2. **Receiver** acknowledges each chunk of data as it's processed.
3. Once data has been fully sent and processed, the **Receiver** sends an acknowledgment back to the **Sender**.

---

### **Sync Completion and Feedback**:

1. Once all data has been sent, processed, and acknowledged:
   - **Sender** marks the sync as **complete**.
   - **Receiver** confirms the sync completion.
2. **Logs** should include feedback about:
   - **How many chunks were sent/processed**.
   - **Any missing or updated entries**.
   - **Errors** (e.g., checksum mismatches, failed chunk transmissions).
3. Feedback to user: Display status message like **"Sync Complete"**, **"Sync Failed"**, or **"Error Encountered"**.

---

### **Restartable Sync Logic**:

1. After completing the sync for one **Addon User**, the **Sender** checks for the next **online addon user**.
   - If there is another user, the sync process is **repeated** for that user.
   - If no more users are online, the workflow ends.

---

---

### **Key Adjustments Made**:

- **Removed "Handling Deletions" and "Delaying Deletion Removal" steps**, as they were no longer necessary for the streamlined process.
- Updated the **metadata comparison** and **missing/outdated data request** to ensure they are aligned with your vision of syncing tables.
- **Sender’s flow** has been clarified to ensure it processes the metadata comparison and sends only **missing/updated data**.
- Added steps for **status updates** and **acknowledgments** for better feedback and tracking.



#############################################################################################################
### Programming Logic (Code Standards)
############################################################################################################

### **1. Serialization and Deserialization**

- **No JSON required** for data tables—serialization and deserialization should be done using standard table structures without relying on JSON conversion.
- Tables should not include a `lastUpdated` timestamp field anymore for tracking updates. Or date in the news, guildinfo and calendar tables.

---

### **2. Checksum Calculation** - Not needed

- **Remove all checksum-related operations**.
  - Rely **solely on `lastUpdated` timestamps** to detect changes in the data. Or date in the news, guildinfo and calendar tables.
  - When comparing entries, check the `lastUpdated` timestamp for changes rather than using checksums. Or date in the news, guildinfo and calendar tables.
  - This keeps the addon lightweight and avoids unnecessary complexity.

---

### **3. Flagging Deletions**

- Entries marked for deletion should have a `deleted: true` flag.
- The `deleted` flag should be **integrated into metadata** for each table.
  - Flagged entries are to be tracked and **removed** when necessary (e.g., after a set period like 30 days).

---

### **4. Data Chunking**

- **Max characters per chunk**: 
  - Follow the format: `3;4;4;5;5;data` 
  - This ensures that the **chunk size** is predictable and consistent with the defined limits, allowing for more data to be sent per message.
  
---

### **5. Messaging Command Format**

- **Max characters per command message**:
  - Use the format: `3;4;4;5;5;data`
  - Example format:
    - `SND;DATA;SETU;00001;00003;data_chunk_1`
    - `ACK;DATA;SETU`
  - This ensures that the command format remains predictable and allows for consistency in chunking.

---

### **6. Handling Sync Progress**

- **Track sync progress** using a **session table** to track the status of each table:
  - **Completed**: Sync for that table is finished.
  - **In Progress**: Sync for that table is ongoing.
  - **Pending**: Sync for that table has not started yet.
- **Use session IDs** to uniquely identify sync sessions.
- **Track progress for each user** to ensure multiple users can be synced independently.

---

### **7. Logging**

- **Avoid logging per entry**—logging should be focused on **summary-level logs** to reduce performance issues:
  - **Log one example entry** if needed for troubleshooting.
  - Include logs such as:
    - **Number of chunks sent**.
    - **Sync progress** for each table.
    - **Total entries processed**, including missing/updated/deleted entries.
    - Example log:
      ```lua
      GuildHelper:AddLogEntry("Sync completed for 50 entries of roster table.")
      ```
    - **Delays** should be introduced to **avoid performance bottlenecks** in logging.

---

### **8. Data Comparison and Merging**

- **Add delays** for each table to prevent performance issues:
  - Introduce delays when comparing data to **allow for bulk processing**.
  - Example:
    - Introduce a **.1 second delay** for every **50 entries** processed.
    - Ensure this delay applies when processing large tables, especially when reading or writing to/from tables.

- **Comparison logic**:
  - **Roster tables**: Compare based on the **key (toon name)** and **lastUpdated timestamp**. Or date in the news, guildinfo and calendar tables.
  - **News, GuildInfo, Calendar** tables: Compare based on **ID**, **timestamp**, and the **deleted flag** (no checksum involved).

---

### **9. Error Handling**

- **Remove checksum verbiage** from the error handling.
- Handle errors related to:
  - **Failed transmissions** (e.g., if a chunk fails to send).
  - **Invalid data** (e.g., a corrupted chunk or unexpected missing fields).
  - **Log errors clearly**, with enough context to resolve the issue (without overloading the logs).

---

### **10. Sync Completion and User Feedback**

- **Sender and Receiver** should provide **detailed progress feedback** to the user.
  - Every **50 entries** processed, introduce a **short delay** to prevent overwhelming the system and ensure smooth user feedback.
  - Display status messages:
    - **“Sync Complete”**
    - **“Sync Failed”**
    - **“Error Encountered”** (with specific error details).

---

### **11. Restartable Sync Logic**

- **Track sync progress** with **session IDs** to allow for restarting a sync if it’s interrupted.
- After completing the sync for one user, check if other **online addon users** need to be synced.
  - If another user is available, repeat the sync process for that user.
  - If no more users are available, the workflow ends.

---

### **Key Updates**:
1. **Serialization**: JSON is no longer necessary, and serialization should be done directly with Lua tables.
2. **Checksums**: Removed. Only `lastUpdated` timestamps are used for comparison. Or date in the news, guildinfo and calendar tables.
3. **Deletions**: Entries are flagged as deleted, not immediately removed.
4. **Chunking/Message Format**: Standardize the chunk size and message format, ensuring consistent, predictable communication.
5. **Logging**: Summary-level logs with delays to reduce performance issues.
6. **Delays**: Introduce delays when processing large datasets, especially when merging data or logging entries.



###  Examples of the shareddata tables to make sure after processing the receiver's sharedDataRemote table will be the same structure as the source table

<!--
["sharedData"] = {
["roster"] = {
["Sakarra-Skywall"] = {
["pt_itemLevel"] = 0,
["deleted"] = false,
["gb_battletag"] = "NA",
["pt_level"] = 80,
["pt_roles"] = {
},
["pt_guildJoinDate"] = "2024-11-30",
["pt_professions"] = {
},
["gb_mainCharacter"] = "NA",
["pt_interests"] = {
},
["pt_class"] = "Shaman",
["lastUpdated"] = "20241130192941",
["gb_birthdate"] = "NA",
["pt_guildName"] = "No Rest For The Wicked-Eonar",
["pt_faction"] = "Unknown",
["pt_rank"] = "Member",
["pt_name"] = "Sakarra-Skywall",
},
},
},


["calendar"] = {
{
["guildName"] = "No Rest For The Wicked-Eonar",
["title"] = "Welcome to the Guild!  8",
["category"] = "General",
["id"] = "202411301950388623",
["eventDate"] = "2024-12-01 04:28:07",
["content"] = "Welcome to our guild! We are glad to have you here. Please check the guild Calendar for more details.",
["date"] = "2024-12-01 04:28:07",
},
},


["news"] = {
{
["title"] = "Welcome to the Guild!  4",
["category"] = "General",
["id"] = "202411301924102656",
["date"] = "2024-12-01 05:09:22",
["content"] = "Welcome to our guild! We are glad to have you here. Please check the guild News for more details.",
["guildName"] = "No Rest For The Wicked-Eonar",
},
},


["guildInfo"] = {
{
["title"] = "Welcome to the Guild! test",
["category"] = "General",
["id"] = "202411301949531535",
["date"] = "2024-11-30 19:50:37",
["content"] = "Welcome to our guild! We are glad to have you here. Please check the guild News for more details.",
["guildName"] = "No Rest For The Wicked-Eonar",
},
},

["setup"] = {
["linkedGuildGroups"] = {
["lastUpdated"] = "20241130194258",
["guilds"] = {
{
["name"] = "No Reset For The Wicked-Eonar",
},
{
["name"] = "No Reset For The Wicked-Alleria",
},
{
["name"] = "No Rest For The Wicked-Eonar",
},
{
["name"] = "No Rest For The Wicked-Alleria",
},
},
},
-->



### **Orchestration Function vs. Task-based Functions**

In a software system, particularly one like a data synchronization process, it's important to distinguish between **orchestration functions** (also known as **manager functions**) and **task-based functions**. These two types of functions serve different purposes and are responsible for different aspects of the program's workflow. Let's break it down clearly:

---

### **Orchestration Function** (Manager Function)

An **orchestration function** is responsible for managing and controlling the **overall flow** of a specific process. It coordinates and oversees multiple tasks and ensures that everything is executed in the correct order and under the correct conditions.

#### **Key Characteristics of Orchestration Functions**:
1. **Higher-Level Control**: It serves as a "master" function, orchestrating the various task-based functions that make up the larger process.
2. **Coordination**: It coordinates the execution of different steps and functions in the correct order. It decides which task-based function should run next based on logic or conditions.
3. **Tracking and Progress**: The orchestration function often keeps track of the process's state, including tracking progress, handling errors, and deciding when a task is completed.
4. **Error Handling**: It often handles any issues or errors that arise in any of the task-based functions, deciding how to handle retries or abort the process.
5. **Delegation**: The orchestration function delegates specific sub-tasks to the task-based functions, but doesn't generally perform the actual work itself.

#### **Example of an Orchestration Function**:
In the context of a **data sync process**, an orchestration function might manage the entire sync process for multiple toons, as shown in this simplified example:

```lua
-- Orchestration function to manage sync process
function OrchestrateSync()
    -- Step 1: Check if sender and receiver are ready
    if not IsReceiverReady() then
        Log("Receiver is not ready, aborting sync.")
        return
    end

    -- Step 2: Initiate metadata comparison
    local metadataStatus = CompareMetadata()
    if metadataStatus == "error" then
        Log("Error in metadata comparison.")
        return
    end

    -- Step 3: Request missing or outdated data
    RequestMissingData()

    -- Step 4: Handle received data
    HandleReceivedData()

    -- Step 5: Complete sync and provide feedback
    CompleteSync()
end
```

In the example above, the orchestration function **OrchestrateSync** controls the flow of the sync process by calling specific task-based functions in sequence: `IsReceiverReady`, `CompareMetadata`, `RequestMissingData`, `HandleReceivedData`, and `CompleteSync`. It is primarily concerned with managing the process and making decisions based on the state of the sync.

---

### **Task-Based Functions**

A **task-based function** is designed to perform a specific, **small-scale operation** or task within a process. It does the "work" that the orchestration function calls it to do.

#### **Key Characteristics of Task-Based Functions**:
1. **Focused Work**: These functions focus on a single specific task, like comparing data, requesting missing information, or processing a chunk of data.
2. **Independent Execution**: Task-based functions can typically be executed independently, often with minimal external dependencies.
3. **Direct Responsibility**: Each task-based function handles its own error handling, validation, and output related to the specific task it is responsible for.
4. **No Coordination**: They do not handle coordination or process flow. That is the job of the orchestration function.

#### **Example of Task-Based Functions**:

Continuing with the **data sync example**, here are some task-based functions that are called by the orchestration function:

```lua
-- Task-based function to check if the receiver is ready for sync
function IsReceiverReady()
    if IsPlayerInParty() or IsPlayerInRaid() then
        Log("Receiver is busy, unable to start sync.")
        return false
    end
    return true
end

-- Task-based function to compare metadata between Sender and Receiver
function CompareMetadata()
    local senderMetadata = GetSenderMetadata()
    local receiverMetadata = GetReceiverMetadata()

    if senderMetadata == receiverMetadata then
        Log("No changes detected, no sync required.")
        return "no_change"
    else
        Log("Metadata mismatch, sync required.")
        return "mismatch"
    end
end

-- Task-based function to request missing data
function RequestMissingData()
    -- Logic to send request for missing data
    Log("Requesting missing data from Receiver.")
end

-- Task-based function to handle received data
function HandleReceivedData()
    -- Logic to process and merge received data
    Log("Processing received data.")
end

-- Task-based function to mark sync as complete
function CompleteSync()
    Log("Sync completed successfully.")
end
```

In this case, each of the functions such as `IsReceiverReady`, `CompareMetadata`, `RequestMissingData`, and `HandleReceivedData` is a **task-based function** that handles a specific part of the overall sync process. These functions are small, focused, and reusable in different parts of the orchestration process.

---

### **Key Differences between Orchestration Functions and Task-Based Functions**:
- **Purpose**: 
  - **Orchestration Functions**: Manage the flow of the entire process, coordinating multiple tasks.
  - **Task-Based Functions**: Perform specific actions, usually independent of one another.
  
- **Control**:
  - **Orchestration Functions**: Make decisions, track the sync status, handle progress, and call task-based functions.
  - **Task-Based Functions**: Do the actual work of comparing data, sending requests, handling responses, and more.
  
- **Complexity**:
  - **Orchestration Functions**: Tend to be more complex as they handle high-level coordination.
  - **Task-Based Functions**: Tend to be simpler as they focus on performing a single task.

---

### **How They Work Together**:
- The **orchestration function** will delegate specific tasks to the task-based functions, ensuring the entire sync process happens in the correct order and that errors are handled appropriately.
- The **task-based functions** are responsible for executing individual pieces of the workflow, and the orchestration function coordinates these tasks.

---

### **In Your Context**:
- **Orchestration Function**: The function that controls the flow of the sync process (checking if the receiver is available, initiating metadata comparison, handling missing data, etc.).
- **Task-Based Functions**: Functions that perform specific actions, such as comparing metadata, requesting missing data, or processing chunks of data during the sync.

---

Let me know if you'd like to dive deeper into one of these functions or how to best organize them for the sync process in your addon.