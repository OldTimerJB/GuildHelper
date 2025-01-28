# Data Sync Flow Diagram

```mermaid
flowchart LR
    A((Initiate Sync)) --> Z[Process Setup Table - Federated Guild Check]
    Z -->|Not Federated| X((Only sync current guild content))
    Z -->|Federated| B[Check Mode: DAYS or ALL]((Only sync federated guild content))
    B -->|DAYS| C[CalculateDaysDifference]
    B -->|ALL| D[Skip Days Check]
    C --> E[CompareMetadata (local vs remote)]
    D --> E
    E -->|Missing or older locally| F[updatesNeededLocally]
    E -->|Missing or older remotely| G[updatesNeededRemotely]
    F -->|Need remote data| H[Request Entries from Remote]
    G -->|Send local data| I[Push Entries to Remote]
    H -->|Chunks Received| J[Update Local State]
    I -->|Remote updates| K[Update Remote State]
    J -->|All chunks received| L[HandleDataChunkRemote]
    K -->|All chunks received| M[HandleDataChunkLocal]
    L --> N[HandleLocalSyncCompletion]
    M --> O[SyncNextTable]
```

## Order of Tasks and Functions

1. **Initiate Sync**: `GuildHelper.WorkflowManager:StartSync(user, mode, N)`
2. **Federated Guild Check**: `GuildHelper.WorkflowManager:IsFederatedGuild()`
3. **Send User Sync Table**: `GuildHelper.WorkflowManager:SendSaveUser()`
4. **Request Remote Metadata**: `GuildHelper.WorkflowManager:RequestRemoteMetadata()`
    - The remote user receives the request and sends back the metadata.
    - The request includes the mode, days, and table name.
5. **Handle Metadata Request**: `GuildHelper.DataSyncHandler:HandleMetadataRequest(user, mode, days, tableName)`
    - Filter metadata based on mode and days.
    - Send metadata in chunks or send a NO_META response if no metadata to send.
6. **Handle Metadata Response**: `GuildHelper:HandleAddonMessage(prefix, message, channel, sender)`
    - The local user listens for the metadata response.
    - The remote user sends the metadata back in chunks.
7. **Handle Metadata Chunk**: `GuildHelper.DataSyncHandler:HandleMetadataChunk(message)`
    - Reassemble metadata chunks and store them.
8. **Compare Metadata**: `GuildHelper.DataSyncManager:CompareMetadata(localMetadata, remoteMetadata)`
    - Compare local and remote metadata to determine updates needed.
9. **Process Metadata Comparison**: `GuildHelper.DataSyncManager:ProcessMetadataComparison()`
    - Process the results of the metadata comparison.
10. **Handle Updates Needed**: `GuildHelper.DataSyncManager:HandleUpdatesNeeded(updatesNeededLocally, updatesNeededRemotely)`
    - Handle the updates needed based on the comparison.
11. **Request Entries from Remote**: `GuildHelper.DataSyncHandler:RequestEntriesFromRemote(entries)`
    - Request missing entries from the remote user.
12. **Push Entries to Remote**: `GuildHelper.DataSyncHandler:SendDataRemote(entries)`
    - Push local entries to the remote user.
13. **Send Data Chunks (Local)**: `GuildHelper.DataSyncHandler:SendDataLocal(callback)`
    - Send data chunks to the remote user.
14. **Send Data Chunks (Remote)**: `GuildHelper.DataSyncHandler:SendDataRemote(callback)`
    - Send data chunks to the remote user.
15. **Handle Data Chunks (Remote)**: `GuildHelper.DataSyncHandler:HandleDataChunkRemote(message)`
    - Handle incoming data chunks from the remote user.
16. **Handle Data Chunks (Local)**: `GuildHelper.DataSyncHandler:HandleDataChunkLocal(message)`
    - Handle incoming data chunks from the local user.
17. **Update Local State**: `GuildHelper.DataSyncHandler:HandleDataChunkRemote(message)`
    - Update the local state with received data chunks.
18. **Update Remote State**: `GuildHelper.DataSyncHandler:HandleDataChunkLocal(message)`
    - Update the remote state with received data chunks.
19. **Handle Local Sync Completion**: `GuildHelper.WorkflowManager:HandleLocalSyncCompletion()`
    - Handle the completion of the local sync process.
20. **Sync Next Table**: `GuildHelper.WorkflowManager:syncNextTable()`
    - Move to the next table after processing the current one.

Areas clarified:
- Missing entries feed into updatesNeededLocally or updatesNeededRemotely.
- DAYS mode calls CalculateDaysDifference first.
- ALL mode compares timestamps directly.

For clarification of mode, days
Mode = DAYS or ALL -- this is to check for entries updated in past N days or ALL entries to be compared
Days = N -- N represents the number of days in the past to look for changes.  LastUpdated timestamp is less than 7 days old for example.  7 days is the default but if a user has not logged in in 14 days they can adjust it to look back 14 days.
Days = 0 -- If mode ALL and days 0 then all metadata table will be returned to be compared against.

Rules:
- Purpose of this sync process is to sync entries of data between users of the addon local and remote. The goal is to make sure the out of date entries the source exactly in table structure.
- No duplicating functions.
- Make sure every function has a comment of what function(s) call it.
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

