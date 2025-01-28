-- This file is for the Guild Master to setup guilds for this addon
-- This will be where Multi-Guild support will be added
-- This will be where the guilds are added and removed
-- This will be where the guilds are selected
-- This will be where the permissions are set for the roles or ranks in the guild to make edits or create news or update information

function GuildHelper:CreateSetupPane(parentFrame)
    local currentGroup = GuildHelper:isGuildFederatedMember()
    if not currentGroup or #currentGroup == 0 then
        return
    end

    local combinedGuildName = GuildHelper:GetCombinedGuildName()  -- Use the combined guild name

    if combinedGuildName == "NA" then
        return
    end

    if not GuildHelper_SavedVariables.sharedData.setup then
        GuildHelper_SavedVariables.sharedData.setup = {}
    end

    -- Ensure only one federated guild
    local setupData = GuildHelper_SavedVariables.sharedData.setup["199901010000001234"]
    if not setupData then
        setupData = {
            id = "199901010000001234",  -- Set ID to the specified value
            tableType = "setup",
            guildName = combinedGuildName,
            lastUpdated = "19990101000000",  -- Default date
            deleted = false,
            data = { guilds = {}, chat = {} }
        }
        GuildHelper_SavedVariables.sharedData.setup["199901010000001234"] = setupData
    end

    local setupFrame = GuildHelper:CreateStandardFrame(parentFrame)

    -- Set the background texture to look like old paper
    local bgTexture = setupFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(setupFrame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Add a title
    local title = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", setupFrame, "TOP", 0, -10)
    title:SetText("Setup Guilds")

    -- Add a box for adding guild names
    local guildNameLabel = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildNameLabel:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 20, -50)
    guildNameLabel:SetText("Guild Name:")

    -- Ensure guildNameEditBox is initialized
    local guildNameEditBox = CreateFrame("EditBox", nil, setupFrame, "InputBoxTemplate")
    guildNameEditBox:SetSize(200, 30)
    guildNameEditBox:SetPoint("LEFT", guildNameLabel, "RIGHT", 10, 0)
    guildNameEditBox:SetAutoFocus(false)
    guildNameEditBox:SetText(combinedGuildName)  -- Set default text to the full guild name

    local tempGuildList = setupData.data.guilds
    local guildColors = setupData.data.chat.color or {}
    setupData.data.chat.color = guildColors

    local addButton = CreateFrame("Button", nil, setupFrame, "GameMenuButtonTemplate")
    addButton:SetSize(100, 30)
    addButton:SetPoint("LEFT", guildNameEditBox, "RIGHT", 10, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local guildName = guildNameEditBox:GetText()
        if guildName and guildName ~= "" then
            if not guildName:find("-") then
                print("Invalid guild name format. Please include the realm name (e.g., GuildName-Realm).")
            else
                local exists = false
                for _, guild in ipairs(tempGuildList) do
                    if guild.name == guildName then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(tempGuildList, { name = guildName })
                    guildColors[guildName] = guildColors[guildName] or { colorcode = "ffffff" }
                    guildNameEditBox:SetText("")
                    GuildHelper:UpdateGuildList(setupFrame, tempGuildList)
                    GuildHelper:UpdateColorSelectorList(setupFrame, tempGuildList, guildColors)
                else
                    print("Guild name already exists in the list.")
                end
            end
        end
    end)

    -- Create a scroll frame for the guild list
    local scrollFrame = CreateFrame("ScrollFrame", nil, setupFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 200)
    scrollFrame:SetPoint("TOPLEFT", guildNameLabel, "BOTTOMLEFT", 0, -20)

    local r, g, b = 0, 0, 0
    if setupData.data.chat.bgcolor then
        r, g, b = tonumber("0x" .. setupData.data.chat.bgcolor:sub(1, 2)) / 255,
                  tonumber("0x" .. setupData.data.chat.bgcolor:sub(3, 4)) / 255,
                  tonumber("0x" .. setupData.data.chat.bgcolor:sub(5, 6)) / 255
    end

    local guildListFrame = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    guildListFrame:SetSize(300, 200)
    -- Add a default backdrop to show color
    guildListFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
    guildListFrame:SetBackdropColor(r, g, b, 1)
    scrollFrame:SetScrollChild(guildListFrame)

    setupFrame.guildListFrame = guildListFrame

    -- Add fields for Chat Channel and Channel Password
    local chatChannelLabel = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatChannelLabel:SetPoint("TOPLEFT", guildNameLabel, "BOTTOMLEFT", 0, -250)
    chatChannelLabel:SetText("Chat Channel:")

    local chatChannelEditBox = CreateFrame("EditBox", nil, setupFrame, "InputBoxTemplate")
    chatChannelEditBox:SetSize(200, 30)
    chatChannelEditBox:SetPoint("LEFT", chatChannelLabel, "RIGHT", 10, 0)
    chatChannelEditBox:SetAutoFocus(false)
    chatChannelEditBox:SetText(setupData.data.chat.chatchannel or "")  -- Set default text to the saved chat channel

    -- Add the background color selector above the color list
    local bgColorLabel = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bgColorLabel:SetPoint("TOPLEFT", chatChannelEditBox, "TOPRIGHT", 45, 0)  -- Move to the right by 45 pixels
    bgColorLabel:SetText("Background Color:")

    local bgColorField = CreateFrame("EditBox", nil, setupFrame, "InputBoxTemplate")
    bgColorField:SetSize(100, 20)
    bgColorField:SetPoint("TOPLEFT", bgColorLabel, "BOTTOMLEFT", 0, -10)
    bgColorField:SetAutoFocus(false)
    bgColorField:SetText(setupData.data.chat.bgcolor or "000000")

    local bgColorPicker = CreateFrame("Button", nil, setupFrame, "UIPanelButtonTemplate")
    bgColorPicker:SetSize(20, 20)
    bgColorPicker:SetPoint("LEFT", bgColorField, "RIGHT", 10, 0)
    bgColorPicker:SetText("C")
    bgColorPicker:SetScript("OnClick", function()
        if not C_AddOns.IsAddOnLoaded("Blizzard_ColorPicker") then
            C_AddOns.LoadAddOn("Blizzard_ColorPicker")
        end
        if ColorPickerFrame and not ColorPickerFrame:IsShown() then
            local r, g, b = 0, 0, 0
            if setupData.data.chat.bgcolor then
                r, g, b = tonumber("0x" .. setupData.data.chat.bgcolor:sub(1, 2)) / 255,
                          tonumber("0x" .. setupData.data.chat.bgcolor:sub(3, 4)) / 255,
                          tonumber("0x" .. setupData.data.chat.bgcolor:sub(5, 6)) / 255
            end
            if ColorPickerFrame.SetColorRGB then
                ColorPickerFrame:SetColorRGB(r, g, b)
            end
            ColorPickerFrame.previousValues = { r = r, g = g, b = b }
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                setupData.data.chat.bgcolor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                bgColorField:SetText(setupData.data.chat.bgcolor)
                -- Update both colorSelector list frame and guild list frame
                setupFrame.colorSelectorListFrame:SetBackdropColor(r, g, b, 1)
                setupFrame.guildListFrame:SetBackdropColor(r, g, b, 1)
            end
            ColorPickerFrame.cancelFunc = function(previousValues)
                local r, g, b = previousValues.r, previousValues.g, previousValues.b
                setupData.data.chat.bgcolor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                bgColorField:SetText(setupData.data.chat.bgcolor)
                setupFrame.colorSelectorListFrame:SetBackdropColor(r, g, b, 1)
                setupFrame.guildListFrame:SetBackdropColor(r, g, b, 1)
            end
            ColorPickerFrame.swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                setupData.data.chat.bgcolor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                bgColorField:SetText(setupData.data.chat.bgcolor)
                setupFrame.colorSelectorListFrame:SetBackdropColor(r, g, b, 1)
                setupFrame.guildListFrame:SetBackdropColor(r, g, b, 1)
            end
            ColorPickerFrame:Show()
        end
    end)

    -- Add the color selector list to the right of the chat channel edit box
    local colorSelectorLabel = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorSelectorLabel:SetPoint("TOPLEFT", bgColorField, "BOTTOMLEFT", 0, -20)  -- Move to the right by 100 pixels
    colorSelectorLabel:SetText("Guild Colors:")

    local colorSelectorScrollFrame = CreateFrame("ScrollFrame", nil, setupFrame, "UIPanelScrollFrameTemplate")
    colorSelectorScrollFrame:SetSize(450, 175)  -- Increase width by 250
    colorSelectorScrollFrame:SetPoint("TOPLEFT", colorSelectorLabel, "BOTTOMLEFT", 0, -10)

    local colorSelectorListFrame = CreateFrame("Frame", nil, colorSelectorScrollFrame, "BackdropTemplate")
    colorSelectorListFrame:SetSize(450, 180)  -- Increase width by 250
    colorSelectorScrollFrame:SetScrollChild(colorSelectorListFrame)

    setupFrame.colorSelectorListFrame = colorSelectorListFrame

    -- Set the initial background color
    local r, g, b = 0, 0, 0
    if setupData.data.chat.bgcolor then
        r, g, b = tonumber("0x" .. setupData.data.chat.bgcolor:sub(1, 2)) / 255,
                  tonumber("0x" .. setupData.data.chat.bgcolor:sub(3, 4)) / 255,
                  tonumber("0x" .. setupData.data.chat.bgcolor:sub(5, 6)) / 255
    end
    colorSelectorListFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
    colorSelectorListFrame:SetBackdropColor(r, g, b, 1)

    local channelPasswordLabel = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelPasswordLabel:SetPoint("TOPLEFT", chatChannelLabel, "BOTTOMLEFT", 0, -20)
    channelPasswordLabel:SetText("Channel Password:")

    local channelPasswordEditBox = CreateFrame("EditBox", nil, setupFrame, "InputBoxTemplate")
    channelPasswordEditBox:SetSize(200, 30)
    channelPasswordEditBox:SetPoint("LEFT", channelPasswordLabel, "RIGHT", 10, 0)
    channelPasswordEditBox:SetAutoFocus(false)
    channelPasswordEditBox:SetText(setupData.data.chat.channelpassword or "")  -- Set default text to the saved channel password

    -- Add a save button
    local saveButton = CreateFrame("Button", nil, setupFrame, "GameMenuButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("BOTTOMLEFT", setupFrame, "BOTTOMLEFT", 20, 20)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Save setup information logic here
        setupData.data.guilds = tempGuildList
        setupData.data.chat.chatchannel = chatChannelEditBox:GetText()
        setupData.data.chat.channelpassword = channelPasswordEditBox:GetText()
        setupData.lastUpdated = date("%Y%m%d%H%M%S")
        GuildHelper:SaveSetupInfo(setupData)
    end)

    GuildHelper:UpdateGuildList(setupFrame, tempGuildList)
    GuildHelper:UpdateColorSelectorList(setupFrame, tempGuildList, guildColors)

    -- Store references to the edit boxes for later use
    setupFrame.guildNameEditBox = guildNameEditBox
    setupFrame.chatChannelEditBox = chatChannelEditBox
    setupFrame.channelPasswordEditBox = channelPasswordEditBox

    -- Load setup info
    GuildHelper:LoadSetupInfo(setupFrame)
