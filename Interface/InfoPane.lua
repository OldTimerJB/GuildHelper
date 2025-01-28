-- InfoPane Module
-- This module handles the creation of the informational pane

    -- Check if the user is an officer or GM
    local isOfficerOrGM = IsGuildLeader() or C_GuildInfo.CanEditOfficerNote()

function GuildHelper:CreateInfoPane(parentFrame)
    -- Implement info pane creation logic here
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

    -- Create a table for articles
    local articleTable = CreateFrame("Frame", nil, content)
    articleTable:SetSize(820, 200)  -- Decreased width by 20 pixels
    articleTable:SetPoint("TOPLEFT", 10, -10)

    -- Add columns for article titles, categories, and dates
    local headers = {"Title", "Category", "Date"}
    local headerFrame = CreateFrame("Frame", nil, articleTable)
    headerFrame:SetSize(articleTable:GetWidth() - 30, 20)  -- Decreased width by 30 pixels
    headerFrame:SetPoint("TOPLEFT", articleTable, "TOPLEFT", 0, -4)

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

    -- Create a scroll frame for the article rows
    local rowScrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    rowScrollFrame:SetSize(820, 150)  -- Decreased width by 20 pixels
    rowScrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)

    local rowContent = CreateFrame("Frame", nil, rowScrollFrame)
    rowContent:SetSize(rowScrollFrame:GetWidth(), rowScrollFrame:GetHeight())
    rowScrollFrame:SetScrollChild(rowContent)

    -- Define saveButton, deleteButton, and editButton before using them
    local saveButton, deleteButton, editButton

    -- Create fields for new article
    local labels = {"Title:", "Category:"}
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
            table.insert(editBoxes, editBox)
        end
    end

    local titleEditBox = editBoxes[1]
    local categoryDropdown = editBoxes[2]

    local categories = {"Guildlines", "Rules", "Community"}

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

    local selectedArticleID = nil
    local articles = GuildHelper_SavedVariables.sharedData.guildInfo or {}

    -- Function to filter articles based on the current guild and linked guilds
    local function FilterInfoArticles(articles)
        local linkedGuildGroups = GuildHelper:isGuildFederatedMember()

        local filteredArticles = {}
        for _, article in pairs(articles) do
            if not article.deleted then -- Filter out deleted articles
                for _, guild in ipairs(linkedGuildGroups) do
                    if article.guildName == guild.name then
                        table.insert(filteredArticles, article)
                        break
                    end
                end
            end
        end

        return filteredArticles
    end

    -- Example articles
    local filteredArticles = FilterInfoArticles(articles)

    if #filteredArticles == 0 then
        -- Create a default welcome article if there are no articles
        local welcomeArticle = {
            id = "199901010000001234",
            tableType = "guildInfo",
            guildName = GuildHelper:GetCombinedGuildName(),
            lastUpdated = "19990101000000",
            deleted = false,
            data = {
                title = "Welcome to the Guild!",
                content = "Welcome to our guild! We are glad to have you here. Please check the guild Information for more details.",
                category = "General",
                date = "2024-12-15 08:59:06",
            }
        }
        articles[welcomeArticle.id] = welcomeArticle
        filteredArticles = FilterInfoArticles(articles)
    end

    -- Function to create a row in the article table
    local function CreateArticleRow(article, index)
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
        titleLabel:SetText(article.data.title)
        titleLabel:SetJustifyH("CENTER")

        local categoryLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        categoryLabel:SetSize(headerWidth, 20)
        categoryLabel:SetPoint("LEFT", titleLabel, "RIGHT", 0, 0)
        categoryLabel:SetText(article.data.category)
        categoryLabel:SetJustifyH("CENTER")

        local dateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dateLabel:SetSize(headerWidth, 20)
        dateLabel:SetPoint("LEFT", categoryLabel, "RIGHT", 0, 0)
        dateLabel:SetText(article.data.date)
        dateLabel:SetJustifyH("CENTER")

        row:SetScript("OnMouseDown", function()
            -- Load the article content when the row is clicked
            selectedArticleID = article.id
            titleEditBox:SetText(article.data.title)
            UIDropDownMenu_SetText(categoryDropdown, article.data.category)
            wysiwygEditBox:SetText(article.data.content)
            wysiwygEditBox:Show()
            if (isOfficerOrGM) then
            saveButton:Show()
            deleteButton:Show()
            editButton:Show()
            end
        end)

        return row
    end

    for index, article in ipairs(filteredArticles) do
        CreateArticleRow(article, index)
    end

    if (isOfficerOrGM) then
        -- Create, Edit, and Delete buttons
        local newButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
        newButton:SetSize(100, 30)
        newButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 10)
        newButton:SetText("New")
        newButton:SetScript("OnClick", function()
            -- Logic to create a new article
            selectedArticleID = nil
            titleEditBox:SetText("")
            UIDropDownMenu_SetText(categoryDropdown, "")
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
            -- Logic to edit the selected article
            if selectedArticleID then
                titleEditBox:Show()
                categoryDropdown:Show()
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
            -- Logic to mark the selected article as deleted
            if selectedArticleID then
                for i, article in ipairs(articles) do
                    if article.id == selectedArticleID then
                        article.deleted = true -- Mark as deleted
                        break
                    end
                end
                GuildHelper_SavedVariables.sharedData.guildInfo = articles  -- Save to shared/syncable dataset
                selectedArticleID = nil
                titleEditBox:Show()
                categoryDropdown:Show()
                wysiwygEditBox:Show()
                saveButton:Hide()
                deleteButton:Hide()
                editButton:Hide()
                -- Refresh the article list
                filteredArticles = FilterInfoArticles(articles)
                for _, child in ipairs({rowContent:GetChildren()}) do
                    child:Hide()
                end
                for i, article in ipairs(filteredArticles) do
                    CreateArticleRow(article, i)
                end
            end
        end)
        deleteButton:Hide()
    end

    -- Create Next and Back buttons to cycle through the news
    local currentIndex = 1

    local function UpdateArticleDisplay(index)
        if filteredArticles[index] then
            local article = filteredArticles[index]
            titleEditBox:SetText(article.data.title)
            UIDropDownMenu_SetText(categoryDropdown, article.data.category)
            wysiwygEditBox:SetText(article.data.content)
            wysiwygEditBox:Show()
        end
    end

    local nextButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    nextButton:SetSize(100, 30)
    nextButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    nextButton:SetText("Next")
    nextButton:SetScript("OnClick", function()
        currentIndex = currentIndex + 1
        if currentIndex > #filteredArticles then
            currentIndex = 1
        end
        UpdateArticleDisplay(currentIndex)
    end)
    nextButton:Show()

    local backButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    backButton:SetSize(100, 30)
    backButton:SetPoint("RIGHT", nextButton, "LEFT", -10, 0)
    backButton:SetText("Back")
    backButton:SetScript("OnClick", function()
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #filteredArticles
        end
        UpdateArticleDisplay(currentIndex)
    end)
    backButton:Show()

    -- Initialize the display with the first article
    UpdateArticleDisplay(currentIndex)

    -- Save button
    saveButton = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("LEFT", deleteButton, "RIGHT", 10, 0)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Logic to save the new or edited article
        local newArticle = {
            id = selectedArticleID or date("%Y%m%d%H%M%S") .. random(1000, 9999),
            tableType = "guildInfo",
            guildName = GuildHelper:GetCombinedGuildName(),
            lastUpdated = date("%Y%m%d%H%M%S"),
            deleted = false,
            data = {
                title = titleEditBox:GetText(),
                category = UIDropDownMenu_GetText(categoryDropdown),
                date = date("%Y-%m-%d %H:%M:%S"),
                content = wysiwygEditBox:GetText(),
            }
        }
        articles[newArticle.id] = newArticle
        GuildHelper_SavedVariables.sharedData.guildInfo = articles  -- Save to shared/syncable dataset
        -- Clear existing rows
        for _, child in ipairs({rowContent:GetChildren()}) do
            child:Hide()
        end
        filteredArticles = FilterInfoArticles(articles)
        for i, article in ipairs(filteredArticles) do
            CreateArticleRow(article, i)
        end
        titleEditBox:Show()
        categoryDropdown:Show()
        wysiwygEditBox:Show()
        saveButton:Hide()
        deleteButton:Hide()
        editButton:Hide()
    end)
    saveButton:Hide()
end