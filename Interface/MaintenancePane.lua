-- MaintenancePane Module
-- This module handles the maintenance pane for cleaning up inactive users



function GuildHelper:CreateMaintenancePane(parentFrame)
    local maintenanceFrame = GuildHelper:CreateStandardFrame(parentFrame)

    -- Set the background texture to look like old paper
    local bgTexture = maintenanceFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(maintenanceFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Add a title
    local title = maintenanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", maintenanceFrame, "TOP", 0, -10)
    title:SetText("Maintenance - Verify Before Remove")

    -- Add a days field to filter inactive members
    local daysFieldLabel = maintenanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    daysFieldLabel:SetPoint("TOPLEFT", maintenanceFrame, "TOPLEFT", 10, -50)
    daysFieldLabel:SetText("Days Inactive:")

    local daysField = CreateFrame("EditBox", nil, maintenanceFrame, "InputBoxTemplate")
    daysField:SetSize(50, 30)
    daysField:SetPoint("LEFT", daysFieldLabel, "RIGHT", 10, 0)
    daysField:SetAutoFocus(false)
    daysField:SetNumeric(true)
    daysField:SetMaxLetters(3)
    daysField:SetText(GuildHelper_SavedVariables.daysInactive or "60")  -- Load saved value or default to 60 days

    daysField:SetScript("OnTextChanged", function(self)
        GuildHelper_SavedVariables.daysInactive = self:GetText()
    end)

    -- Add a title for the excluded list
    local excludedTitle = maintenanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    excludedTitle:SetPoint("TOPLEFT", daysFieldLabel, "BOTTOMLEFT", 0, -20)
    excludedTitle:SetText("Excluded Members")

    -- Create a scroll frame for the excluded list
    local excludedScrollFrame = CreateFrame("ScrollFrame", nil, maintenanceFrame, "UIPanelScrollFrameTemplate")
    excludedScrollFrame:SetSize(160, 200)  -- Shrink width by 20 pixels
    excludedScrollFrame:SetPoint("TOPLEFT", excludedTitle, "BOTTOMLEFT", 0, -10)

    local excludedContent = CreateFrame("Frame", nil, excludedScrollFrame)
    excludedContent:SetSize(excludedScrollFrame:GetWidth(), excludedScrollFrame:GetHeight())
    excludedScrollFrame:SetScrollChild(excludedContent)

    -- Create a scroll frame for the member list
    local scrollFrame = CreateFrame("ScrollFrame", nil, maintenanceFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(parentFrame:GetWidth() - 220, parentFrame:GetHeight() - 100)
    scrollFrame:SetPoint("TOPLEFT", maintenanceFrame, "TOPLEFT", 200, -50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(content)
    maintenanceFrame.content = content

    -- Add paper texture background to the maintenance pane content frame
    local backgroundTexture = maintenanceFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetAllPoints(maintenanceFrame)
    backgroundTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Create headers
    local headers = {"Toon", "Rank", "Level", "Class", "Main Toon", "Note", "Officer Note", "Days Offline", "Actions"}
    local headerFrame = CreateFrame("Frame", nil, content)
    headerFrame:SetSize(content:GetWidth(), 20)
    headerFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)  -- Move header up

    local headerWidth = headerFrame:GetWidth() / #headers
    for i, title in ipairs(headers) do
        local header = CreateFrame("Button", nil, headerFrame)
        header:SetSize(headerWidth, 20)
        if i == 1 then
            header:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
        else
            header:SetPoint("LEFT", headerFrame.headers[i - 1], "RIGHT", 0, 0)
        end
        header:SetNormalFontObject("GameFontHighlightSmall")
        header:SetText(title)
        header:SetNormalTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        header:GetNormalTexture():SetVertexColor(0.1, 0.1, 0.1, 1)
        headerFrame.headers = headerFrame.headers or {}
        headerFrame.headers[i] = header
    end

    maintenanceFrame.headerFrame = headerFrame

    -- Populate the excluded list
    local function PopulateExcludedList()
        local excludedList = GuildHelper_SavedVariables.exclusionList or {}
        local rowHeight = 20
        local currentGuildName = GuildHelper:GetCombinedGuildName()  -- Use the new function

        -- Clear existing rows
        for _, child in ipairs({excludedContent:GetChildren()}) do
            child:Hide()
        end
        -- Populate rows
        local i = 0
        for toonName, toonData in pairs(excludedList) do
            if type(toonData) == "table" and toonData.guildName == currentGuildName then
                local row = CreateFrame("Frame", nil, excludedContent)
                row:SetSize(excludedContent:GetWidth(), rowHeight)
                row:SetPoint("TOPLEFT", excludedContent, "TOPLEFT", 0, -rowHeight * i)

                local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                cell:SetSize(row:GetWidth() - 20, rowHeight)
                cell:SetPoint("LEFT", row, "LEFT", 0, 0)
                cell:SetText(toonName)

                local removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                removeButton:SetSize(20, 20)
                removeButton:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                removeButton:SetText("X")
                removeButton:SetScript("OnClick", function()
                    GuildHelper_SavedVariables.exclusionList[toonName] = nil
                    PopulateExcludedList()  -- Refresh the excluded list
                end)

                i = i + 1
            end
        end
    end

    -- Add a count of rows at the bottom of the scroll frame
    local rowCountText = maintenanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rowCountText:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 10, -10)
    rowCountText:SetText("Total Inactive Members: 0")  -- Initial text

    -- Function to display the guild roster
    local function GetMainToon(toonName)
        local roster = GuildHelper_SavedVariables.sharedData.roster or {}
        return roster[toonName] and roster[toonName].gb_mainCharacter or "N/A"
    end

    local function DisplayGuildRoster()
        -- Clear existing rows
        for _, child in ipairs({content:GetChildren()}) do
            if child ~= headerFrame then
                child:Hide()
            end
        end

        local daysInactive = tonumber(daysField:GetText()) or 0
        local excludedList = GuildHelper_SavedVariables.exclusionList or {}
        local currentGuildName = GetGuildInfo("player")
        GuildHelper_SavedVariables.guilds = GuildHelper_SavedVariables.guilds or {}
        local roster = GuildHelper_SavedVariables.guilds[currentGuildName] and GuildHelper_SavedVariables.guilds[currentGuildName].roster or {}

        -- Populate rows
        local rowHeight = 20
        local rowIndex = 0
        for i = 1, GetNumGuildMembers() do
            local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation, guid, lastOnline = GetGuildRosterInfo(i)
            local years, months, days, hours = GetGuildRosterLastOnline(i)
            local daysOffline = (years or 0) * 365 + (months or 0) * 30 + (days or 0) + math.floor((hours or 0) / 24)
            local mainToon = GetMainToon(name)

            -- Include only inactive members
            if daysOffline >= daysInactive and not excludedList[name] then

                local row = CreateFrame("Frame", nil, content)
                row:SetSize(content:GetWidth(), rowHeight)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -rowHeight * rowIndex - 24)  -- Move table down
                rowIndex = rowIndex + 1

                local function CreateCell(text, parent, point, relativeTo, relativePoint, xOffset, yOffset)
                    local cell = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
                    cell:SetSize(headerWidth, rowHeight)
                    cell:SetAutoFocus(false)
                    cell:SetText(text or "")  -- Ensure text is a valid string
                    cell:SetCursorPosition(0)
                    cell:SetFontObject("GameFontHighlightSmall")
                    cell:SetJustifyH("CENTER")
                    cell:SetTextColor(1, 1, 1)
                    cell:Disable()
                    cell:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
                    return cell
                end

                local nameCell = CreateCell(name, row, "LEFT", row, "LEFT", 0, 0)
                local rankCell = CreateCell(rank, row, "LEFT", nameCell, "RIGHT", 0, 0)
                local levelCell = CreateCell(level, row, "LEFT", rankCell, "RIGHT", 0, 0)
                local classCell = CreateCell(class, row, "LEFT", levelCell, "RIGHT", 0, 0)
                local mainToonCell = CreateCell(mainToon, row, "LEFT", classCell, "RIGHT", 0, 0)
                local noteCell = CreateCell(note, row, "LEFT", mainToonCell, "RIGHT", 0, 0)
                local officerNoteCell = CreateCell(officerNote, row, "LEFT", noteCell, "RIGHT", 0, 0)
                local daysOfflineCell = CreateCell(tostring(daysOffline), row, "LEFT", officerNoteCell, "RIGHT", 0, 0)

                -- Add Exclude button
                local excludeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                excludeButton:SetSize(20, 20)
                excludeButton:SetPoint("LEFT", daysOfflineCell, "RIGHT", 5, 0)
                excludeButton:SetText("E")
                excludeButton:SetScript("OnClick", function()
                    local combinedGuildName = GuildHelper:GetCombinedGuildName()  -- Use the new function
                    GuildHelper_SavedVariables.exclusionList[name] = {
                        guildName = combinedGuildName,
                        toonName = name
                    }
                    DisplayGuildRoster()  -- Refresh the guild roster
                    PopulateExcludedList()  -- Refresh the excluded list
                end)
            end
        end

        -- Update the row count text when the roster is displayed
        local rowCount = rowIndex
        rowCountText:SetText("Total Inactive Members: " .. rowCount)
    end

    -- Initial population of excluded list
    PopulateExcludedList()

    -- Initial population of rows
    C_GuildInfo.GuildRoster() -- Ensure guild roster is updated
    C_Timer.After(2, DisplayGuildRoster) -- Add delay to ensure data loads

    -- Add a refresh button
    local refreshButton = CreateFrame("Button", nil, maintenanceFrame, "GameMenuButtonTemplate")
    refreshButton:SetSize(100, 30)
    refreshButton:SetPoint("BOTTOMRIGHT", maintenanceFrame, "BOTTOMRIGHT", -10, 10)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        -- Clear existing rows but keep the header
        for _, child in ipairs({content:GetChildren()}) do
            if child ~= headerFrame then
                child:Hide()
            end
        end
        -- Repopulate rows
        C_GuildInfo.GuildRoster() -- Ensure guild roster is updated
        C_Timer.After(2, DisplayGuildRoster) -- Add delay to ensure data loads
    end)

