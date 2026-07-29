--[[
    locale.lua — Localization loader for Mumble
]]

local L = {}

if GetLocale() == "zhCN" then
	L.Title = "Mumble 转录记录"
	L.ZoneLabel = "区域："
	L.NPCLabel = "NPC："
	L.AllNPC = "全部 NPC"
	L.HideTimestamp = "隐藏时间戳"
	L.CopyAll = "复制全部"
	L.ClearCurrent = "清除当前"
	L.Close = "关闭"
	L.SelectZone = "请选择一个区域。"
	L.NoRecords = "（该区域暂无对话记录）"
	L.Copied = "文本已选中，按 Ctrl+C 复制。"
	L.ClearConfirm = "确认清除 \"%s\" 的所有对话记录？\n(此操作不可撤销)"
	L.ClearDone = "已清除 %s 的记录。"
	L.ResetConfirm = "确认清除 Mumble 的所有记录？\n(此操作不可撤销)"
	L.ResetDone = "所有记录已清除。"
	L.ConfirmButton = "确认清除"
	L.CancelButton = "取消"
	L.NoGUI = "GUI 模块未加载。"
	L.Usage = "用法 — /mumble（打开界面）, /mumble reset"
	L.GroupSuffix = " (组)"
	L.Divider = "------------------- %s -------------------"
else
	L.Title = "Mumble Transcripts"
	L.ZoneLabel = "Zone:"
	L.NPCLabel = "NPC:"
	L.AllNPC = "All NPCs"
	L.HideTimestamp = "Hide Timestamps"
	L.CopyAll = "Copy All"
	L.ClearCurrent = "Clear Zone"
	L.Close = "Close"
	L.SelectZone = "Please select a zone."
	L.NoRecords = "No records for this zone."
	L.Copied = "Text selected. Press Ctrl+C to copy."
	L.ClearConfirm = "Clear all records for \"%s\"?\n(This cannot be undone)"
	L.ClearDone = "Cleared records for %s."
	L.ResetConfirm = "Clear all Mumble records?\n(This cannot be undone)"
	L.ResetDone = "All records cleared."
	L.ConfirmButton = "Confirm"
	L.CancelButton = "Cancel"
	L.NoGUI = "GUI module not loaded."
	L.Usage = "Usage — /mumble (open GUI), /mumble reset"
	L.GroupSuffix = " (group)"
	L.Divider = "------------------- %s -------------------"
end

MUMBLE_LOCALE = L
