-- RaidBingo_Leader.lua
RaidBingo = RaidBingo or {}  -- Reference the main addon table if it exists
RaidBingo.LeaderFrame = RaidBingo.LeaderFrame or {}  -- Namespace for leader-specific variables

-- DO NOT REMOVE COMMENTS
-- Create the main frame for the leader interface, Top, Lower Left and Lower Right frames
-- Main window that contains the 3 frames will be centered on the screen, with a close button in the top right corner.
-- Top frame will have a title, Winning numbers, a roll button, a reset button next to the roll button and both centered next to each other.
-- The lower left frame will contain the member names, and numbers selected on their cards. Their matched numbers, as numbers are rolled will turn green.
-- The lower right frame will contain a field to enter the winning amount, if the winning field's value is a number we will calculate the winnings divided up by how many numbers are matched per player.
-- Winnings will be for 3 matched numbers a share of 10% of the total winnings, 4 matched numbers a share of 30% of the total winnings, 5 matched numbers a share of 60% of the total winnings.
-- Since the data will be saved in case the game crashed or the game UI is reloaded treat loading this leader frame in two ways. If there is data to load and how to process it and re-display the rolled numbers, members and their selected numbers.. or if the data was reset and the data is loaded for the first time.
-- Main window will have a close button in the top right corner to close the window. Needs to be movable.
-- The 3 frames need to meet each other. And the main window needs to be taller to support 25 members in the list.
-- All messages sent or received need to support Raid, Party or solo player for testing.
-- All loading of the interfaces need to support a clean no data load without nil errors or loading with saved data containing, rolled numbers, members' select numbers and matches to show the matches correctly in green text.
-- Example of the interface layout:
-- ------------------------------------------------------
-- |                        title                       |
-- ------------------------------------------------------
-- |         Giveaway Amount:   xxxxxxxxxxxx            |
-- |       Rolled numbers: 10,5,45,65,44                |
-- |                |Roll| |ResetGame|                  |
-- ------------------------------------------------------
-- |       Members         |        Winners             |
-- | member1,x,x,x,x,x     | Winner1, 3 matches - 1000  |
-- | member2,x,x,x,x,x     | Winner2, 5 matches - 60000 |

-- Create the main frame for the leader interface
RaidBingo.LeaderFrame.frame = CreateFrame("Frame", "RaidBingoLeaderFrame", UIParent, "BackdropTemplate")
RaidBingo.LeaderFrame.frame:SetSize(600, 800)  -- Increased height of the frame
RaidBingo.LeaderFrame.frame:SetPoint("CENTER")  -- Position it in the center of the screen
RaidBingo.LeaderFrame.frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
RaidBingo.LeaderFrame.frame:EnableMouse(true)
RaidBingo.LeaderFrame.frame:SetMovable(true)
RaidBingo.LeaderFrame.frame:RegisterForDrag("LeftButton")
RaidBingo.LeaderFrame.frame:SetScript("OnDragStart", RaidBingo.LeaderFrame.frame.StartMoving)
RaidBingo.LeaderFrame.frame:SetScript("OnDragStop", RaidBingo.LeaderFrame.frame.StopMovingOrSizing)
RaidBingo.LeaderFrame.frame:Hide()  -- Hide initially

-- Title for the Leader Interface
RaidBingo.LeaderFrame.title = RaidBingo.LeaderFrame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
RaidBingo.LeaderFrame.title:SetPoint("TOP", 0, -10)
RaidBingo.LeaderFrame.title:SetText("Raid Bingo Leader - FatherRahl/HereTanky - JB")

