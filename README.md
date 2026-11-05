# EnderDevelopment — Custom Drugs System

A modular drugs system for FiveM. Supports **ESX**, **QBCore**, and **standalone** (log-only) frameworks. This resource provides a complete drug economy with harvesting, processing, selling, and unique player effects.

## Features

- **10 custom drugs** with unique effects (walk styles, run speed, overdose risk).
- **Harvest zones** that give raw drugs on a timed interaction.
- **Processing zones** that convert raw drugs into sellable products.
- **Sell zones** with NPC dealers that pay configurable prices.
- **Overdose system** with cumulative toxicity and damage.
- Marker + prompt drawing, NPC spawning, progress bars.

## Installation

1. Copy this folder into your server's `resources` directory.
2. Add `ensure ender_drugs` to your server config.
3. Import `items.sql` into your database so the inventory knows the drug items.
4. Set `Config.Framework` in `config.lua` to `'esx'`, `'qb'`, or `'standalone'`.
5. (Optional) Enable `ox_lib` / QB progress in `client/main.lua` by uncommenting the lines in the `ProgressBar` and `notify` helpers.

## Commands (client)

| Command      | Action                                |
|--------------|---------------------------------------|
| `/drug`      | Lists available drugs                 |
| `/usedrug <id>` | Uses the selected drug              |
| `/sell <id>` | Sells a drug while at a dealer        |

## Configuration

Everything is tuned in `config.lua`:

- `Config.Drugs` — item names, labels, sell values, effect times, effects.
- `Config.CropZones` — where raw drugs are harvested.
- `Config.ProcessingZones` — where raw drugs are processed.
- `Config.SellZones` — NPC dealer locations and pricing policy.
- `Config.Effects` — walk style / speed / toxicity per effect type.
- `Config.Overdose` — toxicity threshold, damage and chance.

Police-pressure blocking is optional per zone via `policeThreshold` (set to `0` to disable).

## Note

This resource uses your framework's inventory (ESX / QBCore items). Make sure the item names defined in `Config.Drugs` exist as inventory items in your framework (see `items.sql`).

---

More FiveM resource projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/1720db30-9024-487e-aa18-da3acbac9639?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=1720db30-9024-487e-aa18-da3acbac9639
