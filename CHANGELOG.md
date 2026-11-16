# Changelog

## [1.1.0] - 2026-11-16

Full rewrite. Now runs on [bp_lib](https://github.com/xDope7137/bp_lib) instead of jraxion_lib.

### Added
- Police megaphone lines: with the megaphone up, press J (or `/megaphonelines`) for 10 stock GTA police lines (Pull over, Stop the vehicle, Clear the area...), heard by everyone within 60 m. Six voices, male and female. On-duty police jobs by default, or the ACE `bp_megaphone.lines`.
- Voice range (`Config.Range`, pma-voice) and volume (`Config.Volume`) settings.
- Built-in animation and prop: no emote menu entry needed any more.
- Puts itself away on death, cuffs, swimming, vehicles or when the item is gone.
- `useMegaphone` and `openLines` client exports.

### Fixed
- Only the speaker's voice range changes. Before, every client overrode its own range, so everyone's voice HUD showed "Custom".
- The voice filter values are applied (they were all written as integer 1 before).
- Players who join or walk up while someone is talking hear the effect, and it returns after radio or phone calls.
- The server owns the on/off state (player state bag) and checks the item. A client can no longer turn the effect on by itself.
- The resource no longer has to be renamed for the item to work.

## [2026-10-07] - Submix event hardening

### Fixed
- `applySubmix` validates its argument and rate-limits per player (250 ms), so a modified client can no longer spam submix toggles at everyone.
