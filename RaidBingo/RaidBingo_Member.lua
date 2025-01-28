-- RaidBingo_Member.lua
RaidBingo = RaidBingo or {}  -- Reference the main addon table if it exists
RaidBingo.MemberFrame = RaidBingo.MemberFrame or {}  -- Namespace for member-specific variables

-- DO NOT REMOVE COMMENTS
-- Create the main frame for the member interface
-- Main window is a single frame with a title at top, card deck in the middle and a roll new card button in the bottom center.
-- The card deck will be a 5x5 grid of buttons, each representing a number from 1 to 75.
-- 
-- Example of the interface layout:
-- ------------------------------------------------------
-- |                        title                       |
-- |                                                    |
-- |         Leader rolled numbers x,x,x,x,x            |
-- |                                                    |
-- |            14   25   36   47   58                  |
-- |            13   24   35   46   57                  |
-- |            12   23   Star 45   56                  |
-- |            11   22   33   44   55                  |
-- |            10   21   32   43   54                  |
-- |                                                    |
-- |                                                    |
-- |                  Roll new card                     |
-- |                                                    |
-- ------------------------------------------------------

-- Selected number buttons will show a checkmark
-- When the fifth number is selected the card locks and the member name and numbers are sent to the leader.
-- As the leader interface will send the rolled numbers to the members' interface as each are rolled and the numbers and checkmarks will turn green if a matched number is rolled.
-- The rolled numbers and selected cards will be saved data so if it crashes or the UI is reloaded when the member interface it loaded it will display the same card with its selected numbers.
-- If the leader interface issues a reset message the card will reset its data and unload the cards selected numbers and matches.
-- The member interface needs to handle loading the data and displaying the card with the selected numbers and matches if data is saved or if the data is reset and the card is loaded for the first time.
-- The member interface will have a close button in the top right corner to close the window. Needs to be movable.
-- All messages sent or received need to support Raid, Party or solo player for testing.
-- All loading of the interfaces need to support a clean no data load without nil errors or loading with saved data containing, rolled numbers, members' select numbers\checkmarks and matches to show the matches correctly in green text.
-- The center number button will always be a star icon to indicate a free space. It will need to be handled correctly when saving or loading saved data or resetting the cards.

