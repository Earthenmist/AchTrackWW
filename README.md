# Meta Hunter

**Meta Hunter** is a lightweight World of Warcraft addon for tracking curated
meta-achievement progress across expansions.

It currently supports **Midnight through Classic** using LoadOnDemand expansion
modules, so achievement data only loads when you select that expansion.

## Features

- Expansion sidebar ordered newest to oldest.
- Compact achievement trees grouped by category.
- Completion progress and status colouring.
- Click a row to open it in Blizzard's Achievement UI.
- Right-click a row to toggle objective tracking.
- Addon compartment and minimap launcher support.
- Profile-backed settings for display preferences.

## Supported Modules

- `MetaHunter_Midnight`
- `MetaHunter_TheWarWithin`
- `MetaHunter_Dragonflight`
- `MetaHunter_Shadowlands`
- `MetaHunter_BFA`
- `MetaHunter_Legion`
- `MetaHunter_WarlordsOfDraenor`
- `MetaHunter_MistsOfPandaria`
- `MetaHunter_Cataclysm`
- `MetaHunter_Wrath`
- `MetaHunter_TBC`
- `MetaHunter_Classic`

## Included Tracking

- Midnight expected preparation targets.
- The War Within, Dragonflight, Shadowlands, and Battle for Azeroth expansion
  metas and notable Glory roots.
- Legion through Classic notable dungeon, raid, Pathfinder, and broad
  completion achievements where applicable.

Older-expansion data is still being refined through in-game audit passes.

## Slash Commands

| Command | Function |
|--------|----------|
| `/mh` | Toggle Meta Hunter |
| `/metahunter` | Toggle Meta Hunter |

## Install

Install through CurseForge, or extract the release zip into:

`World of Warcraft/_retail_/Interface/AddOns/`

The release should install `MetaHunter` plus the `MetaHunter_<Expansion>`
module folders listed above.

The old `AchTrackWW` retirement folder is no longer shipped. If an addon
manager leaves `Interface/AddOns/AchTrackWW/` behind, it can be removed
manually.

## Notes

- Game version: Retail.
- Coverage: Midnight through Classic.
- Midnight's final expansion-wide meta has not been announced yet, so its
  module tracks likely preparation targets.
- Real prerequisite/lock-state handling is planned but not implemented yet.

## Support

For bug reports, feature requests, release notes, and beta builds, join:

**Earthenmist - Addon Hub**  
https://discord.gg/U8mKfHpeeP

## License

All Rights Reserved.

## Credits

Author: Earthenmist

Meta Hunter is developed, tested and maintained by Earthenmist. AI-assisted
development tools are used where helpful for coding, debugging and
documentation, but the direction, decisions and final implementation remain
human-led.
