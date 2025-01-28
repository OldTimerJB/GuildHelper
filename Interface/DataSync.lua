local DataSync = {}

-- Ensure DataSyncComs is properly referenced
local DataSyncComs = GuildHelper.DataSyncComs

function GuildHelper:CreateDataSyncPane(parentFrame)
    -- Create the main frame
    local frame = GuildHelper:CreateStandardFrame(parentFrame)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("Data Sync")

    -- Content frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(parentFrame:GetWidth() - 20, parentFrame:GetHeight() - 150)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    frame.content = content

    -- Set the background texture to look like old paper
    local bgTexture = content:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(content)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Scroll frame for online users
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(content:GetWidth() - 20, content:GetHeight() - 20)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(scrollChild)

    -- N of days in past changes to sync
    local daysLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    daysLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 50)
    daysLabel:SetText("N of days in past changes to sync:")

    local daysInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    daysInput:SetSize(50, 20)
    daysInput:SetPoint("LEFT", daysLabel, "RIGHT", 10, 0)
    daysInput:SetAutoFocus(false)
    daysInput:SetText("7")
    frame.daysInput = daysInput

    -- Sync logs button
    local syncLogsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    syncLogsButton:SetSize(120, 30)
    syncLogsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    syncLogsButton:SetText("Show Sync Logs")
    syncLogsButton:SetScript("OnClick", function()
        GuildHelper:ShowLogViewer()
    end)

    -- Purge logs button
    local purgeLogsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    purgeLogsButton:SetSize(120, 30)
    purgeLogsButton:SetPoint("LEFT", syncLogsButton, "RIGHT", 10, 0)
    purgeLogsButton:SetText("Purge Logs")
    purgeLogsButton:SetScript("OnClick", function()
        GuildHelper_SavedVariables.log = {}
        GuildHelper:ShowLogViewer()
    end)

    -- Reset sync button
    local resetSyncButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetSyncButton:SetSize(120, 30)
    resetSyncButton:SetPoint("LEFT", purgeLogsButton, "RIGHT", 10, 0)
    resetSyncButton:SetText("Reset Sync")
    resetSyncButton:SetScript("OnClick", function()
        GuildHelper_SavedVariables.sharedData.UserStatus.lastSync = nil
        print("Sync reset for local user.")
    end)

    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(120, 30)
    refreshButton:SetPoint("BOTTOM", frame, "BOTTOM", 25, 10)  -- Move to the right by 10 pixels
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        GuildHelper.DataSync:Refresh()
    end)

    -- List of available users
    local availableUsersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    availableUsersLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    availableUsersLabel:SetText("Available Users:")

    -- Create headers
    local headers = {"User", "Last Sync", "Status", "Actions"}
    local headerFrame = CreateFrame("Frame", nil, scrollChild)
    headerFrame:SetSize(scrollChild:GetWidth(), 20)
    headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)

    local headerWidth = headerFrame:GetWidth() / #headers
    for i, title in ipairs(headers) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetSize(headerWidth, 20)
        header:SetFontObject("GameFontHighlightSmall")  -- Set font to bold
        header:SetTextColor(1, 1, 1)  -- Set text color to white
        if i == 1 then
            header:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
        else
            header:SetPoint("LEFT", headerFrame.headers[i - 1], "RIGHT", 0, 0)
        end
        header:SetText(title)
        headerFrame.headers = headerFrame.headers or {}
        headerFrame.headers[i] = header
    end

    local function PopulateAvailableUsers()
        local onlineUsers = GuildHelper.onlineAddonUsers or {}
        local offset = -30
        for _, user in ipairs(onlineUsers) do
            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(scrollChild:GetWidth(), 20)
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, offset)

            local userName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            userName:SetPoint("LEFT", row, "LEFT", 0, 0)
            userName:SetSize(headerWidth, 20)
            userName:SetFontObject("GameFontHighlightSmall")  -- Set font to bold
            userName:SetTextColor(1, 1, 1)  -- Set text color to white
            userName:SetText(user.sender)

            local lastSync = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lastSync:SetPoint("LEFT", userName, "RIGHT", 0, 0)
            lastSync:SetSize(headerWidth, 20)
            lastSync:SetFontObject("GameFontHighlightSmall")  -- Set font to bold
            lastSync:SetTextColor(1, 1, 1)  -- Set text color to white
            lastSync:SetText(user.lastSync or "N/A")

            local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            status:SetPoint("LEFT", lastSync, "RIGHT", 0, 0)
            status:SetSize(headerWidth, 20)
            status:SetFontObject("GameFontHighlightSmall")  -- Set font to bold
            status:SetTextColor(1, 1, 1)  -- Set text color to white
            status:SetText(user.status)

            local actionsFrame = CreateFrame("Frame", nil, row)
            actionsFrame:SetSize(70, 20)
            actionsFrame:SetPoint("LEFT", status, "RIGHT", 10, 0)

            local syncDaysButton = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
            syncDaysButton:SetSize(30, 20)
            syncDaysButton:SetPoint("LEFT", actionsFrame, "LEFT", 0, 0)
            syncDaysButton:SetText("SD")
            syncDaysButton:SetScript("OnClick", function()
                local days = tonumber(daysInput:GetText()) or 7
                GuildHelper.WorkflowManager:StartSync(user.sender, "DAYS", days)
            end)

            local syncAllButton = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
            syncAllButton:SetSize(30, 20)
            syncAllButton:SetPoint("LEFT", syncDaysButton, "RIGHT", 10, 0)
            syncAllButton:SetText("SA")
            syncAllButton:SetScript("OnClick", function()
                GuildHelper.WorkflowManager:StartSync(user.sender, "ALL", 0)
            end)

            offset = offset - 25
        end
    end

    -- Get online users and populate available users after a delay
    GuildHelper:GetOnlineAddonUsers()
    C_Timer.After(2, PopulateAvailableUsers)

    self.dataSyncFrame = frame