-- Close button
RaidBingo.LeaderFrame.closeButton = CreateFrame("Button", nil, RaidBingo.LeaderFrame.frame, "UIPanelCloseButton")
RaidBingo.LeaderFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Create the top frame for rolled numbers and controls
local topFrame = CreateFrame("Frame", nil, RaidBingo.LeaderFrame.frame, "BackdropTemplate")
topFrame:SetSize(580, 200)  -- Increased height by 40
topFrame:SetPoint("TOP", 0, -40)
topFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Rolled numbers display
RaidBingo.LeaderFrame.rolledNumbersText = topFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RaidBingo.LeaderFrame.rolledNumbersText:SetPoint("TOPLEFT", 20, -20)
RaidBingo.LeaderFrame.rolledNumbersText:SetText("Rolled Numbers:")

-- Scrolling text box for rolled numbers history
local scrollFrame = CreateFrame("ScrollFrame", nil, topFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(540, 100)  -- Increased height by 20
scrollFrame:SetPoint("TOPLEFT", 20, -40)


local rolledNumbersBox = CreateFrame("EditBox", nil, scrollFrame)
rolledNumbersBox:SetMultiLine(true)
rolledNumbersBox:SetFontObject(GameFontNormal)
rolledNumbersBox:SetWidth(540)
rolledNumbersBox:SetAutoFocus(false)
rolledNumbersBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
scrollFrame:SetScrollChild(rolledNumbersBox)

-- Data structure to store rolled numbers
RaidBingo.LeaderFrame.rolledNumbers = RaidBingo.LeaderFrame.rolledNumbers or {}  -- Ensure rolledNumbers is initialized
RaidBingo.LeaderFrame.rolledNumbersConfirmed = RaidBingo.LeaderFrame.rolledNumbersConfirmed or {}  -- Ensure rolledNumbersConfirmed is initialized

-- Data structure to store selected numbers for each member
RaidBingo.LeaderFrame.memberSelections = RaidBingo.LeaderFrame.memberSelections or {}

-- Function to update member selections display
local function UpdateMemberSelections()
    local displayText = ""
    for member, numbers in pairs(RaidBingo.LeaderFrame.memberSelections) do
        local matchedNumbers = {}
        for _, number in ipairs(numbers) do
            if RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] then
                table.insert(matchedNumbers, "|cff00ff00" .. number .. "|r")  -- Green color for matched numbers
            else
                table.insert(matchedNumbers, number)
            end
        end
        displayText = displayText .. member .. ": " .. table.concat(matchedNumbers, ", ") .. "\n"
    end
    RaidBingo.LeaderFrame.selectedNumbersDisplay:SetText(displayText)
end

-- Function to update rolled numbers display
local function UpdateRolledNumbers()
    rolledNumbersBox:SetText(table.concat(RaidBingo.LeaderFrame.rolledNumbers, ", "))
    UpdateMemberSelections()
end

-- Function to send roll message
local function SendRollMessage(number)
    local channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER"
    local target = channel == "WHISPER" and UnitName("player") or nil
    C_ChatInfo.SendAddonMessage("RaidBingo", "ROLLED:" .. number, channel, target)
    -- Start a timer to check for confirmation
    C_Timer.After(5, function()
        if not RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] then
            SendChatMessage("Warning: No confirmation received for rolled number " .. number, "WHISPER", nil, UnitName("player"))
        end
    end)
end

-- Function to send reset message
local function SendResetMessage()
    local channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER"
    local target = channel == "WHISPER" and UnitName("player") or nil
    C_ChatInfo.SendAddonMessage("RaidBingo", "RESET", channel, target)
    -- Start a timer to check for confirmation
    C_Timer.After(5, function()
        if not RaidBingo.LeaderFrame.resetConfirmed then
            SendChatMessage("Warning: No confirmation received for reset message", "WHISPER", nil, UnitName("player"))
        end
    end)
end

