--[[
    Mumble — NPC/BOSS dialogue transcriptor
]]

-- ── Global namespace ──
L = {}
Mumble = Mumble or {}

function Mumble.GetPlayerKey()
	return GetLocale()
end

function Mumble.GetConfig()
	if not CHAT_MSG_LOG_DB then
		CHAT_MSG_LOG_DB = {}
	end
	if not CHAT_MSG_LOG_DB.__config then
		CHAT_MSG_LOG_DB.__config = { hideTimestamp = false }
	elseif CHAT_MSG_LOG_DB.__config.hideTimestamp == nil then
		CHAT_MSG_LOG_DB.__config.hideTimestamp = false
	end
	if not CHAT_MSG_LOG_DB.__config.fontSize then
		local _, defaultSize = ChatFontNormal:GetFont()
		CHAT_MSG_LOG_DB.__config.fontSize = defaultSize or 12
	end
	return CHAT_MSG_LOG_DB.__config
end

-- Get the zone key for the player's current location
function Mumble.GetCurrentZoneKey()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID and mapID > 0 then
		local mapInfo = C_Map.GetMapInfo(mapID)
		local mapName = mapInfo and mapInfo.name or "Map" .. mapID
		return mapID .. "@" .. mapName
	end

	local name, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	if instanceMapID and instanceMapID > 0 then
		local mapInfo = C_Map.GetMapInfo(instanceMapID)
		local mapName = mapInfo and mapInfo.name or name or "Instance" .. instanceMapID
		return instanceMapID .. "@" .. mapName
	end

	local scenarioInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo()
	if scenarioInfo and scenarioInfo.uiMapID and scenarioInfo.uiMapID > 0 then
		local mapInfo = C_Map.GetMapInfo(scenarioInfo.uiMapID)
		local mapName = mapInfo and mapInfo.name or scenarioInfo.scenarioName or "Scenario" .. scenarioInfo.uiMapID
		return scenarioInfo.uiMapID .. "@" .. mapName
	end

	return nil
end

-- ── Data cleanup ──────────────────────────────────────────────────────────────
-- Merge zone entries with the same map ID on load, to clean up InstanceX duplicates

function Mumble.MergeDuplicateZones()
	local db = CHAT_MSG_LOG_DB
	if not db then return end

	-- Collect all zone keys by map ID across all locales
	for locale, localeDB in pairs(db) do
		if type(localeDB) == "table" then
			local byID = {}
			for zk in pairs(localeDB) do
				if zk ~= "__config" then
					local idStr, name = zk:match("^(%d+)@(.+)$")
					if idStr then
						local id = tonumber(idStr)
						if not byID[id] then byID[id] = {} end
						tinsert(byID[id], zk)
					end
				end
			end

			for id, keys in pairs(byID) do
				if #keys > 1 then
					-- Pick the best key (prefer non-Instance name)
					sort(keys)
					local best = keys[1]
					for _, k in ipairs(keys) do
						if not k:find("Instance") then best = k; break end
					end

					-- Merge data from other keys into best
					for _, k in ipairs(keys) do
						if k ~= best and localeDB[k] then
							local src = localeDB[k]
							local dst = localeDB[best]

							-- Merge timeline
							if src.__timeline and dst.__timeline then
								for _, line in ipairs(src.__timeline) do
									tinsert(dst.__timeline, line)
								end
							elseif src.__timeline then
								dst.__timeline = src.__timeline
							end

							-- Merge seen
							if src.__seen then
								for dedup in pairs(src.__seen) do
									dst.__seen[dedup] = true
								end
							end

							-- Merge NPC entries
							for npc, events in pairs(src) do
								if npc ~= "__timeline" and npc ~= "__seen" then
									if not dst[npc] then dst[npc] = {} end
									for eventType, msgs in pairs(events) do
										if not dst[npc][eventType] then dst[npc][eventType] = {} end
										for _, msg in ipairs(msgs) do
											tinsert(dst[npc][eventType], msg)
										end
									end
								end
							end

							-- Sort timeline by timestamp prefix
							sort(dst.__timeline)

							-- Remove the merged key
							localeDB[k] = nil
						end
					end
				end
			end
		end
	end
end

-- ── Events ───────────────────────────────────────────────────────────────────

