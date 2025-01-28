-- RosterPane Module
-- This module handles the roster pane

function GuildHelper:HideRosterPane()
    if self.rosterFrame then
        self.rosterFrame:Hide()
    end
end

local function GetToonLevel(toonName)
    -- Pull the level from the shared roster data or set it to NA
    local savedToons = GuildHelper_SavedVariables.sharedData.roster or {}
    local toonData = savedToons[toonName]
    if (toonData and toonData.data and toonData.data.level and toonData.data.level ~= "") then
        return toonData.data.level
    else
        return "NA"
    end
end

local function IsToonOnlineInLinkedGuilds(toonName)
    -- Check online status in linked guilds
    local online = GuildHelper:IsToonOnline(toonName)
    return online or false
end

local function UpdateToonCount(rosterFrame, count)
    local toonCountText = rosterFrame.toonCountText
    if (toonCountText) then
        toonCountText:SetText("Total Toons: " .. count)
    end
end

function GuildHelper:CreateRosterPane(parentFrame)
    -- Ensure the filtered roster is populated
    self:FilterGuildData2()  -- Ensure filteredRoster is populated

    local currentGuildName = GetGuildInfo("player")
    if not currentGuildName then
        return
    end

    local rosterFrame = GuildHelper:CreateStandardFrame(parentFrame)

    -- Set the background texture to look like old paper
    local bgTexture = rosterFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(rosterFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Add a title
    local title = rosterFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", rosterFrame, "TOP", 0, -10)
    title:SetText("Guild Roster")

    -- Create a checkbox to filter online players
    local showOnlineCheckbox = CreateFrame("CheckButton", nil, rosterFrame, "UICheckButtonTemplate")
    showOnlineCheckbox:SetPoint("TOPLEFT", rosterFrame, "TOPLEFT", 10, -30) -- Adjusted position
    showOnlineCheckbox.text:SetText("Show Online Players Only")
    showOnlineCheckbox.text:SetTextColor(1, 1, 1) -- Set text color to white
    rosterFrame.showOnlineCheckbox = showOnlineCheckbox -- Ensure showOnlineCheckbox is referenced correctly

    -- Create a column selector dropdown
    GuildHelper:CreateColumnSelector(rosterFrame)

    -- Create a search box using InputBoxTemplate instead of SearchBoxTemplate
    local searchBox = CreateFrame("EditBox", nil, rosterFrame, "InputBoxTemplate")
    searchBox:SetSize(200, 30)
    searchBox:SetPoint("TOPRIGHT", rosterFrame, "TOPRIGHT", -10, -40) -- Adjusted position
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == SEARCH then
            self:SetText("")
        end
    end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("")
        end
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        local searchText = self:GetText():lower()
        local result = GuildHelper:PopulateRows(rosterFrame.content, showOnlineCheckbox, rosterFrame.headerFrame, rosterFrame.headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchText, sortBy, sortOrder)
        GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount)
    end)
    searchBox:SetText("")  -- Ensure the search box is empty initially
    rosterFrame.searchBox = searchBox -- Ensure searchBox is referenced correctly

    -- Create a content frame for the roster
    local content = CreateFrame("Frame", nil, rosterFrame)
    content:SetSize(parentFrame:GetWidth() - 20, parentFrame:GetHeight() - 150) -- Adjusted height to accommodate checkbox and search box
    content:SetPoint("TOPLEFT", rosterFrame, "TOPLEFT", 10, -90) -- Adjusted position to move window down by 20 pixels
    rosterFrame.content = content -- Ensure content is referenced correctly
    content.rows = {} -- Initialize rows table

    local sortBy, sortOrder = nil, "asc"

    -- Ensure selectedColumns is initialized
    if not selectedColumns then
        selectedColumns = {
            ["Main"] = true,
            ["BattleTag"] = true,
            ["Item Level"] = true,
            ["Interests"] = true,
            ["Guild Name"] = false,
            ["Professions"] = false,
            ["Realm"] = false,
            ["Main Toon"] = true,
            ["Spec"] = true,
            ["Joined Guild"] = false,
            ["Class"] = false,
            ["Birthdate"] = false,
            ["Faction"] = false,
            ["Roles"] = true,
            ["Rank"] = false
        }
    end

    -- Create headers
    local headers = { "Level", "Toon", "Actions" }
    for column, _ in pairs(selectedColumns) do
        if selectedColumns[column] then
            table.insert(headers, column)
        end
    end

    local headerFrame = CreateFrame("Frame", nil, rosterFrame) -- Attach headerFrame to rosterFrame instead of content
    headerFrame:SetSize(content:GetWidth(), 20)
    headerFrame:SetPoint("TOPLEFT", rosterFrame, "TOPLEFT", 10, -70) -- Adjusted position to move down by 4 pixels

    local headerWidth = (headerFrame:GetWidth() - 5) / #headers -- Shrink width by 5 pixels
    for i, title in ipairs(headers) do
        local header = CreateFrame("Button", nil, headerFrame)
        header:SetSize(headerWidth, 20)
        if (i == 1) then
            header:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 2, 0) -- Move 2 pixels to the right
        else
            header:SetPoint("LEFT", headerFrame.headers[i - 1], "RIGHT", 0, 0)
        end
        header:SetNormalFontObject("GameFontHighlightSmall")
        header:SetText(title)
        header:SetNormalTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        header:GetNormalTexture():SetVertexColor(0.1, 0.1, 0.1, 1)
        headerFrame.headers = headerFrame.headers or {}
        headerFrame.headers[i] = header

        -- Add sorting functionality
        header:SetScript("OnClick", function()
            if sortBy == title then
                sortOrder = sortOrder == "asc" and "desc" or "asc"
            else
                sortBy, sortOrder = title, "asc"
            end
            local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, headerFrame, headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower(), sortBy, sortOrder)
            rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
            GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount)
        end)
    end

    rosterFrame.headerFrame = headerFrame -- Ensure headerFrame is referenced correctly
    rosterFrame.headerWidth = headerWidth -- Ensure headerWidth is referenced correctly
    headerFrame:Show() -- Ensure headerFrame is shown

    -- Add a count of toons at the bottom center
    local toonCountText = rosterFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toonCountText:SetPoint("BOTTOM", rosterFrame, "BOTTOM", 0, 35) -- Moved up 25 pixels and to the center
    toonCountText:SetText("Total Toons: 0")
    rosterFrame.toonCountText = toonCountText

    -- Add a page indicator
    local pageIndicator = rosterFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pageIndicator:SetPoint("BOTTOM", rosterFrame, "BOTTOM", 0, 10) -- Moved to the center
    pageIndicator:SetText("Page 1 of 1")
    rosterFrame.pageIndicator = pageIndicator

    -- Initial population of rows
    rosterFrame.currentPage = 1
    rosterFrame.numRows = 20 -- Display 20 rows at a time
    self:FilterGuildData2()  -- Ensure filteredRoster is populated before calling GHPopulateRows
    local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, headerFrame, headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower())
    local rows = result.rows
    rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
    GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated initially

    -- Add pagination controls
    local prevButton = CreateFrame("Button", nil, rosterFrame, "GameMenuButtonTemplate")
    prevButton:SetSize(100, 30)
    prevButton:SetPoint("BOTTOMRIGHT", rosterFrame, "BOTTOMRIGHT", -120, 10)
    prevButton:SetText("Previous")
    prevButton:SetScript("OnClick", function()
        if rosterFrame.currentPage > 1 then
            rosterFrame.currentPage = rosterFrame.currentPage - 1
            local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, rosterFrame.headerFrame, rosterFrame.headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower(), sortBy, sortOrder)
            rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
            GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated on page change
        end
    end)

    local nextButton = CreateFrame("Button", nil, rosterFrame, "GameMenuButtonTemplate")
    nextButton:SetSize(100, 30)
    nextButton:SetPoint("BOTTOMRIGHT", rosterFrame, "BOTTOMRIGHT", -10, 10)
    nextButton:SetText("Next")
    nextButton:SetScript("OnClick", function()
        if rosterFrame.currentPage * rosterFrame.numRows < result.totalRowCount then
            rosterFrame.currentPage = rosterFrame.currentPage + 1
            local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, rosterFrame.headerFrame, rosterFrame.headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower(), sortBy, sortOrder)
            rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
            GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated on page change
        end
    end)

    -- Add a refresh button and move it to the left side, renaming it to "Reset"
    local resetButton = CreateFrame("Button", nil, rosterFrame, "GameMenuButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("BOTTOMLEFT", rosterFrame, "BOTTOMLEFT", 10, 10)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        rosterFrame.currentPage = 1  -- Reset to page 1
        -- Clear existing rows but keep the header
        for _, child in ipairs({ content:GetChildren() }) do
            if (child ~= rosterFrame.headerFrame) then
                child:Hide()
            end
        end
        -- Call SyncMissingToons and FilterGuildData2 before repopulating rows
        -- GuildHelper:SyncMissingToons()
        self:FilterGuildData2()  -- Ensure filteredRoster is populated before calling PopulateRows
        -- Repopulate rows and refresh online status
        local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, rosterFrame.headerFrame, rosterFrame.headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower(), sortBy, sortOrder)
        rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
        GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated on refresh
        -- Move cursor to the left or position 0
        for _, row in ipairs(content.rows) do
            for _, cell in ipairs(row.cells) do
                cell:SetCursorPosition(0)
            end
        end
    end)

    -- Ensure the checkbox calls GHPopulateRows correctly
    showOnlineCheckbox:SetScript("OnClick", function()
        rosterFrame.currentPage = 1  -- Reset to page 1
        -- Clear existing rows but keep the header
        for _, child in ipairs({ content:GetChildren() }) do
            if (child ~= rosterFrame.headerFrame) then
                child:Hide()
            end
        end
        -- Call SyncMissingToons and GHFilterGuildData2 before repopulating rows
        -- GuildHelper:SyncMissingToons()
        self:FilterGuildData2()  -- Ensure filteredRoster is populated before calling GHPopulateRows
        -- Repopulate rows and refresh online status
        local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, rosterFrame.headerFrame, rosterFrame.headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower(), sortBy, sortOrder)
        rosterFrame.pageIndicator:SetText("Page " .. rosterFrame.currentPage .. " of " .. result.totalPages)
        GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated on refresh
    end)

    self.rosterFrame = rosterFrame
    self.rosterFrame.toonCountText = toonCountText -- Ensure toonCountText is referenced correctly
    self.rosterFrame.resetButton = resetButton -- Ensure resetButton is referenced correctly
    self.rosterFrame.prevButton = prevButton -- Ensure prevButton is referenced correctly
    self.rosterFrame.nextButton = nextButton -- Ensure nextButton is referenced correctly
    self.rosterFrame.pageIndicator = pageIndicator -- Ensure pageIndicator is referenced correctly

    -- Call the reset button's OnClick script to populate rows initially
    resetButton:GetScript("OnClick")()

    -- Ensure the guild roster is displayed immediately
    C_GuildInfo.GuildRoster() -- Ensure guild roster is updated
    C_Timer.After(2, function() 
        self:FilterGuildData2()  -- Ensure filteredRoster is populated before calling GHPopulateRows
        local result = GuildHelper:PopulateRows(content, showOnlineCheckbox, headerFrame, headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower())
        GuildHelper:UpdateToonCount(rosterFrame, result.totalRowCount) -- Ensure toon count is updated after delay
    end) -- Add delay to ensure data loads
end

function GuildHelper:UpdateRosterList(rosterFrame, linkedGuilds, showOnlineCheckbox, headerWidth, headerFrame)
    local content = rosterFrame.content
    local rows = GuildHelper:PopulateRows(content, showOnlineCheckbox, headerFrame, headerWidth, rosterFrame.currentPage, rosterFrame.numRows, searchBox:GetText():lower())
    GuildHelper:UpdateToonCount(rosterFrame, #rows) -- Ensure toon count is updated on update
end

-- Ensure the CreateRosterPane method is defined in the GuildHelper table
GuildHelper.CreateRosterPane = GuildHelper.CreateRosterPane
GuildHelper.HideRosterPane = GuildHelper.HideRosterPane
