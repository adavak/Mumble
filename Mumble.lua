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
	return GetLocale()
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
	if not CHAT_MSG_LOG_DB[key] then
		CHAT_MSG_LOG_DB[key] = {}
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

-- Slash command
SLASH_MUMBLE1 = "/mumble"
SlashCmdList["MUMBLE"] = function(input)
	input = input:trim()
	if input == "reset" then
		CHAT_MSG_LOG_DB = {}
		print("Mumble: cache reset.")
	else
		print("Mumble: unknown command. Usage: /mumble reset")
	end
end

local f = CreateFrame'Frame'

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
