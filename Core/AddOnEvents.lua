-- AddOnEvents.lua
-- Centralized event handling for GuildHelper

-- Initialize log tables
GuildHelper.senderlogs = GuildHelper.senderlogs or {}
GuildHelper.receiverlogs = GuildHelper.receiverlogs or {}

-- Ensure InitializeMinimapIcon is defined
if not GuildHelper.InitializeMinimapIcon then
    function GuildHelper:InitializeMinimapIcon()
        -- Called by event PLAYER_LOGIN
        if not GuildHelper_SavedVariables.minimap then
            GuildHelper_SavedVariables.minimap = {}  -- Ensure minimap table is initialized
        end
        local minimapButton = CreateFrame("Button", "GuildHelperMinimapButton", Minimap)
        minimapButton:SetSize(32, 32)
        minimapButton:SetFrameStrata("MEDIUM")
        minimapButton:SetFrameLevel(8)
        minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

        local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
        overlay:SetSize(53, 53)
        overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        overlay:SetPoint("TOPLEFT")

        local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
        icon:SetSize(20, 20)
        icon:SetTexture("Interface\\AddOns\\GuildHelper\\Textures\\icon64.tga")
        icon:SetPoint("TOPLEFT", 7, -5)

        minimapButton:SetScript("OnClick", function()
            if GuildHelper.mainFrame and GuildHelper.mainFrame:IsShown() then
                GuildHelper.mainFrame:Hide()
            elseif GuildHelper.mainFrame then
                GuildHelper.mainFrame:Show()
            else
                GuildHelper:CreateInterface()
                GuildHelper.mainFrame:Show()
            end
        end)

        minimapButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("GuildHelper", 1, 1, 1)
            GameTooltip:AddLine("Left-click to toggle the main interface.", nil, nil, nil, true)
            GameTooltip:Show()
        end)

        minimapButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        minimapButton:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        minimapButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            GuildHelper_SavedVariables.minimap.position = { self:GetPoint() }
        end)

        minimapButton:RegisterForDrag("LeftButton")
        minimapButton:SetMovable(true)
        minimapButton:EnableMouse(true)

        -- Restore saved position
        if GuildHelper_SavedVariables.minimap.position then
            minimapButton:ClearAllPoints()
            minimapButton:SetPoint(unpack(GuildHelper_SavedVariables.minimap.position))
        else
            minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        end
    end
end

-- Define changelogKey
local changelogKey = "GuildHelper_Changelog"

-- OnLoad function to initialize the addon
function GuildHelper:OnLoad()
    -- Called by event ADDON_LOADED
    table.insert(self.senderlogs, string.format("[%s] %s loaded! Version: %s", date("%Y-%m-%d %H:%M:%S"), self.name, self.version))
    
    -- Initialize saved variables
    if not GuildHelper_SavedVariables then
        GuildHelper_SavedVariables = {}
    end
    if not GuildHelper_SavedVariables.globalInfo then
        GuildHelper_SavedVariables.globalInfo = {}
    end
    if not GuildHelper_SavedVariables.characterInfo then
        GuildHelper_SavedVariables.characterInfo = {}
    end
    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {
            roster = {},
            news = {},
            guildInfo = {},
            calendar = {},
            setup = {},
            UserStatus = {}  -- Ensure UserStatus table is included
        }
    end
    if not GuildHelper_SavedVariables.sharedData.UserStatus then
        GuildHelper_SavedVariables.sharedData.UserStatus = {
            userNameRealm = UnitName("player") .. "-" .. GetRealmName(),
            lastSync = nil,
            status = "available"
        }
    end
    if not GuildHelper_SavedVariables.minimap then
        GuildHelper_SavedVariables.minimap = {}
    end
    if not GuildHelper_SavedVariables[changelogKey] then
        GuildHelper_SavedVariables[changelogKey] = {}
    end
    if not GuildHelper_SavedVariables.exclusionList then
        GuildHelper_SavedVariables.exclusionList = {}
    end
    if not GuildHelper_SavedVariables.log then
        GuildHelper_SavedVariables.log = {}
    end
    -- Ensure UserStatus is initialized by calling OnlineAddonUsers
    -- Initialize WorkflowManager
    GuildHelper.WorkflowManager = GuildHelper.WorkflowManager or {}

    -- Register the addon message prefix
    C_ChatInfo.RegisterAddonMessagePrefix("GUILDHELPER")
end

