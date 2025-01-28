-- CalendarPane Module
-- This module handles the calendar pane
    -- Check if the user is an officer or GM
    local isOfficerOrGM = IsGuildLeader() or C_GuildInfo.CanEditOfficerNote()

function GuildHelper:CreateCalendarPane(parentFrame)
    if not GuildHelper_SavedVariables then
        GuildHelper_SavedVariables = {}
    end
    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {
            calendar = {}
        }
    end

    local events = GuildHelper_SavedVariables.sharedData.calendar or {}

    -- Implement event calendar pane creation logic here
    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(860, 570)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(860, 570)
    scrollFrame:SetScrollChild(content)

    -- Set the background texture to look like old paper
    local bgTexture = content:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(content)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Create a table for events
    local eventTable = CreateFrame("Frame", nil, content)
    eventTable:SetSize(820, 200)  -- Decreased width by 20 pixels
    eventTable:SetPoint("TOPLEFT", 10, -10)

    -- Add columns for event titles, categories, and dates
    local headers = {"Title", "Category", "Date", "Event Date"}
    local headerFrame = CreateFrame("Frame", nil, eventTable)
    headerFrame:SetSize(eventTable:GetWidth() - 30, 20)  -- Decreased width by 30 pixels
    headerFrame:SetPoint("TOPLEFT", eventTable, "TOPLEFT", 0, -4)

    -- Add a shaded background to the header
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame)
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)  -- Shaded background

    local headerWidth = headerFrame:GetWidth() / #headers
    headerFrame.headers = {}
    for i, title in ipairs(headers) do
        local header = CreateFrame("Frame", nil, headerFrame)
        header:SetSize(headerWidth, 20)
        if i == 1 then
            header:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
        else
            header:SetPoint("LEFT", headerFrame.headers[i - 1], "RIGHT", 0, 0)
        end

        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        headerText:SetPoint("CENTER", header, "CENTER", 0, 0)
        headerText:SetText(title)
        headerText:SetJustifyH("CENTER")  -- Align text to the center

        headerFrame.headers[i] = header
    end

    -- Create a scroll frame for the event rows
    local rowScrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    rowScrollFrame:SetSize(820, 150)  -- Decreased width by 20 pixels
    rowScrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)

    local rowContent = CreateFrame("Frame", nil, rowScrollFrame)
    rowContent:SetSize(rowScrollFrame:GetWidth(), rowScrollFrame:GetHeight())
    rowScrollFrame:SetScrollChild(rowContent)

    -- Define saveButton, deleteButton, and editButton before using them
    local saveButton, deleteButton, editButton

    -- Create fields for new event
    local labels = {"Title:", "Event Date:", "Category:"}
    local yOffset = -20
    local xOffset = 10
    local fieldXOffset = 150

    local editBoxes = {}

    -- Create an invisible table for alignment
    local tableFrame = CreateFrame("Frame", nil, content)
    tableFrame:SetPoint("TOPLEFT", rowScrollFrame, "BOTTOMLEFT", xOffset, yOffset)
    tableFrame:SetSize(400, 100)  -- Adjust size as needed

    for i, label in ipairs(labels) do
        local titleLabel = tableFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 0, -30 * (i - 1))  -- Adjusted spacing
        titleLabel:SetText(label)

        if label == "Category:" then
            -- Create dropdown for category
            local dropdown = CreateFrame("Frame", "CategoryDropdown", tableFrame, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOPLEFT", titleLabel, "TOPLEFT", (fieldXOffset - 25), 8)
            UIDropDownMenu_SetWidth(dropdown, 200)
            table.insert(editBoxes, dropdown)
        else
            -- Create edit boxes for other fields
            local editBox = CreateFrame("EditBox", nil, tableFrame, "InputBoxTemplate")
            editBox:SetSize(200, 30)
            editBox:SetPoint("TOPLEFT", titleLabel, "TOPLEFT", fieldXOffset, 8)
            editBox:SetAutoFocus(false)
            if label == "Event Date:" then
                editBox:SetScript("OnEditFocusLost", function(self)
                    local text = self:GetText()
                    if not text:match("^%d%d%d%d%-%d%d%-%d%d$") then
                        print("Invalid date format. Please use YYYY-MM-DD.")
                    end
                end)
            end
            table.insert(editBoxes, editBox)
        end
    end

    local titleEditBox = editBoxes[1]
    local dateEditBox = editBoxes[2]
    local categoryDropdown = editBoxes[3]

    local categories = {"Anniversary", "Birthday", "Raid", "Mythic Run"}

    UIDropDownMenu_Initialize(categoryDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetSelectedID(categoryDropdown, self:GetID())
        end
        for i, category in ipairs(categories) do
            info.text = category
            info.value = category
            info.checked = false
            UIDropDownMenu_AddButton(info)
        end
    end)

    local wysiwygFrame = CreateFrame("Frame", nil, tableFrame, "BackdropTemplate")
    wysiwygFrame:SetPoint("TOPLEFT", titleEditBox, "BOTTOMLEFT", -150, -65)  -- Moved down by 20 pixels
    wysiwygFrame:SetSize(820, 190)  -- Change height to 190
    wysiwygFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    wysiwygFrame:SetBackdropColor(0, 0, 0, 1)

    local wysiwygBox = CreateFrame("ScrollFrame", "WYSIWYGBox", wysiwygFrame, "UIPanelScrollFrameTemplate")
    wysiwygBox:SetSize(800, 130)  -- Adjust height to fit within the frame
    wysiwygBox:SetPoint("TOPLEFT", 10, -10)

    local wysiwygEditBox = CreateFrame("EditBox", nil, wysiwygBox)
    wysiwygEditBox:SetMultiLine(true)
    wysiwygEditBox:SetAutoFocus(false)
    wysiwygEditBox:SetFontObject("ChatFontNormal")
    wysiwygEditBox:SetWidth(780)
    wysiwygEditBox:SetHeight(110)  -- Adjust height to fit within the frame
    wysiwygEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    wysiwygBox:SetScrollChild(wysiwygEditBox)
    wysiwygEditBox:Show()

    local selectedEventID = nil
    local events = GuildHelper_SavedVariables.sharedData.calendar or {}

    -- Function to filter events based on the current guild and linked guilds
    local function FilterEvents(events)
        local linkedGuildGroups = GuildHelper:isGuildFederatedMember()

        local filteredEvents = {}
        for _, event in pairs(events) do
            if not event.deleted then
                for _, guild in ipairs(linkedGuildGroups) do
                    if event.guildName == guild.name then
                        table.insert(filteredEvents, event)
                        break
                    end
                end
            end
        end

        return filteredEvents
    end

    -- Function to create a row in the event table
    local function CreateEventRow(event, index)
        local row = CreateFrame("Frame", nil, rowContent)
        row:SetSize(820, 20)
        row:SetPoint("TOPLEFT", 0, -22 * (index - 1))

        -- Add a background with a different color for alternating rows
        local background = row:CreateTexture(nil, "BACKGROUND")
        if index % 2 == 0 then
            background:SetColorTexture(0.2, 0.2, 0.2, 0.7)  -- Darker background for even rows
        else
            background:SetColorTexture(0.1, 0.1, 0.1, 0.7)  -- Lighter background for odd rows
        end
        background:SetAllPoints(row)
        row.background = background

        local titleLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetSize(headerWidth, 20)
        titleLabel:SetPoint("LEFT", row, "LEFT", 0, 0)
        titleLabel:SetText(event.data.title)
        titleLabel:SetJustifyH("CENTER")

        local categoryLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        categoryLabel:SetSize(headerWidth, 20)
        categoryLabel:SetPoint("LEFT", titleLabel, "RIGHT", 0, 0)
        categoryLabel:SetText(event.data.category)
        categoryLabel:SetJustifyH("CENTER")

        local dateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dateLabel:SetSize(headerWidth, 20)
        dateLabel:SetPoint("LEFT", categoryLabel, "RIGHT", 0, 0)
        dateLabel:SetText(event.data.date)
        dateLabel:SetJustifyH("CENTER")

        local eventDateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        eventDateLabel:SetSize(headerWidth, 20)
        eventDateLabel:SetPoint("LEFT", dateLabel, "RIGHT", 0, 0)
        eventDateLabel:SetText(event.data.eventDate or "")
        eventDateLabel:SetJustifyH("CENTER")

        row:SetScript("OnMouseDown", function()
            -- Load the event content when the row is clicked
            selectedEventID = event.id
            titleEditBox:SetText(event.data.title)
            UIDropDownMenu_SetText(categoryDropdown, event.data.category)
            dateEditBox:SetText(event.data.eventDate or "")
            wysiwygEditBox:SetText(event.data.content)
            if (isOfficerOrGM) then
            wysiwygEditBox:Show()
            saveButton:Show()
            deleteButton:Show()
            editButton:Show()
            end
        end)

        return row
    end

    -- Example events
    local filteredEvents = FilterEvents(events)

    if #filteredEvents == 0 then
        -- Create a default welcome event if there are no events
        local welcomeEvent = {
            id = "199901010000001234",
            tableType = "calendar",
            guildName = GuildHelper:GetCombinedGuildName(),
            lastUpdated = "19990101000000",
            deleted = false,
            data = {
                title = "Welcome to the Guild!",
                category = "Birthday",
                date = "1999-01-01 00:00:00",
                eventDate = "1999-01-01 00:00:00",
                content = "Welcome to our guild! We are glad to have you here. Please check the guild Calendar for more details.",
            }
        }
        events[welcomeEvent.id] = welcomeEvent
        filteredEvents = FilterEvents(events)
    end

    for index, event in ipairs(filteredEvents) do
        CreateEventRow(event, index)
    end

    if (isOfficerOrGM) then
        -- Create, Edit, and Delete buttons
        local newButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
        newButton:SetSize(100, 30)
        newButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 10)
        newButton:SetText("New")
        newButton:SetScript("OnClick", function()
            -- Logic to create a new event
            selectedEventID = nil
            titleEditBox:SetText("")
            UIDropDownMenu_SetText(categoryDropdown, "")
            dateEditBox:SetText("")
            wysiwygEditBox:SetText("")
            wysiwygEditBox:Show()
            saveButton:Show()
            deleteButton:Hide()
            editButton:Hide()
        end)
        newButton:Show()

        editButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
        editButton:SetSize(100, 30)
        editButton:SetPoint("LEFT", newButton, "RIGHT", 10, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            -- Logic to edit the selected event
            if selectedEventID then
                titleEditBox:Show()
                categoryDropdown:Show()
                dateEditBox:Show()
                wysiwygEditBox:Show()
                saveButton:Show()
                deleteButton:Show()
            end
        end)
        editButton:Hide()

        deleteButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
        deleteButton:SetSize(100, 30)
        deleteButton:SetPoint("LEFT", editButton, "RIGHT", 10, 0)
        deleteButton:SetText("Delete")
        deleteButton:SetScript("OnClick", function()
            -- Logic to mark the selected event as deleted
            if selectedEventID then
                for i, event in ipairs(events) do
                    if event.id == selectedEventID then
                        event.deleted = true
                        break
                    end
                end
                GuildHelper_SavedVariables.sharedData.calendar = events  -- Save to shared/syncable dataset
                selectedEventID = nil
                titleEditBox:Show()
                categoryDropdown:Show()
                dateEditBox:Show()
                wysiwygEditBox:Show()
                saveButton:Hide()
                deleteButton:Hide()
                editButton:Hide()
                -- Refresh the event list
                filteredEvents = FilterEvents(events)
                for _, child in ipairs({rowContent:GetChildren()}) do
                    child:Hide()
                end
                for i, event in ipairs(filteredEvents) do
                    CreateEventRow(event, i)
                end
            end
        end)
        deleteButton:Hide()
    end

    -- Create Next and Back buttons to cycle through the events
    local currentIndex = 1

    local function UpdateEventDisplay(index)
        if filteredEvents[index] then
            local event = filteredEvents[index]
            titleEditBox:SetText(event.data.title)
            UIDropDownMenu_SetText(categoryDropdown, event.data.category)
            dateEditBox:SetText(event.data.eventDate or "")
            wysiwygEditBox:SetText(event.data.content)
            wysiwygEditBox:Show()
        end
    end

    local nextButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    nextButton:SetSize(100, 30)
    nextButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    nextButton:SetText("Next")
    nextButton:SetScript("OnClick", function()
        currentIndex = currentIndex + 1
        if currentIndex > #filteredEvents then
            currentIndex = 1
        end
        UpdateEventDisplay(currentIndex)
    end)
    nextButton:Show()

    local backButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    backButton:SetSize(100, 30)
    backButton:SetPoint("RIGHT", nextButton, "LEFT", -10, 0)
    backButton:SetText("Back")
    backButton:SetScript("OnClick", function()
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #filteredEvents
        end
        UpdateEventDisplay(currentIndex)
    end)
    backButton:Show()

    -- Initialize the display with the first event
    UpdateEventDisplay(currentIndex)

    -- Save button
    saveButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("LEFT", deleteButton, "RIGHT", 10, 0)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Logic to save the new or edited event
        local newEvent = {
            id = selectedEventID or date("%Y%m%d%H%M%S") .. random(1000, 9999),
            tableType = "calendar",
            guildName = GuildHelper:GetCombinedGuildName(),
            lastUpdated = date("%Y%m%d%H%M%S"),
            deleted = false,
            data = {
                title = titleEditBox:GetText(),
                category = UIDropDownMenu_GetText(categoryDropdown),
                date = date("%Y-%m-%d %H:%M:%S"),
                eventDate = dateEditBox:GetText() ~= "" and dateEditBox:GetText() or date("%Y-%m-%d %H:%M:%S"),
                content = wysiwygEditBox:GetText(),
            }
        }
        events[newEvent.id] = newEvent
        GuildHelper_SavedVariables.sharedData.calendar = events  -- Save to shared/syncable dataset
        -- Clear existing rows
        for _, child in ipairs({rowContent:GetChildren()}) do
            child:Hide()
        end
        filteredEvents = FilterEvents(events)
        for i, event in ipairs(filteredEvents) do
            CreateEventRow(event, i)
        end
        titleEditBox:Show()
        categoryDropdown:Show()
        dateEditBox:Show()
        wysiwygEditBox:Show()
        saveButton:Hide()
        deleteButton:Hide()
        editButton:Hide()
    end)
    saveButton:Hide()
end  -- This closes the function GuildHelper:CreateCalendarPane

-- Function to print reminders to the chat
function GuildHelper:PrintEventReminders()
    if not GuildHelper_SavedVariables.sharedData then
        GuildHelper_SavedVariables.sharedData = {}
    end

    if not GuildHelper_SavedVariables then
        return
    end

    local events = GuildHelper_SavedVariables.sharedData.calendar or {}
    local today = date("%Y-%m-%d")
    local soon = date("%Y-%m-%d", time() + 3 * 24 * 60 * 60)  -- 3 days from now

    for _, event in ipairs(events) do
        if event.eventDate == today then
            print("Reminder: " .. event.title .. " is happening today!")
        elseif event.eventDate <= soon then
            print("Reminder: " .. event.title .. " is happening soon!")
        end
    end
end

-- Call the PrintEventReminders function on load
GuildHelper:PrintEventReminders()
