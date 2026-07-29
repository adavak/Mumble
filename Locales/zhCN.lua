--[[
    zhCN.lua
]]

if GetLocale() == "zhCN" then
	local L = {}
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
	MUMBLE_LOCALE = L
end