end  -- Add this end statement to close the CreateMaintenancePane function

-- Function to save the guild roster to saved variables
function GuildHelper:SaveGuildRoster()
    local currentGuildName = GetGuildInfo("player")
    if not currentGuildName then return end

    local roster = {}
    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation, guid, lastOnline = GetGuildRosterInfo(i)
        roster[name] = {
            name = name,
            rank = rank,
            rankIndex = rankIndex,
            level = level,
            class = class,
            zone = zone,
            note = note,
            officerNote = officerNote,
            online = online,
            status = status,
            classFileName = classFileName,
            achievementPoints = achievementPoints,
            achievementRank = achievementRank,
            isMobile = isMobile,
            canSoR = canSoR,
            reputation = reputation,
            guid = guid,
            lastOnline = lastOnline,
            gb_mainCharacter = GuildHelper_SavedVariables.sharedData.roster[name] and GuildHelper_SavedVariables.sharedData.roster[name].gb_mainCharacter or "N/A"
        }
    end

    GuildHelper_SavedVariables.guilds = GuildHelper_SavedVariables.guilds or {}
    GuildHelper_SavedVariables.guilds[currentGuildName] = {
        roster = roster,
        lastUpdated = date("%Y-%m-%d %H:%M:%S")
    }

end

-- Ensure the CreateMaintenancePane method is defined in the GuildHelper table
GuildHelper.CreateMaintenancePane = GuildHelper.CreateMaintenancePane