-- Roll button
RaidBingo.LeaderFrame.rollButton = CreateFrame("Button", nil, topFrame, "UIPanelButtonTemplate")
RaidBingo.LeaderFrame.rollButton:SetSize(100, 40)
RaidBingo.LeaderFrame.rollButton:SetPoint("TOPLEFT", 20, -150)  -- Adjusted position
RaidBingo.LeaderFrame.rollButton:SetText("Roll")
RaidBingo.LeaderFrame.rollButton:SetScript("OnClick", function()
    local number = math.random(1, 75)
    if not RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] then
        table.insert(RaidBingo.LeaderFrame.rolledNumbers, number)
        RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] = true
        UpdateRolledNumbers()
        SendRollMessage(number)
    end
end)

-- Reset button
RaidBingo.LeaderFrame.resetButton = CreateFrame("Button", nil, topFrame, "UIPanelButtonTemplate")
RaidBingo.LeaderFrame.resetButton:SetSize(100, 40)
RaidBingo.LeaderFrame.resetButton:SetPoint("LEFT", RaidBingo.LeaderFrame.rollButton, "RIGHT", 20, 0)
RaidBingo.LeaderFrame.resetButton:SetText("Reset Game")
RaidBingo.LeaderFrame.resetButton:SetScript("OnClick", function()
    RaidBingo.LeaderFrame.rolledNumbers = {}
    RaidBingo.LeaderFrame.rolledNumbersConfirmed = {}
    RaidBingo.LeaderFrame.memberSelections = {}
    RaidBingo.LeaderFrame.winnersDisplay:SetText("Winners:")  -- Clear the winners display
    UpdateRolledNumbers()
    UpdateMemberSelections()
    SendResetMessage()
end)

-- Event handler function
local function OnEvent(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "RaidBingo" then
        local command, param1 = strsplit(":", message)
        if command == "CONFIRMED" then
            if param1 == "RESET" then
                RaidBingo.LeaderFrame.resetConfirmed = true
            else
                local number = tonumber(param1)
                if number then
                    RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] = true
                end
            end
        elseif command == "SELECTED" then
            local numbers = {strsplit(",", param1)}
            for i, num in ipairs(numbers) do
                numbers[i] = tonumber(num)
            end
            RaidBingo.LeaderFrame.memberSelections[sender] = numbers
            UpdateMemberSelections()
        end
    end
end

-- Register the event handler for receiving messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", OnEvent)
C_ChatInfo.RegisterAddonMessagePrefix("RaidBingo")

-- Create the lower left frame for member names and selected numbers
local lowerLeftFrame = CreateFrame("Frame", nil, RaidBingo.LeaderFrame.frame, "BackdropTemplate")
lowerLeftFrame:SetSize(305, 540) -- Adjusted size to fit within the main frame
lowerLeftFrame:SetPoint("BOTTOMLEFT", RaidBingo.LeaderFrame.frame, "BOTTOMLEFT", 5, 10)  -- Adjusted position to fit within the main frame
lowerLeftFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Placeholder to display selected numbers from each player
RaidBingo.LeaderFrame.selectedNumbersDisplay = lowerLeftFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RaidBingo.LeaderFrame.selectedNumbersDisplay:SetPoint("TOPLEFT", 10, -10)
RaidBingo.LeaderFrame.selectedNumbersDisplay:SetText("Player Selections:")

-- Create the lower right frame for entering the winning amount
local lowerRightFrame = CreateFrame("Frame", nil, RaidBingo.LeaderFrame.frame, "BackdropTemplate")
lowerRightFrame:SetSize(305, 540) -- Adjusted size to fit within the main frame
lowerRightFrame:SetPoint("BOTTOMRIGHT", RaidBingo.LeaderFrame.frame, "BOTTOMRIGHT", -5, 10)  -- Adjusted position to fit within the main frame
lowerRightFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Title for the Winners Frame
local winnersTitle = lowerRightFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
winnersTitle:SetPoint("TOP", 0, -10)
winnersTitle:SetText("GiveAway Winnings")

