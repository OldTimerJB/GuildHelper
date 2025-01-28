-- GuildHelper Main Entry Point

GuildHelper = GuildHelper or {}
GuildHelper_SavedVariables = {}
GuildHelper_SavedVariables.sharedData = {}
GuildHelper.name = "GuildHelper"
GuildHelper.version = "1.0.23f"  -- Add version information

-- Define changelogKey
local changelogKey = "GuildHelper_Changelog"

-- Initialize saved variables early
if not GuildHelper_SavedVariables then
    GuildHelper_SavedVariables = {}
end

-- Function to add log entries
function GuildHelper:AddLogEntry(entry)
    -- Called by various functions to add log entries
    if self.logText then
        self.logText:SetText(self.logText:GetText() .. entry .. "\n")
        self.logContent:SetHeight(self.logText:GetStringHeight())
    end
end

C_Timer.NewTicker(86400, function()  -- Run every 24 hours
    GuildHelper:UpdateGuildRoster()
end)

function GuildHelper:PeriodicCleanup()
    -- Called by C_Timer.NewTicker
    C_Timer.NewTicker(86400, function()  -- Run every 24 hours
        GuildHelper:UpdateGuildRoster()
    end)
end

function GuildHelper:InitializeSavedVariables()
    -- Called by function GuildHelper:OnLoad
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
            setup = {}
        }
    end
    if not GuildHelper_SavedVariables.sharedData.setup then
        GuildHelper_SavedVariables.sharedData.setup = {}
    end
    if not GuildHelper_SavedVariables.minimap then
        GuildHelper_SavedVariables.minimap = {}  -- Ensure minimap table is initialized
    end
    if not GuildHelper_SavedVariables[changelogKey] then
        GuildHelper_SavedVariables[changelogKey] = {}
    end
    if not GuildHelper_SavedVariables.exclusionList then
        GuildHelper_SavedVariables.exclusionList = {}
    end

    -- Add a delay before calling SyncMissingToons to ensure guild information is available
    C_Timer.After(5, function()
        GuildHelper:SyncMissingToons()
        GuildHelper:FilterGuildData2()
    end)
end

function GuildHelper:InitializeInterface()
    -- Called by function GuildHelper:OnLoad
    if not self.interfaceInitialized then
        self:CreateInterface()
        self.interfaceInitialized = true
    end
end