-- Function to show a custom popup window with the /gremove command
function GuildHelper:ShowRemovePopup(member)
    -- Create the popup frame
    local popupFrame = CreateFrame("Frame", "GuildHelperRemovePopup", UIParent, "BasicFrameTemplateWithInset")
    popupFrame:SetSize(300, 150)
    popupFrame:SetPoint("CENTER")
    popupFrame:SetMovable(true)
    popupFrame:EnableMouse(true)
    popupFrame:RegisterForDrag("LeftButton")
    popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
    popupFrame:SetScript("OnDragStop", popupFrame.StopMovingOrSizing)

    -- Add a title
    popupFrame.title = popupFrame:CreateFontString(nil, "OVERLAY")
    popupFrame.title:SetFontObject("GameFontHighlight")
    popupFrame.title:SetPoint("CENTER", popupFrame.TitleBg, "CENTER", 0, 0)
    popupFrame.title:SetText("Confirm Removal")

    -- Add a label to show the /gremove command
    local commandLabel = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    commandLabel:SetPoint("TOP", popupFrame, "TOP", 0, -40)
    commandLabel:SetText("/gremove " .. member)

    -- Create or update the macro
    local macroName = "RemoveInactiveMember"
    local macroBody = "/gremove " .. member
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        -- Create a new macro if it doesn't exist
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody, false)
    else
        -- Update the existing macro
        EditMacro(macroIndex, macroName, "INV_MISC_QUESTIONMARK", macroBody, false)
    end

    -- Add a "Run" button
    local runButton = CreateFrame("Button", nil, popupFrame, "GameMenuButtonTemplate")
    runButton:SetSize(100, 30)
    runButton:SetPoint("BOTTOMLEFT", popupFrame, "BOTTOMLEFT", 10, 10)
    runButton:SetText("Run")
    runButton:SetScript("OnClick", function()
        -- Execute the macro
        RunMacro(macroName)
        popupFrame:Hide()
    end)

    -- Add a "Close" button
    local closeButton = CreateFrame("Button", nil, popupFrame, "GameMenuButtonTemplate")
    closeButton:SetSize(100, 30)
    closeButton:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOMRIGHT", -10, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        popupFrame:Hide()
    end)

    popupFrame:Show()
end