📜 Changelog – Version 1.0.3  
  
📅 Release Date: 15-01-2026  
  
🆕 New Features  
🧭 Minimap Icon  
  
Added a minimap button for quick access to AchTrackWW.  
Uses the custom AchTrackWW logo for consistent branding.  
Left-click toggles the main tracker window.  
Right-click hides or shows the minimap icon.  
Icon position and visibility are saved between sessions.  
  
🧾 Minimap Tooltip Enhancements  
  
Tooltip now clearly documents all available slash commands:  
  
/achtrack – Toggle the tracker window  
/achincomplete – Toggle “Incomplete only” mode  
/achfind <keyword> – Search achievements by name  
/achrefresh – Refresh/rebuild the achievement list  
/achminimap – Show or hide the minimap icon  
  
Provides quick usage guidance without needing to remember commands.  
  
⚙️ Stability & Compatibility  
  
Minimap functionality is implemented in a separate module for improved modularity.  
Defensive initialisation ensures compatibility on first load and fresh installs.  

📜 Changelog – Version 1.0.2  
  
📅 Release Date: 15-01-2026  
  
🛠️ Changes & Improvements  
🎨 UI & Visual Polish  
  
Repositioned the “Incomplete only” toggle beneath the title for improved layout and clarity.  
Added additional vertical padding before the achievement list to enhance readability.  
Improved overall spacing and alignment for a cleaner, more intentional UI presentation.  
  
🧩 Tooltip Improvements  
  
Replaced font-based status symbols with Blizzard’s built-in Ready Check icons:  
  
Green tick for completed achievements  
Red cross for incomplete achievements  
Resolves issues where some fonts rendered status symbols as coloured squares.  
Ensures consistent appearance across all locales and clients.  
  
🌍 Localization & Robustness  
  
Improved locale-safe handling of achievement resolution by persisting resolved IDs.  
Tooltip and UI elements now render correctly on non-English clients.  
  
⚙️ Performance & Stability  
  
Cached achievement title lookups for the session to reduce unnecessary API scanning.  
Hardened Achievement UI opening logic to prevent edge-case failures.  
Verified compatibility with Retail 11.x and Midnight 12.x clients.  
  
🚀 Thank you for using AchTrackWW!  
If you have suggestions, issues, or feature requests, please report them via GitHub.  
