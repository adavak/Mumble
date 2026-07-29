--[[
    locale.lua — Default locale (English fallback)
]]

if not MUMBLE_LOCALE then
	local L = {}
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
	MUMBLE_LOCALE = L
end
