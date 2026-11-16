# Free FiveM Megaphone Script

A free megaphone for FiveM roleplay servers. Use the item and your character raises a megaphone: your voice gets a megaphone filter, carries further and comes through louder for everyone near you. On-duty police also get a menu of stock GTA police megaphone lines.

![Platform](https://img.shields.io/badge/platform-FiveM-orange)
![Frameworks](https://img.shields.io/badge/frameworks-Qbox%20%7C%20QBCore%20%7C%20ESX-blue)
![Language](https://img.shields.io/badge/language-Lua-000080)
![Price](https://img.shields.io/badge/price-free-success)

**Docs:** https://docs.bhavikp.in/scripts/bp-megaphone/ · **Store:** https://tebex.bhavikp.in/free-fivem-scripts/free-fivem-megaphone-script · **Forum:** https://forum.cfx.re/t/free-megaphone-script/5049366 · **Support:** https://discord.bhavikp.in

## Features

- Use the item to raise or lower the megaphone. No key to hold while talking.
- Megaphone voice filter, longer voice range (30 m by default, pma-voice) and louder volume for everyone who hears you.
- Players who walk up or join while you talk hear it too, and it comes back after a radio or phone call.
- Puts itself away on death, cuffs, swimming, vehicles or when the item is gone.
- Police lines: press **J** (or `/megaphonelines`) for 10 stock GTA police megaphone lines, heard within 60 m, in one of six voices. On-duty police jobs by default.
- Animation and prop built in. No emote menu entry needed.

## Requirements

| | |
| --- | --- |
| Library | [bp_lib](https://github.com/xDope7137/bp_lib) 0.9.2 or newer, [ox_lib](https://github.com/overextended/ox_lib) |
| Framework | Qbox, QBCore or ESX, through bp_lib |
| Inventory | Any inventory bp_lib supports |
| Voice | [pma-voice](https://github.com/AvarianKnight/pma-voice) for the longer range (filter, volume and lines work without it) |

## Installation

1. Install [bp_lib](https://github.com/xDope7137/bp_lib/releases) and ox_lib.
2. Copy `bp_megaphone` into `resources/`. Keep the folder name.
3. Add the item (below) and copy `images/megaphone.png` into your inventory's image folder.
4. Start it after its dependencies:

```cfg
ensure ox_lib
ensure pma-voice
ensure qbx_core
ensure bp_lib
ensure bp_megaphone
```

### Item

**ox_inventory** (`ox_inventory/data/items.lua`):

```lua
['megaphone'] = {
    label = 'Megaphone',
    weight = 500,
    stack = false,
    close = true,
    client = { export = 'bp_megaphone.useMegaphone' },
},
```

**QBCore** (`qb-core/shared/items.lua`), `useable` must be `true`:

```lua
megaphone = { name = 'megaphone', label = 'Megaphone', weight = 500, type = 'item', image = 'megaphone.png', unique = true, useable = true, shouldClose = true, description = 'Makes you heard' },
```

**ESX** without ox_inventory:

```sql
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('megaphone', 'Megaphone', 1, 0, 1);
```

## Configuration

Everything is in `config.lua`: item name, voice range, volume, voice filter, stop in vehicles, and the police lines (jobs, on-duty only, key, command, cooldown, range, voices, lines) plus every message for translating. Full table: [docs](https://docs.bhavikp.in/scripts/bp-megaphone/).

Police lines are also allowed by ACE:

```cfg
add_ace group.admin bp_megaphone.lines allow
```

## For developers

| Export | Side | |
| --- | --- | --- |
| `exports.bp_megaphone:useMegaphone()` | Client | Toggle, same as using the item (the server still checks the item) |
| `exports.bp_megaphone:openLines()` | Client | Open the police lines menu |

The on/off state is the player state bag `bp_megaphone`. Only the server turns it on.

## Credits

Megaphone animation from MollyEmotes (free custom emotes).

## More from BP Development

[tebex.bhavikp.in](https://tebex.bhavikp.in/)