-- Field to enter the winning amount
local winningAmountEditBox = CreateFrame("EditBox", nil, lowerRightFrame, "InputBoxTemplate")
winningAmountEditBox:SetSize(120, 30)
winningAmountEditBox:SetPoint("TOPLEFT", 20, -40)
winningAmountEditBox:SetAutoFocus(false)
winningAmountEditBox:SetNumeric(true)
winningAmountEditBox:SetMaxLetters(10)
winningAmountEditBox:SetText("Enter Winnings")

-- Placeholder to display winners and their winnings
RaidBingo.LeaderFrame.winnersDisplay = lowerRightFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RaidBingo.LeaderFrame.winnersDisplay:SetPoint("TOPLEFT", 20, -120)
RaidBingo.LeaderFrame.winnersDisplay:SetText("Winners:")

-- Function to calculate and display winnings
local function CalculateWinnings()
    local totalWinnings = tonumber(winningAmountEditBox:GetText())
    if totalWinnings then
        local winningsText = "Winners:\n"
        local winners = { [3] = {}, [4] = {}, [5] = {} }
        local matchCounts = { [3] = 0, [4] = 0, [5] = 0 }

        -- Count the number of players with 3, 4, and 5 matches
        for member, numbers in pairs(RaidBingo.LeaderFrame.memberSelections) do
            local matchCount = 0
            for _, number in ipairs(numbers) do
                if RaidBingo.LeaderFrame.rolledNumbersConfirmed[number] then
                    matchCount = matchCount + 1
                end
            end
            if matchCount >= 3 then
                table.insert(winners[matchCount], member)
                matchCounts[matchCount] = matchCounts[matchCount] + 1
            end
        end

        -- Calculate the share for each match count
        local shares = {
            [3] = (totalWinnings * 0.10) / (matchCounts[3] > 0 and matchCounts[3] or 1),
            [4] = (totalWinnings * 0.30) / (matchCounts[4] > 0 and matchCounts[4] or 1),
            [5] = (totalWinnings * 0.60) / (matchCounts[5] > 0 and matchCounts[5] or 1)
        }

        -- Adjust shares if there are no 3 or 4 matched winners
        if matchCounts[3] == 0 then
            shares[5] = shares[5] + (totalWinnings * 0.10)
        end
        if matchCounts[4] == 0 then
            shares[5] = shares[5] + (totalWinnings * 0.30)
        end

        -- Distribute the winnings
        for matchCount, members in pairs(winners) do
            for _, member in ipairs(members) do
                winningsText = winningsText .. member .. ": " .. matchCount .. " matches - " .. shares[matchCount] .. "\n"
            end
        end

        RaidBingo.LeaderFrame.winnersDisplay:SetText(winningsText)
    else
        print("Please enter a valid number for winnings.")
    end
end

-- Button to calculate winnings
local calculateWinningsButton = CreateFrame("Button", nil, lowerRightFrame, "UIPanelButtonTemplate")
calculateWinningsButton:SetSize(130, 30)
calculateWinningsButton:SetPoint("TOPLEFT", 15, -80)
calculateWinningsButton:SetText("Calculate Winnings")
calculateWinningsButton:SetScript("OnClick", CalculateWinnings)

-- Function to post winner information to chat
local function PostWinnersToChat()
    local channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER"
    local target = channel == "WHISPER" and UnitName("player") or nil
    local winnersText = RaidBingo.LeaderFrame.winnersDisplay:GetText()
    if winnersText and winnersText ~= "Winners:" then
        for line in winnersText:gmatch("[^\r\n]+") do
            SendChatMessage(line, channel, nil, target)
        end
    else
        print("No winners to post.")
    end
end

-- Button to post winners to chat
local postWinnersButton = CreateFrame("Button", nil, lowerRightFrame, "UIPanelButtonTemplate")
postWinnersButton:SetSize(130, 30)
postWinnersButton:SetPoint("LEFT", calculateWinningsButton, "RIGHT", 10, 0)
postWinnersButton:SetText("Post Winners")
postWinnersButton:SetScript("OnClick", PostWinnersToChat)

print("RaidBingo_Leader.lua loaded")