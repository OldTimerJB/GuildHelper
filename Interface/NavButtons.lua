-- NavButtons Module
-- This module handles the creation of navigation buttons

-- Buttons
-- - News and Announcements - NewsPane.lua
-- - Guild Information - InfoPane.lua
-- - Roster - GuildMembers.lua
-- - Member - MemberPane.lua
-- - Calendar - CalendarPane.lua
-- - Setup - SetupPane.lua

local selectedButton = nil

function GuildHelper:CreateNavButtons(parentFrame)
    local function SelectButton(button)
        if selectedButton then
            selectedButton:UnlockHighlight()
        end
        selectedButton = button
        selectedButton:LockHighlight()
    end

    -- Create a button for News and Announcements
    local newsButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    newsButton:SetSize(180, 30)
    newsButton:SetPoint("TOP", parentFrame, "TOP", 0, -10)
    newsButton:SetText("News and Announcements")
    newsButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("NewsPane")
        SelectButton(newsButton)
    end)

    -- Create a button for Guild Information
    local infoButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    infoButton:SetSize(180, 30)
    infoButton:SetPoint("TOP", newsButton, "BOTTOM", 0, -10)
    infoButton:SetText("Guild Information")
    infoButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("InfoPane")
        SelectButton(infoButton)
    end)

    -- Create a button for Roster
    local rosterButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    rosterButton:SetSize(180, 30)
    rosterButton:SetPoint("TOP", infoButton, "BOTTOM", 0, -10)
    rosterButton:SetText("Roster")
    rosterButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("RosterPane")
        SelectButton(rosterButton)
        if GuildHelper.rosterFrame and GuildHelper.rosterFrame.refreshButton then
            GuildHelper.rosterFrame.refreshButton:GetScript("OnClick")()
        end
    end)

    -- Create a button for Member
    local memberButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    memberButton:SetSize(180, 30)
    memberButton:SetPoint("TOP", rosterButton, "BOTTOM", 0, -10)
    memberButton:SetText("My Toons")
    memberButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("MemberPane")
        SelectButton(memberButton)
    end)

    -- Create a button for Calendar
    local calendarButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    calendarButton:SetSize(180, 30)
    calendarButton:SetPoint("TOP", memberButton, "BOTTOM", 0, -10)
    calendarButton:SetText("Calendar")
    calendarButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("CalendarPane")
        SelectButton(calendarButton)
    end)

    -- Create a button for Chat
    local chatButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    chatButton:SetSize(180, 30)
    chatButton:SetPoint("TOP", calendarButton, "BOTTOM", 0, -10)
    chatButton:SetText("Chat")
    chatButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("ChatPane")
        SelectButton(chatButton)
    end)

    -- Create a button for DataSync
    local dataSyncButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    dataSyncButton:SetSize(180, 30)
    dataSyncButton:SetPoint("TOP", chatButton, "BOTTOM", 0, -10)
    dataSyncButton:SetText("DataSync")
    dataSyncButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("DataSyncPane")
        SelectButton(dataSyncButton)
    end)

    -- Create a button for Groups
    local groupsButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    groupsButton:SetSize(180, 30)
    groupsButton:SetPoint("TOP", dataSyncButton, "BOTTOM", 0, -10)
    groupsButton:SetText("Groups")
    groupsButton:SetScript("OnClick", function()
        GuildHelper:ShowPane("GroupsPane")  -- Ensure the correct pane name is used
        SelectButton(groupsButton)
    end)

    local isOfficerOrGM = IsGuildLeader()
    -- Create a button for Setup (only for GMs)
    if isOfficerOrGM then
        local setupButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
        setupButton:SetSize(180, 30)
        setupButton:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 50)
        setupButton:SetText("Setup")
        setupButton:SetScript("OnClick", function()
            GuildHelper:ShowPane("SetupPane")
            SelectButton(setupButton)
        end)
    end

    -- Create a button for Maintenance (only for officers and GMs)
    if isOfficerOrGM then
        local maintenanceButton = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
        maintenanceButton:SetSize(180, 30)
        maintenanceButton:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 10)
        maintenanceButton:SetText("Maintenance")
        maintenanceButton:SetScript("OnClick", function()
            GuildHelper:ShowPane("MaintenancePane")
            SelectButton(maintenanceButton)
        end)
    end

    -- Select the News button by default
    SelectButton(newsButton)
end

function GuildHelper:IsGuildLeader()
    local playerRankIndex = C_GuildInfo.GetGuildRankOrder(UnitName("player"))
    return playerRankIndex == 0  -- Guild leader rank is always 0
end

function GuildHelper:IsGuildOfficer()
    local playerRankIndex = C_GuildInfo.GetGuildRankOrder(UnitName("player"))
    return playerRankIndex and playerRankIndex <= 1  -- Assuming rank 1 is officer
end

-- Function to show the specified pane
function GuildHelper:ShowPane(paneName)
    if not self.contentFrame then
        return
    end

    local currentGroup = GuildHelper:isGuildFederatedMember()
    local combinedGuildName = GuildHelper:GetCombinedGuildName()

    -- Clear the content frame
    self.contentFrame:Hide()
    for _, child in ipairs({self.contentFrame:GetChildren()}) do
        child:Hide()
    end

    -- Create and show the specified pane
    if paneName == "NewsPane" then
        self:CreateNewsPane(self.contentFrame)
    elseif paneName == "InfoPane" then
        self:CreateInfoPane(self.contentFrame)
    elseif paneName == "RosterPane" then
        if self.CreateRosterPane then
            self:CreateRosterPane(self.contentFrame)
        end
    elseif paneName == "MemberPane" then
        self:CreateMemberPane(self.contentFrame)
    elseif paneName == "CalendarPane" then
        self:CreateCalendarPane(self.contentFrame)
    elseif paneName == "SetupPane" then
        if self.CreateSetupPane then
            self:CreateSetupPane(self.contentFrame)
        end
    elseif paneName == "SyncPane" then
        if self.CreateSyncPane then
            self:CreateSyncPane(self.contentFrame)
        end
    elseif paneName == "MaintenancePane" then
        if self.CreateMaintenancePane then
            self:CreateMaintenancePane(self.contentFrame)
        end
    elseif paneName == "DataSyncPane" then
        if self.CreateDataSyncPane then
            self:CreateDataSyncPane(self.contentFrame)
        end
    elseif paneName == "ChatPane" then
        if self.CreateChatPane then
            self:CreateChatPane(self.contentFrame)
        end
    elseif paneName == "GroupsPane" then
        if GuildHelper.CreateGroupsPane then
            GuildHelper:CreateGroupsPane(self.contentFrame)
        end
    end

    self.contentFrame:Show()
end