end

function GuildHelper:SaveGuildName(guildName, currentGroup)
    local realmName = GetRealmName()
    if not guildName:find("-") then
        guildName = guildName .. "-" .. realmName
    end
    table.insert(currentGroup.guilds, { name = guildName })
    currentGroup.lastUpdated = date("%Y%m%d%H%M%S")
end

function GuildHelper:UpdateGuildList(setupFrame, guilds)
    local guildListFrame = setupFrame.guildListFrame
    local children = { guildListFrame:GetChildren() }
    for i = 1, #children do
        children[i]:Hide()
    end

    for index, guild in ipairs(guilds) do
        if type(guild.name) == "string" then  -- Ensure guild.name is a string
            local row = CreateFrame("Frame", nil, guildListFrame)
            row:SetSize(300, 30)
            row:SetPoint("TOPLEFT", guildListFrame, "TOPLEFT", 0, -30 * (index - 1))

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("LEFT", row, "LEFT", 10, 0)
            nameLabel:SetText(guild.name)

            local removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            removeButton:SetSize(20, 20)
            removeButton:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            removeButton:SetText("X")
            removeButton:SetScript("OnClick", function()
                for i, g in ipairs(guilds) do
                    if g.name == guild.name then
                        table.remove(guilds, i)
                        break
                    end
                end
                GuildHelper:UpdateGuildList(setupFrame, guilds)
            end)
        else
        end
    end
