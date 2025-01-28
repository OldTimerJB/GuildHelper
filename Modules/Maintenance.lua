GuildHelper = GuildHelper or {}
GuildHelper.Maintenance = GuildHelper.Maintenance or {}

-- Initialize metadata tables for shared data
function GuildHelper.Maintenance:InitializeMetadataTables()
    -- Called by function GuildHelper:OnLoad
    if not GuildHelper_SavedVariables.sharedData.metadata then
        GuildHelper_SavedVariables.sharedData.metadata = {
            roster = {},
            news = {},
            guildInfo = {},
            calendar = {},
            setup = {}
        }
    end

    -- Ensure setup table is initialized
    GuildHelper_SavedVariables.sharedData.setup = GuildHelper_SavedVariables.sharedData.setup or {}

    -- Build or update the metadata tables
    for key, news in pairs(GuildHelper_SavedVariables.sharedData.news) do
        GuildHelper_SavedVariables.sharedData.metadata.news[key] = {
            id = news.id,
            tableType = "news",
            guildName = news.guildName,
            lastUpdated = news.lastUpdated,
            deleted = news.deleted
        }
    end

    for key, guildInfo in pairs(GuildHelper_SavedVariables.sharedData.guildInfo) do
        GuildHelper_SavedVariables.sharedData.metadata.guildInfo[key] = {
            id = guildInfo.id,
            tableType = "guildInfo",
            guildName = guildInfo.guildName,
            lastUpdated = guildInfo.lastUpdated,
            deleted = guildInfo.deleted
        }
    end

    for key, calendar in pairs(GuildHelper_SavedVariables.sharedData.calendar) do
        GuildHelper_SavedVariables.sharedData.metadata.calendar[key] = {
            id = calendar.id,
            tableType = "calendar",
            guildName = calendar.guildName,
            lastUpdated = calendar.lastUpdated,
            deleted = calendar.deleted
        }
    end

    --local count = 0
    for key, roster in pairs(GuildHelper_SavedVariables.sharedData.roster) do
    --        if count >= 10 then
    --            break
    --        end
        GuildHelper_SavedVariables.sharedData.metadata.roster[key] = {
            id = roster.id,
            tableType = "roster",
            guildName = roster.guildName,
            lastUpdated = roster.lastUpdated,
            deleted = roster.deleted
        }
    --        count = count + 1
    end

    for key, setupData in pairs(GuildHelper_SavedVariables.sharedData.setup) do
        if key == "199901010000001234" then
            GuildHelper_SavedVariables.sharedData.metadata.setup[key] = {
                id = setupData.id,
                tableType = "setup",
                guildName = setupData.guildName,
                lastUpdated = setupData.lastUpdated,
                deleted = setupData.deleted
            }
        end
    end
end
