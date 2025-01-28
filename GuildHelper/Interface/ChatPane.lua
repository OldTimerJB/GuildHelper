GuildHelper = GuildHelper or {}
GuildHelper.ChatPane = GuildHelper.ChatPane or {}

function GuildHelper.ChatPane:GetChatData()
    -- Determine if the user is part of a federated guild
    local currentGroup = GuildHelper:isGuildFederatedMember()
    local combinedGuildName = GuildHelper:GetCombinedGuildName()
    local setupData = GuildHelper_SavedVariables.sharedData.setup or {}
    local chatData = nil

    for _, guild in ipairs(currentGroup) do
        local guildSetupData = setupData[guild.name]
        if guildSetupData and guildSetupData.data and guildSetupData.data.chat then
            chatData = guildSetupData.data.chat
            break
        end
    end

    if not chatData then
        chatData = setupData["199901010000001234"] and setupData["199901010000001234"].data and setupData["199901010000001234"].data.chat or {}
    end

    return chatData
end

function GuildHelper.ChatPane:CreateChatPane(parent)
    -- Create the chat pane frame
    local frame = CreateFrame("Frame", "GuildHelperChatPane", parent, "BackdropTemplate")
    frame:SetSize(860, 570)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)

    -- Set the background texture to look like old paper
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal")

    -- Create an edit box for the ID number
    local idEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    idEditBox:SetSize(100, 20)
    idEditBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    idEditBox:SetAutoFocus(false)
    idEditBox:SetText(GuildHelper_SavedVariables.chatMemberId or "")  -- Load saved ID number

    -- Create a refresh button
    local refreshButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    refreshButton:SetSize(20, 20)
    refreshButton:SetPoint("LEFT", idEditBox, "RIGHT", 5, 0)
    refreshButton:SetText("R")
    refreshButton:SetScript("OnClick", function()
        local id = idEditBox:GetText()
        GuildHelper_SavedVariables.chatMemberId = id  -- Save the ID number
        -- Clear the chat member list
        for _, child in ipairs({ GuildHelper.ChatPane.frame.playerListContent:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)  -- Remove the child from the parent to avoid overlaying
        end
        GuildHelper.ChatPane:UpdatePlayerList()
    end)

    -- Create a title for the chat pane
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Guild Chat")

    -- Get chat data
    local chatData = GuildHelper.ChatPane:GetChatData()

    -- Guild list at top (color-coded)
    local guildListFrame = CreateFrame("Frame", "GuildHelperGuildListFrame", frame, "BackdropTemplate")
    guildListFrame:SetSize(550, 120)  -- Same width as chat message window
    guildListFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -50)
    guildListFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    guildListFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a title for the guild list
    local guildListTitle = guildListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guildListTitle:SetPoint("TOP", guildListFrame, "TOP", 0, -10)
    guildListTitle:SetText("Guild Legend")

    -- Create a scroll frame for the guild list
    local guildListScrollFrame = CreateFrame("ScrollFrame", "GuildHelperGuildListScrollFrame", guildListFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    guildListScrollFrame:SetSize(530, 80)  -- Same width as chat message window
    guildListScrollFrame:SetPoint("TOPLEFT", guildListFrame, "TOPLEFT", 10, -30)
    guildListScrollFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    guildListScrollFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a content frame to hold the guild list
    local guildListContent = CreateFrame("Frame", nil, guildListScrollFrame)
    guildListContent:SetSize(510, 80)  -- Same width as chat message window
    guildListScrollFrame:SetScrollChild(guildListContent)

    -- Populate the guild list with guild names and colors
    local guildColors = chatData.color or {}
    local currentGroup = GuildHelper:isGuildFederatedMember()
    for i, guild in ipairs(currentGroup) do
        local guildName = guild.name
        local colorCode = guildColors[guildName] and guildColors[guildName].colorcode or "ffffff"
        local r, g, b = tonumber("0x" .. colorCode:sub(1, 2)) / 255, tonumber("0x" .. colorCode:sub(3, 4)) / 255, tonumber("0x" .. colorCode:sub(5, 6)) / 255

        local guildLabel = guildListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        guildLabel:SetPoint("TOPLEFT", guildListContent, "TOPLEFT", 10, -20 * (i - 1))
        guildLabel:SetText(guildName)
        guildLabel:SetTextColor(r, g, b)
    end

    -- Chat messages scroll frame in the center-left
    local chatFrame = CreateFrame("Frame", "GuildHelperChatFrame", frame, "BackdropTemplate")
    chatFrame:SetSize(550, 340)  -- Increase width by 100 pixels
    chatFrame:SetPoint("TOPLEFT", guildListFrame, "BOTTOMLEFT", 0, -10)
    chatFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    chatFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a title for the chat messages
    local chatTitle = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    chatTitle:SetPoint("TOP", chatFrame, "TOP", 0, -10)
    chatTitle:SetText("Chat Messages")

    -- Create a scroll frame for the chat messages
    local chatScrollFrame = CreateFrame("ScrollFrame", "GuildHelperChatScrollFrame", chatFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    chatScrollFrame:SetSize(530, 300)  -- Increase width by 100 pixels
    chatScrollFrame:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 10, -30)
    chatScrollFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    chatScrollFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a content frame to hold the chat messages
    local chatContent = CreateFrame("Frame", nil, chatScrollFrame)
    chatContent:SetSize(510, 300)  -- Increase width by 100 pixels
    chatScrollFrame:SetScrollChild(chatContent)

    -- Create an editable scrolling message frame for the chat messages
    local chatText = CreateFrame("EditBox", nil, chatContent)
    chatText:SetMultiLine(true)
    chatText:SetSize(490, 280)  -- Increase width by 100 pixels
    chatText:SetPoint("TOPLEFT", chatContent, "TOPLEFT", 10, -0)
    chatText:SetFontObject("GameFontHighlightSmall")
    chatText:SetJustifyH("LEFT")
    chatText:SetMaxLetters(99999)
    chatText:EnableMouseWheel(true)
    chatText:SetAutoFocus(false)
    chatText:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        else
            self:ScrollDown()
        end
    end)

    chatText.AddMessage = function(self, msg, r, g, b)
        local existing = self:GetText() or ""
        local colorPrefix = string.format("|cff%02x%02x%02x", (r or 1)*255, (g or 1)*255, (b or 1)*255)
        local newText = (existing == "")
            and (colorPrefix .. msg .. "|r")
            or (existing .. "\n" .. colorPrefix .. msg .. "|r")
        self:SetText(newText)
    end

    frame.chatText = chatText

    -- Player list scroll frame in the center-right
    local playerListFrame = CreateFrame("Frame", "GuildHelperPlayerListFrame", frame, "BackdropTemplate")
    playerListFrame:SetSize(190, 340)  -- Increase width by 50 pixels
    playerListFrame:SetPoint("TOPLEFT", chatFrame, "TOPRIGHT", 25, 0)  -- Move up to the same position as chat message window
    playerListFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    playerListFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a title for the player list
    local playerListTitle = playerListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerListTitle:SetPoint("TOP", playerListFrame, "TOP", 0, -10)
    playerListTitle:SetText("Chat Members")

    -- Move the ID edit box and refresh button down above the chat members title or frame
    idEditBox:ClearAllPoints()
    idEditBox:SetPoint("BOTTOMLEFT", playerListFrame, "TOPLEFT", 10, 10)
    refreshButton:ClearAllPoints()
    refreshButton:SetPoint("LEFT", idEditBox, "RIGHT", 5, 0)

    -- Create a scroll frame for the player list
    local playerListScrollFrame = CreateFrame("ScrollFrame", "GuildHelperPlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    playerListScrollFrame:SetSize(170, 300)  -- Increase width by 50 pixels
    playerListScrollFrame:SetPoint("TOPLEFT", playerListFrame, "TOPLEFT", 10, -30)
    playerListScrollFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    playerListScrollFrame:SetBackdropColor(0, 0, 0, 1)

    -- Create a content frame to hold the player list
    local playerListContent = CreateFrame("Frame", nil, playerListScrollFrame)
    playerListContent:SetSize(150, 300)  -- Increase width by 50 pixels
    playerListScrollFrame:SetScrollChild(playerListContent)

    frame.playerListScrollFrame = playerListScrollFrame  -- Ensure this is set
    frame.playerListContent = playerListContent

    -- Bottom row: [M/A][PlayerName] EditBox + Send button
    -- Create an input box for sending messages
    local inputBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    inputBox:SetSize(550, 30)
    inputBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    inputBox:SetAutoFocus(false)
    inputBox:SetScript("OnEnterPressed", function(self)
        local message = self:GetText()
        if message ~= "" then
            GuildHelper.ChatPane:SendMessage(message)
            self:SetText("")
        end
    end)

    frame.inputBox = inputBox

    -- Create a send button
    local sendButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    sendButton:SetSize(100, 30)
    sendButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -195, 10)
    sendButton:SetText("Send")
    sendButton:SetScript("OnClick", function()
        local message = inputBox:GetText()
        if message ~= "" then
            GuildHelper.ChatPane:SendMessage(message)
            inputBox:SetText("")
        end
    end)

    frame.sendButton = sendButton

    -- Show the frame
    frame:Show()

    GuildHelper.ChatPane.frame = frame

    -- Update the player list initially
    GuildHelper.ChatPane:UpdatePlayerList()