end

function GuildHelper:UpdateColorSelectorList(setupFrame, guilds, guildColors)
    local colorSelectorListFrame = setupFrame.colorSelectorListFrame
    local children = { colorSelectorListFrame:GetChildren() }
    for i = 1, #children do
        children[i]:Hide()
    end

    for index, guild in ipairs(guilds) do
        if type(guild.name) == "string" then
            -- Ensure entry is defined before indexing
            guildColors[guild.name] = guildColors[guild.name] or { colorcode = "ffffff" }

            local row = CreateFrame("Frame", nil, colorSelectorListFrame)
            row:SetSize(450, 30)  -- Increase width by 250
            row:SetPoint("TOPLEFT", colorSelectorListFrame, "TOPLEFT", 0, -30 * (index - 1))

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("LEFT", row, "LEFT", 10, 0)
            nameLabel:SetText(guild.name)
            local r, g, b = tonumber("0x" .. guildColors[guild.name].colorcode:sub(1, 2)) / 255,
                            tonumber("0x" .. guildColors[guild.name].colorcode:sub(3, 4)) / 255,
                            tonumber("0x" .. guildColors[guild.name].colorcode:sub(5, 6)) / 255
            nameLabel:SetTextColor(r, g, b)

            local colorField = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            colorField:SetSize(100, 20)
            colorField:SetPoint("RIGHT", row, "RIGHT", -40, 0)
            colorField:SetAutoFocus(false)
            colorField:SetText(guildColors[guild.name].colorcode or "ffffff")

            local colorPicker = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            colorPicker:SetSize(20, 20)
            colorPicker:SetPoint("RIGHT", colorField, "LEFT", -10, 0)
            colorPicker:SetText("C")
            colorPicker:SetScript("OnClick", function()
                if not C_AddOns.IsAddOnLoaded("Blizzard_ColorPicker") then
                    C_AddOns.LoadAddOn("Blizzard_ColorPicker")
                end
                if ColorPickerFrame and not ColorPickerFrame:IsShown() then
                    local r, g, b = 1, 1, 1
                    if guildColors[guild.name] and guildColors[guild.name].colorcode then
                        r, g, b = tonumber("0x" .. guildColors[guild.name].colorcode:sub(1, 2)) / 255,
                                  tonumber("0x" .. guildColors[guild.name].colorcode:sub(3, 4)) / 255,
                                  tonumber("0x" .. guildColors[guild.name].colorcode:sub(5, 6)) / 255
                    end
                    if ColorPickerFrame.SetColorRGB then
                        ColorPickerFrame:SetColorRGB(r, g, b)
                    end
                    ColorPickerFrame.previousValues = { r = r, g = g, b = b }
                    ColorPickerFrame.func = function()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        guildColors[guild.name].colorcode = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                        colorField:SetText(guildColors[guild.name].colorcode)
                        nameLabel:SetTextColor(r, g, b)
                    end
                    ColorPickerFrame.cancelFunc = function(previousValues)
                        local r, g, b = previousValues.r, previousValues.g, previousValues.b
                        guildColors[guild.name].colorcode = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                        colorField:SetText(guildColors[guild.name].colorcode)
                        nameLabel:SetTextColor(r, g, b)
                    end
                    ColorPickerFrame.swatchFunc = function()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        guildColors[guild.name].colorcode = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                        colorField:SetText(guildColors[guild.name].colorcode)
                        nameLabel:SetTextColor(r, g, b)
                    end
                    ColorPickerFrame:Show()
                end
            end)
        end
    end
