# Mumble 🗣️

[EN](README.md) | [中文](README.zhCN.md)

World of Warcraft NPC 对话记录插件。

自动捕获怪物和首领的聊天消息，按区域整理记录。即装即用，无需配置。

[CurseForge](https://www.curseforge.com/wow/addons/mumble)

## 功能

- **记录** — 怪物/首领的说、大喊、密语、表情、队伍消息
- **GUI 界面** — 按区域浏览记录、按 NPC 筛选、复制文本
- **自动合并** — 同副本楼层通过 `C_Map.GetMapGroupID` 合并，同 ID 不同名自动去重
- **自动定位** — 打开界面默认选中当前所在区域
- **彩色日志** — 事件类型按游戏默认颜色着色，时间戳灰色
- **时间戳开关** — 显示/隐藏时间戳
- **NPC 筛选** — 只查看单个 NPC 的台词
- **区域分隔线** — 合并多个地图 ID 时显示分组头
- **本地化** — 简体中文、英文
- **CurseForge 打包** — `.pkgmeta` 支持 nolib/with-lib 双版本

## 命令

| 命令 | 作用 |
|------|------|
| `/mumble` | 打开记录界面 |
| `/mumble reset` | 清除所有录音数据 |

## 文件结构

```
Mumble/
├── Mumble.lua          # 核心录制逻辑
├── MumbleFrame.lua     # AceGUI 记录浏览界面
├── Mumble.xml          # 文件清单
├── Mumble.toc          # 插件清单
├── .pkgmeta            # CurseForge 打包配置
├── Locales/
│   ├── enUS.lua        # 英文（默认）
│   └── zhCN.lua        # 简体中文
```

## 依赖

- **Ace3**（nolib 版本需自行安装；with-lib 版本已内嵌）

## 数据存储

保存在 `WTF/Account/\<账号ID\>/SavedVariables/Mumble.lua`。

## 记录的事件

| 事件 | 说明 |
|------|------|
| 怪物说 / 大喊 / 密语 / 表情 / 队伍 | NPC 公开及私密聊天 |
| 首领表情 / 首领密语 | 团队副本首领对话 |

## 数据结构

```
CHAT_MSG_LOG_DB[Locale][ZoneKey] = {
  __timeline = { "[时间][说话者][标签]消息", ... },
  __seen     = { 去重键 → true },
  [说话者] = { [事件类型] = { "消息1", ... } },
}
```

- **Locale**: 游戏语言 (如 `enUS`、`zhCN`)
- **ZoneKey**: `地图ID@地图名`
