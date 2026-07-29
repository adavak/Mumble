--[[
    MumbleFrame.lua — GUI for Mumble Transcriptor
    Display recorded dialogues and copy out.
]]

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

-- Chat color by event type (RRGGBB hex)
local eventColors = {
	["说"] = "FFFF9F", ["大喊"] = "FF4040", ["密语"] = "FFB5EB",
	["表情"] = "FF8040", ["队伍"] = "AAAFFF", ["首领表情"] = "FFDD00",
	["首领密语"] = "FFDD00",
	["Say"] = "FFFF9F", ["Yell"] = "FF4040", ["Whisper"] = "FFB5EB",
	["Emote"] = "FF8040", ["Party"] = "AAAFFF", ["BossEmote"] = "FFDD00",
	["BossWhisper"] = "FFDD00",
}

-- ── Display refresh ──────────────────────────────────────────────────────────

local function RefreshTimeline()
	local text = MumbleFrame and MumbleFrame.scrollText
	if not text then return end

	local zoneKeys = MumbleFrame and MumbleFrame._selZoneKeys
	if not zoneKeys or #zoneKeys == 0 then
		text:SetText("请选择一个区域。")
		return
	end

	local hideTS = Mumble.GetConfig().hideTimestamp
	local filterNPC = MumbleFrame.selectedNPC

	local lines = {}
	local showDivider = #zoneKeys > 1
	for _, zk in ipairs(zoneKeys) do
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
						local color = tag and eventColors[tag] or "FFFFFF"
						tinsert(keyLines, "|cFF" .. color .. display .. "|r")
					else
						local _, _, tag = display:find("%[.-%]%[.-%]%[([^%]]+)")
						local color = tag and eventColors[tag] or "FFFFFF"
						tinsert(keyLines, "|cFF" .. color .. display .. "|r")
					end
				end
			end
		end
		-- Only add divider if this zone key actually has matching entries
		if #keyLines > 0 then
			if showDivider then
				tinsert(lines, "|cFF888888------------------- " .. zk .. " -------------------|r")
			end
			for _, colored in ipairs(keyLines) do
				tinsert(lines, colored)
			end
		end
	end

	local content = #lines > 0 and table.concat(lines, "\n") or "（该区域暂无对话记录）"
	text:SetText(content)

	local ts = MumbleFrame and MumbleFrame.textScroll
	if ts and ts:GetHeight() and ts:GetHeight() > 0 then
		local lineH = (text:GetFont() and select(2, text:GetFont())) or 14
		local numLines = select(2, content:gsub("\n", "\n")) + 1
		text:SetHeight(math.max(ts:GetHeight(), numLines * (lineH + 1) + 8))
	end
end

-- ── Refresh AceGUI zone dropdown ─────────────────────────────────────────────

-- Build zone name list: group keys with the same name
local zoneNameGroups = {} -- zoneName -> { zk1, zk2, ... }

local function BuildZoneNameList()
	zoneNameGroups = {}
	local keys = GetZoneKeys()
	for _, zk in ipairs(keys) do
		local name = zk:match("@(.+)") or zk
		if not zoneNameGroups[name] then zoneNameGroups[name] = {} end
		tinsert(zoneNameGroups[name], zk)
	end
end

local function RefreshZoneDropdown()
	local dd = MumbleFrame and MumbleFrame.zoneDD
	if not dd then return end

	BuildZoneNameList()
	local names = {}
	for name in pairs(zoneNameGroups) do tinsert(names, name) end
	sort(names)

	local list = {}
	for _, name in ipairs(names) do list[name] = name end
	dd:SetList(list)
	if #names == 0 then return end

	-- Find which group matches current zone or pick first
	local cur = Mumble.GetCurrentZoneKey()
	local curName = cur and cur:match("@(.+)") or nil
	local defaultName = nil
	if curName then
		for _, name in ipairs(names) do
			if name == curName then defaultName = name; break end
		end
	end
	if not defaultName then defaultName = names[1] end

	dd:SetValue(defaultName)
	-- OnValueChanged will handle the rest
end

-- ── Refresh AceGUI NPC dropdown ──────────────────────────────────────────────

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

	local list = { ["全部 NPC"] = "全部 NPC" }
	for _, name in ipairs(npcs) do list[name] = name end
	dd:SetList(list)
	if MumbleFrame.selectedNPC and list[MumbleFrame.selectedNPC] then
		dd:SetValue(MumbleFrame.selectedNPC)
	else
		MumbleFrame.selectedNPC = nil
		dd:SetValue("全部 NPC")
	end
end

-- ── AceGUI setup ─────────────────────────────────────────────────────────────

