# Changelog

All notable changes to **nb-pedwelcome** are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] — 2026-05-05

### Added
- **Visible welcome NPC.** A floating chevron above the NPC's head (visible from up to 30m) and a 3D label that appears as the player approaches now make it obvious that the NPC is interactive — addressing the most common feedback from v1.0.0/v1.0.1 where players were walking past the NPC without realising they could talk to it.
- **`Config.Indicators`** block in `shared/config.lua`. Both indicators are independently toggleable and fully restyleable (color, size, distance, height, bob/rotate).
- **Localized label text** in EN and ES (`floating_label` key in `shared/locale.lua`).

## [1.0.1] — 2026-05-05

### Fixed
- **No more crash on claim** when `nb-garages` is running but its `Config.PersistentVehicles` is set to `false`. The previous availability check unintentionally invoked the missing export through the FiveM exports proxy, raising `No such export SpawnPersistentVehicle`. The call is now wrapped in `pcall`, the missing-export case is detected and cached after the first attempt, and subsequent vehicles in the same claim short-circuit straight to the client-side spawn fallback. Rewards are never lost — vehicles always end up in the player's garage regardless of the spawn path.

## [1.0.0] — 2026-05-05

First public release.

### Added
- **Configurable welcome NPC** with model, coordinates, scenario, freeze/invincible flags, and an optional map blip.
- **One-time-per-identifier reward system** for cash, bank, items, and vehicles. Enforced server-side with a `UNIQUE` SQL index so concurrent claims cannot double-deliver.
- **Vehicle rewards** with two delivery modes per vehicle:
  - `garage` — inserted directly into the player's framework garage.
  - `spawn` — physically created next to the player after a real collision check against vehicles, peds, and static props, with configurable retry offsets if the primary spawn point is blocked.
- **Reward never lost.** If a `spawn` location stays blocked after retries, the vehicle still lands in the player's garage and a notification tells the player to retrieve it.
- **Auto-detection** for the most common server stacks:
  - Frameworks: ESX and QBCore via [`nb-bridge`](https://github.com/neenbyss/nb-bridge).
  - Targets: `ox_target`, `qb-target`, with a marker + `[E]` prompt fallback when neither is installed.
  - Inventories: `ox_inventory`, `qb-inventory`, `qs-inventory`, framework default.
  - Notifications and progress bars: `ox_lib`, framework native, GTA native.
- **`nb-garages` integration.** Vehicles are placed under the configured garage label (overridable per vehicle), and `mode = 'spawn'` rewards are spawned via `exports['nb-garages']:SpawnPersistentVehicle` when nb-garages has persistence enabled — so the reward survives server restarts.
- **Vehicle keys auto-detection** for `qs-vehiclekeys`, `wasabi_carlock`, `MrNewbVehicleKeys`, `mk_vehiclekeys`, `qb-vehiclekeys`, and `t1ger_keys`, plus a manual hook for any other key system.
- **`/nbpwreset [serverId]`** admin command to clear a player's claim — useful for testing or VIP rebirth flows.
- **Bilingual locale** (EN + ES) via `shared/locale.lua`.
- **Tebex-escrow ready.** Config, locale, debugger, and database bridge are listed in `escrow_ignore`; business logic stays closed.

---

Built and maintained by **Neenbyss Studios** — custom FiveM scripts, full server builds from scratch, and rescue jobs on tired servers.

Join the Discord: **[neenbyss.com/discord](https://neenbyss.com/discord)**

[1.0.2]: https://github.com/neenbyss/nb-pedwelcome/releases/tag/v1.0.2
[1.0.1]: https://github.com/neenbyss/nb-pedwelcome/releases/tag/v1.0.1
[1.0.0]: https://github.com/neenbyss/nb-pedwelcome/releases/tag/v1.0.0