-- Create the main frame for the member interface
RaidBingo.MemberFrame.frame = CreateFrame("Frame", "RaidBingoMemberFrame", UIParent, "BackdropTemplate")
RaidBingo.MemberFrame.frame:SetSize(600, 800)  -- Increased size of the frame
RaidBingo.MemberFrame.frame:SetPoint("CENTER")  -- Position it in the center of the screen
RaidBingo.MemberFrame.frame:SetBackdrop({
    bgFile = "Interface\\AddOns\\RaidBingo\\textures\\bingocard.tga",  -- Set the bingo card texture as the background
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = false, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
RaidBingo.MemberFrame.frame:EnableMouse(true)
RaidBingo.MemberFrame.frame:SetMovable(true)
RaidBingo.MemberFrame.frame:RegisterForDrag("LeftButton")
RaidBingo.MemberFrame.frame:SetScript("OnDragStart", RaidBingo.MemberFrame.frame.StartMoving)
RaidBingo.MemberFrame.frame:SetScript("OnDragStop", RaidBingo.MemberFrame.frame.StopMovingOrSizing)
RaidBingo.MemberFrame.frame:Hide()  -- Hide initially

-- Title for the Member Interface
RaidBingo.MemberFrame.title = RaidBingo.MemberFrame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
RaidBingo.MemberFrame.title:SetPoint("TOP", 0, -10)
RaidBingo.MemberFrame.title:SetText("Raid Bingo Member - FatherRahl/HereTanky - JB")
RaidBingo.MemberFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
RaidBingo.MemberFrame.title:SetTextColor(0, 0, 0)  -- Set text color to black

-- Close button
RaidBingo.MemberFrame.closeButton = CreateFrame("Button", nil, RaidBingo.MemberFrame.frame, "UIPanelCloseButton")
RaidBingo.MemberFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Rolled numbers display
RaidBingo.MemberFrame.rolledNumbersText = RaidBingo.MemberFrame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RaidBingo.MemberFrame.rolledNumbersText:SetPoint("TOP", 0, -225)  -- Moved down by 250
RaidBingo.MemberFrame.rolledNumbersText:SetText("Rolled Numbers:")
RaidBingo.MemberFrame.rolledNumbersText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
RaidBingo.MemberFrame.rolledNumbersText:SetTextColor(0, 0, 0)  -- Set text color to black

-- Scrolling text box for rolled numbers history
local scrollFrame = CreateFrame("ScrollFrame", nil, RaidBingo.MemberFrame.frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(360, 80)  -- Adjusted width
scrollFrame:SetPoint("TOP", 0, -245)  -- Moved down by 250

local rolledNumbersBox = CreateFrame("EditBox", nil, scrollFrame)
rolledNumbersBox:SetMultiLine(true)
rolledNumbersBox:SetFontObject(GameFontNormal)
rolledNumbersBox:SetWidth(360)
rolledNumbersBox:SetAutoFocus(false)
rolledNumbersBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
scrollFrame:SetScrollChild(rolledNumbersBox)

-- Data structure to store rolled numbers
RaidBingo.MemberFrame.rolledNumbers = RaidBingo.MemberFrame.rolledNumbers or {}  -- Ensure rolledNumbers is initialized
RaidBingo.MemberFrame.processedNumbers = RaidBingo.MemberFrame.processedNumbers or {}  -- Ensure processedNumbers is initialized

-- Function to update rolled numbers display
local function UpdateRolledNumbers()
    rolledNumbersBox:SetText(table.concat(RaidBingo.MemberFrame.rolledNumbers, ", "))
end

-- Function to check if the card should be locked
local function CheckCardLock()
    if selectedNumbers >= 5 then
        cardLocked = true
        RaidBingo.MemberFrame.rollNewCardButton:Disable()
        -- Send the selected numbers to the leader
        local selectedNumbersList = {}
        for _, button in ipairs(RaidBingo.MemberFrame.cardButtons) do
            if button:GetNormalTexture() then
                table.insert(selectedNumbersList, button:GetText())
            end
        end
        C_ChatInfo.SendAddonMessage("RaidBingo", "SELECTED:" .. table.concat(selectedNumbersList, ","), IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER", UnitName("player"))
    end
end

-- Function to create the card deck
local function CreateCardDeck()
    -- Clear previous buttons
    RaidBingo.MemberFrame.cardButtons = RaidBingo.MemberFrame.cardButtons or {}
    for _, button in ipairs(RaidBingo.MemberFrame.cardButtons) do
        button:Hide()
    end
    RaidBingo.MemberFrame.cardButtons = {}

    local buttonIndex = 1
    for row = 1, 5 do
        for col = 1, 5 do
            if not (row == 3 and col == 3) then  -- Skip the center button
                local button = CreateFrame("Button", nil, RaidBingo.MemberFrame.frame, "UIPanelButtonTemplate")
                button:SetSize(60, 60)  -- Increased size
                button:SetPoint("TOPLEFT", 135 + (col - 1) * 70, -320 - (row - 1) * 70)  -- Adjusted position
                button:SetText("")
                button:SetNormalFontObject("GameFontNormalLarge")
                button:SetHighlightFontObject("GameFontHighlightLarge")
                button:SetScript("OnClick", function(self)
                    if cardLocked then return end
                    if self:GetNormalTexture() then
                        self:SetNormalTexture("Interface\\Buttons\\WHITE8X8")  -- Set to a blank texture
                        selectedNumbers = selectedNumbers - 1
                    else
                        self:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
                        selectedNumbers = selectedNumbers + 1
                        CheckCardLock()
                    end
                end)
                RaidBingo.MemberFrame.cardButtons[buttonIndex] = button
                buttonIndex = buttonIndex + 1
            end
        end
    end

    -- Add the star icon in the center
    local centerIcon = RaidBingo.MemberFrame.frame:CreateTexture(nil, "ARTWORK")
    centerIcon:SetSize(60, 60)  -- Increased size
    centerIcon:SetPoint("TOPLEFT", 135 + (3 - 1) * 70, -320 - (3 - 1) * 70)  -- Adjusted position
    centerIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
end

-- Roll new card button
RaidBingo.MemberFrame.rollNewCardButton = CreateFrame("Button", nil, RaidBingo.MemberFrame.frame, "UIPanelButtonTemplate")
RaidBingo.MemberFrame.rollNewCardButton:SetSize(120, 40)
RaidBingo.MemberFrame.rollNewCardButton:SetPoint("BOTTOM", 0, 20)
RaidBingo.MemberFrame.rollNewCardButton:SetText("Roll New Card")

-- Function to roll a new card
local function RollNewCard()
    if cardLocked then return end
    CreateCardDeck()

    -- Generate new card numbers
    local numbers = {}
    for i = 1, 75 do
        table.insert(numbers, i)
    end
    for i = 1, 24 do  -- 24 buttons excluding the center
        local index = math.random(#numbers)
        RaidBingo.MemberFrame.cardButtons[i]:SetText(numbers[index])
        table.remove(numbers, index)
    end
    selectedNumbers = 0
end

RaidBingo.MemberFrame.rollNewCardButton:SetScript("OnClick", RollNewCard)

-- Event handler function
local function OnEvent(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "RaidBingo" and sender ~= UnitName("player") then
        local command, param1 = strsplit(":", message)
        if command == "ROLLED" then
            local number = tonumber(param1)
            if number and number ~= 0 and not RaidBingo.MemberFrame.processedNumbers[number] then
                table.insert(RaidBingo.MemberFrame.rolledNumbers, number)
                RaidBingo.MemberFrame.processedNumbers[number] = true
                UpdateRolledNumbers()
                -- Update card buttons to show matched numbers in green
                for _, button in ipairs(RaidBingo.MemberFrame.cardButtons) do
                    if tonumber(button:GetText()) == number and button:GetNormalTexture() then
                        button:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")  -- Set to a green checkmark texture
                    end
                end
                -- Send confirmation back to the leader
                C_ChatInfo.SendAddonMessage("RaidBingo", "CONFIRMED:" .. number, IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER", UnitName("player"))
            end
        elseif command == "RESET" then
            -- Reset the card
            RaidBingo.MemberFrame.rolledNumbers = {}
            RaidBingo.MemberFrame.processedNumbers = {}
            UpdateRolledNumbers()
            RollNewCard()  -- Reset the bingo card
            cardLocked = false
            RaidBingo.MemberFrame.rollNewCardButton:Enable()
            -- Send confirmation back to the leader
            C_ChatInfo.SendAddonMessage("RaidBingo", "CONFIRMED:RESET", IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "WHISPER", UnitName("player"))
        end
    end
end

-- Register the event handler for receiving messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", OnEvent)
C_ChatInfo.RegisterAddonMessagePrefix("RaidBingo")

-- Load saved data if available
local function LoadSavedData()
    -- Load saved rolled numbers
    if RaidBingo_SavedVariables and RaidBingo_SavedVariables.rolledNumbers then
        RaidBingo.MemberFrame.rolledNumbers = RaidBingo_SavedVariables.rolledNumbers
        UpdateRolledNumbers()
    end

    -- Load saved card numbers
    if RaidBingo.SavedVariables and RaidBingo.SavedVariables.cardNumbers then
        CreateCardDeck()
        for i, number in ipairs(RaidBingo.SavedVariables.cardNumbers) do
            RaidBingo.MemberFrame.cardButtons[i]:SetText(number)
        end
    else
        RollNewCard()
    end
end

-- Save data before logout or reload
local function SaveData()
    RaidBingo_SavedVariables = {
        rolledNumbers = RaidBingo.MemberFrame.rolledNumbers,
        cardNumbers = {}
    }
    for _, button in ipairs(RaidBingo.MemberFrame.cardButtons) do
        table.insert(RaidBingo.SavedVariables.cardNumbers, button:GetText())
    end
end

-- Register events for saving data
local saveEventFrame = CreateFrame("Frame")
saveEventFrame:RegisterEvent("PLAYER_LOGOUT")
saveEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
saveEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        SaveData()
    elseif event == "PLAYER_ENTERING_WORLD" then
        LoadSavedData()
    end
end)


-- Create the disclaimer box
local function CreateDisclaimer()
    local disclaimerFrame = CreateFrame("Frame", "RaidBingoDisclaimerFrame", UIParent, "BackdropTemplate")
    disclaimerFrame:SetSize(400, 200)  -- Set size of the frame
    disclaimerFrame:SetPoint("CENTER")  -- Position it in the center of the screen
    disclaimerFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    disclaimerFrame:EnableMouse(true)
    disclaimerFrame:SetMovable(true)
    disclaimerFrame:RegisterForDrag("LeftButton")
    disclaimerFrame:SetScript("OnDragStart", disclaimerFrame.StartMoving)
    disclaimerFrame:SetScript("OnDragStop", disclaimerFrame.StopMovingOrSizing)

    -- Disclaimer text
    local disclaimerText = disclaimerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disclaimerText:SetPoint("TOPLEFT", 20, -20)
    disclaimerText:SetPoint("BOTTOMRIGHT", -20, 40)
    disclaimerText:SetJustifyH("LEFT")
    disclaimerText:SetJustifyV("TOP")
    disclaimerText:SetText("Note: This is not a traditional Bingo game.  Its been adjusted to work with the UI and a Raids/Party.  Pick 5 numbers after the Raid Lead has loaded their interface. \n \n Disclaimer: This is a zero risk or stakes game for raid members. You are not allowed to buy in or exchange anything of value to play. This is a giveaway for raid members who consistently play with the raid group. To be eligible for the giveaway, you must be present for the entire raid and be a regular, showing up for at least 6 raids a month. The winner will be selected at the end of the raid once a month. The winner will be given a prize of one or more of the following: gold, gear, or gifts. If you have any questions or concerns, please contact the raid leader.")

    -- Close button for the disclaimer
    local disclaimerCloseButton = CreateFrame("Button", nil, disclaimerFrame, "UIPanelButtonTemplate")
    disclaimerCloseButton:SetSize(100, 30)
    disclaimerCloseButton:SetPoint("BOTTOM", 0, 10)
    disclaimerCloseButton:SetText("Close")
    disclaimerCloseButton:SetScript("OnClick", function()
        disclaimerFrame:Hide()
    end)

    -- Auto close after 30 seconds
    C_Timer.After(30, function()
        disclaimerFrame:Hide()
    end)

    disclaimerFrame:Show()
end

-- Show the disclaimer when the member frame is shown
RaidBingo.MemberFrame.frame:SetScript("OnShow", CreateDisclaimer)

print("RaidBingo_Member.lua loaded")