local events = {
	'CHAT_MSG_RAID_BOSS_EMOTE',
	'CHAT_MSG_RAID_BOSS_WHISPER',
	'CHAT_MSG_MONSTER_EMOTE',
	'CHAT_MSG_MONSTER_PARTY',
	'CHAT_MSG_MONSTER_SAY',
	'CHAT_MSG_MONSTER_WHISPER',
	'CHAT_MSG_MONSTER_YELL',
}

local function GetCurrentZoneID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID and mapID > 0 then
		local mapInfo = C_Map.GetMapInfo(mapID)
		local mapName = mapInfo and mapInfo.name or "Map" .. mapID
		return mapID, mapName
	end

	local name, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	if instanceMapID and instanceMapID > 0 then
		local mapInfo = C_Map.GetMapInfo(instanceMapID)
		local mapName = mapInfo and mapInfo.name or name or "Instance" .. instanceMapID
		return instanceMapID, mapName
	end

	local scenarioInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo()
	if scenarioInfo and scenarioInfo.uiMapID and scenarioInfo.uiMapID > 0 then
		local mapInfo = C_Map.GetMapInfo(scenarioInfo.uiMapID)
		local mapName = mapInfo and mapInfo.name or scenarioInfo.scenarioName or "Scenario" .. scenarioInfo.uiMapID
		return scenarioInfo.uiMapID, mapName
	end

	return nil, "UnknownZone"
end

local function ZoneKeyByID(mapID, mapName)
	return mapID .. "@" .. mapName
end

local function EnsurePlayerDB()
	local key = Mumble.GetPlayerKey()
	if not CHAT_MSG_LOG_DB then CHAT_MSG_LOG_DB = {} end
	if not CHAT_MSG_LOG_DB[key] then
		CHAT_MSG_LOG_DB[key] = {}
	end
	return key
end

local function TimeStamp()
	return date("%Y-%m-%d %H:%M:%S")
end

-- ── Event tag localization ───────────────────────────────────────────────────

local function FormatDisplay(t, who, event, msg)
	local tag = L[event] or event
	return "[" .. t .. "][" .. who .. "][" .. tag .. "]：" .. msg
end

-- ── Init config on load ──────────────────────────────────────────────────────

Mumble.GetConfig()
Mumble.MergeDuplicateZones()

-- ── Slash command ────────────────────────────────────────────────────────────

SLASH_MUMBLE1 = "/mumble"
SlashCmdList["MUMBLE"] = function(input)
	input = strtrim(input)
	if input == "" then
		if Mumble.OpenGUI then
			Mumble.OpenGUI()
		else
			print(L['no_gui'])
		end
	elseif input == "reset" then
		StaticPopupDialogs["MUMBLE_RESET_ALL"] = {
			text = L['reset_confirm'],
			button1 = L['confirm_button'],
			button2 = L['cancel_button'],
			OnAccept = function()
				CHAT_MSG_LOG_DB = {}
				print(L['reset_done'])
			end,
			timeout = 0,
			hideOnEscape = true,
		preferredIndex = 3,
		}
		StaticPopup_Show("MUMBLE_RESET_ALL")
	else
		print(L['usage'])
	end
end

-- ── Event frame ──────────────────────────────────────────────────────────────

local f = CreateFrame("Frame")

for k, v in pairs(events) do
	f:RegisterEvent(v)
end

f:SetScript("OnEvent", function(self, event, msg, who, ...)
	if (not event) or (not msg) then return end

	if issecretvalue(msg) then return end
	if who and issecretvalue(who) then return end

	local playerKey = EnsurePlayerDB()
	local mapID, mapName = GetCurrentZoneID()
	if not mapID then mapID = "Unknown" end
	if not mapName then mapName = mapID end

	local zoneKey = ZoneKeyByID(mapID, mapName)

	if not CHAT_MSG_LOG_DB[playerKey][zoneKey] then
		CHAT_MSG_LOG_DB[playerKey][zoneKey] = {
			__timeline = {},
			__seen     = {},
		}
	end

	local zoneDB = CHAT_MSG_LOG_DB[playerKey][zoneKey]

	local dedupKey = who .. ":" .. msg
	if zoneDB.__seen[dedupKey] then return end
	zoneDB.__seen[dedupKey] = true

	tinsert(zoneDB.__timeline, FormatDisplay(TimeStamp(), who, event, msg))

	if not zoneDB[who] then zoneDB[who] = {} end
	if not zoneDB[who][event] then zoneDB[who][event] = {} end
	tinsert(zoneDB[who][event], msg)
end)
