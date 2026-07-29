--[[
    Mumble — NPC/BOSS dialogue transcriptor
]]

-- ── Global namespace for shared functions ──
Mumble = Mumble or {}

function Mumble.GetPlayerKey()
	return GetLocale()
end

function Mumble.GetAllKnownNPCs()
	local seen = {}
	local pk = Mumble.GetPlayerKey()
	local db = CHAT_MSG_LOG_DB and CHAT_MSG_LOG_DB[pk]
	if not db then return {} end
	for zk, zoneDB in pairs(db) do
		if zk ~= "__config" then
			for who in pairs(zoneDB) do
				if who ~= "__timeline" and who ~= "__seen" then
					seen[who] = true
				end
			end
		end
	end
	local list = {}
	for name in pairs(seen) do tinsert(list, name) end
	sort(list)
	return list
end

function Mumble.InitConfig()
	Mumble.GetConfig() -- ensure initialized
end

function Mumble.GetConfig()
	if not CHAT_MSG_LOG_DB then
		CHAT_MSG_LOG_DB = {}
	end
	if not CHAT_MSG_LOG_DB.__config then
		CHAT_MSG_LOG_DB.__config = { npcFilter = {}, hideTimestamp = false }
	end
	-- lazily add hideTimestamp if config existed before this field
	if CHAT_MSG_LOG_DB.__config.hideTimestamp == nil then
		CHAT_MSG_LOG_DB.__config.hideTimestamp = false
	end
	return CHAT_MSG_LOG_DB.__config
end

function Mumble.ShouldRecord(who)
	if not who then return true end
	local filter = Mumble.GetConfig().npcFilter
	if not filter or #filter == 0 then
		return true -- empty filter = record all
	end
	for _, name in ipairs(filter) do
		if name == who then return true end
	end
	return false
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

-- ── Init config on load ──────────────────────────────────────────────────────

Mumble.InitConfig()

-- ── Slash command ────────────────────────────────────────────────────────────

SLASH_MUMBLE1 = "/mumble"
SlashCmdList["MUMBLE"] = function(input)
	input = strtrim(input)
	if input == "" then
		if Mumble.OpenGUI then
			Mumble.OpenGUI()
		else
			print("Mumble: GUI 模块未加载。")
		end
	elseif input == "reset" then
		CHAT_MSG_LOG_DB = {}
		print("Mumble: 所有记录已清除。")
	elseif input == "list" then
		local filter = Mumble.GetConfig().npcFilter
		if filter and #filter > 0 then
			print("Mumble NPC 过滤列表：" .. table.concat(filter, ", "))
		else
			print("Mumble: NPC 过滤列表为空（记录所有 NPC）。")
		end
	elseif input:sub(1, 7) == "filter " then
		local cmd = strtrim(input:sub(8))
		if cmd == "" then
			local filter = Mumble.GetConfig().npcFilter
			if filter and #filter > 0 then
				print("Mumble NPC 过滤列表：" .. table.concat(filter, ", "))
			else
				print("Mumble: NPC 过滤列表为空（记录所有 NPC）。")
			end
		elseif cmd:sub(1, 4) == "add " then
			local name = strtrim(cmd:sub(5))
			if name ~= "" then
				local filter = Mumble.GetConfig().npcFilter
				for _, n in ipairs(filter) do
					if n == name then print("Mumble: '" .. name .. "' 已在列表中。"); return end
				end
				tinsert(filter, name)
				sort(filter)
				print("Mumble: 已添加 '" .. name .. "' 到过滤列表。")
			end
		elseif cmd:sub(1, 7) == "remove " then
			local name = strtrim(cmd:sub(8))
			if name ~= "" then
				local filter = Mumble.GetConfig().npcFilter
				for i, n in ipairs(filter) do
					if n == name then
						tremove(filter, i)
						print("Mumble: 已从过滤列表移除 '" .. name .. "'。")
						return
					end
				end
				print("Mumble: 过滤列表中未找到 '" .. name .. "'。")
			end
		elseif cmd == "clear" then
			Mumble.GetConfig().npcFilter = {}
			print("Mumble: NPC 过滤列表已清空（将记录所有 NPC）。")
		else
			print("Mumble: 用法 — /mumble filter add <NPC名>, /mumble filter remove <NPC名>, /mumble filter clear")
		end
	else
		print("Mumble: 用法 — /mumble（打开界面）, /mumble reset, /mumble list, /mumble filter ...")
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

	-- NPC filter check
	if not Mumble.ShouldRecord(who) then return end

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
