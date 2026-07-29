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

-- Event tag lookup (registered for all locales)
MUMBLE_TAG_TO_EVENT = MUMBLE_TAG_TO_EVENT or {}
MUMBLE_TAG_TO_EVENT['Say'] = 'CHAT_MSG_MONSTER_SAY'
MUMBLE_TAG_TO_EVENT['Yell'] = 'CHAT_MSG_MONSTER_YELL'
MUMBLE_TAG_TO_EVENT['Whisper'] = 'CHAT_MSG_MONSTER_WHISPER'
MUMBLE_TAG_TO_EVENT['Emote'] = 'CHAT_MSG_MONSTER_EMOTE'
MUMBLE_TAG_TO_EVENT['Party'] = 'CHAT_MSG_MONSTER_PARTY'
MUMBLE_TAG_TO_EVENT['BossEmote'] = 'CHAT_MSG_RAID_BOSS_EMOTE'
MUMBLE_TAG_TO_EVENT['BossWhisper'] = 'CHAT_MSG_RAID_BOSS_WHISPER'
