--[[
    MumbleFrame.lua — GUI for Mumble Transcriptor
]]

-- L is global, set in Mumble.lua
local playerKey = Mumble.GetPlayerKey()

-- ── Zone helpers ─────────────────────────────────────────────────────────────

local function GetZoneKeys()
    local keys = {}
    local db = CHAT_MSG_LOG_DB[playerKey]
    if not db then return keys end
    for k in pairs(db) do
        if k ~= "__config" then tinsert(keys, k) end
    end
    sort(keys)
    return keys
end

local function GetZoneDB(zoneKey)
    if not zoneKey then return nil end
    return CHAT_MSG_LOG_DB[playerKey] and CHAT_MSG_LOG_DB[playerKey][zoneKey]
end

local function GetZoneNPCs(zoneKey)
    local zd = GetZoneDB(zoneKey)
    if not zd then return {} end
    local list = {}
    for k in pairs(zd) do
        if k ~= "__timeline" and k ~= "__seen" then tinsert(list, k) end
    end
    sort(list)
    return list
end

-- Chat colors by raw event name; looked up by GetTagColor()
local eventColors = {
    ["CHAT_MSG_MONSTER_SAY"] = "FFFF9F",
    ["CHAT_MSG_MONSTER_YELL"] = "FF4040",
    ["CHAT_MSG_MONSTER_WHISPER"] = "FFB5EB",
    ["CHAT_MSG_MONSTER_EMOTE"] = "FF8040",
    ["CHAT_MSG_MONSTER_PARTY"] = "AAAFFF",
    ["CHAT_MSG_RAID_BOSS_EMOTE"] = "FFDD00",
    ["CHAT_MSG_RAID_BOSS_WHISPER"] = "FFDD00",
}

local tagColors = {}
local tagColorsReady = false

local function GetTagColor(tag)
	if not tagColorsReady then
		tagColorsReady = true
		for event, color in pairs(eventColors) do
			local t = L['CHAT_MSG_' .. event]
			if t then tagColors[t] = color end
		end
	end
	return tagColors[tag] or "FFFFFF"
end

-- Zone name grouping

local zoneNameGroups = {}

local function BuildZoneNameList()
    zoneNameGroups = {}
    local keys = GetZoneKeys()
    for _, zk in ipairs(keys) do
        local idStr, name = zk:match("^(%d+)@(.+)$")
        local mapID = idStr and tonumber(idStr)
        local key
        if mapID and C_Map.GetMapGroupID then
            local gid = C_Map.GetMapGroupID(mapID)
            if gid and gid > 0 then
                key = "mg:" .. gid
            else
                key = "id:" .. mapID
            end
        elseif mapID then
            key = "id:" .. mapID
        else
            key = name or zk
        end
        local label = name or zk
        if not zoneNameGroups[key] then
            zoneNameGroups[key] = { label = label, keys = {} }
        else
            local curLabel = zoneNameGroups[key].label
            if curLabel:find("Instance") and not label:find("Instance") then
                zoneNameGroups[key].label = label
            end
        end
        tinsert(zoneNameGroups[key].keys, zk)
    end
end

-- Display refresh

