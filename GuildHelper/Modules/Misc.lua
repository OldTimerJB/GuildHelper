-- Manages data sync communications between clients.
-- Handles sending and receiving data chunks and addon messages.

GuildHelper = GuildHelper or {}
GuildHelper.Misc = GuildHelper.Misc or {}

-- Function to export raid members to edit box
local function ExportRaidMembers()
    local raidInfo = {}
    local date = date("%Y-%m-%d")
    
    -- Add header line
    table.insert(raidInfo, "Name,Rank,Subgroup,Level,Class,Zone,Role,Date")
    
    for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
        local roleText = role == "MAINTANK" and "Tank" or role == "MAINASSIST" and "Healer" or "DPS"
        table.insert(raidInfo, string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s", name or "Unknown", rank or "Unknown", subgroup or "Unknown", level or "Unknown", class or "Unknown", classFileName or "Unknown", zone or "Unknown", roleText or "Unknown", date))
    end
    
    if #raidInfo > 1 then  -- Check if there are any members besides the header
        local memberList = table.concat(raidInfo, "\n")
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

-- Register the slash command
SLASH_GHREXPORT1 = "/ghrexport"
SlashCmdList["GHREXPORT"] = function()
    ExportRaidMembers()
end
