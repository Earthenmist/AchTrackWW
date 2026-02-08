# AchTrackWW – The War Within Meta Achievement Tracker 

Overview

AchTrackWW is a clean, lightweight achievement tracker for The War Within (and beyond).
It shows a curated list of important meta/zone/raid/delve achievements with:

Green = completed, Red = not yet, Grey = locked by prerequisites, Amber = unresolved title.

Click to open the Blizzard Achievement UI on the right achievement.

Smart sorting: locked → incomplete → complete → unresolved.

Prerequisites: metas display requires lines (by label or ID) and lock until all are done.

“Any-of” support: where Blizzard replaces or scales achievements, any of the configured IDs counts (e.g., Bounty Seeker ↔ Vigilante; multi-ID raid clears like Nerub-ar Palace).

Friendly tooltips show ✓/✗ for each prerequisite and candidate achievement.

Why use it?

Focuses on real-world goals for The War Within content (zones, delves, Undermine, K’aresh, raids).

Clear UI that’s compatible with the default look and feel.

Zero bloat, zero performance drama.

Features

Curated list: Isle of Dorn, Ringing Deeps, Hallowfall, Azj-Kahet, Khaz Algar Explorer, Pathfinder, major metas like All That Khaz, You Xal Not Pass, Glory of the Delver, Going Goblin Mode, Unraveled and Persevering, plus raid clears (Nerub-ar Palace, Liberation of Undermine, Manaforge Omega).

Delve chains incl. Moonlighter → Bounty Seeker/Vigilante and Nemesis achievements (My First / New / Stab-Happy).

Smart prerequisite awareness using requires (IDs) and requires_labels (other rows).

Any-of IDs for achievements that scale/replace.

Click-through navigation to the exact Blizzard achievement when available.

Live updates when achievements are earned (debounced to avoid spam).

Movable, scrollable frame with a close button.

Minimal dependencies; uses Blizzard’s Achievement UI.

Slash Commands

/achtrack — Toggle the tracker window.

/achfind <keyword> — Quick search helper that prints matching achievement names & IDs (max 20 lines).

/achrefresh — Rebuild/sort list on demand.

Installation

Download the release and unzip to:
_retail_/Interface/AddOns/AchTrackWW/

Files should be:
AchTrackWW.toc and AchTrackWW.lua

Launch/reload WoW and run /achtrack.

How it Works (short & sweet)

On open, the addon maps titles → IDs from the game’s category lists.

Some achievements are hidden until earned; these are tracked by ID.

Any-of entries mark complete if any provided IDs are earned.

Metas can declare requires (IDs) and/or requires_labels (names of other rows).
If any prerequisite is missing, the meta shows locked (grey) and clicking it opens the first unmet prerequisite.

Known Quirks

If Blizzard keeps an achievement fully hidden until earned, clicking that row before you have credit may not navigate (normal Blizzard behavior).

Title lookups depend on localized names. Prefer ID entries for hidden or region-localized differences (use /achfind to confirm).

Performance

Ultra-lightweight.

Debounced event handling for ACHIEVEMENT_EARNED.

No savedvariables bloat; only trivial config/state if needed.

Localization

English labels are provided. For fully localized titles, either:

Switch entries to IDs, or

Adjust the label strings to match your locale’s achievement names.

Support / Feedback

Found a swapped ID or another scaling achievement? Post the name/ID and whether it’s any-of or has prerequisites and I’ll add it.

Suggestions for extra metas welcome.
