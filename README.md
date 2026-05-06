# nb-pedwelcome

> Free welcome NPC for FiveM. New players walk up, get their starter package — cash, items, vehicles — and you keep your onboarding clean and professional.

[![Lua 5.4](https://img.shields.io/badge/Lua-5.4-blue.svg)](https://www.lua.org/)
[![Framework](https://img.shields.io/badge/framework-ESX%20%7C%20QBCore-success.svg)](#compatibility)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](#license)
[![Discord](https://img.shields.io/badge/discord-join-5865F2.svg)](https://neenbyss.com/discord)

Built and maintained by **[Neenbyss Studios](https://neenbyss.com/discord)**.

---

## What it does

A configurable NPC stands at the coordinates you choose. The first time a player approaches and interacts, they receive a customizable welcome package:

- **Cash and bank money** (independently configurable)
- **Items** (any list, any quantity, any inventory system)
- **Vehicles** that either land directly in their garage *or* spawn next to them — with a real collision check so cars never end up clipping into each other or stacked on top of a bystander.

One claim per identifier (license / citizenid). After they claim, the blip and interaction disappear so the NPC stops bothering them.

---

## Features

- **Framework agnostic** — works on ESX and QBCore through [`nb-bridge`](https://github.com/neenbyss/nb-bridge), no per-framework forks.
- **Auto-detects your stack** — picks up `ox_target` / `qb-target`, falls back to a marker + `[E]` prompt if you don't run a target system.
- **nb-garages integration** — vehicles in `garage` mode land in the configured garage label; in `spawn` mode they're created via the persistent vehicle export so they survive restarts.
- **Vehicle keys, automatically** — detects `qs-vehiclekeys`, `wasabi_carlock`, `MrNewbVehicleKeys`, `mk_vehiclekeys`, `qb-vehiclekeys`, and `t1ger_keys`. Manual override available for anything else.
- **Reward never lost** — if a spawn point is blocked, the vehicle still lands in the player's garage and the player is told to retrieve it.
- **One-time per identifier** — race-safe, enforced by a `UNIQUE` index on the DB.
- **Admin reset command** — `/nbpwreset [serverId]` lets a player claim again (great for testing or VIP rebirth flows).
- **Bilingual** — English and Spanish locales out of the box.
- **Tebex-escrow ready** — config, locale, and database bridge are listed in `escrow_ignore`; business logic is closed.

---

## Compatibility

| Layer            | Supported |
|------------------|-----------|
| Framework        | ESX, QBCore (via `nb-bridge`) |
| Database         | `oxmysql` |
| Target           | `ox_target`, `qb-target`, distance fallback |
| Inventory        | `ox_inventory`, `qb-inventory`, `qs-inventory`, framework default |
| Notifications    | `ox_lib`, framework native, GTA native (auto) |
| Garages          | `nb-garages` (auto-detected), or any system reading `owned_vehicles.garage` / `player_vehicles.garage` |
| Vehicle keys     | `qs-vehiclekeys`, `wasabi_carlock`, `MrNewbVehicleKeys`, `mk_vehiclekeys`, `qb-vehiclekeys`, `t1ger_keys`, manual hook |
| Progress / anim  | `ox_lib` progress bar, native fallback |

---

## Installation

1. **Drop the resource** into your `resources/` folder.
2. **Run the SQL** in `[sql]/pedwelcome.sql` against your database (creates `nb_pedwelcome_received`, idempotent).
3. **Add to `server.cfg`**, after `nb-bridge`:
   ```cfg
   ensure oxmysql
   ensure es_extended           # or qb-core
   ensure nb-bridge
   ensure nb-garages            # optional
   ensure nb-pedwelcome
   ```
4. **Open `shared/config.lua`** and adjust the ped, rewards, and (if used) the target garage label.
5. Restart and walk up to the NPC.

---

## Configuration highlights

Everything lives in `shared/config.lua`. The most common edits:

```lua
-- Where the NPC stands
Config.Ped.Coords = vector4(-1037.27, -2737.65, 19.17, 311.0)

-- What the player gets
Config.Rewards = {
    Money = { Cash = 5000, Bank = 10000 },
    Items = {
        { name = 'phone', amount = 1 },
        { name = 'water', amount = 5 },
    },
    Vehicles = {
        { Model = 'blista', Mode = 'garage' },
        { Model = 'sultan', Mode = 'spawn',
          Spawn = vector4(-1031.85, -2730.17, 20.16, 240.0) },
    },
}

-- Which nb-garages garage receives 'garage' mode vehicles
Config.NbGarages.AssignGarage = 'PillboxGarage'

-- Vehicle keys: 'auto' detects, 'manual' uses your event, 'off' disables
Config.Keys.Mode = 'auto'
```

The full file is heavily commented — every option has an explanation and every default has a sensible fallback.

---

## Admin

```
/nbpwreset           # reset your own welcome status
/nbpwreset 12        # reset welcome status for serverId 12
```

Admin groups are read from `Config.AdminGroups` (defaults to `admin`, `superadmin`, `god`).

---

## Support & community

This script — and a lot more — comes from **Neenbyss Studios**.

> **Need help, want a custom version, building a server from scratch, or fixing one that's been duct-taped for too long?**
>
> Join the Discord: **[neenbyss.com/discord](https://neenbyss.com/discord)**

We do:
- Custom FiveM scripts (Lua, NUI, frameworks, integrations)
- Full server builds — from a clean QBCore / ESX template to a finished, branded experience
- Server fixes, optimization, and migrations
- Free public releases (like this one) and premium scripts on Tebex

If this script saves you time, a star on the repo is the easiest way to say thanks.

---

## License

MIT. Use it, fork it, ship it. If you build something cool on top, let us know in the Discord.