local function RefreshTimeline()
    local text = MumbleFrame and MumbleFrame.scrollText
    if not text then return end

    local zoneKeys = MumbleFrame and MumbleFrame._selZoneKeys
    if not zoneKeys or #zoneKeys == 0 then
        text:SetText(L['select_zone'])
        return
    end

    local hideTS = Mumble.GetConfig().hideTimestamp
    local filterNPC = MumbleFrame.selectedNPC

    local lines = {}
    local showDivider = #zoneKeys > 1
    local bestKeyForID = {}
    for _, zk in ipairs(zoneKeys) do
        local id = zk:match("^(%d+)@")
        if id then
            if not bestKeyForID[id] or (bestKeyForID[id]:find("Instance") and not zk:find("Instance")) then
                bestKeyForID[id] = zk
            end
        end
    end

    local seenIDs = {}
    for _, zk in ipairs(zoneKeys) do
        local id = zk:match("^(%d+)@")
        local isNewID = id and not seenIDs[id]
        if id then seenIDs[id] = true end

        local zd = GetZoneDB(zk)
        local keyLines = {}
        if zd and zd.__timeline then
            for _, line in ipairs(zd.__timeline) do
                local match = true
                local _, _, who = line:find("%[.-%]%[([^%]]+)")
                if filterNPC then
                    if who ~= filterNPC then match = false end
                end
                if match then
                    local display = line
                    if hideTS then
                        display = display:gsub("^%[%d+-%d+-%d+ %d+:%d+:%d+%]", "")
                        local _, _, tag = display:find("%[.-%]%[([^%]]+)")
                        local color = GetTagColor(tag)
                        tinsert(keyLines, "|cFF" .. color .. display .. "|r")
                    else
                        local tsEnd = display:find("%]")
                        local ts = tsEnd and display:sub(1, tsEnd) or ""
                        local rest = tsEnd and display:sub(tsEnd + 1) or display
                        local _, _, tag = rest:find("%[.-%]%[([^%]]+)")
                        local color = GetTagColor(tag)
                        tinsert(keyLines, "|cFFAAAAAA" .. ts .. "|r|cFF" .. color .. rest .. "|r")
                    end
                end
            end
        end
        if #keyLines > 0 then
            if showDivider and isNewID then
                local displayKey = bestKeyForID[id] or zk
                tinsert(lines, ("|cFF888888" .. L['divider'] .. "|r"):format(displayKey))
            end
            for _, colored in ipairs(keyLines) do
                tinsert(lines, colored)
            end
        end
    end

    local content = #lines > 0 and table.concat(lines, "\n") or L['no_records']
    text:SetText(content)

    local ts = MumbleFrame and MumbleFrame.textScroll
    if ts and ts:GetHeight() and ts:GetHeight() > 0 then
        local lineH = (text:GetFont() and select(2, text:GetFont())) or 14
        local numLines = select(2, content:gsub("\n", "\n")) + 1
        text:SetHeight(math.max(ts:GetHeight(), numLines * (lineH + 1) + 8))
    end
end

-- Refresh zone dropdown

local function RefreshZoneDropdown()
    local dd = MumbleFrame and MumbleFrame.zoneDD
    if not dd then return end

    BuildZoneNameList()
    local groupLabels = {}
    local groupRef = {}
    for _, g in pairs(zoneNameGroups) do
        local id = g.keys[1]:match("^(%d+)@")
        local label
        if #g.keys > 1 then
            label = (id or "") .. "@" .. g.label .. L['group_suffix']
        else
            label = g.keys[1]
        end
        groupLabels[label] = label
        groupRef[label] = g.keys
    end

    local labels = {}
    for label in pairs(groupLabels) do tinsert(labels, label) end
    sort(labels)

    local list = {}
    for _, label in ipairs(labels) do list[label] = label end
    dd:SetList(list)
    if #labels == 0 then return end

    local cur = Mumble.GetCurrentZoneKey()
    local defaultLabel = nil
    if cur then
        for _, label in ipairs(labels) do
            local keys = groupRef[label]
            for _, k in ipairs(keys) do
                if k == cur then defaultLabel = label; break end
            end
            if defaultLabel then break end
        end
    end
    if not defaultLabel then defaultLabel = labels[1] end

    MumbleFrame._groupRef = groupRef
    dd:SetValue(defaultLabel)
end

-- Refresh NPC dropdown

local function RefreshNPCDropdown()
    local dd = MumbleFrame and MumbleFrame.npcDD
    if not dd then return end
    local zoneKeys = MumbleFrame and MumbleFrame._selZoneKeys
    local allNPCs = {}
    for _, zk in ipairs(zoneKeys or {}) do
        for _, name in ipairs(GetZoneNPCs(zk)) do
            allNPCs[name] = true
        end
    end
    local npcs = {}
    for name in pairs(allNPCs) do tinsert(npcs, name) end
    sort(npcs)

    local list = { [L['all_npc']] = L['all_npc'] }
    for _, name in ipairs(npcs) do list[name] = name end
    dd:SetList(list)
    if MumbleFrame.selectedNPC and list[MumbleFrame.selectedNPC] then
        dd:SetValue(MumbleFrame.selectedNPC)
    else
        MumbleFrame.selectedNPC = nil
        dd:SetValue(L['all_npc'])
    end
