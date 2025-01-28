GuildHelper.selectedColumns = {
    ["BattleTag"] = true,
    ["Item Level"] = true,
    ["Interests"] = true,
    ["Guild Name"] = true,
    ["Professions"] = false,
    ["Realm"] = false,
    ["Main Toon"] = true,
    ["Spec"] = false,
    ["Joined Guild"] = false,
    ["Class"] = false,
    ["Birthdate"] = false,
    ["Faction"] = false,
    ["Roles"] = true,
    ["Rank"] = true  -- Ensure Rank is included
}

GuildHelper.columnOrder = {
    "Level",
    "Toon",
    "Main Toon",
    "Item Level",
    "Guild Name",
    "Rank",
    "Realm",
    "Faction",
    "Joined Guild",
    "Class",
    "Spec",
    "Birthdate",
    "Roles",
    "Interests",
    "Professions",
    "BattleTag",
    "Actions"
}

function GuildHelper:SaveColumnPreferences()
    if not GuildHelper_SavedVariables.columnPreferences then
        GuildHelper_SavedVariables.columnPreferences = {}
    end
    GuildHelper_SavedVariables.columnPreferences.selectedColumns = GuildHelper.selectedColumns
    GuildHelper_SavedVariables.columnPreferences.columnOrder = GuildHelper.columnOrder
end

function GuildHelper:LoadColumnPreferences()
    if GuildHelper_SavedVariables.columnPreferences then
        GuildHelper.selectedColumns = GuildHelper_SavedVariables.columnPreferences.selectedColumns or GuildHelper.selectedColumns
        GuildHelper.columnOrder = GuildHelper_SavedVariables.columnPreferences.columnOrder or GuildHelper.columnOrder
    end
end