end

function GuildHelper.ChatPane:SendMessage(message)
    local chatData = GuildHelper.ChatPane:GetChatData()
    local chatChannel = chatData.chatchannel
    if chatChannel and chatChannel ~= "" then
        local sender = UnitName("player")
        local prefixFlag = GuildHelper:IsMainOrAltFlag(sender)
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
        local classColorCode = string.format("%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)

        local currentGroup = GuildHelper:isGuildFederatedMember()
        local guildColors = chatData.color or {}
        local localGuildName = GetGuildInfo("player")
        local matchedGuildColorCode = "ffffff"

        if localGuildName and currentGroup then
            for _, guildInfo in ipairs(currentGroup) do
                if guildInfo.name == localGuildName then
                    local colorData = guildColors[localGuildName]
                    if colorData and colorData.colorcode then
                        matchedGuildColorCode = colorData.colorcode
                    end
                    break
                end
            end
        end

        local combinedGuildName = GuildHelper:GetCombinedGuildName()
        local matchedGuildColorCode = "ffffff"

        if combinedGuildName and currentGroup then
            for _, guildInfo in ipairs(currentGroup) do
                if guildInfo.name == combinedGuildName then
                    local colorData = guildColors[combinedGuildName]
                    if colorData and colorData.colorcode then
                        matchedGuildColorCode = colorData.colorcode
                    end
                    break
                end
            end
        end

        local encodedMessage = string.format(
            "%s|%s|%s|%s|%s|%s",
            prefixFlag, classColorCode, sender, GetRealmName(),
            matchedGuildColorCode, message
        )
        C_ChatInfo.SendAddonMessage("GuildHelper", encodedMessage, "CHANNEL", GetChannelName(chatChannel))
    else
        print("No valid chat channel configured.")
    end
end

function GuildHelper.ChatPane:UpdateGuildList()
    local guildListContent = GuildHelper.ChatPane.frame.guildListContent
    local chatData = GuildHelper.ChatPane:GetChatData()
    local guildColors = chatData.color or {}
    local currentGroup = GuildHelper:isGuildFederatedMember()

    for i, guild in ipairs(currentGroup) do
        local guildName = guild.name
        local colorCode = guildColors[guildName] and guildColors[guildName].colorcode or "ffffff"
        local r, g, b = tonumber("0x" .. colorCode:sub(1, 2)) / 255, tonumber("0x" .. colorCode:sub(3, 4)) / 255, tonumber("0x" .. colorCode:sub(5, 6)) / 255

        local guildLabel = guildListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        guildLabel:SetPoint("TOPLEFT", guildListContent, "TOPLEFT", 10, -30 * (i - 1))
        guildLabel:SetText(guildName)
        guildLabel:SetTextColor(r, g, b)
    end
end

function GuildHelper.ChatPane:UpdatePlayerList()
    local frame = GuildHelper.ChatPane.frame
    if not frame then return end  -- Ensure frame is not nil

    local players = GuildHelper:GetPlayersInChatChannel()

    -- Remove old content frame
    if frame.playerListContent then
        frame.playerListContent:Hide()
        frame.playerListContent:SetParent(nil)
        frame.playerListContent = nil
    end

    -- Create a new content frame each time
    local playerListContent = CreateFrame("Frame", nil, frame.playerListScrollFrame)
    playerListContent:SetSize(150, 300)
    frame.playerListScrollFrame:SetScrollChild(playerListContent)
    frame.playerListContent = playerListContent

    for i, player in ipairs(players) do
        local playerName = player.name
        local classColor = RAID_CLASS_COLORS[player.class] or { r = 1, g = 1, b = 1 }

        local playerLabel = playerListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playerLabel:SetPoint("TOPLEFT", playerListContent, "TOPLEFT", 10, -22 * (i - 1))
        playerLabel:SetText(playerName)
        playerLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    end
end

function GuildHelper.ChatPane:ReceiveMessage(prefix, text, channel, sender)
    if not GuildHelper.ChatPane.frame then return end

    -- Decode 6 parts
    local maFlag, classColorCode, senderName, realmName, guildColorCode, message = strsplit("|", text)

    if maFlag and classColorCode and senderName and realmName and guildColorCode and message then
        -- Class color
        local r = tonumber("0x"..classColorCode:sub(1,2))/255
        local g = tonumber("0x"..classColorCode:sub(3,4))/255
        local b = tonumber("0x"..classColorCode:sub(5,6))/255

        -- Prefix color
        local prefixColored = (maFlag == "M") and "|cff0000ff[M]|r" or "|cff00ff00[A]|r"

        -- Full sender name
        local fullSender = string.format("|cff%s[%s-%s]|r", classColorCode, senderName, realmName)

        -- Guild-colored message
        local coloredMsg = string.format("|cff%s%s|r", guildColorCode, message)

        -- Insert message into saved history, trimming to 300 lines
        GuildHelper_SavedVariables.chatHistory = GuildHelper_SavedVariables.chatHistory or {}
        table.insert(GuildHelper_SavedVariables.chatHistory, prefixColored..fullSender.." "..coloredMsg)
        if #GuildHelper_SavedVariables.chatHistory > 300 then
            table.remove(GuildHelper_SavedVariables.chatHistory, 1)
        end

        -- Rebuild the chat text
        local finalOutput = table.concat(GuildHelper_SavedVariables.chatHistory, "\n")
        GuildHelper.ChatPane.frame.chatText:SetText(finalOutput)
        GuildHelper.ChatPane.frame.chatText:SetCursorPosition(#finalOutput)
        GuildHelperChatScrollFrame:SetVerticalScroll(GuildHelperChatScrollFrame:GetVerticalScrollRange())

    else
        -- Fallback to default
        local guildName = GuildHelper:GetGuildNameFromSender(sender)
        local chatData = GuildHelper.ChatPane:GetChatData()
        local guildColors = chatData.color or {}
        local colorCode = guildColors[guildName] and guildColors[guildName].colorcode or "ffffff"
        local r, g, b = tonumber("0x"..colorCode:sub(1,2))/255,
                        tonumber("0x"..colorCode:sub(3,4))/255,
                        tonumber("0x"..colorCode:sub(5,6))/255

        local prefixFinal = GuildHelper:IsMainOrAlt(sender)
        local fallbackMsg = string.format("%s[%s] %s", prefixFinal, sender, text)

        GuildHelper_SavedVariables.chatHistory = GuildHelper_SavedVariables.chatHistory or {}
        table.insert(GuildHelper_SavedVariables.chatHistory, fallbackMsg)
        if #GuildHelper_SavedVariables.chatHistory > 300 then
            table.remove(GuildHelper_SavedVariables.chatHistory, 1)
        end

        local finalOutput = table.concat(GuildHelper_SavedVariables.chatHistory, "\n")
        GuildHelper.ChatPane.frame.chatText:SetText(finalOutput)
        GuildHelper.ChatPane.frame.chatText:SetCursorPosition(#finalOutput)
        GuildHelperChatScrollFrame:SetVerticalScroll(GuildHelperChatScrollFrame:GetVerticalScrollRange())
    end
end

function GuildHelper:IsMainOrAltFlag(playerName)
    -- Return "M" or "A" only, no color codes.
    local fullPlayerName = playerName
    if not playerName:find("-") then
        fullPlayerName = playerName .. "-" .. GetRealmName()
    end
    local info = GuildHelper_SavedVariables.characterInfo[fullPlayerName]
    if info and info.gb_mainCharacter == fullPlayerName then
        return "M"
    else
        for name, i in pairs(GuildHelper_SavedVariables.characterInfo) do
            if i.gb_mainCharacter == fullPlayerName then
                return "A"
            end
        end
        return "A"
    end
end

function GuildHelper:GetGuildNameFromSender(sender)
    -- Logic to determine the guild name from the sender
    -- This is a placeholder and should be replaced with actual logic
    return "No Rest For The Wicked-Eonar"
end

function GuildHelper:GetPlayersInChatChannel()
    local players = {}
    local chatData = GuildHelper.ChatPane:GetChatData()
    local chatChannel = chatData.chatchannel
    local channelId = tonumber(GuildHelper_SavedVariables.chatMemberId) or GetChannelName(chatChannel)

    -- print("GetPlayersInChatChannel called")
    -- print("Chat channel:", chatChannel)
    -- print("Channel ID:", channelId)

    if chatChannel and chatChannel ~= "" then
        if channelId and channelId > 0 then
            local numMembers = GetNumChannelMembers(channelId)
            -- print("Number of members in channel:", numMembers)
            if numMembers then
                for i = 1, numMembers do
                    local name, _, _, guid = C_ChatInfo.GetChannelRosterInfo(channelId, i)
                    --print("Member", i, ":", name, guid)
                    if name and guid then
                        local _, class = GetPlayerInfoByGUID(guid)
                        table.insert(players, { name = name, class = class or "UNKNOWN", guid = guid })
                    end
                end
            else
                -- print("No members found in channel ID:", channelId)
            end
        else
            -- print("Invalid channel ID:", channelId)
        end
    else
        -- print("Invalid chat channel:", chatChannel)
    end

    return players
end

-- Register event to receive messages and update player list
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
    if event == "CHAT_MSG_ADDON" and prefix == "GuildHelper" then
        GuildHelper.ChatPane:ReceiveMessage(prefix, text, channel, sender)
    else
        local chatData = GuildHelper.ChatPane:GetChatData()
        if channel == chatData.chatchannel then
            if event == "CHAT_MSG_CHANNEL" then
                GuildHelper.ChatPane:ReceiveMessage(text, sender)
            elseif event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
                GuildHelper.ChatPane:UpdatePlayerList()
            end
        end
    end
end)

C_ChatInfo.RegisterAddonMessagePrefix("GuildHelper")
