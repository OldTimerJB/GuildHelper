-- Define the GetSavedToons function directly in this file
local function GetSavedToons()
    local savedToons = {}
    for toonName, _ in pairs(GuildHelper_SavedVariables.characterInfo) do
        table.insert(savedToons, toonName)
    end
    return savedToons
end

function GuildHelper:CreateMemberPane(parentFrame)
    if not GuildHelper_SavedVariables then
        GuildHelper_SavedVariables = {}
    end
    if not GuildHelper_SavedVariables.characterInfo then
        GuildHelper_SavedVariables.characterInfo = {}
    end
    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {
            roster = {},
            news = {},
            guildInfo = {},
            setup = {}
        }
    end

    -- Initialize globalInfo
    local globalInfo = GuildHelper_SavedVariables.globalInfo or {
        gb_mainCharacter = "NA",
        gb_birthdate = "NA",
        gb_battletag = "NA"
    }

    local fullName = UnitName("player") .. "-" .. GetRealmName()
    local characterInfo = GuildHelper_SavedVariables.characterInfo[fullName] or {
        pt_roles = {},
        pt_professions = {},
        pt_interests = {},
        pt_guildJoinDate = "NA"
    }

    local function isOlderThan7Days(timestamp)
        if not timestamp or timestamp == "" then
            return true
        end
        local year, month, day, hour, minute, second = timestamp:match("^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)$")
        if not year then
            return true
        end
        local savedTime = time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(minute),
            sec = tonumber(second)
        })
        return (time() - savedTime) > (7 * 24 * 3600)
    end

    if isOlderThan7Days(characterInfo.lastUpdated) then
        characterInfo.pt_name = fullName
        characterInfo.pt_realm = GetRealmName()
        characterInfo.pt_faction = UnitFactionGroup("player")
        characterInfo.pt_level = UnitLevel("player")
        characterInfo.pt_itemLevel = GetAverageItemLevel()
        local _, class = UnitClass("player")
        characterInfo.pt_class = class
        local currentSpec = GetSpecialization()
        if currentSpec then
            local specName = select(2, GetSpecializationInfo(currentSpec))
            characterInfo.pt_spec = specName or ""
        end
        characterInfo.lastUpdated = date("%Y%m%d%H%M%S")
        GuildHelper_SavedVariables.characterInfo[fullName] = characterInfo
    end

    -- Create the standardized frame for the member pane
    local memberFrame = GuildHelper:CreateStandardFrame(parentFrame)

    -- Set the background texture to look like old paper
    local bgTexture = memberFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(memberFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Add a title
    memberFrame.title = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    memberFrame.title:SetPoint("TOP", memberFrame, "TOP", 0, -10)
    memberFrame.title:SetText("Member Pane")

    -- Add fields for character information
    local labels = {
        "Name:",
        "Realm:",
        "Faction:",
        "Main Character:",
        "Guild Name:",
        "Level:",
        "Item Level:",
        "Class:",
        "Spec:",
        "Role:",
        "Professions:",
        "Interests:",
        "Guild Join Date:",
        "Birthdate(Optional):",
        "BattleTag(Optional):"
    }

    local yOffset = -50
    local xOffset = 20
    local fieldXOffset = 150

    local editBoxes = {}

    -- Create an invisible table for alignment
    local tableFrame = CreateFrame("Frame", nil, memberFrame)
    tableFrame:SetPoint("TOPLEFT", memberFrame, "TOPLEFT", xOffset, yOffset)
    tableFrame:SetSize(400, 600)  -- Adjust size as needed

    for i, label in ipairs(labels) do
        local titleLabel = tableFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 0, -30 * (i - 1))  -- Adjusted spacing
        titleLabel:SetText(label)

        if label == "Main Character:" or label == "Role:" or label == "Professions:" or label == "Interests:" then
            -- Create dropdowns for specific fields
            local dropdown = CreateFrame("Frame", nil, tableFrame, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOPLEFT", titleLabel, "TOPLEFT", (fieldXOffset - 25), 8)
            UIDropDownMenu_SetWidth(dropdown, 200)
            table.insert(editBoxes, dropdown)
        else
            -- Create edit boxes for other fields
            local editBox = CreateFrame("EditBox", nil, tableFrame, "InputBoxTemplate")
            editBox:SetSize(200, 30)
            editBox:SetPoint("TOPLEFT", titleLabel, "TOPLEFT", fieldXOffset, 8)
            editBox:SetAutoFocus(false)
            table.insert(editBoxes, editBox)
        end
    end

    -- Set default values for the edit boxes
    editBoxes[1]:SetText(UnitName("player") .. "-" .. GetRealmName())  -- Name
    editBoxes[2]:SetText(GetRealmName())  -- Realm
    editBoxes[3]:SetText(UnitFactionGroup("player"))  -- Faction
    editBoxes[5]:SetText(GuildHelper:GetCombinedGuildName())  -- Guild Name
    editBoxes[6]:SetText(UnitLevel("player"))  -- Level
    editBoxes[6]:Disable()  -- Make it read-only
    editBoxes[7]:SetText(GetAverageItemLevel())  -- Item Level
    local _, class = UnitClass("player")
    editBoxes[8]:SetText(class)  -- Class
    local currentSpec = GetSpecialization()
    if currentSpec then
        local specName = select(2, GetSpecializationInfo(currentSpec))
        editBoxes[9]:SetText(specName or "")  -- Spec
    end

    -- Initialize dropdowns
    local mainCharDropdown = editBoxes[4]
    UIDropDownMenu_Initialize(mainCharDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = self.SetValue
        local savedToons = GetSavedToons()
        if #savedToons == 0 then
            table.insert(savedToons, UnitName("player") .. "-" .. GetRealmName())
        end
        for _, toon in ipairs(savedToons) do
            info.text, info.arg1 = toon, toon
            UIDropDownMenu_AddButton(info)
        end
    end)

    function mainCharDropdown:SetValue(newValue)
        UIDropDownMenu_SetText(mainCharDropdown, newValue)
        mainCharDropdown.selectedValue = newValue  -- Store the selected value
        CloseDropDownMenus()
    end

    if not GetSavedToons() or #GetSavedToons() == 0 then
        UIDropDownMenu_SetText(mainCharDropdown, UnitName("player") .. "-" .. GetRealmName())
        mainCharDropdown.selectedValue = UnitName("player") .. "-" .. GetRealmName()
    else
        UIDropDownMenu_SetText(mainCharDropdown, globalInfo.gb_mainCharacter ~= "NA" and globalInfo.gb_mainCharacter or "")
        mainCharDropdown.selectedValue = globalInfo.gb_mainCharacter ~= "NA" and globalInfo.gb_mainCharacter or ""
    end

    local roleDropdown = editBoxes[10]
    roleDropdown.selectedValues = characterInfo.pt_roles or {}
    UIDropDownMenu_Initialize(roleDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            local value = self.value
            if tContains(roleDropdown.selectedValues, value) then
                for i, v in ipairs(roleDropdown.selectedValues) do
                    if v == value then
                        table.remove(roleDropdown.selectedValues, i)
                        break
                    end
                end
            else
                table.insert(roleDropdown.selectedValues, value)
            end
            UIDropDownMenu_SetText(roleDropdown, table.concat(roleDropdown.selectedValues, ", "))
            CloseDropDownMenus()
        end
        info.isNotRadio = true  -- Use checkboxes instead of radio buttons
        info.keepShownOnClick = true  -- Allow multiple selections
        local roles = { "DPS", "Healer", "Tank" }
        for _, role in ipairs(roles) do
            info.text, info.arg1 = role, role
            info.checked = tContains(roleDropdown.selectedValues, role)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(roleDropdown, table.concat(roleDropdown.selectedValues, ", "))

    local professionDropdown = editBoxes[11]
    professionDropdown.selectedValues = characterInfo.pt_professions or {}
    UIDropDownMenu_Initialize(professionDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            local value = self.value
            if tContains(professionDropdown.selectedValues, value) then
                for i, v in ipairs(professionDropdown.selectedValues) do
                    if v == value then
                        table.remove(professionDropdown.selectedValues, i)
                        break
                    end
                end
            else
                table.insert(professionDropdown.selectedValues, value)
            end
            UIDropDownMenu_SetText(professionDropdown, table.concat(professionDropdown.selectedValues, ", "))
            CloseDropDownMenus()
        end
        info.isNotRadio = true  -- Use checkboxes instead of radio buttons
        info.keepShownOnClick = true  -- Allow multiple selections
        local professions = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Inscription", "Jewelcrafting", "Leatherworking", "Mining", "Skinning", "Tailoring" }
        for _, profession in ipairs(professions) do
            info.text, info.arg1 = profession, profession
            info.checked = tContains(professionDropdown.selectedValues, profession)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(professionDropdown, table.concat(professionDropdown.selectedValues, ", "))

    local interestDropdown = editBoxes[12]
    interestDropdown.selectedValues = characterInfo.pt_interests or {}
    UIDropDownMenu_Initialize(interestDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            local value = self.value
            if tContains(interestDropdown.selectedValues, value) then
                for i, v in ipairs(interestDropdown.selectedValues) do
                    if v == value then
                        table.remove(interestDropdown.selectedValues, i)
                        break
                    end
                end
            else
                table.insert(interestDropdown.selectedValues, value)
            end
            UIDropDownMenu_SetText(interestDropdown, table.concat(interestDropdown.selectedValues, ", "))
            CloseDropDownMenus()
        end
        info.isNotRadio = true  -- Use checkboxes instead of radio buttons
        info.keepShownOnClick = true  -- Allow multiple selections
        local interests = { "Raids", "Mythic+", "PvP", "Leveling", "Professions" }
        for _, interest in ipairs(interests) do
            info.text, info.arg1 = interest, interest
            info.checked = tContains(interestDropdown.selectedValues, interest)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(interestDropdown, table.concat(interestDropdown.selectedValues, ", "))

    -- Add fields for guild join date and birthdate
    editBoxes[13]:SetText(characterInfo.pt_guildJoinDate ~= "NA" and characterInfo.pt_guildJoinDate or "2024-01-01")
    editBoxes[13]:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText()
        if not text:match("^%d%d%d%d%-%d%d%-%d%d$") then
            print("Invalid date format. Please use YYYY-MM-DD.")
        end
    end)

    editBoxes[14]:SetText(globalInfo.gb_birthdate ~= "NA" and globalInfo.gb_birthdate or "1999-01-01")
    editBoxes[14]:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText()
        if not text:match("^%d%d%d%d%-%d%d%-%d%d$") then
            print("Invalid date format. Please use YYYY-MM-DD.")
        end
    end)

    editBoxes[15]:SetText(globalInfo.gb_battletag ~= "NA" and globalInfo.gb_battletag or "NA")

    -- Add a table of toons' save data on the right side
    local toonsLabel = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toonsLabel:SetPoint("TOPRIGHT", memberFrame, "TOPRIGHT", -20, -50)
    toonsLabel:SetText("My Toons (Delete)")

    -- Create a scroll frame for the toon list
    local scrollFrame = CreateFrame("ScrollFrame", nil, memberFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(200, 400)
    scrollFrame:SetPoint("TOPRIGHT", toonsLabel, "BOTTOMRIGHT", 0, -10)

    local toonListFrame = CreateFrame("Frame", nil, scrollFrame)
    toonListFrame:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(toonListFrame)

    -- Function to update the toon list
    local function UpdateToonList()
        for _, child in ipairs({ toonListFrame:GetChildren() }) do
            child:Hide()
        end

        local savedToons = GetSavedToons()
        for i, toonName in ipairs(savedToons) do
            local row = CreateFrame("Frame", nil, toonListFrame)
            row:SetSize(toonListFrame:GetWidth(), 30)
            row:SetPoint("TOPLEFT", toonListFrame, "TOPLEFT", 0, -30 * (i - 1))

            local background = row:CreateTexture(nil, "BACKGROUND")
            background:SetColorTexture(0.1, 0.1, 0.1, 0.7) -- Dark background
            background:SetAllPoints(row)

            local toonLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            toonLabel:SetPoint("LEFT", row, "LEFT", 10, 0)
            toonLabel:SetText(toonName)

            local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            deleteButton:SetSize(20, 20)
            deleteButton:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            deleteButton:SetText("X")
            deleteButton:SetScript("OnClick", function()
                GuildHelper_SavedVariables.characterInfo[toonName] = nil
                UpdateToonList()
            end)
        end
    end

    UpdateToonList()

    -- Add a save button
    local saveButton = CreateFrame("Button", nil, memberFrame, "GameMenuButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("BOTTOMLEFT", memberFrame, "BOTTOMLEFT", 20, 20)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Save member information logic here
        local newMember = {
            pt_name = editBoxes[1]:GetText(),
            gb_mainCharacter = mainCharDropdown.selectedValue,
            pt_realm = editBoxes[2]:GetText(),
            pt_faction = editBoxes[3]:GetText(),
            pt_guildName = editBoxes[5]:GetText(),
            pt_level = editBoxes[6]:GetText(),
            pt_itemLevel = editBoxes[7]:GetText(),
            pt_class = editBoxes[8]:GetText(),
            pt_spec = editBoxes[9]:GetText(),
            pt_roles = roleDropdown.selectedValues,
            pt_professions = professionDropdown.selectedValues,
            pt_interests = interestDropdown.selectedValues,
            pt_guildJoinDate = editBoxes[13]:GetText(),
            gb_birthdate = editBoxes[14]:GetText(),
            gb_battletag = editBoxes[15]:GetText(),
            lastUpdated = date("%Y%m%d%H%M%S"),
            deleted = false
        }

        -- Save to characterInfo
        GuildHelper_SavedVariables.characterInfo[UnitName("player") .. "-" .. GetRealmName()] = newMember

        -- Save to globalInfo
        GuildHelper_SavedVariables.globalInfo = {
            gb_mainCharacter = mainCharDropdown.selectedValue,
            gb_birthdate = newMember.gb_birthdate,
            gb_battletag = newMember.gb_battletag
        }

        -- Save to sharedData roster
        local fullName = newMember.pt_name
        local rosterEntry = {
            id = fullName,
            tableType = "roster",
            guildName = newMember.pt_guildName,
            lastUpdated = newMember.lastUpdated,
            deleted = newMember.deleted,
            data = {
                name = newMember.pt_name,
                class = newMember.pt_class,
                level = newMember.pt_level,
                rank = "Member",
                itemLevel = newMember.pt_itemLevel,
                battletag = newMember.gb_battletag,
                roles = newMember.pt_roles,
                guildJoinDate = newMember.pt_guildJoinDate,
                professions = newMember.pt_professions,
                mainCharacter = newMember.gb_mainCharacter,
                interests = newMember.pt_interests,
                birthdate = newMember.gb_birthdate,
                faction = newMember.pt_faction
            }
        }

        GuildHelper_SavedVariables.sharedData.roster[fullName] = rosterEntry

        print("Member information saved.")
        UpdateToonList()  -- Update the toon list in real-time
        GuildHelper.Maintenance:InitializeMetadataTables()
    end)
end

--[[ Function to save character info
function GuildHelper:SaveCharacterInfo(globalInfo, characterInfo)
    -- Called by various functions to save character info
    -- Ensure no nil values are passed
    for key, value in pairs(globalInfo) do
        if value == nil or value == "" then
            globalInfo[key] = "NA"
        end
    end

    for key, value in pairs(characterInfo) do
        if value == nil or value == "" then
            characterInfo[key] = "NA"
        end
    end

    -- Add a lastUpdated timestamp
    local timestamp = date("%Y%m%d%H%M%S")
    globalInfo.lastUpdated = timestamp
    characterInfo.lastUpdated = timestamp

    -- Ensure guild name and realm name are captured
    local fullName = characterInfo.pt_name  -- Ensure fullName is defined

    GuildHelper_SavedVariables.globalInfo = globalInfo
    GuildHelper_SavedVariables.characterInfo[fullName] = characterInfo  -- Save with full name
end
]]--