end

-- AceGUI setup

local AceGUI = LibStub("AceGUI-3.0")

-- Main frame creation

function Mumble.OpenGUI()
    if MumbleFrame then
        MumbleFrame:Show()
        RefreshZoneDropdown()
        if MumbleFrame.OnZoneChanged then
            local dd = MumbleFrame.zoneDD
            if dd then MumbleFrame.OnZoneChanged(dd:GetValue()) end
        end
        return
    end

    local frame = CreateFrame("Frame", "MumbleFrame", UIParent, "BackdropTemplate")
    frame:SetSize(900, 600)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetClipsChildren(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.selectedZoneKey = nil
    frame.selectedNPC = nil

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(L['title'])
    title:SetTextColor(1, 0.82, 0)

    -- Close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Zone dropdown (AceGUI)
    local zoneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -44)
    zoneLabel:SetText(L['zone_label'])

    local function UpdateClearBtn()
        local btn = MumbleFrame and MumbleFrame._clearBtn
        if btn then
            btn:SetText(MumbleFrame.selectedNPC and L['clear_npc'] or L['clear_current'])
        end
    end

    local function OnZoneChanged(name)
        if not name then return end
        local ref = MumbleFrame and MumbleFrame._groupRef
        local keys = ref and ref[name]
        if keys and #keys > 0 then
            MumbleFrame.selectedZoneKey = keys[1]
            MumbleFrame._selZoneKeys = keys
        end
        MumbleFrame.selectedNPC = nil
        RefreshNPCDropdown()
        RefreshTimeline()
        UpdateClearBtn()
    end

    local zoneDD = AceGUI:Create("Dropdown")
    zoneDD:SetWidth(300)
    zoneDD.frame:SetParent(frame)
    zoneDD.frame:ClearAllPoints()
    zoneDD.frame:SetPoint("TOPLEFT", zoneLabel, "TOPRIGHT", 4, -3)
    zoneDD.frame:SetHeight(22)
    zoneDD:SetCallback("OnValueChanged", function(widget, event, name)
        OnZoneChanged(name)
    end)
    frame.zoneDD = zoneDD
    frame.OnZoneChanged = OnZoneChanged

    -- NPC dropdown (AceGUI)
    local npcLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npcLabel:SetPoint("TOPLEFT", zoneLabel, "TOPRIGHT", 316, 0)
    npcLabel:SetText(L['npc_label'])

    local npcDD = AceGUI:Create("Dropdown")
    npcDD:SetWidth(150)
    npcDD.frame:SetParent(frame)
    npcDD.frame:ClearAllPoints()
    npcDD.frame:SetPoint("TOPLEFT", npcLabel, "TOPRIGHT", 4, 1)
    npcDD:SetCallback("OnValueChanged", function(widget, event, value)
        if value == L['all_npc'] then
            MumbleFrame.selectedNPC = nil
        else
            MumbleFrame.selectedNPC = value
        end
        UpdateClearBtn()
        RefreshTimeline()
    end)
    frame.npcDD = npcDD

    -- Text display area
    local textBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    textBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -90)
    textBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 70)
    textBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    textBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    textBg:SetBackdropBorderColor(0.3, 0.3, 0.3)

    local textScroll = CreateFrame("ScrollFrame", nil, textBg, "UIPanelScrollFrameTemplate")
    frame.textScroll = textScroll
    textScroll:SetPoint("TOPLEFT", textBg, "TOPLEFT", 6, -6)
    textScroll:SetPoint("BOTTOMRIGHT", textBg, "BOTTOMRIGHT", -20, 6)

    local scrollText = CreateFrame("EditBox", nil, textScroll)
    scrollText:SetMultiLine(true)
    scrollText:SetMaxLetters(0)
    scrollText:EnableMouse(true)
    scrollText:SetAutoFocus(false)
    scrollText:SetFontObject(ChatFontNormal)
    scrollText:SetTextColor(0.9, 0.9, 0.9)
    scrollText:SetWidth(800)
    scrollText:SetHeight(200)
    textScroll:SetScrollChild(scrollText)
    frame.scrollText = scrollText

    local resizeOnce
    resizeOnce = frame:SetScript("OnUpdate", function()
        if textScroll:GetWidth() and textScroll:GetWidth() > 0 then
            scrollText:SetWidth(textScroll:GetWidth())
            frame:SetScript("OnUpdate", nil)
        end
    end)

    -- Bottom buttons
    local btnY = 12

    local hideCB = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    hideCB:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, btnY + 26)
    hideCB:SetSize(24, 24)
    hideCB:SetChecked(Mumble.GetConfig().hideTimestamp)
    hideCB.text = hideCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideCB.text:SetPoint("LEFT", hideCB, "RIGHT", 2, 0)
    hideCB.text:SetText(L['hide_timestamp'])
    hideCB:SetScript("OnClick", function(self)
        Mumble.GetConfig().hideTimestamp = self:GetChecked()
        RefreshTimeline()
    end)

    local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyBtn:SetSize(90, 24)
    copyBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, btnY)
    copyBtn:SetText(L['copy_all'])
    copyBtn:SetScript("OnClick", function()
        local text = scrollText:GetText()
        if text and text ~= "" then
            scrollText:HighlightText()
            scrollText:SetFocus()
            print(L['copied'])
        end
    end)

    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(140, 24)
    clearBtn:SetPoint("BOTTOMLEFT", copyBtn, "BOTTOMRIGHT", 6, 0)
    frame._clearBtn = clearBtn
    UpdateClearBtn()
    clearBtn:SetScript("OnClick", function()
        local zk = MumbleFrame.selectedZoneKey
        local npc = MumbleFrame.selectedNPC
        if not zk then return end
        local zd = CHAT_MSG_LOG_DB[playerKey] and CHAT_MSG_LOG_DB[playerKey][zk]
        if not zd then return end

        local isZone = (npc == nil)
        StaticPopupDialogs["MUMBLE_CLEAR_ZONE"] = {
            text = isZone and L['clear_confirm']:format(zk) or string.format(L['clear_npc_confirm'], npc, zk),
            button1 = L['confirm_button'],
            button2 = L['cancel_button'],
            OnAccept = function()
                if isZone then
                    for _, zk2 in ipairs(GetSelZoneKeys()) do
                        local d = CHAT_MSG_LOG_DB[playerKey] and CHAT_MSG_LOG_DB[playerKey][zk2]
                        if d then
                            d.__timeline = {}
                            d.__seen = {}
                        end
                    end
                else
                    -- Remove matching entries from timeline and seen
                    local newTimeline = {}
                    local newSeen = {}
                    for _, line in ipairs(zd.__timeline) do
                        local _, _, who = line:find("%[.-%]%[([^%]]+)")
                        if who ~= npc then
                            tinsert(newTimeline, line)
                        end
                    end
                    for dedup in pairs(zd.__seen or {}) do
                        if not dedup:find("^" .. npc .. ":") then
                            newSeen[dedup] = true
                        end
                    end
                    zd.__timeline = newTimeline
                    zd.__seen = newSeen
                    -- Also remove NPC entry
                    zd[npc] = nil
                end
                RefreshNPCDropdown()
                RefreshTimeline()
                print(isZone and L['clear_done']:format(zk) or L['clear_npc_done']:format(npc))
            end,
            timeout = 0,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("MUMBLE_CLEAR_ZONE")
    end)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(60, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, btnY)
    closeBtn:SetText(L['close'])
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Show and populate
    frame:Show()
    RefreshZoneDropdown()
    if OnZoneChanged then
        local dd = frame.zoneDD
        if dd then OnZoneChanged(dd:GetValue()) end
    end
end
