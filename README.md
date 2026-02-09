# AchTrackWW

**AchTrackWW** is a clean, lightweight achievement tracker for **The War Within** (and beyond).

It displays a curated list of important **meta / zone / raid / delve** achievements in a compact UI, with smart prerequisite awareness, click-through navigation, and zero bloat.

## 🎨 Status Colours
- **Green** = Completed
- **Red** = Not yet completed
- **Grey** = Locked by prerequisites
- **Amber** = Unresolved title / lookup issue

## ✨ Features
- Curated achievement list focused on real-world TWW goals:
  - Isle of Dorn, Ringing Deeps, Hallowfall, Azj-Kahet
  - Khaz Algar Explorer, Pathfinder
  - Major metas like **All That Khaz**, **You Xal Not Pass**, **Glory of the Delver**
  - Undermine / K’aresh achievements
  - Raid clears (Nerub-ar Palace, Liberation of Undermine, Manaforge Omega)
- Smart sorting:
  - Locked → Incomplete → Complete → Unresolved
- Prerequisite support:
  - Metas can define `requires` (IDs) and/or `requires_labels` (other rows)
  - Locked metas remain grey until all prerequisites are done
  - Clicking a locked meta opens the first unmet prerequisite
- “Any-of” ID support:
  - If Blizzard replaces or scales achievements, any configured ID can satisfy completion  
    (example: **Bounty Seeker ↔ Vigilante**, multi-ID raid clears)
- Friendly tooltips:
  - Shows ✓/✗ for each prerequisite and candidate achievement
- Click-through navigation to the exact Blizzard achievement (when available)
- Live updates when achievements are earned (debounced to avoid spam)
- Movable, scrollable frame with a close button
- Minimal dependencies — uses Blizzard’s Achievement UI only

## ❓ Why use it?
- Focused on real-world goals for The War Within content (zones, delves, Undermine, K’aresh, raids)
- Clean UI that matches the default look and feel
- Ultra-lightweight and performance-friendly

## 💬 Slash Commands
| Command | Function |
|--------|----------|
| `/achtrack` | Toggle the tracker window |
| `/achfind <keyword>` | Search helper (prints matching achievement names & IDs, max 20 lines) |
| `/achrefresh` | Rebuild/sort the list on demand |

## 🧠 How it Works (Short & Sweet)
- On open, the addon maps titles → IDs from Blizzard’s achievement category lists
- Some achievements are hidden until earned; these are tracked by ID
- “Any-of” entries are marked complete if **any** configured ID is earned
- Metas can declare prerequisites using:
  - `requires` (achievement IDs)
  - `requires_labels` (names of other rows)
- If prerequisites are missing, the meta is locked (grey) and clicking opens the first unmet prerequisite

## 📝 Known Quirks
- If Blizzard keeps an achievement fully hidden until earned, clicking that row before you have credit may not navigate  
  *(normal Blizzard behaviour)*
- Title lookups depend on localized names. Prefer ID entries for hidden or region-localised differences  
  (use `/achfind` to confirm)

## ⚡ Performance
- Ultra-lightweight
- Debounced event handling for `ACHIEVEMENT_EARNED`
- No SavedVariables bloat (only trivial config/state if needed)

## 🌍 Localization
English labels are provided. For fully localized titles, either:
- Switch entries to IDs, or
- Adjust the label strings to match your locale’s achievement names

## 📦 Install
### CurseForge
- Install via the CurseForge app or download the latest release.

### Manual
1. Download the latest release `.zip`.
2. Extract into: `World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure the folder name is `AchTrackWW` (not nested).
4. Relaunch the game.

## 🧩 Compatibility
- **Game:** Retail
- **Era:** The War Within / Midnight-ready
- **Dependencies:** None

## 💬 Support & Community
For bug reports, feature requests, release notes, and beta builds, join the official Discord:

**LanniOfAlonsus • Addon Hub**  
https://discord.gg/U8mKfHpeeP

## 📜 License
All Rights Reserved.

## ❤️ Credits
- **Author:** LanniOfAlonsus
