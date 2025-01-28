-- Pane to manage custom groups of players for quick forming of raid or mythic parties
-- Per addon users data Not a shared table to be sync'd.
-- Copy standard frame, table style and background from rosterpane.lua
-- Add Groups button to navbuttons.lua
-- Features include
    -- Field to create group names
    -- Options to add players to group lists from the roster or raid\mythic parties
    -- Rows should include full player name with realm, class, role, ilevel, action buttons to invite,whisper or remove from list
    -- Option to remove groups

function GuildHelper:CreateGroupsPane(parentFrame)
    local groupsFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    groupsFrame:SetAllPoints(parentFrame)
    
    -- Set background
    local bgTexture = groupsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(groupsFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Title
    local title = groupsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", groupsFrame, "TOP", 0, -10)
    title:SetText("Groups Management")

    -- Initialize saved table for personal groups
    GuildHelper_SavedVariables.groups = GuildHelper_SavedVariables.groups or {}

    -- Ensure each group has an order field
    local groupCount = 0
    for _, groupData in pairs(GuildHelper_SavedVariables.groups) do
        groupCount = groupCount + 1
        groupData.order = groupData.order or groupCount
    end

    -- Group creation EditBox
    local groupNameBox = CreateFrame("EditBox", nil, groupsFrame, "InputBoxTemplate")
    groupNameBox:SetSize(200, 30)
    groupNameBox:SetPoint("TOPLEFT", groupsFrame, "TOPLEFT", 10, -50)
    groupNameBox:SetAutoFocus(false)
    groupNameBox:SetText("")

    -- Create group button
    local createGroupButton = CreateFrame("Button", nil, groupsFrame, "GameMenuButtonTemplate")
    createGroupButton:SetSize(100, 30)
    createGroupButton:SetPoint("LEFT", groupNameBox, "RIGHT", 10, 0)
    createGroupButton:SetText("Create")
    createGroupButton:SetScript("OnClick", function()
        local newName = groupNameBox:GetText():trim()
        if newName ~= "" then
            GuildHelper_SavedVariables.groups[newName] = GuildHelper_SavedVariables.groups[newName] or { order = #GuildHelper_SavedVariables.groups + 1 }
            groupNameBox:SetText("")
            GuildHelper:RefreshGroupsList(groupsFrame)
        end
    end)

    -- ScrollFrame to show groups
    local scrollFrame = CreateFrame("ScrollFrame", nil, groupsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", groupsFrame, "TOPLEFT", 10, -90)
    scrollFrame:SetSize(groupsFrame:GetWidth() - 40, groupsFrame:GetHeight() - 100)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(scrollFrame:GetWidth(), 800)
    scrollFrame:SetScrollChild(contentFrame)
    
    groupsFrame.contentFrame = contentFrame
    
    -- RefreshGroupsList creates rows for each group in personal storage
    function GuildHelper:RefreshGroupsList(frame)
        for _, child in ipairs({ frame.contentFrame:GetChildren() }) do
            child:Hide()
        end
        local offsetY = -5

        -- Sort groups by order
        local sortedGroups = {}
        for groupName, groupData in pairs(GuildHelper_SavedVariables.groups) do
            table.insert(sortedGroups, { name = groupName, data = groupData })
        end
        table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)

        for _, group in ipairs(sortedGroups) do
            local groupName = group.name
            local members = group.data

            local groupHeader = CreateFrame("Frame", nil, frame.contentFrame)
            groupHeader:SetSize(frame.contentFrame:GetWidth() - 20, 20)
            groupHeader:SetPoint("TOPLEFT", frame.contentFrame, "TOPLEFT", 10, offsetY)
            
            local groupTitle = groupHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            groupTitle:SetPoint("LEFT", groupHeader, "LEFT")
            groupTitle:SetText(groupName)
            
            -- Button to remove group
            local removeButton = CreateFrame("Button", nil, groupHeader, "GameMenuButtonTemplate")
            removeButton:SetSize(20, 20)
            removeButton:SetPoint("RIGHT", groupHeader, "RIGHT", -5, 0)
            removeButton:SetText("X")
            removeButton:SetScript("OnClick", function()
                GuildHelper_SavedVariables.groups[groupName] = nil
                GuildHelper:RefreshGroupsList(frame)
            end)

            -- Button to move group up
            local moveUpButton = CreateFrame("Button", nil, groupHeader, "UIPanelButtonTemplate")
            moveUpButton:SetSize(20, 20)
            moveUpButton:SetPoint("RIGHT", removeButton, "LEFT", -5, 0)
            moveUpButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
            moveUpButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
            moveUpButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
            moveUpButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
            moveUpButton:SetScript("OnClick", function()
                if members.order > 1 then
                    members.order = members.order - 1
                    for _, otherGroup in pairs(GuildHelper_SavedVariables.groups) do
                        if otherGroup ~= members and otherGroup.order == members.order then
                            otherGroup.order = otherGroup.order + 1
                        end
                    end
                    GuildHelper:RefreshGroupsList(frame)
                end
            end)

            -- Button to move group down
            local moveDownButton = CreateFrame("Button", nil, groupHeader, "UIPanelButtonTemplate")
            moveDownButton:SetSize(20, 20)
            moveDownButton:SetPoint("RIGHT", moveUpButton, "LEFT", -5, 0)
            moveDownButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
            moveDownButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
            moveDownButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
            moveDownButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
            moveDownButton:SetScript("OnClick", function()
                if members.order < #sortedGroups then
                    members.order = members.order + 1
                    for _, otherGroup in pairs(GuildHelper_SavedVariables.groups) do
                        if otherGroup ~= members and otherGroup.order == members.order then
                            otherGroup.order = otherGroup.order - 1
                        end
                    end
                    GuildHelper:RefreshGroupsList(frame)
                end
            end)

            offsetY = offsetY - 25
            
            -- Table header row
            local headerRow = CreateFrame("Frame", nil, frame.contentFrame, "BackdropTemplate")
            headerRow:SetSize(groupHeader:GetWidth(), 20)
            headerRow:SetPoint("TOPLEFT", frame.contentFrame, "TOPLEFT", 15, offsetY)
            headerRow:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = false, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            headerRow:SetBackdropColor(0, 0, 0, 1) -- Black background
            
            local headers = {"Toon", "Class", "Role", "iLvl", "Actions"}
            local headerWidth = (headerRow:GetWidth()) / #headers -- Adjust width to fit action buttons
            for i, title in ipairs(headers) do
                local header = headerRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                header:SetSize(headerWidth, 20)
                if i == 1 then
                    header:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
                else
                    header:SetPoint("LEFT", headerRow.headers[i - 1], "RIGHT", 0, 0)
                end
                header:SetText(title)
                headerRow.headers = headerRow.headers or {}
                headerRow.headers[i] = header
            end
            
            offsetY = offsetY - 25
            
            -- List each member
            for index, member in ipairs(members) do
                -- Here we handle new table fields if they exist
                local displayName, class, role, ilvl = "Unknown", "?", "?", 0
                if type(member) == "table" then
                    displayName = member.fullName or "Unknown"
                    class = member.class or "?"
                    role = member.role or "?"
                    ilvl = member.ilvl or 0
                elseif type(member) == "string" then
                    displayName = member  -- Fallback for old entries
                end

                local rowFrame = CreateFrame("Frame", nil, frame.contentFrame)
                rowFrame:SetSize(groupHeader:GetWidth(), 20)
                rowFrame:SetPoint("TOPLEFT", frame.contentFrame, "TOPLEFT", 15, offsetY)
                
                local cells = {displayName, class, role, ilvl}
                for i, cellText in ipairs(cells) do
                    local cell = CreateFrame("Frame", nil, rowFrame, "BackdropTemplate")
                    cell:SetSize(headerWidth, 20)
                    if i == 1 then
                        cell:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
                    else
                        cell:SetPoint("LEFT", rowFrame.cells[i - 1], "RIGHT", 0, 0)
                    end
                    local cellTextFont = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    cellTextFont:SetAllPoints(cell)
                    cellTextFont:SetText(cellText)
                    cellTextFont:SetTextColor(1, 1, 1) -- White text
                    cell:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = false, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }
                    })
                    cell:SetBackdropColor(0, 0, 0, 1) -- Black background
                    rowFrame.cells = rowFrame.cells or {}
                    rowFrame.cells[i] = cell
                end
                
                -- Invite button
                local inviteBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                inviteBtn:SetSize(20, 20)
                inviteBtn:SetPoint("LEFT", rowFrame.cells[#cells], "RIGHT", 10, 0)
                inviteBtn:SetText("I")
                inviteBtn:SetScript("OnClick", function()
                    if C_PartyInfo and C_PartyInfo.InviteUnit then
                        C_PartyInfo.InviteUnit(member.fullName or member)
                    else
                        print("C_PartyInfo.InviteUnit function is not available.")
                    end
                end)
                
                -- Whisper button
                local whisperBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                whisperBtn:SetSize(20, 20)
                whisperBtn:SetPoint("LEFT", inviteBtn, "RIGHT", 5, 0)
                whisperBtn:SetText("W")
                whisperBtn:SetScript("OnClick", function()
                    ChatFrame_SendTell(member.fullName or member)
                end)

                -- Function to retrieve role and item level for a specific player by full name
                function GetPlayerDetailsByFullName(fullName, callback)
                    local unitId = nil
                    local shortName = fullName:match("([^%-]+)") -- Extract character name without realm name
                    -- print("Looking for character:", fullName, "or", shortName)
                    
                    -- Determine the group type (party or raid)
                    local groupType = IsInRaid() and "raid" or "party"
                    local numGroupMembers = GetNumGroupMembers()
                
                    -- Find the unitId that matches the given full name or short name
                    for i = 1, numGroupMembers do
                        local unit = groupType .. i
                        local unitName = UnitName(unit)
                        local unitRealm = GetRealmName()
                        local unitFullName = unitName and unitRealm and (unitName .. "-" .. unitRealm) or unitName
                        -- print("Checking unit:", unitFullName)
                        if unitFullName == fullName or unitName == shortName then
                            unitId = unit
                            break
                        end
                    end
                
                    if not unitId then
                        print("Player not found in Raid/Party.")
                        return
                    end
                
                    -- Get the assigned role
                    local role = UnitGroupRolesAssigned(unitId)
                    local roleMap = {
                        DAMAGER = "DPS",
                        TANK = "Tank",
                        HEALER = "Healer"
                    }
                    local mappedRole = roleMap[role] or role
                
                    -- Function to calculate the item level from inspected data
                    local function CalculateItemLevel(unit)
                        local totalItemLevel = 0
                        local numItems = 0
                
                        -- Loop through all equipment slots
                        for slot = 1, 18 do
                            if slot ~= 4 then  -- Ignore the shirt slot (slot 4)
                                local itemLink = GetInventoryItemLink(unit, slot)
                                if itemLink then
                                    local itemLevel = GetDetailedItemLevelInfo(itemLink)
                                    if itemLevel then
                                        totalItemLevel = totalItemLevel + itemLevel
                                        numItems = numItems + 1
                                    end
                                end
                            end
                        end
                
                        -- Calculate average item level if any items were counted
                        local avgItemLevel = numItems > 0 and (totalItemLevel / numItems) or 0
                        return math.floor(avgItemLevel * 10 + 0.5) / 10  -- Round to 1 decimal place
                    end
                
                    -- Register event handler for INSPECT_READY
                    local frame = CreateFrame("Frame")
                    frame:RegisterEvent("INSPECT_READY")
                    frame:SetScript("OnEvent", function(self, event, guid)
                        if event == "INSPECT_READY" and UnitGUID(unitId) == guid then
                            local itemLevel = CalculateItemLevel(unitId)
                            local playerDetails = {
                                name = fullName,
                                role = mappedRole,
                                itemLevel = itemLevel
                            }
                            ClearInspectPlayer()
                            frame:UnregisterEvent("INSPECT_READY")
                            callback(playerDetails)
                        end
                    end)
                
                    -- Notify the game client that you wish to inspect this unit
                    NotifyInspect(unitId)
                end
                
                -- Refresh button
                local refreshBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                refreshBtn:SetSize(20, 20)
                refreshBtn:SetPoint("LEFT", whisperBtn, "RIGHT", 5, 0)
                refreshBtn:SetText("R")
                refreshBtn:SetScript("OnClick", function()
                    -- Update ilvl and role for the member
                    local unitID = member.fullName or member.name or member
                    GetPlayerDetailsByFullName(unitID, function(details)
                        if details then
                            member.ilvl = details.itemLevel
                            member.role = details.role
                            GuildHelper:RefreshGroupsList(frame)
                        end
                    end)
                end)

                -- Remove from group
                local removeBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                removeBtn:SetSize(20, 20)
                removeBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 5, 0)
                removeBtn:SetText("X")
                removeBtn:SetScript("OnClick", function()
                    for i, v in ipairs(members) do
                        if v == member then
                            table.remove(members, i)
                            break
                        end
                    end
                    GuildHelper:RefreshGroupsList(frame)
                end)

                -- Move up button
                local moveUpBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                moveUpBtn:SetSize(20, 20)
                moveUpBtn:SetPoint("LEFT", removeBtn, "RIGHT", 5, 0)
                moveUpBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
                moveUpBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
                moveUpBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
                moveUpBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
                moveUpBtn:SetScript("OnClick", function()
                    if index > 1 then
                        local temp = members[index - 1]
                        members[index - 1] = members[index]
                        members[index] = temp
                        GuildHelper:RefreshGroupsList(frame)
                    end
                end)

                -- Move down button
                local moveDownBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
                moveDownBtn:SetSize(20, 20)
                moveDownBtn:SetPoint("LEFT", moveUpBtn, "RIGHT", 5, 0)
                moveDownBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
                moveDownBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
                moveDownBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
                moveDownBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
                moveDownBtn:SetScript("OnClick", function()
                    if index < #members then
                        local temp = members[index + 1]
                        members[index + 1] = members[index]
                        members[index] = temp
                        GuildHelper:RefreshGroupsList(frame)
                    end
                end)
                
                offsetY = offsetY - 20 -- Remove space between rows
            end
            
            -- Two dropdowns under each group's table
            local rosterDropdown = CreateFrame("Frame", "GH_RosterDropdown_"..groupName, frame.contentFrame, "UIDropDownMenuTemplate")
            rosterDropdown:SetPoint("TOPLEFT", frame.contentFrame, "TOPLEFT", 30, offsetY)
            UIDropDownMenu_SetWidth(rosterDropdown, 150)
            UIDropDownMenu_Initialize(rosterDropdown, function(self, level, menuList)
                local roster = GuildHelper_SavedVariables.filteredRoster or {}
                local chunkSize = 20
                local sortedToonNames = {}
                for toonName, _ in pairs(roster) do
                    table.insert(sortedToonNames, toonName)
                end
                table.sort(sortedToonNames)

                if not level or level == 1 then
                    local totalChunks = math.ceil(#sortedToonNames / chunkSize)
                    for i = 1, totalChunks do
                        local startIndex = (i - 1) * chunkSize + 1
                        local endIndex = math.min(i * chunkSize, #sortedToonNames)
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = "Toon " .. startIndex .. "-" .. endIndex
                        info.hasArrow = true
                        info.notCheckable = true
                        info.menuList = { startIndex = startIndex, endIndex = endIndex }
                        UIDropDownMenu_AddButton(info, level)
                    end
                else
                    -- Level 2 submenu
                    local range = menuList
                    if not range or type(range.startIndex) ~= "number" or type(range.endIndex) ~= "number" then
                        print("Invalid range:", range)
                        return
                    end
                    for i = range.startIndex, range.endIndex do
                        local toonName = sortedToonNames[i]
                        local toonData = roster[toonName]
                        local data = toonData and toonData.data or {}
                        local subInfo = UIDropDownMenu_CreateInfo()
                        subInfo.text = toonName
                        subInfo.value = toonName
                        subInfo.func = function(self)
                            local newMember = {
                                fullName = data.name or toonName,
                                class = data.class or "Unknown",
                                role = (data.roles and data.roles[1]) or "Unknown",
                                ilvl = data.itemLevel or 0
                            }
                            table.insert(GuildHelper_SavedVariables.groups[groupName], newMember)
                            GuildHelper:RefreshGroupsList(frame)
                        end
                        UIDropDownMenu_AddButton(subInfo, level)
                    end
                end
            end)
            UIDropDownMenu_SetText(rosterDropdown, "Add from Guild")

            local partyRaidDropdown = CreateFrame("Frame", "GH_PartyRaidDropdown_"..groupName, frame.contentFrame, "UIDropDownMenuTemplate")
            partyRaidDropdown:SetPoint("LEFT", rosterDropdown, "RIGHT", 20, 0)
            UIDropDownMenu_SetWidth(partyRaidDropdown, 150)
            UIDropDownMenu_Initialize(partyRaidDropdown, function(self, level)
                local numMembers = GetNumGroupMembers()
                local info = UIDropDownMenu_CreateInfo()
                info.func = function(self)
                    local toonName = self.value
                    local c = select(2, UnitClass(toonName)) or "Unknown"
                    local realmName = GetRealmName()
                    local fullName = toonName .. "-" .. realmName
                    local newMember = {
                        fullName = fullName,
                        class = c,
                        role = "?",
                        ilvl = 0
                    }
                    table.insert(GuildHelper_SavedVariables.groups[groupName], newMember)
                    GuildHelper:RefreshGroupsList(frame)
                end
                if numMembers > 0 then
                    for i = 1, numMembers do
                        local unitID = (UnitInRaid("player") and "raid"..i) or (i < numMembers and "party"..i)
                        if unitID and UnitExists(unitID) then
                            local toonName = UnitName(unitID) or "?"
                            info.text = toonName
                            info.value = toonName
                            UIDropDownMenu_AddButton(info, level)
                        end
                    end
                end
            end)
            UIDropDownMenu_SetText(partyRaidDropdown, "Add from Party/Raid")

            offsetY = offsetY - 40
        end
        frame.contentFrame:SetHeight(math.abs(offsetY) + 50)
    end
    
    -- Initial population
    GuildHelper:RefreshGroupsList(groupsFrame)
end
