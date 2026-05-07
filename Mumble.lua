local events = {
	'CHAT_MSG_RAID_BOSS_EMOTE',
	'CHAT_MSG_RAID_BOSS_WHISPER',
	'CHAT_MSG_MONSTER_EMOTE',
	'CHAT_MSG_MONSTER_PARTY',
	'CHAT_MSG_MONSTER_SAY',
	'CHAT_MSG_MONSTER_WHISPER',
	'CHAT_MSG_MONSTER_YELL',
}

local function GetPlayerKey()
	return GetRealmName() .. "#" .. GetLocale()
end

local function GetCurrentZoneID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID and mapID > 0 then
		local mapInfo = C_Map.GetMapInfo(mapID)
		local mapName = mapInfo and mapInfo.name or "Map" .. mapID
		return mapID, mapName
	end

	local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	if instanceMapID and instanceMapID > 0 then
		local mapInfo = C_Map.GetMapInfo(instanceMapID)
		local mapName = mapInfo and mapInfo.name or "Instance" .. instanceMapID
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
	local key = GetPlayerKey()
	if not CHAT_MSG_LOG_DB then CHAT_MSG_LOG_DB = {} end

	-- ── PlayerKey migration: PlayerName@RealmName#Locale → RealmName#Locale ──
	if not CHAT_MSG_LOG_DB.__migrated then
		CHAT_MSG_LOG_DB.__migrated = true
		local merged = {}
		for oldKey, playerData in pairs(CHAT_MSG_LOG_DB) do
			if type(oldKey) == "string" and type(playerData) == "table" then
				-- Match old format: PlayerName@RealmName#Locale
				local atPos, hashPos = oldKey:find("@"), oldKey:find("#")
				if atPos and hashPos and hashPos > atPos then
					local newKey = oldKey:sub(atPos + 1)
					if not merged[newKey] then merged[newKey] = {} end
					-- Merge zones
					for zoneKey, zoneData in pairs(playerData) do
						if type(zoneData) == "table" and (zoneData.__timeline or zoneData.__seen) then
							if not merged[newKey][zoneKey] then
								merged[newKey][zoneKey] = zoneData
							else
								local tgt = merged[newKey][zoneKey]
								-- Merge __timeline: dedup by message, keep earliest timestamp
								if zoneData.__timeline then
									local byMsg = {}
									-- Index existing entries by message body
									for _, e in ipairs(tgt.__timeline or {}) do
										local _, _, time, body = e:find("%[(%d+-%d+-%d+ %d+:%d+:%d+)%](.*)")
										if body then
											if not byMsg[body] or time < byMsg[body] then
												byMsg[body] = time
											end
										end
									end
									-- Merge from source
									for _, e in ipairs(zoneData.__timeline) do
										local _, _, time, body = e:find("%[(%d+-%d+-%d+ %d+:%d+:%d+)%](.*)")
										if body then
											if not byMsg[body] or time < byMsg[body] then
												byMsg[body] = time
											end
										end
									end
									-- Rebuild timeline sorted by time
									tgt.__timeline = {}
									local sorted = {}
									for body, time in pairs(byMsg) do
										table.insert(sorted, { time = time, body = body })
									end
									table.sort(sorted, function(a, b) return a.time < b.time end)
									for _, item in ipairs(sorted) do
										table.insert(tgt.__timeline, "[" .. item.time .. "]" .. item.body)
									end
								end
								-- Merge __seen
								if zoneData.__seen then
									for k, _ in pairs(zoneData.__seen) do
										tgt.__seen[k] = true
									end
								end
								-- Merge NPC entries
								for npc, events in pairs(zoneData) do
									if npc ~= "__timeline" and npc ~= "__seen" and type(events) == "table" then
										if not tgt[npc] then tgt[npc] = {} end
										for evt, msgs in pairs(events) do
											if not tgt[npc][evt] then tgt[npc][evt] = {} end
											local seenMsg = {}
											for _, m in ipairs(tgt[npc][evt]) do seenMsg[m] = true end
											for _, m in ipairs(msgs) do
												if not seenMsg[m] then
													seenMsg[m] = true
													table.insert(tgt[npc][evt], m)
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		-- Write merged data and remove old keys
		for newKey, zoneData in pairs(merged) do
			if not CHAT_MSG_LOG_DB[newKey] then CHAT_MSG_LOG_DB[newKey] = {} end
			for zoneKey, z in pairs(zoneData) do
				CHAT_MSG_LOG_DB[newKey][zoneKey] = z
			end
		end
		for oldKey, _ in pairs(CHAT_MSG_LOG_DB) do
			if type(oldKey) == "string" and oldKey:find("@") and oldKey:find("#") then
				-- Check it's actually PlayerName@Realm#Locale format
				local atPos, hashPos = oldKey:find("@"), oldKey:find("#")
				if hashPos > atPos then
					CHAT_MSG_LOG_DB[oldKey] = nil
				end
			end
		end
	end

	if not CHAT_MSG_LOG_DB[key] then
		CHAT_MSG_LOG_DB[key] = {}
	end

	-- ── Zone key migration: numeric → ID@Name ──
	local migrateList = {}
	for k, v in pairs(CHAT_MSG_LOG_DB[key]) do
		if type(k) == "number" and type(v) == "table" then
			local name = v.__mapName
			if not name then
				local mapInfo = C_Map.GetMapInfo(k)
				name = mapInfo and mapInfo.name or "Map" .. k
			end
			local newKey = ZoneKeyByID(k, name)
			if newKey ~= k then
				v.__mapName = nil
				migrateList[k] = { newKey = newKey, data = v }
			end
		end
	end
	for oldKey, info in pairs(migrateList) do
		CHAT_MSG_LOG_DB[key][info.newKey] = info.data
		CHAT_MSG_LOG_DB[key][oldKey] = nil
	end

	return key
