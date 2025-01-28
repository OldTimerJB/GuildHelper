## Data Synchronization Strategy and Workflow

### Purpose of Each File

1. An orchestrates function - Is the Parent function that handles the over all series of tasks that need to be performed.  It passed information to task functions with information in the format it needs, like session ID, toonName, Data, etc. It also handles the tracking and error handling of the status a tasks returns.
2. Task functions -  Functions that performs specific tasks. Error handling.  It returns data, status or error messages back to the parent to address before passing on to the next task function.

- **Modules/DataSyncManager.lua**: Manages the overall simple data synchronization process for each table independently, including initialization, starting sync, and handling sync data.
- **Modules/DataSyncHandler.lua**: Handles the serialization, deserialization, and chunking of data. Ensures data integrity and manages the merging of received data.
- **Modules/DataSyncComs.lua**: Manages communication between clients, sending and receiving data chunks, and handling addon messages.
- **Interface/DataSync.lua**: The pane to show the online addon users to sync with. Includes a button to show the pop-up sync log windows for the sender and receiver.

### Alignment with Standards

- Ensure all tables are structured to be JSON and sync-friendly.
- Avoid interference with Blizzard UI or other addons.
- Follow the table structure standards outlined in the Changelog.md file.
- Implement robust error handling, data integrity checks, and concurrency management.

### Logging

- Only log to the respective sender\receiver pop-up sync log windows to provide detailed feedback to the user about the sync progress and results.

### Workflow

#### Sender workflow
1. **Initialization**:
   - Initialize saved variables and set up the interface.
   - Register for addon messages and send an "ONLINE" message.

#### Per table
#### Sender workflow
2. **Starting Sync**:
   - User initiates sync via the interface.
   - Log the start of the sync and show the sync logs window.
   - Send a "SYNC_INITIATE" message to the target toon.

3. **Sending Data**:
   - Serialize the data and split it into chunks.
   - Limit chunks to ~200. Leave room for toonname, sessionID and tablename to be sent.
   - Send each chunk with a checksum for integrity verification.
   - Send confirmation request and wait for response

#### Separate worfflow for the receiver
#### Receiver workflow
4. **Receiving Data**:
   - Handle incoming "SYNC_DATA" messages.
   - Verify the integrity of each chunk using the checksum.
   - Reassemble the full data and log the progress.

5. **Handling Sync Data**:
   - Compare and Merge the received data with the local data.
   - Log the results and update the interface.
   - Send confirmation data processing completed

#### Sender workflow
6. **Updating Interface**:
   - Update the DataSync pane to reflect the current state of online addon users and sync status.
   - Provide detailed feedback to the user about the sync progress and results.

### Additional Details

- **JSON Functions**: Use JSON functions in `DataSyncHandler.lua` for serialization and deserialization.
- **Array Keys**: Do not leave number keys in arrays that are merged into the remote table.
- **Tracking Sync Sessions**: Use a table for tracking multiple sync sessions with different addon users and progress. This allows sessions to be restarted and pick up where they left off.
- **Session Timeout**: Timeout sessions after 60 minutes.
- **Reset Sessions**: Include a button on `DataSync.lua` to reset sessions so they can restart.
- **Data Comparison and Merging**:
  - **Roster**: Compare and merge based on the toon's name and last updated timestamp.
  - **LinkedGuildGroups**: Compare based on ID and last updated timestamp.
  - **News, GuildInfo, Calendar**: Overwrite if the received data is newer.
- **Data Structure Consistency**: Ensure the source and destination (remote) data structures are the same to avoid breaking the addon.

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


### WorkflowSender - Logs to senderlogs

- One table at a time and each will be handled differently
### Handling Different Table Types

- **Roster**: Process separately and merge based on the toon's name and last updated timestamp.
- **LinkedGuildGroups**: Process separately from News, GuildInfo, and Calendar. 
- **News, GuildInfo, Calendar**: Overwrite if the received data is newer.


- function startWorkflowSender
  - Send request to determine if receiver is busy or idle.
  - Receiver confirms or rejects request to sync. If rejected, end sync.
  - If confirmed, create session ID and initiate table to track progress.
  - Get data from table and process it into chunks.
  - Send data to receiver with chunk count and checksum.
  - Send confirmation for when data is processed.
  - Handle any errors during data transmission and log them.
  - Once confirmation is received, mark tracker for table complete to move on to the next table.
  - Once all tables are complete, mark tracker complete to be ready for next sync.
  - Provide detailed feedback to the user about the sync progress and results.

### WorkflowReceiver - Logs to receiverlogs - For this testing the receivers base table will be sharedDataRemote

- Message from sender triggers event that starts the workflow.
- function startWorkflowReceiver - Series of functions that drive the process end to end.
  - Send confirmation/acknowledgement ready to receive data chunks or busy with another sync.
  - Receive data chunks, confirm checksum data is valid.
  - Reassemble chunks.
  - Compare data to table, merge updated and missing objects.
  - Log total objects received and objects merged.
  - Confirm data processed successfully to sender.
  - Handle any errors during data reception and log them.
  - Provide detailed feedback to the user about the sync progress and results.

### Step 2: Test the Sender and Receiver Workflows

Ensure that both workflows are tested thoroughly. Here are some test cases to consider:

- **Sender Workflow**:
  - Initiate a sync and verify that data is sent correctly.
  - Check that the logs are updated with the sync progress and any errors.
  - Verify that the sync completes successfully.

- **Receiver Workflow**:
  - Receive a sync request and verify that data is received correctly.
  - Check that the data is processed and merged correctly.
  - Verify that the logs are updated with the sync progress and any errors.

### Step 3: Handle Edge Cases and Errors

Ensure that both workflows handle errors gracefully and log appropriate messages. Test scenarios where the receiver is busy or does not respond.

### Step 4: Update Documentation

Ensure that the documentation reflects the current implementation and provides clear instructions for using the sync functionality.

### [Datasync.md](file:///d:/Code/WoW/GuildHelper/Datasync.md)

Update the documentation to reflect the current implementation.