end

function DataSync:Show()
    if not GuildHelper.dataSyncFrame then
        GuildHelper:CreateDataSyncPane(GuildHelper.mainFrame)
    end
    GuildHelper.dataSyncFrame:Show()
end

function DataSync:Hide()
    if GuildHelper.dataSyncFrame then
        GuildHelper.dataSyncFrame:Hide()
    end
end

GuildHelper.DataSync = DataSync

-- Function to show a log viewer window
function GuildHelper:ShowLogViewer()
    if not self.logViewerFrame then
        local frame = CreateFrame("Frame", "GuildHelperLogViewerFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(600, 400)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            GuildHelper_SavedVariables.logViewerPosition = { self:GetPoint() }
        end)

        frame.title = frame:CreateFontString(nil, "OVERLAY")
        frame.title:SetFontObject("GameFontHighlight")
        frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
        frame.title:SetText("GuildHelper Logs")

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(560, 320)
        scrollFrame:SetPoint("TOP", frame, "TOP", 0, -30)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(560, 320)
        scrollFrame:SetScrollChild(content)

        local logText = CreateFrame("EditBox", nil, content)
        logText:SetMultiLine(true)
        logText:SetSize(540, 300)
        logText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        logText:SetFontObject("GameFontHighlightSmall")
        logText:SetJustifyH("LEFT")
        logText:SetMaxLetters(999999)
        logText:EnableMouse(true)
        logText:SetAutoFocus(false)
        logText:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        frame.logText = logText

        -- Add refresh button
        local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        refreshButton:SetSize(120, 30)
        refreshButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            GuildHelper:ShowLogViewer()
        end)

        self.logViewerFrame = frame
    end

    if GuildHelper_SavedVariables.logViewerPosition then
        self.logViewerFrame:ClearAllPoints()
        self.logViewerFrame:SetPoint(unpack(GuildHelper_SavedVariables.logViewerPosition))
    end

    self.logViewerFrame.logText:SetText("")
    for _, logEntry in ipairs(GuildHelper_SavedVariables.log or {}) do
        self.logViewerFrame.logText:Insert(logEntry .. "\n")
    end
    self.logViewerFrame:Show()
end

-- Function to refresh the data sync interface
function GuildHelper.DataSync:Refresh()
    -- Called by the refresh button
    GuildHelper:AddLogEntry("Refreshing data sync interface...")

    -- Ensure the callback function is correctly defined
    local function refreshCallback()
        -- Add the logic to refresh the data sync interface here
        GuildHelper:AddLogEntry("Data sync interface refreshed.")
    end

    -- Call C_Timer.After with the correct callback function
    C_Timer.After(1, refreshCallback)
end

