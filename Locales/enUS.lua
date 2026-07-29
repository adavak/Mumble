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
L['say'] = 'Say'
L['yell'] = 'Yell'
L['whisper'] = 'Whisper'
L['emote'] = 'Emote'
L['party'] = 'Party'
L['boss_emote'] = 'BossEmote'
L['boss_whisper'] = 'BossWhisper'
L['divider'] = '------------------- %s -------------------'

-- Event tag map: key=event name, value=localized tag
MUMBLE_CHAT_TAGS = MUMBLE_CHAT_TAGS or {}
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_SAY'] = 'Say'
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_YELL'] = 'Yell'
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_WHISPER'] = 'Whisper'
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_EMOTE'] = 'Emote'
MUMBLE_CHAT_TAGS['CHAT_MSG_MONSTER_PARTY'] = 'Party'
MUMBLE_CHAT_TAGS['CHAT_MSG_RAID_BOSS_EMOTE'] = 'BossEmote'
MUMBLE_CHAT_TAGS['CHAT_MSG_RAID_BOSS_WHISPER'] = 'BossWhisper'
