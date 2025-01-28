-- RaidBingo.lua
local addonName = ...

-- Initialize the RaidBingo table
RaidBingo = RaidBingo or {}
RaidBingo.LeaderFrame = RaidBingo.LeaderFrame or {}
RaidBingo.MemberFrame = RaidBingo.MemberFrame or {}

-- Initialize the LibDBIcon library
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RaidBingo", {
    type = "launcher",
    text = "RaidBingo",
    icon = "Interface\\AddOns\\RaidBingo\\Textures\\minimap-icon64.tga",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if RaidBingoMemberFrame:IsShown() then
                RaidBingoMemberFrame:Hide()
            else
                RaidBingoMemberFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:SetText("Raid Bingo")
        tooltip:AddLine("Left-click to open the Member Interface.", 1, 1, 1)
    end,
})

local icon = LibStub("LibDBIcon-1.0")

-- Function to get the leader's name
local function GetLeaderName()
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if UnitIsGroupLeader("raid" .. i) then
                return UnitName("raid" .. i)
            end
        end
    elseif IsInGroup() then
        if UnitIsGroupLeader("player") then
            return UnitName("player")
        else
            for i = 1, GetNumGroupMembers() do
                local unit = "party" .. i
                if UnitIsGroupLeader(unit) then
                    return UnitName(unit)
                end
            end
        end
    else
        return UnitName("player")  -- For solo testing
    end
    return nil
end

-- Function to save the minimap button position
local function SaveMinimapButtonPosition()
    local x, y = icon:GetMinimapButtonPosition()
    RaidBingoData.minimapPos = { x = x, y = y }
end

-- Function to restore the minimap button position
local function RestoreMinimapButtonPosition()
    if RaidBingoData.minimapPos then
        icon:SetMinimapButtonPosition(RaidBingoData.minimapPos.x, RaidBingoData.minimapPos.y)
    end
end

-- Initialize the addon
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        C_ChatInfo.RegisterAddonMessagePrefix("RaidBingo")
        if not RaidBingoData then
            RaidBingoData = {}
        end
        if not RaidBingoData.minimap then
            RaidBingoData.minimap = { hide = false }
        end
        icon:Register("RaidBingo", LDB, RaidBingoData.minimap)
        RestoreMinimapButtonPosition()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)

-- Define InitializeLeader function
function RaidBingo:InitializeLeader()
    print("Initializing Leader Interface...")

    if not IsInGroup() then
        print("You are not in a group.")
        return
    end

    if not UnitIsGroupLeader("player") then
        print("You are not the raid/party leader.")
        return
    end

    if not RaidBingo.LeaderFrame then
        print("Loading RaidBingo_Leader addon...")
        LoadAddOn("RaidBingo_Leader")
    end

    if RaidBingo.LeaderFrame and RaidBingo.LeaderFrame.frame then
        print("Showing Leader Frame...")
        RaidBingo.LeaderFrame.frame:Show()
    else
        print("Error: Leader frame not found.")
    end
end

-- Define InitializeMember function
function RaidBingo:InitializeMember()
    if not RaidBingo.MemberFrame then
        LoadAddOn("RaidBingo_Member")
    end

    if RaidBingo.MemberFrame and RaidBingo.MemberFrame.frame then
        RaidBingo.MemberFrame.frame:Show()

    else
        print("Error: Member frame not found.")
    end
end

-- Define TestLeader function for testing purposes
function RaidBingo:TestLeader()
    print("Testing Leader Interface...")

    if not RaidBingo.LeaderFrame then
        print("Loading RaidBingo_Leader addon...")
        LoadAddOn("RaidBingo_Leader")
    end

    if RaidBingo.LeaderFrame and RaidBingo.LeaderFrame.frame then
        print("Showing Leader Frame for testing...")
        RaidBingo.LeaderFrame.frame:Show()
    else
        print("Error: Leader frame not found.")
    end
end

-- Register slash commands
SLASH_RAIDBINGO1 = "/raidbingo"
SLASH_RAIDBINGO2 = "/rb"
SLASH_RAIDBINGO3 = "/lbtest"
SlashCmdList["RAIDBINGO"] = function(msg)
    if msg == "leader" then
        RaidBingo:InitializeLeader()
    elseif msg == "member" then
        RaidBingo:InitializeMember()
    elseif msg == "lbtest" then
        RaidBingo:TestLeader()
    else
        print("Usage:")
        print("/raidbingo leader - Initialize leader interface")
        print("/raidbingo member - Initialize member interface")
        print("/lbtest - Test leader interface without being in a group")
    end
end