--[[
    enUS.lua — Default locale
]]

local L = {}
MUMBLE_LOCALE = L
L['title'] = 'Mumble Transcripts'
L['zone_label'] = 'Zone:'
L['npc_label'] = 'NPC:'
L['all_npc'] = 'All NPCs'
L['hide_timestamp'] = 'Hide Timestamps'
L['copy_all'] = 'Copy All'
L['clear_current'] = 'Clear Zone'
L['close'] = 'Close'
L['select_zone'] = 'Please select a zone.'
L['no_records'] = 'No records for this zone.'
L['copied'] = 'Text selected. Press Ctrl+C to copy.'
L['clear_confirm'] = 'Clear all records for "%s"?\n(This cannot be undone)'
L['clear_done'] = 'Cleared records for %s.'
L['reset_confirm'] = 'Clear all Mumble records?\n(This cannot be undone)'
L['reset_done'] = 'All records cleared.'
L['confirm_button'] = 'Confirm'
L['cancel_button'] = 'Cancel'
L['no_gui'] = 'GUI module not loaded.'
L['usage'] = 'Usage — /mumble (open GUI), /mumble reset'
L['group_suffix'] = ' (group)'
L['CHAT_MSG_MONSTER_SAY'] = 'Say'
L['CHAT_MSG_MONSTER_YELL'] = 'Yell'
L['CHAT_MSG_MONSTER_WHISPER'] = 'Whisper'
L['CHAT_MSG_MONSTER_EMOTE'] = 'Emote'
L['CHAT_MSG_MONSTER_PARTY'] = 'Party'
L['CHAT_MSG_RAID_BOSS_EMOTE'] = 'BossEmote'
L['CHAT_MSG_RAID_BOSS_WHISPER'] = 'BossWhisper'
L['divider'] = '------------------- %s -------------------'

-- Cross-locale tag registry (unconditional)
MUMBLE_CHAT_TAGS = MUMBLE_CHAT_TAGS or {}
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_SAY'] = L['CHAT_MSG_MONSTER_SAY']
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_YELL'] = L['CHAT_MSG_MONSTER_YELL']
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_WHISPER'] = L['CHAT_MSG_MONSTER_WHISPER']
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_EMOTE'] = L['CHAT_MSG_MONSTER_EMOTE']
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_PARTY'] = L['CHAT_MSG_MONSTER_PARTY']
MUMBLE_CHAT_TAGS['CHAT_MSG_RAID_BOSS_EMOTE'] = L['CHAT_MSG_RAID_BOSS_EMOTE']
MUMBLE_CHAT_TAGS['CHAT_MSG_RAID_BOSS_WHISPER'] = L['CHAT_MSG_RAID_BOSS_WHISPER']