end

local function TimeStamp()
	return date("%Y-%m-%d %H:%M:%S")
end

local eventTag
if GetLocale() == "zhCN" then
	eventTag = {
		CHAT_MSG_MONSTER_SAY           = "说",
		CHAT_MSG_MONSTER_YELL          = "大喊",
		CHAT_MSG_MONSTER_WHISPER       = "密语",
		CHAT_MSG_MONSTER_EMOTE         = "表情",
		CHAT_MSG_MONSTER_PARTY         = "队伍",
		CHAT_MSG_RAID_BOSS_EMOTE       = "首领表情",
		CHAT_MSG_RAID_BOSS_WHISPER     = "首领密语",
	}
elseif GetLocale() == "zhTW" then
	eventTag = {
		CHAT_MSG_MONSTER_SAY           = "說",
		CHAT_MSG_MONSTER_YELL          = "大喊",
		CHAT_MSG_MONSTER_WHISPER       = "密語",
		CHAT_MSG_MONSTER_EMOTE         = "表情",
		CHAT_MSG_MONSTER_PARTY         = "隊伍",
		CHAT_MSG_RAID_BOSS_EMOTE       = "首領表情",
		CHAT_MSG_RAID_BOSS_WHISPER     = "首領密語",
	}
else
	eventTag = {
		CHAT_MSG_MONSTER_SAY           = "Say",
		CHAT_MSG_MONSTER_YELL          = "Yell",
		CHAT_MSG_MONSTER_WHISPER       = "Whisper",
		CHAT_MSG_MONSTER_EMOTE         = "Emote",
		CHAT_MSG_MONSTER_PARTY         = "Party",
		CHAT_MSG_RAID_BOSS_EMOTE       = "BossEmote",
		CHAT_MSG_RAID_BOSS_WHISPER     = "BossWhisper",
	}
end

local function FormatDisplay(t, who, event, msg)
	local tag = eventTag[event] or event
	return "[" .. t .. "][" .. who .. "][" .. tag .. "]：" .. msg
end

local f = CreateFrame'Frame'

-- Run migration immediately on load, not waiting for chat events
local _ = EnsurePlayerDB()

for k, v in pairs(events) do
	f:RegisterEvent(v)
end

f:SetScript('OnEvent', function(self, event, msg, who, ...)
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

	table.insert(zoneDB.__timeline, FormatDisplay(TimeStamp(), who, event, msg))

	if not zoneDB[who] then zoneDB[who] = {} end
	if not zoneDB[who][event] then zoneDB[who][event] = {} end
	table.insert(zoneDB[who][event], msg)
end)
