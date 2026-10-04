# Changelog

Legend: `!` Fix · `+` Addition · `*` Change · `-` Removal

## 1.8.0 (29.09.2026)

- `!` Fix KD calculation when deaths are zero, including 0 kills / 0 deaths
- `!` Validate players before accessing client information
- `!` Prevent invalid client errors on world deaths
- `!` Handle sm_kdr calls from the server console
- `!` Read the updated scoreboard after a kill instead of adding a fixed +1
- `!` Apply the configured check interval after configs have loaded
- `+` Apply check interval changes immediately
- `*` Include players with zero deaths in KD monitoring once the minimum kill count is reached
- `*` Respect the plugin enable setting for sm_kdr
- `*` Modernize SourcePawn syntax and replace deprecated SteamID functions
- `-` Remove unused code

## 1.7.1 (11.05.2014)

- `!` Language fix

## 1.7.0 (27.12.2013)

- `!` Fix an occasional bug after map changes
- `+` Auto-Updater support

## 1.6.0 (11.11.2011)

- `+` ConVar "sm_kdrc_show_kill" to show the KD ratio to the attacker after a kill

## 1.5.0 (27.05.2011)

- `+` ConVar "sm_kdr_debug" to log player information during checks
- `!` Ignore bots
- `*` Chat messages
- `*` Code optimizations

## 1.4.0 (06.01.2011)

- `!` Ignore bots

## 1.3.0 (06.01.2011)

- `!` Ban management
- `!` KD calculation when deaths are zero
- `!` KD calculation when frags are negative
- `!` Show the KD ratio with two decimal places
- `!` Exclude bots from monitoring

## 1.2.0 (06.01.2011)

- `!` Fix ban management
- `!` Fix incorrect personal KD display

## 1.1.0 (05.01.2011)

- `+` Show your KD ratio by typing "kdr" or "!kdr" in chat
- `+` Show your KD ratio by typing "sm_kdr" / "kdr" in the console
- `+` ConVar to show your KD ratio at round end
- `+` ConVar to disable KD monitoring
- `+` SourceBans ban reason support

## 1.0.0 (06.12.2010)

- `+` Initial release
