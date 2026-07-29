--[[
    zhCN.lua — Simplified Chinese locale
]]

if GetLocale() == 'zhCN' then
	local L = {}
	MUMBLE_LOCALE = L
	L['title'] = 'Mumble 转录记录'
	L['zone_label'] = '区域：'
	L['npc_label'] = 'NPC：'
	L['all_npc'] = '全部 NPC'
	L['hide_timestamp'] = '隐藏时间戳'
	L['copy_all'] = '复制全部'
	L['clear_current'] = '清除当前'
	L['close'] = '关闭'
	L['select_zone'] = '请选择一个区域。'
	L['no_records'] = '（该区域暂无对话记录）'
	L['copied'] = '文本已选中，按 Ctrl+C 复制。'
	L['clear_confirm'] = '确认清除 "%s" 的所有对话记录？\n(此操作不可撤销)'
	L['clear_done'] = '已清除 %s 的记录。'
	L['reset_confirm'] = '确认清除 Mumble 的所有记录？\n(此操作不可撤销)'
	L['reset_done'] = '所有记录已清除。'
	L['confirm_button'] = '确认清除'
	L['cancel_button'] = '取消'
	L['no_gui'] = 'GUI 模块未加载。'
	L['usage'] = '用法 — /mumble（打开界面）, /mumble reset'
	L['group_suffix'] = ' (组)'
	L['CHAT_MSG_MONSTER_SAY'] = '说'
	L['CHAT_MSG_MONSTER_YELL'] = '大喊'
	L['CHAT_MSG_MONSTER_WHISPER'] = '密语'
	L['CHAT_MSG_MONSTER_EMOTE'] = '表情'
	L['CHAT_MSG_MONSTER_PARTY'] = '队伍'
	L['CHAT_MSG_RAID_BOSS_EMOTE'] = '首领表情'
	L['CHAT_MSG_RAID_BOSS_WHISPER'] = '首领密语'
	L['divider'] = '------------------- %s -------------------'
end
