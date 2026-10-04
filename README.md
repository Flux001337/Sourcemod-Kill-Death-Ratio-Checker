# SourceMod - Kill Death Ratio Checker

SourceMod Plugin for displaying and monitoring player kill/death ratios.
Current version: **1.8.0**.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the complete version history.

## Features

- Show KDR with `kdr`, `!kdr`, `/kdr`, or `sm_kdr`.
- Optional KDR display at round end and after a kill.
- Optional periodic monitoring with minimum kills and a KDR threshold.
- Kick or ban when the configured thresholds are met.
- Optional [Updater](https://forums.alliedmods.net/showthread.php?p=1570806) integration.
- SourceBans support: when the `sourcebans` library is present, bans use `sm_ban`; otherwise, the plugin uses SourceMod's `BanClient`.

Automatic monitoring is disabled by default. With zero deaths, the KDR is the number of frags; non-positive frags produce a KDR of zero.

## Requirements

- SourceMod and a game providing `round_end` and `player_death` events.
- Matching SourcePawn compiler and SourceMod standard includes.
- `scripting/include/updater.inc` (bundled for compilation). The Updater plugin is optional at runtime.

## Installation

Compile `scripting/kdchecker.sp` and copy `plugins/kdchecker.smx` to the server's `addons/sourcemod/plugins/` directory.
Reload the plugin or change the map to load it. The plugin automatically generates `cfg/sourcemod/plugin.kdcheck.cfg`.

## Updating

Replace `addons/sourcemod/plugins/kdchecker.smx` and reload the plugin or change the map. When new configuration options are introduced, back up your existing `cfg/sourcemod/plugin.kdcheck.cfg`, remove it, and reload the plugin to generate a fresh configuration. Reapply your custom settings afterwards.

## Configuration

| ConVar | Default | Purpose |
| --- | --- | --- |
| `sm_kdrc_version` | `1.8.0` | Plugin version |
| `sm_kdrc_enable` | `1` | Enable plugin |
| `sm_kdrc_show_roundend` | `1` | Show KDR at round end |
| `sm_kdrc_show_kill` | `0` | Show KDR after a kill |
| `sm_kdrc_watch_enable` | `0` | Enable automatic monitoring |
| `sm_kdrc_watch_rate` | `4.0` | KDR threshold (inclusive) |
| `sm_kdrc_watch_kills` | `15` | Minimum frags before action |
| `sm_kdrc_watch_checkrate` | `30.0` | Check interval in seconds |
| `sm_kdrc_watch_action` | `0` | 0 = kick, 1 = ban |
| `sm_kdrc_watch_bantime` | `60` | Ban duration in minutes; 0 = permanent |
| `sm_kdrc_debug` | `0` | Log player checks |

## Commands

| Location | Command | Purpose |
| --- | --- | --- |
| Chat | `kdr`, `!kdr`, `/kdr` | Show your own kill/death ratio |
| Player console | `sm_kdr` | Show your own kill/death ratio |
| Chat | `kdrselfaction` | Test the configured kick or ban action on yourself |

The `kdrselfaction` test command It applies the configured kick/ban action to the calling player without checking the KDR threshold or monitoring switch. The main enable switch still applies. Use this command to test the configured player action.

## Build

Run from this repository directory. The commands below use the shared compiler and standard includes three directories above the repository. For a standalone checkout, replace those paths with your SourceMod installation path.

Windows CMD:

```bat
if not exist plugins mkdir plugins
../../../spcomp64.exe scripting/kdchecker.sp -iscripting/include -i../../../include -oplugins/kdchecker.smx
```

Linux:

```sh
mkdir -p plugins
../../../spcomp64 scripting/kdchecker.sp -iscripting/include -i../../../include -oplugins/kdchecker.smx
```

Compiled binaries and local backups are excluded from Git.

## Repository structure

```text
scripting/
├── kdchecker.sp
└── include/
    └── updater.inc
```

## Release package

A release ZIP contains `plugins/kdchecker.smx` and the `scripting/` directory. Extract it into the server's `addons/sourcemod/` directory. README and changelog may also be included in the ZIP. GitHub's automatic source archive contains the source files; it does not include the compiled plugin.

## Source and credits

Original plugin: HSFighter, http://www.hsfighter.net

[AlliedModders forum thread](https://forums.alliedmods.net/showthread.php?p=1364793)

Thanks to **Kathy**, **scheibo**, **FAKK|biggiman**, and **Popoklopsi**.

## Tip

To retain scores when players disconnect and reconnect before reaching the KDR limit, the original forum post recommends [exvel's score-saving plugin](https://forums.alliedmods.net/showthread.php?p=660327). Its current compatibility has not been verified.

## Source notices

The source and bundled include retain their existing notices. No additional project license has been assigned. Confirm redistribution terms before publishing.
The existing HTTP Updater endpoint remains unchanged in the source.