end

function GuildHelper:RemoveGuildName(guildName, currentGroup)
    for i, guild in ipairs(currentGroup.guilds) do
        if guild.name == guildName then
            table.remove(currentGroup.guilds, i)
            break
        end
    end
end

function GuildHelper:SaveLinkedGuilds(currentGroup)
    local currentGuildName = GetGuildInfo("player") or "NA"
    if not GuildHelper_SavedVariables.sharedData.setup then
        GuildHelper_SavedVariables.sharedData.setup = {}
    end
    local setupData = GuildHelper_SavedVariables.sharedData.setup["199901010000001234"]
    if not setupData then
        setupData = {
            id = currentGuildName,
            tableType = "setup",
            guildName = currentGuildName,
            lastUpdated = "19990101000000",
            deleted = false,
            data = { guilds = {}, chat = {} }
        }
        GuildHelper_SavedVariables.sharedData.setup["199901010000001234"] = setupData
    end

    -- Find the group that contains the current guild
    local groupFound = false
    for i, guild in ipairs(setupData.data.guilds) do
        if guild.name == currentGuildName then
            setupData.data.guilds[i] = currentGroup
            groupFound = true
            break
        end
    end

    -- If no group is found, add the current group to setupData.data.guilds
    if not groupFound then
        table.insert(setupData.data.guilds, currentGroup)
    end

    GuildHelper:FilterGuildData()