-- Function to handle addon messages with raw data logging
function GuildHelper:HandleAddonMessage(prefix, message, channel, sender)
    -- Called by event CHAT_MSG_ADDON
    if prefix ~= "GUILDHELPER" then return end

    if message == "WHO_IS_ONLINE" then
        local userStatus = GuildHelper_SavedVariables.sharedData.UserStatus
        local responseMessage = userStatus.status == "syncing" and "I_AM_BUSY" or "I_AM_ONLINE"
        responseMessage = responseMessage .. ";" .. (userStatus.lastSync or "N/A")
        C_ChatInfo.SendAddonMessage("GUILDHELPER", responseMessage, "GUILD")
    elseif message:find("I_AM_ONLINE") then
        local lastSync = message:match("I_AM_ONLINE;(.*)")
        GuildHelper.onlineAddonUsers = GuildHelper.onlineAddonUsers or {}
        table.insert(GuildHelper.onlineAddonUsers, { sender = sender, status = "available", lastSync = lastSync })
    elseif message:find("I_AM_BUSY") then
        local lastSync = message:match("I_AM_BUSY;(.*)")
        GuildHelper.onlineAddonUsers = GuildHelper.onlineAddonUsers or {}
        table.insert(GuildHelper.onlineAddonUsers, { sender = sender, status = "busy", lastSync = lastSync })
    elseif message:find("ENTRY_CHUNK_L") then
        GuildHelper.DataSyncHandler:HandleDataChunkLocal(message)
    elseif message:find("ENTRY_CHUNK_R") then
        GuildHelper.DataSyncHandler:HandleDataChunkRemote(message)
    elseif message:find("SAVE_USER") then
        local data = message:match("SAVE_USER;(.*)")
        GuildHelper:AddLogEntry("Received SAVE_USER data from " .. sender)
        local userTable = GuildHelper.json:json_parse(data)
        GuildHelper.UserSyncTable = userTable
        GuildHelper:AddLogEntry("SAVE_USER data from " .. sender .. " saved in local UserSyncTable")
        print( "Sync process started by: " .. sender)
    elseif message:find("REQUEST_METADATA") then
        local mode, days, tableName = message:match("REQUEST_METADATA;([^;]+);([^;]+);([^;]+)")
        GuildHelper.DataSyncHandler:HandleMetadataRequest(sender, mode, tonumber(days), tableName)
    elseif message:find("META_CHUNK") then
        GuildHelper.DataSyncHandler:HandleMetadataChunk(message)
    elseif message:find("NO_META") then
        local tableName = message:match("NO_META;([^;]+)")
        GuildHelper:AddLogEntry("No metadata received for table " .. tableName .. " from " .. sender)
        -- Proceed with metadata comparison and sync
        GuildHelper.DataSyncManager:ProcessMetadataComparison()
    elseif message:find("REQUEST_ENTRY") then
        local tableName, entryId = message:match("REQUEST_ENTRY;([^;]+);([^;]+)")
        GuildHelper.DataSyncHandler:FetchAndSendEntries(sender, tableName, entryId)
    end
end

-- Function to get online addon users
function GuildHelper:GetOnlineAddonUsers()
    GuildHelper.onlineAddonUsers = {}
    C_ChatInfo.SendAddonMessage("GUILDHELPER", "WHO_IS_ONLINE", "GUILD")
    C_Timer.After(2, function()
        -- Process the list of online addon users after 2 seconds
        for _, user in ipairs(GuildHelper.onlineAddonUsers) do
            --print(user.sender .. " is " .. user.status .. " (Last Sync: " .. user.lastSync .. ")")
        end
    end)
end

-- Function to add log entries
function GuildHelper:AddLogEntry(entry)
    table.insert(GuildHelper_SavedVariables.log, entry)
    if self.logViewerFrame and self.logViewerFrame.logText then
        self.logViewerFrame.logText:Insert(entry .. "\n")
    end
end

-- Event handler function
local function OnEvent(self, event, ...)
    -- Called by various events
    -- Log the event being handled
    -- table.insert(GuildHelper.senderlogs, string.format("[Local][%s] Handling event: %s", date("%Y-%m-%d %H:%M:%S"), event))
    
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "GuildHelper" then
            GuildHelper:OnLoad()
        end
    elseif event == "PLAYER_LOGIN" then
        GuildHelper:InitializeMinimapIcon()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        -- Log the received addon message
        --table.insert(GuildHelper.receiverlogs, string.format("[Local][%s] Received addon message from %s: %s", date("%Y-%m-%d %H:%M:%S"), sender, message))
        GuildHelper:HandleAddonMessage(prefix, message, channel, sender)
    end
end

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", OnEvent)