function GuildHelper:CreateInterface()
    -- Called by function GuildHelper:InitializeInterface
    -- Create the main frame for the addon
    self.mainFrame = CreateFrame("Frame", "GuildHelperMainFrame", UIParent)
    self.mainFrame:SetSize(850, 600)  -- Increased width by 50 pixels
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", self.mainFrame.StartMoving)
    self.mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        GuildHelper:SaveMainFramePosition()
    end)

    -- Set the background texture to look like old paper
    local bgTexture = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(self.mainFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Load the guild banner
    GuildHelper:LoadGuildBanner(self.mainFrame)

    -- Create a title for the main frame
    local title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.mainFrame, "TOP", 0, -10)
    title:SetText("GuildHelper - FatherRahl/HereTanky - JB")

    -- Display the current guild name in the middle center of the frame
    local currentGuildName = GetGuildInfo("player") or "No Guild"
    local guildNameText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    guildNameText:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    guildNameText:SetText(currentGuildName)

    -- Create a scroll frame for the content
    local scrollFrame = CreateFrame("ScrollFrame", "GuildHelperScrollFrame", self.mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Create a content frame to hold the different panes
    self.contentFrame = CreateFrame("Frame", nil, scrollFrame)
    self.contentFrame:SetSize(1250, 1000)  -- Increased width by 50 pixels
    scrollFrame:SetScrollChild(self.contentFrame)

    -- Create navigation buttons
    self:CreateNavButtons(self.mainFrame)

    -- Create all panes
    self:CreateNewsPane(self.contentFrame)
    self:CreateRosterPane(self.contentFrame)
    self:CreateMemberPane(self.contentFrame)
    self:CreateCalendarPane(self.contentFrame)
    self:CreateSetupPane(self.contentFrame)
    self:CreateSyncPane(self.contentFrame)
    self:CreateMaintenancePane(self.contentFrame)
    self:CreateChatPane(self.contentFrame)  -- Add this line to create the ChatPane

    -- Restore saved position
    self:RestoreMainFramePosition(self.mainFrame)

    -- Show the main frame
    self.mainFrame:Hide()
end

function GuildHelper:LoadGuildBanner(frame)
    -- Called by function GuildHelper:CreateInterface
    -- This function is now empty as the banner code is moved to Interface.lua
end

function GuildHelper:ShowPane(paneName)
    -- Called by function GuildHelper:CreateInterface
    -- Hide all panes
    for _, pane in pairs({self.contentFrame:GetChildren()}) do
        pane:Hide()
    end

    -- Show the selected pane
    if paneName == "GroupsPane" then
        if not self.groupsFrame then
            self.groupsFrame = CreateFrame("Frame", "GuildHelperGroupsFrame", self.contentFrame)
            self.groupsFrame:SetAllPoints(self.contentFrame)
            self:CreateGroupsPane(self.groupsFrame)
        end
        self.groupsFrame:Show()
    elseif paneName == "DataSyncPane" then
        if not self.dataSyncFrame then
            self:CreateDataSyncPane()
        end
        self.dataSyncFrame:Show()
    elseif paneName == "ChatPane" then
        if not self.chatFrame then
            self:CreateChatPane(self.contentFrame)
        end
        self.chatFrame:Show()
    elseif self[paneName] then
        self[paneName]:Show()
    end
end

function GuildHelper:CreateChatPane(parent)
    -- Called by function GuildHelper:ShowPane
    GuildHelper.ChatPane:CreateChatPane(parent)
end

function GuildHelper:PurgeRoster()
    -- Called by user command or interface action
    GuildHelper_SavedVariables.sharedData.roster = {}
end

function GuildHelper:ToggleSelfTest()
    -- Called by user command or interface action
    self.testWithSelf = not self.testWithSelf
end

-- Function to wipe all saved data
function GuildHelper:WipeAllData()
    -- Called by user command or interface action
    GuildHelper_SavedVariables = {
        sharedData = {
            setup = {},
            roster = {},
            news = {},
            calendar = {},
            guildInfo = {}
        },
        globalInfo = {},
        exclusionList = {},
        daysInactive = 60
    }
end

function GuildHelper:RegisterSlashCommands()
    -- Called by function GuildHelper:OnLoad
    SLASH_GUILDHELPER1 = "/ghelper"
    SlashCmdList["GUILDHELPER"] = function(msg)
        if msg == "gui" then
            if GuildHelper.mainFrame and GuildHelper.mainFrame:IsShown() then
                GuildHelper.mainFrame:Hide()
            elseif GuildHelper.mainFrame then
                GuildHelper.mainFrame:Show()
            else
                GuildHelper:CreateInterface()
                GuildHelper.mainFrame:Show()
            end
        elseif msg == "reset_data" then
            GuildHelper:ResetSavedVariables()
        elseif msg == "reset_toon" then
            ClearMemberInfo(UnitName("player"))
        elseif msg == "reset_all" then
            ClearAllMemberInfo()
        elseif msg == "purgeroster" then
            GuildHelper:PurgeRoster()
        elseif msg == "toggle_self_test" then
            GuildHelper:ToggleSelfTest()
        elseif msg == "clearsessions" then
            GuildHelper.DataSyncManager:ClearAllSessions()
        elseif msg == "wipe_data" then
            GuildHelper:WipeAllData()
        elseif msg == "clearexcluded" then
            GuildHelper_SavedVariables.exclusionList = {}
        elseif msg == "setup" then
            GuildHelper:ShowPane("SetupPane")
        else
            print("Usage:")
            print("/ghelper gui - Toggle the main interface")
        end
    end
end

local function ClearMemberInfo(toonName)
    -- Called by user command or interface action
    GuildHelper_SavedVariables.characterInfo[toonName] = nil
end

local function ClearAllMemberInfo()
    -- Called by user command or interface action
    GuildHelper_SavedVariables.characterInfo = {}
end

-- Function to handle the ADDON_LOADED event
local function OnAddonLoaded(self, event, addonName)
    -- Called by event ADDON_LOADED
    if addonName == "GuildHelper" then
        GuildHelper:InitializeSavedVariables()
        GuildHelper:SyncMissingToons()
        GuildHelper:RegisterSlashCommands()  -- Register slash commands
        -- Initialize WorkflowManager
        GuildHelper.WorkflowManager = GuildHelper.WorkflowManager or {}
        -- Initialize Metadata Tables
        GuildHelper.Maintenance:InitializeMetadataTables()

        -- Join the chat channel after a 30-second delay
        C_Timer.After(30, function()
            GuildHelper:JoinChatChannel()
        end)

        C_Timer.After(15, function()
            GuildHelper.WorkflowManager:SyncActiveUsers()
        end)
    end
end

-- Function to join the chat channel
function GuildHelper:JoinChatChannel()
    local chatData = GuildHelper.ChatPane:GetChatData()
    local chatChannel = chatData.chatchannel
    local channelPassword = chatData.channelpassword

    if chatChannel and chatChannel ~= "" then
        JoinChannelByName(chatChannel, nil)
        C_Timer.After(1, function()
            local channels = { GetChannelList() }
            for i = 1, #channels, 3 do
                local id, name, _ = channels[i], channels[i + 1], channels[i + 2]
                if name == chatChannel then
                    print("Joined channel:", chatChannel, "with ID:", id)
                    GuildHelper.ChatPane.channelId = id
                    break
                end
            end
        end)
    end
end

-- Register event to join the chat channel after 10 seconds
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(10, function()
            GuildHelper:JoinChatChannel()
        end)
    end
end)

-- Register the ADDON_LOADED event
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)

C_Timer.NewTicker(86400, function()  -- Run every 24 hours
    GuildHelper:UpdateGuildRoster()
end)

GuildHelper_SavedVariables.log = {}