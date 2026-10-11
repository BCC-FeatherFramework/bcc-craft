# bcc-craft

> Crafting for RedM on the **Feather Framework**: crafting locations with NPCs, recipe categories unlocked by *Craft Books*, XP and levels, a crafting queue, and job-restricted recipes.

Version **2.0.0** is the Feather port of BryceCanyonCounty's bcc-crafting 1.4.0. Locations, recipes, menus, craft books, levels and translations are unchanged; items, weapons, money and jobs now go through Feather domains, and the server (not the client) decides what a recipe is. Port details: [FEATHER_PORT.md](FEATHER_PORT.md).

## Features

- **Crafting locations** with NPCs, blips and prompts (`configs/*.lua`).
- **Craft Books** unlock a location or category; they can be sold at the location for dollars and gold.
- **XP and levels**: recipes give XP and need a minimum level.
- **Crafting queue**: crafts finish over time and are collected at the location (or anywhere with `allowGlobalCollection`).
- **Materials and tools**: required items are consumed; needed tools (hammer, saw, ...) lose condition and can break.
- **Weapons and ammunition** are crafted as real feather-weapons items.
- **Job-restricted recipes** through feather-jobs.
- Optional Discord webhook and bcc-userlog playtime limits.

## How it uses Feather

| Concern | Feather resource |
|---|---|
| Player and character | feather-core sessions, feather-character (character UUIDs) |
| Materials, tools, crafted items | feather-inventory (counts, grant, remove, carry limits, tool condition) |
| Crafted weapons | feather-weapons `IssueWeapon` (purpose `crafting`) |
| Craft book prices | feather-economy wallet transfers |
| Job recipes | feather-jobs `CheckAssignment` |
| Menus | feather-menu-v2 |
| Prompts, blips, NPCs, progress bars | feather-toolkit |
| Notifications, translations | feather-notify, feather-core locales (`en_us`, `ro`, `pl`, `de`, `it`) |

## Requirements

Start these before `bcc-craft`:

```cfg
ensure feather-mysql
ensure feather-core
ensure feather-character
ensure feather-notify
ensure feather-toolkit
ensure feather-menu-v2
ensure feather-economy
ensure feather-inventory
ensure feather-weapons
ensure feather-organizations
ensure feather-jobs
ensure bcc-craft
```

Optional: `bcc-userlog` for playtime restrictions (`useBccUserlog`).

## Installation

1. Put the folder in `resources/[bcc]/bcc-craft` and add `ensure bcc-craft` after the resources above.
2. Trust bcc-craft in the Feather resources it calls (keep the entries already there):

   **feather-jobs/config.lua** (job recipes):

   ```lua
   Access = {
       trustedReaders = { ['feather-jobs'] = true, ['feather-admin'] = true,
           ['bcc-craft'] = true },
   }
   ```

   **feather-weapons/config.lua** (crafted weapons):

   ```lua
   -- inside the Config table
   Issuance = {
       trustedResources = { ["feather-weapons"] = true, ["feather-admin"] = true, ["bcc-craft"] = true },
       -- other Issuance settings unchanged
   },
   ```

   **feather-economy/config.lua** (craft book prices):

   ```lua
   Access = {
       trustedReaders      = { --[[ ... ]] ['bcc-craft'] = true },
       trustedProvisioners = { --[[ ... ]] ['bcc-craft'] = true },
       trustedTransactors  = { --[[ ... ]] ['bcc-craft'] = true },
   }
   ```

3. Import [sql/install_items.sql](sql/install_items.sql) once: the 47 materials, tools, food and tobacco items the recipes use. Craft books named in the config are added to the item table automatically on start.
4. Restart `feather-jobs`, `feather-weapons`, `feather-economy`, `feather-inventory` (to load the new items), then `ensure bcc-craft`.
5. Run `CraftReleaseSmokeTest` in the server console. It lists any recipe item, craft book or weapon that is still missing.

## Configuration

General settings are in [configs/main.lua](configs/main.lua); locations and recipes in `configs/ammo.lua`, `food.lua`, `others.lua` and `weapons.lua`.

A recipe:

```lua
{
    itemName = "trainoil",           -- feather-inventory item (or a feather-weapons weapon / ammo name)
    itemLabel = "Train Oil",
    itemAmount = 1,
    rewardXP = 10,
    requiredLevel = 3,
    duration = 40,                   -- seconds
    neededItems = {                  -- tools: kept, lose condition
        { itemName = "hammer", itemLabel = "Hammer" },
    },
    requiredItems = {                -- materials
        { itemName = "petroleum", itemLabel = "Crude Oil", itemCount = 10, removeItem = true },
    },
    requiredJobs = false,            -- or feather-jobs job keys:
    -- requiredJobs = { 'chef', { 'doctor', 10 } },   -- 'job' or { 'job', minimum grade ordinal }
    playAnimation = false,
    requiredPlaytimeMinutes = 0
}
```

| Setting | Purpose |
|---|---|
| `JobAccess.requireOnDuty` | Job recipes also need that job on duty |
| `HasCraftBooks` | Show a "buy craft book" button at every location |
| `craftbookprice`, `craftbookpricemoney`, `craftbookpricegold` (per location/category) | Book price, charged from the wallet through feather-economy |
| `WeaponsLimit`, `maxWeaponsAllowed` | Weapons per craft and per collection |
| `allowGlobalCollection` | Collect finished crafts from anywhere |
| `WebhookLink` | Discord webhook (empty = off; never commit a real link) |
| `useBccUserlog` | Playtime restrictions through bcc-userlog |
| `devMode` | Debug output; keep `false` on a live server |

Jobs in `requiredJobs` must exist in feather-jobs. They are registered by the resource that owns them, for example bcc-society's job types (`doctor`, `gunsmith`, `blacksmith`, ...).

## Usage

- Walk to a crafting location and press the prompt to open the menu.
- Use or buy the location's *Craft Book* to unlock its categories.
- Pick a recipe and an amount; finished crafts are collected from the same menu.

## Console

| Command | Purpose |
|---|---|
| `CraftReleaseSmokeTest` | Read-only release check: dev mode, Jobs trust, Economy, craft books, recipe items, weapon mapping |

## Not carried over

- `craftbookpricexp`: Feather has no character XP yet, so books do not cost XP.
- Book prices are two Economy transfers (dollars, then gold), checked for balance first.
- Toolkit progress bars last at most 10 minutes.

## Credits

Original script by [BryceCanyonCounty](https://github.com/BryceCanyonCounty/bcc-craft). Feather port by [BCC-FeatherFramework](https://github.com/BCC-FeatherFramework/bcc-craft). Licensed GPL-3.0.

Need help with the original gameplay? Join the BCC Discord: https://discord.gg/VrZEEpBgZJ