local AceGUI = LibStub("AceGUI-3.0")

-- ── Main frame creation ──────────────────────────────────────────────────────

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

	-- ── Title ──
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -14)
	title:SetText("Mumble 转录记录")
	title:SetTextColor(1, 0.82, 0)

	-- ── Close button ──
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
	close:SetScript("OnClick", function() frame:Hide() end)

	-- ── Zone dropdown (AceGUI) ──
	local zoneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	zoneLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -44)
	zoneLabel:SetText("区域：")

	local zoneDD = AceGUI:Create("Dropdown")
	zoneDD:SetWidth(350)
	zoneDD.frame:SetParent(frame)
	zoneDD.frame:ClearAllPoints()
	zoneDD.frame:SetPoint("TOPLEFT", zoneLabel, "TOPRIGHT", 4, -3)
	local function OnZoneChanged(name)
		if not name then return end
		local keys = zoneNameGroups[name]
		if keys and #keys > 0 then
			MumbleFrame.selectedZoneKey = keys[1]
			MumbleFrame._selZoneKeys = keys
		end
		MumbleFrame.selectedNPC = nil
		RefreshNPCDropdown()
		RefreshTimeline()
	end

	zoneDD:SetCallback("OnValueChanged", function(widget, event, name)
		OnZoneChanged(name)
	end)
	frame.zoneDD = zoneDD
	frame.OnZoneChanged = OnZoneChanged

	-- ── NPC dropdown (AceGUI) ──
	local npcLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	npcLabel:SetPoint("TOPLEFT", zoneDD.frame, "TOPRIGHT", 12, 3)
	npcLabel:SetText("NPC：")

	local npcDD = AceGUI:Create("Dropdown")
	npcDD:SetWidth(150)
	npcDD.frame:SetParent(frame)
	npcDD.frame:ClearAllPoints()
	npcDD.frame:SetPoint("TOPLEFT", npcLabel, "TOPRIGHT", 4, -3)
	npcDD:SetCallback("OnValueChanged", function(widget, event, value)
		if value == "全部 NPC" then
			MumbleFrame.selectedNPC = nil
		else
			MumbleFrame.selectedNPC = value
		end
		RefreshTimeline()
	end)
	frame.npcDD = npcDD

	-- ── Text display area ──
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

	-- ── Bottom buttons ──
	local btnY = 12

	local hideCB = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	hideCB:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, btnY + 26)
	hideCB:SetSize(24, 24)
	hideCB:SetChecked(Mumble.GetConfig().hideTimestamp)
	hideCB.text = hideCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	hideCB.text:SetPoint("LEFT", hideCB, "RIGHT", 2, 0)
	hideCB.text:SetText("隐藏时间戳")
	hideCB:SetScript("OnClick", function(self)
		Mumble.GetConfig().hideTimestamp = self:GetChecked()
		RefreshTimeline()
	end)

	local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	copyBtn:SetSize(90, 24)
	copyBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, btnY)
	copyBtn:SetText("复制全部")
	copyBtn:SetScript("OnClick", function()
		local text = scrollText:GetText()
		if text and text ~= "" then
			scrollText:HighlightText()
			scrollText:SetFocus()
			print("Mumble: 文本已选中，按 Ctrl+C 复制。")
		end
	end)

	local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearBtn:SetSize(90, 24)
	clearBtn:SetPoint("BOTTOMLEFT", copyBtn, "BOTTOMRIGHT", 6, 0)
	clearBtn:SetText("清除当前")
	clearBtn:SetScript("OnClick", function()
		local zk = MumbleFrame.selectedZoneKey
		if not zk then return end
		local zd = CHAT_MSG_LOG_DB[playerKey] and CHAT_MSG_LOG_DB[playerKey][zk]
		if not zd then return end

		StaticPopupDialogs["MUMBLE_CLEAR_ZONE"] = {
			text = "确认清除 \"" .. zk .. "\" 的所有对话记录？\n(此操作不可撤销)",
			button1 = "确认清除",
			button2 = "取消",
			OnAccept = function()
				zd.__timeline = {}
				zd.__seen = {}
				RefreshTimeline()
				print("Mumble: 已清除 " .. zk .. " 的记录。")
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
	closeBtn:SetText("关闭")
	closeBtn:SetScript("OnClick", function() frame:Hide() end)

	-- ── Show and populate ──
	frame:Show()
	RefreshZoneDropdown()
	-- Ensure zone data loads even if callback didn't fire
	if frame.OnZoneChanged then
		local dd = frame.zoneDD
		if dd then frame.OnZoneChanged(dd:GetValue()) end
	end
end
