# Mumble 🗣️

NPC dialogue logger for World of Warcraft.

Silently captures monster and boss chat messages and organizes transcripts by locale and zone. No UI, no configuration — just install and forget.

[CurseForge](https://www.curseforge.com/wow/addons/mumble)

## Files

```
Mumble/
├── Mumble.lua    # Core logic
└── Mumble.toc    # AddOn manifest
```

## What It Logs

| Event | Description |
|-------|-------------|
| Monster Say / Yell / Whisper / Emote / Party | NPC public and private chat |
| Boss Emote / Whisper | Raid boss dialogue |

## Data Structure

All records stored in SavedVariables under `CHAT_MSG_LOG_DB`:

```
CHAT_MSG_LOG_DB[Locale][ZoneKey] = {
  __timeline = { "[timestamp][speaker][tag]message", ... },  -- ordered transcript
  __seen     = { dedup_key → true },                         -- deduplication
  [SpeakerName] = {
    [EventType] = { "message1", "message2", ... },           -- per-speaker grouping
  },
}
```

- **Locale**: game locale (e.g. `zhCN`, `enUS`, `zhTW`)
- **ZoneKey**: `MapID@MapName`
