-- Interface Module
-- This module loads and initializes all interface components

-- Function to create the main interface layout
function GuildHelper:CreateInterface()

    -- Create the main frame
    local mainFrame = CreateFrame("Frame", "GuildHelperMainFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(1100, 730)  -- Increased width by 300 and height by 100
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        GuildHelper:SaveMainFramePosition(self)
    end)

    -- Add a title
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.title:SetFontObject("GameFontHighlight")
    mainFrame.title:SetPoint("LEFT", mainFrame.TitleBg, "LEFT", 5, 0)
    mainFrame.title:SetText("GuildHelper - FatherRahl/HereTanky - JB")

    -- Create the top frame to hold the banner
    local topFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    topFrame:SetSize(1100, 100)
    topFrame:SetPoint("TOP", mainFrame, "TOP", 0, -30)
    topFrame:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",  -- Set the paper texture as the background
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,  -- Disable tiling
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Add a new border frame around the banner frame
    local bannerBorderFrame = CreateFrame("Frame", nil, topFrame, "BackdropTemplate")
    bannerBorderFrame:SetSize(1100, 100)
    bannerBorderFrame:SetPoint("CENTER", topFrame, "CENTER", 0, 0)
    bannerBorderFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Add a title banner to display the current guild name including the realm
    local combinedGuildName = GuildHelper:GetCombinedGuildName()  -- Use the new function

    local guildNameText = topFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    guildNameText:SetPoint("CENTER", topFrame, "CENTER", 0, 0)
    guildNameText:SetText(combinedGuildName)
    guildNameText:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")  -- Increased font size to 32
    guildNameText:SetTextColor(1, 0.82, 0)  -- Gold color
    guildNameText:SetShadowColor(0, 0, 0, 1)  -- Black shadow
    guildNameText:SetShadowOffset(2, -2)  -- Offset for 3D effect

    -- Create the navigation frame on the left side
    local navFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    navFrame:SetSize(200, 590)  -- Adjusted height to fit new main frame size
    navFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -130)
    navFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,  -- Disable tiling
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Create navigation buttons
    GuildHelper:CreateNavButtons(navFrame)

    -- Create the content frame on the right side
    self.contentFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    self.contentFrame:SetSize(880, 590)  -- Adjusted width to fit new main frame size
    self.contentFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -10, -130)
    self.contentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,  -- Disable tiling
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Default to NewsPane
    GuildHelper:ShowPane("NewsPane")

    -- Store the mainFrame reference
    GuildHelper.mainFrame = mainFrame

    self:RestoreMainFramePosition(mainFrame)
end

function GuildHelper:SaveMainFramePosition(frame)
    if not GuildHelper_SavedVariables.mainFramePosition then
        GuildHelper_SavedVariables.mainFramePosition = {}
    end
    GuildHelper_SavedVariables.mainFramePosition.point, _, GuildHelper_SavedVariables.mainFramePosition.relativePoint, GuildHelper_SavedVariables.mainFramePosition.xOfs, GuildHelper_SavedVariables.mainFramePosition.yOfs = frame:GetPoint()
end

function GuildHelper:RestoreMainFramePosition(frame)
    if GuildHelper_SavedVariables.mainFramePosition then
        frame:ClearAllPoints()
        frame:SetPoint(GuildHelper_SavedVariables.mainFramePosition.point, UIParent, GuildHelper_SavedVariables.mainFramePosition.relativePoint, GuildHelper_SavedVariables.mainFramePosition.xOfs, GuildHelper_SavedVariables.mainFramePosition.yOfs)
    end
end

-- Function to create a standardized frame
function GuildHelper:CreateStandardFrame(parentFrame)
    local frame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    frame:SetAllPoints(parentFrame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,  -- Disable tiling
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    return frame
end

-- Create the DataSync pane
function GuildHelper:CreateDataSyncPane(parentFrame)
    local frame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    frame:SetAllPoints(parentFrame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("DataSync")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(800, 500)
    scrollFrame:SetPoint("TOP", 0, -50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(780, 480)
    scrollFrame:SetScrollChild(content)

    function GuildHelper:PopulateDataSyncList()
        if not GuildHelper.DataSyncManager then
            GuildHelper:AddLogEntry("DataSyncManager is not initialized.")
            return
        end

        for _, child in ipairs({content:GetChildren()}) do
            child:Hide()
        end

        local onlineToons = GuildHelper.DataSyncManager:GetOnlineAddonUsers()

        for i, toon in ipairs(onlineToons) do
            local toonFrame = CreateFrame("Frame", nil, content)
            toonFrame:SetSize(760, 30)
            toonFrame:SetPoint("TOP", 0, -30 * (i - 1))

            local toonName = toonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            toonName:SetPoint("LEFT", 10, 0)
            toonName:SetText(toon.name)

            local lastSync = toonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lastSync:SetPoint("LEFT", 200, 0)
            lastSync:SetText("Last Sync: " .. toon.lastSync)

            local syncButton = CreateFrame("Button", nil, toonFrame, "UIPanelButtonTemplate")
            syncButton:SetSize(100, 20)
            syncButton:SetPoint("RIGHT", -10, 0)
            syncButton:SetText("Sync")
            syncButton:SetScript("OnClick", function()
                GuildHelper:StartFullDataSync(toon.name)
                GuildHelper:ShowSyncLogsWindow(toon.name)
            end)
        end
    end

    GuildHelper:PopulateDataSyncList()

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 30)
    refreshButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        GuildHelper:PopulateDataSyncList()
    end)
end

function GuildHelper:ShowPane(paneName)
    if not self.contentFrame then
        return
    end

    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {
            setup = {},
            roster = {},
            news = {},
            guildInfo = {},
            calendar = {}
        }
    end

    local currentGuildName = GuildHelper:GetCombinedGuildName()
    local currentGroup = GuildHelper:isGuildFederatedMember()

    if not GuildHelper:tContains(currentGroup, {name = currentGuildName}) and paneName ~= "SetupPane" then
        return
    end

    GuildHelper:FilterGuildData2()

    if paneName == "NewsPane" then
        if self.CreateNewsPane then
            self:CreateNewsPane(self.contentFrame)
        end
    elseif paneName == "DataSyncPane" then
        if self.CreateDataSyncPane then
            self:CreateDataSyncPane(self.contentFrame)
        end
    elseif paneName == "ChatPane" then
        if self.CreateChatPane then
            self:CreateChatPane(self.contentFrame)
        end
    end
end


-- Update CreateDataSyncPane to use GuildHelper module
function GuildHelper:CreateDataSyncPane()
    -- Called by function GuildHelper:ShowPane
    -- Create the main frame
    local frame = CreateFrame("Frame", "GuildHelperDataSyncFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set the background texture to look like old paper
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText("Data Sync")

    -- Create content frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(580, 460)
    content:SetPoint("CENTER", frame, "CENTER", 0, 0)

    -- Populate online users
    GuildHelper:PopulateOnlineUsers()

    -- Add Receiver and Sender log buttons
    -- (Buttons are added in DataSync.lua)

    -- Add Purge Logs and Refresh buttons
    -- (Buttons are added in DataSync.lua)

    self.dataSyncFrame = frame
end
