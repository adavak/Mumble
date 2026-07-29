# Mumble 🗣️

[EN](README.md) | [中文](README.zhCN.md)

NPC dialogue logger for World of Warcraft.

Silently captures monster and boss chat messages and organizes transcripts by zone. No configuration needed.

[CurseForge](https://www.curseforge.com/wow/addons/mumble)

## Features

- **Record** monster/boss say, yell, whisper, emote, party messages
- **GUI** — browse transcripts by zone, filter by NPC, copy text
- **Auto-group** — same-dungeon floors merged via `C_Map.GetMapGroupID`, same-map-ID duplicates merged on load
- **Auto-select** — opens to your current zone
- **Colored log** — event types colored by game defaults, timestamps in gray
- **Timestamp toggle** — show/hide timestamps
- **NPC filter** — view transcripts for a single NPC
- **Zone divider** — group headers when multiple map IDs are merged
- **Localization** — zhCN, enUS
- **CurseForge ready** — `.pkgmeta` with nolib/with-lib variants

## Usage

| Command | Action |
|---------|--------|
| `/mumble` | Open GUI |
| `/mumble reset` | Clear all saved data |

## Files

```
Mumble/
├── Mumble.lua          # Core recording logic
├── MumbleFrame.lua     # AceGUI-based transcript browser
├── Mumble.xml          # File manifest
├── Mumble.toc          # AddOn manifest
├── .pkgmeta            # CurseForge packaging config
├── Locales/
│   ├── enUS.lua        # English (default)
│   └── zhCN.lua        # Simplified Chinese
```

## Dependencies

- **Ace3** (required for nolib variant; bundled in with-lib variant)

## Storage

Data saved to `WTF/Account/\<AccountID\>/SavedVariables/Mumble.lua`.

## What It Logs

| Event | Description |
|-------|-------------|
| Monster Say / Yell / Whisper / Emote / Party | NPC public and private chat |
| Boss Emote / Whisper | Raid boss dialogue |

## Data Structure

```
CHAT_MSG_LOG_DB[Locale][ZoneKey] = {
  __timeline = { "[timestamp][speaker][tag]message", ... },
  __seen     = { dedup_key → true },
  [SpeakerName] = { [EventType] = { "message1", ... } },
}
```

- **Locale**: game locale (e.g. `enUS`, `zhCN`)
- **ZoneKey**: `MapID@MapName`
