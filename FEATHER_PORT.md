# BCC Craft: Feather port

**Status:** code complete on the development server (2026-10-08); not yet live-tested.
**Version:** 2.0.0 (from upstream bcc-craft 1.4.0)
**Plan:** phase B1 of the [BCC on Feather master plan](https://github.com/BCC-FeatherFramework/bcc-feather-masterplan).

Everything a server owner sees stays: crafting locations, NPCs, blips, prompts,
categories, recipes (`configs/*.lua`), menus, craft books, levels and XP, the crafting
queue and collection, translations, the Discord webhook and the optional bcc-userlog
playtime check. What changed is the framework underneath and that the server, not the
client, now decides what a recipe is.

## What moved where

| Before (VORP) | Now (Feather) |
|---|---|
| `vorp_core` user, `charIdentifier` | `feather-core` session, character UUID (`bcc_crafting_log`, `bcc_craft_progress`) |
| `character.job` / `jobGrade` in `requiredJobs` | `feather-jobs` `CheckAssignment`: `'job'` or `{ 'job', minGrade }` (grade ordinal) |
| `vorp_inventory` counts, add, remove, limits | `feather-inventory` `GetItemCount`, `GrantItem`, `RemoveItemByName`, `max_quantity`, `InventoryCanHold` |
| Tool durability in item metadata | `feather-inventory` item condition (0–100) on unique tools; stackable tools are not worn |
| `createWeapon` | `feather-weapons` `IssueWeapon` (purpose `crafting`), matched by `nativeWeaponName` |
| Book price via `char.removeCurrency` | `feather-economy` wallet transfers (dollars and gold) to the system sink |
| `bcc-utils` RPC, prompts, blips, peds, webhook | `feather-core` RPC, `feather-toolkit` prompts/blips/peds, local webhook sender |
| `feather-menu` (v1) | `feather-menu-v2` through `client/feather/menu_v2.lua` |
| `feather-progressbar` | `feather-toolkit` progress, behind the same `progressbar.start/onCancel` calls |
| Local `Locales` table | `feather-core` locales (`en_us`, `ro`, `pl`, `de`, `it`), keys prefixed `bcc-craft.` |
| Item images from `vorp_inventory` | `feather-inventory/ui/images/items` |

There is no VORP, `bcc-utils`, `oxmysql`, Menu v1 or `feather-progressbar` code left.

## Security and bug fixes

- **Recipes come from the server config.** Upstream accepted the whole recipe from the
  client (materials, yield, XP, duration), so a modified client could craft anything for
  free. Now the client names a location and item; the server looks up the rest.
- **Collection loads the log from the database**, only the player's own completed rows.
- **Craft books:** only books configured on a location or category can be given, at the
  configured price, one at a time.
- Required materials are checked for the full amount (upstream checked one batch but
  removed all of them).
- `AttemptCraft` answered twice; it now answers once.
- The Italian translation registered as English and could overwrite it; it is now `it`.

## Not carried over

- `craftbookpricexp` (character XP for books): Feather has no character XP yet, so it is
  not checked. Dollars and gold are still charged.
- Book prices are two Economy transfers (dollars, then gold), checked for balance first;
  they are not one atomic payment.
- Toolkit progress bars last at most 10 minutes; longer animated crafts show a shorter bar.

## Data

`charidentifier` now holds character UUIDs (it is `varchar(50)`, no schema change).
Logs and progress rows of VORP numeric characters stay in the table but no Feather
character matches them. Craft books named in the config are added to `items` once on
start; restart feather-inventory afterwards so it loads them.

## Trust needed in other resources

| Resource | Setting | Entry |
|---|---|---|
| feather-jobs | `Config.Access.trustedReaders` | `['bcc-craft'] = true` |
| feather-weapons | `Config.Issuance.trustedResources` | `["bcc-craft"] = true` |
| feather-economy | `trustedReaders`, `trustedProvisioners`, `trustedTransactors` | `['bcc-craft'] = true` |

## Console

| Command | Purpose |
|---|---|
| `CraftReleaseSmokeTest` | Read-only: dev mode, Jobs trust, Economy, books, recipe items and weapon mapping |

## Remaining work

1. Live test every flow: craft with and without animation, cancel, queue, collect (full
   and partial), tool wear and break, weapon craft, book use, book purchase.
2. Recipe items that do not exist in feather-inventory (the smoke test lists them) need
   item definitions; retired weapons (for example the standard lantern) need recipes removed.