function GuildHelper:CreateColumnSelector(parentFrame)
    -- Load column preferences before initializing the column selector
    GuildHelper:LoadColumnPreferences()

    local columnSelectorLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    columnSelectorLabel:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -50, -10)
    columnSelectorLabel:SetText("Click Roster to refresh columns after selections")

    local columnSelector = CreateFrame("Frame", "ColumnSelectorDropdown", parentFrame, "UIDropDownMenuTemplate")
    columnSelector:SetPoint("RIGHT", columnSelectorLabel, "LEFT", -10, 0)
    UIDropDownMenu_SetWidth(columnSelector, 200)
    UIDropDownMenu_Initialize(columnSelector, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            local value = self.value
            local selectedCount = 0
            for _, selected in pairs(GuildHelper.selectedColumns) do
                if selected then
                    selectedCount = selectedCount + 1
                end
            end
            if GuildHelper.selectedColumns[value] or selectedCount < 7 then
                GuildHelper.selectedColumns[value] = not GuildHelper.selectedColumns[value]
                UIDropDownMenu_SetText(columnSelector, "Columns Selected")
                GuildHelper:SaveColumnPreferences()  -- Save preferences when changed
                CloseDropDownMenus()
            else
                print("You can select up to 7 columns only.")
            end
        end
        info.isNotRadio = true
        info.keepShownOnClick = true
        for column, _ in pairs(GuildHelper.selectedColumns) do
            if type(column) == "string" then  -- Ensure only string keys are added
                info.text, info.arg1 = column, column
                info.checked = GuildHelper.selectedColumns[column]
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    UIDropDownMenu_SetText(columnSelector, "Columns Selected")
end

function GuildHelper:PopulateRows(content, showOnlineCheckbox, headerFrame, headerWidth, page, numRows, searchText, sortBy, sortOrder)
    -- Refresh the filtered roster
    GuildHelper:FilterGuildData2()  -- Ensure filteredRoster is populated

    -- Data
    local savedToons = GuildHelper_SavedVariables.filteredRoster or {}
    local rows = {}
    local showOnlineOnly = showOnlineCheckbox:GetChecked()

    for toonName, toonData in pairs(savedToons) do
        if (toonName and toonName ~= "") then
            local online = GuildHelper:IsToonOnlineInLinkedGuilds(toonName)
            if (not showOnlineOnly or online) then
                if (not searchText or toonName:lower():find(searchText) or (toonData.data.mainCharacter or ""):lower():find(searchText)) then
                    local row = {
                        ["Level"] = toonData.data.level or "NA",
                        ["Toon"] = toonName,
                        ["Main Toon"] = toonData.data.mainCharacter or "NA",
                        ["Online"] = online,
                        ["BattleTag"] = toonData.data.battletag or "NA",
                        ["Item Level"] = toonData.data.itemLevel or "NA",
                        ["Interests"] = toonData.data.interests and table.concat(toonData.data.interests, ", ") or "NA",
                        ["Guild Name"] = toonData.guildName or "NA",
                        ["Professions"] = toonData.data.professions and table.concat(toonData.data.professions, ", ") or "NA",
                        ["Realm"] = toonData.data.realm or "NA",
                        ["Spec"] = toonData.data.spec or "NA",
                        ["Joined Guild"] = toonData.data.guildJoinDate or "NA",
                        ["Class"] = toonData.data.class or "NA",
                        ["Birthdate"] = toonData.data.birthdate or "NA",
                        ["Faction"] = toonData.data.faction or "NA",
                        ["Roles"] = toonData.data.roles and table.concat(toonData.data.roles, ", ") or "NA",
                        ["Rank"] = toonData.data.rank or "NA",
                        ["lastUpdated"] = toonData.lastUpdated
                    }
                    table.insert(rows, row)
                end
            end
        end
    end

    -- Sort rows based on the sortBy and sortOrder parameters
    if sortBy then
        table.sort(rows, function(a, b)
            local aValue = a[sortBy] or ""
            local bValue = b[sortBy] or ""
            if sortBy == "Level" or sortBy == "Item Level" then
                aValue = tonumber(aValue) or 0
                bValue = tonumber(bValue) or 0
            else
                if aValue == "NA" then aValue = "" end
                if bValue == "NA" then bValue = "" end
                aValue = tostring(aValue):lower()
                bValue = tostring(bValue):lower()
            end
            if sortOrder == "asc" then
                return aValue < bValue
            else
                return aValue > bValue
            end
        end)
    end

    -- Clear existing rows
    for _, child in ipairs({ content:GetChildren() }) do
        if (child ~= headerFrame) then -- Ensure header is not hidden
            child:Hide()
        end
    end

    -- Calculate the range of rows to display for the current page
    local startIndex = (page - 1) * numRows + 1
    local endIndex = math.min(startIndex + numRows - 1, #rows)

    -- Define headers
    local headers = { "Level", "Toon" }
    for _, column in ipairs(GuildHelper.columnOrder) do
        if GuildHelper.selectedColumns[column] then
            table.insert(headers, column)
        end
    end
    table.insert(headers, "Actions")

    -- Adjust header visibility and width
    local headerWidth = (headerFrame:GetWidth() - 5) / #headers -- Shrink width by 5 pixels
    for i, header in ipairs(headerFrame.headers) do
        if headers[i] then
            header:SetWidth(headerWidth)
            header:SetText(headers[i])
            header:Show()
        else
            header:Hide()
        end
    end

    -- Populate rows
    local rowHeit = 20
    for i = startIndex, endIndex do
        local rowData = rows[i]
        local row = content.rows[i - startIndex + 1]
        if not row then
            row = CreateFrame("Frame", nil, content)
            row:SetSize(headerFrame:GetWidth(), rowHeit) -- Match the size of the headers
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -rowHeit * (i - startIndex))
            content.rows[i - startIndex + 1] = row

            -- Add a background with a different color for online players
            local background = row:CreateTexture(nil, "BACKGROUND")
            row.background = background
            background:SetAllPoints(row)

            row.cells = {}
            for j, header in ipairs(headers) do
                if GuildHelper.selectedColumns[header] or j <= 2 or j == #headers then
                    local cell = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                    cell:SetSize(headerWidth, rowHeit)
                    cell:SetAutoFocus(false)
                    cell:SetFontObject("GameFontHighlightSmall")
                    cell:SetJustifyH("LEFT")  -- Ensure text is left-aligned
                    cell:SetTextColor(1, 1, 1) -- Set text color to white
                    cell:Disable() -- Make it read-only initially

                    cell:SetScript("OnMouseDown", function(self)
                        self:Enable()
                        self:SetFocus()
                        self:HighlightText()
                    end)

                    cell:SetScript("OnEditFocusLost", function(self)
                        self:Disable()
                        self:HighlightText(0, 0)
                    end)

                    -- Disable text scrolling
                    cell:SetScript("OnCursorChanged", function(self)
                        self:SetCursorPosition(0)
                    end)

                    -- Ensure text selection is possible using Ctrl+A and Ctrl+C
                    cell:SetScript("OnKeyDown", function(self, key)
                        if key == "A" and IsControlKeyDown() then
                            self:HighlightText()  -- Corrected method name
                        end
                    end)

                    -- Set the text and move the cursor to the end
                    cell:SetText(tostring(rowData[header]))
                    cell:SetCursorPosition(0)

                    if (j == 1) then
                        cell:SetPoint("LEFT", row, "LEFT", 0, 0)
                    else
                        cell:SetPoint("LEFT", row.cells[j - 1], "RIGHT", 0, 0)
                    end
                    row.cells[j] = cell
                end
            end

            -- Add Invite and Whisper buttons
            local inviteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            inviteButton:SetSize(20, 20)
            inviteButton:SetText("I")
            inviteButton:SetScript("OnClick", function()
                local fullName = rowData["Toon"]
                C_PartyInfo.InviteUnit(fullName) -- Invite the toon

                -- Convert to raid if the group size exceeds 5
                if (GetNumGroupMembers() >= 5 and not IsInRaid()) then
                    ConvertToRaid()
                end
            end)

            local whisperButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            whisperButton:SetSize(20, 20)
            whisperButton:SetText("W")
            whisperButton:SetScript("OnClick", function()
                local fullName = rowData["Toon"]  -- Use full name as constructed in the form
                ChatFrame_OpenChat("/w " .. fullName .. " ", DEFAULT_CHAT_FRAME) -- Whisper the toon
            end)

            -- Create a container for the action buttons to center them
            local actionContainer = CreateFrame("Frame", nil, row)
            actionContainer:SetSize(50, rowHeit)
            actionContainer:SetPoint("LEFT", row.cells[#headers - 1], "RIGHT", 0, 0)

            inviteButton:SetParent(actionContainer)
            inviteButton:SetPoint("LEFT", actionContainer, "LEFT", 0, 0)

            whisperButton:SetParent(actionContainer)
            whisperButton:SetPoint("LEFT", inviteButton, "RIGHT", 5, 0)

            row.inviteButton = inviteButton
            row.whisperButton = whisperButton
            row.actionContainer = actionContainer

            -- Add a line/space between rows
            local separator = row:CreateTexture(nil, "ARTWORK")
            separator:SetColorTexture(0.5, 0.5, 0.5, 1) -- Grey line
            separator:SetHeight(1)
            separator:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, 0)
            separator:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, 0)
        end

        -- Update row data
        row.background:SetColorTexture(rowData["Online"] and 0.2 or 0.1, rowData["Online"] and 0.6 or 0.1, rowData["Online"] and 0.2 or 0.1, 0.7)
        for j, header in ipairs(headers) do
            local cell = row.cells[j]
            if cell then
                cell:SetText(tostring(rowData[header]))
                cell:SetCursorPosition(0)  -- Move cursor to the left or position 0
                if (header == "Toon") then -- Toon name column
                    local classColor = rowData["Class"] and RAID_CLASS_COLORS[string.upper(rowData["Class"]:gsub("%s+", ""))] -- Ensure class color is applied correctly
                    if (classColor) then
                        cell:SetTextColor(classColor.r, classColor.g, classColor.b)
                    end
                end
                if (rowData["Online"]) then
                    cell:SetFontObject("GameFontNormal") -- Set font to bold
                    cell:SetShadowColor(0, 0, 0, 1) -- Set shadow color to black
                    cell:SetShadowOffset(2, -2) -- Increased shadow offset
                end
                -- Hide cell if the column is not selected
                cell:SetShown(GuildHelper.selectedColumns[header] or j <= 2 or j == #headers)
            end
        end

        -- Ensure action buttons are aligned with the toon name
        row.actionContainer:SetPoint("LEFT", row.cells[#headers - 1], "RIGHT", 0, 0)

        -- Update action buttons' scripts to use the correct rowData
        row.inviteButton:SetScript("OnClick", function()
            local fullName = rowData["Toon"]
            C_PartyInfo.InviteUnit(fullName) -- Invite the toon

            -- Convert to raid if the group size exceeds 5
            if (GetNumGroupMembers() >= 5 and not IsInRaid()) then
                ConvertToRaid()
            end
        end)

        row.whisperButton:SetScript("OnClick", function()
            local fullName = rowData["Toon"]  -- Use full name as constructed in the form
            ChatFrame_OpenChat("/w " .. fullName .. " ", DEFAULT_CHAT_FRAME) -- Whisper the toon
        end)

        row:Show()  -- Ensure the row is shown
    end

    -- Update the toon count text when rows are populated
    GuildHelper:UpdateToonCount(content, #rows)

    -- Return rows, total row count, and total pages
    return {
        rows = rows,
        totalRowCount = #rows,
        totalPages = math.ceil(#rows / numRows)
    }
end

function GuildHelper:IsToonOnlineInLinkedGuilds(toonName)
    -- Check online status in linked guilds
    local online = GuildHelper:IsToonOnline(toonName)
    return online or false
end

function GuildHelper:GetToonLevel(toonName)
    -- Pull the level from the shared roster data or set it to NA
    local savedToons = GuildHelper_SavedVariables.sharedData.roster or {}
    local toonData = savedToons[toonName]
    if (toonData and toonData.data.level and toonData.data.level ~= "") then
        return toonData.data.level
    else
        return "NA"
    end
end

function GuildHelper:UpdateToonCount(content, count)
    local toonCountText = content:GetParent().toonCountText
    if (toonCountText) then
        toonCountText:SetText("Total Toons: " .. count)
    end
end

-- Load column preferences on addon load
GuildHelper:LoadColumnPreferences()