end

function GuildHelper:FilterGuildData()
    local currentGroup = GuildHelper:isGuildFederatedMember()

    local filteredRoster = {}
    local roster = GuildHelper_SavedVariables.sharedData.roster or {}

    for toonName, toonData in pairs(roster) do
        for _, guild in ipairs(currentGroup) do
            if toonData.pt_guildName == guild.name then
                filteredRoster[toonName] = toonData
                break
            end
        end
    end

    GuildHelper_SavedVariables.filteredRoster = filteredRoster
end

-- Ensure the CreateSetupPane method is defined in the GuildHelper table
GuildHelper.CreateSetupPane = GuildHelper.CreateSetupPane

function GuildHelper:LoadSetupInfo(setupFrame)
    -- Ensure guildNameEditBox is not nil
    if not setupFrame.guildNameEditBox then
        return
    end

    -- Load setup info
    local setupInfo = GuildHelper_SavedVariables.sharedData.setup or {}
    local combinedGuildName = GuildHelper:GetCombinedGuildName()
    setupFrame.guildNameEditBox:SetText(combinedGuildName)  -- Set default text to the full guild name

    -- Find the setup data for the current guild or any federated guild
    local setupData = nil
    for _, guild in ipairs(GuildHelper:isGuildFederatedMember()) do
        setupData = setupInfo[guild.name]
        if setupData then
            break
        end
    end

    if setupData then
        GuildHelper:UpdateGuildList(setupFrame, setupData.data.guilds)
        GuildHelper:UpdateColorSelectorList(setupFrame, setupData.data.guilds, setupData.data.chat.color or {})
        setupFrame.chatChannelEditBox:SetText(setupData.data.chat.chatchannel or "")
        setupFrame.channelPasswordEditBox:SetText(setupData.data.chat.channelpassword or "")
    end
end

-- Define the SaveSetupInfo method
function GuildHelper:SaveSetupInfo(setupData)
    -- Ensure no nil values are passed
    setupData.guildName = setupData.guildName or "NA"
    setupData.data = setupData.data or { guilds = {}, chat = {} }
    setupData.lastUpdated = setupData.lastUpdated or date("%Y%m%d%H%M%S")

    GuildHelper_SavedVariables.sharedData.setup[setupData.id] = setupData
end
