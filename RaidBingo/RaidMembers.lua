-- RaidMembers.lua
RaidBingo = RaidBingo or {}  -- Reference the main addon table if it exists

-- GM asked for list of regular raid members to promote to raid member in guild
-- Function to get the list of raid members
local function GetRaidMembers()
    local members = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            if name then
                table.insert(members, name)
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = (i == 1) and "player" or "party" .. (i - 1)
            local name = UnitName(unit)
            if name then
                table.insert(members, name)
            end
        end
    else
        print("You are not in a raid or party.")
        return members
    end
    return members
end

-- Function to export raid members to edit box
local function ExportRaidMembers()
    local members = GetRaidMembers()
    if #members > 0 then
        local memberList = table.concat(members, "\n")
        local frame = CreateFrame("Frame", "RaidMembersExportFrame", UIParent, "BackdropTemplate")
        frame:SetSize(420, 320)
        frame:SetPoint("CENTER")
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        local editBox = CreateFrame("EditBox", "RaidMembersExportEditBox", frame, "InputBoxTemplate")
        editBox:SetMultiLine(true)
        editBox:SetSize(400, 260)
        editBox:SetPoint("TOP", 0, -20)
        editBox:SetText(memberList)
        editBox:HighlightText()
        editBox:SetFocus()
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
        editBox:SetScript("OnShow", function(self) self:HighlightText() end)

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeButton:SetSize(100, 30)
        closeButton:SetPoint("BOTTOM", 0, 10)
        closeButton:SetText("Close")
        closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        frame:Show()
        print("Raid members copied to clipboard. You can now paste them into Excel.")
    else
        print("No raid members found.")
    end
end

-- Slash command to export raid members
SLASH_RBEXPORT1 = "/rbexport"
SlashCmdList["RBEXPORT"] = function()
    ExportRaidMembers()
end

print("RaidMembers.lua loaded")