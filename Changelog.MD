📜 Changelog – Version 1.0.6  
  
📅 Release Date: 22-01-2026  
  
🛠️ Changes & Improvements  
  
Right-clicking an achievement now tracks it in the Objective Tracker.  
Registered the main frame with WoW’s Escape handling system.  
  
Pressing ESC will now:  
  
Close the window.  
Respect UI order (won’t break other panels).  

Added a minimap button for quick access to AchTrackWW.   
Uses the custom AchTrackWW logo for consistent branding.  
Left-click toggles the main tracker window.  
Right-click hides or shows the minimap icon.  
Icon position and visibility are saved between sessions.  
  
🧾 Minimap Tooltip Enhancements  
  
Tooltip now clearly documents all available slash commands:  
  
/achtrack – Toggle the tracker window  
/achincomplete – Toggle “Incomplete only” mode  
/achfind – Search achievements by name  
/achrefresh – Refresh/rebuild the achievement list  
/achminimap – Show or hide the minimap icon  
  
Provides quick usage guidance without needing to remember commands.  
  
⚡ Performance Improvements  
  
Eliminated login and /reload UI freezes caused by heavy achievement scanning.  
Achievement title-to-ID scanning now only runs when unresolved labels are detected.  
Initial UI build no longer runs automatically on world entry.  
Opening the tracker window remains instant after first-time resolution.  
  
⚙️ Stability & Compatibility  
  
Minimap functionality is implemented in a separate module for improved modularity.  
Defensive initialisation ensures compatibility on first load and fresh installs.  
Improved resilience against incomplete or missing achievement data.  
  
🚀Thank you for using AchTrackWW!  
If you have suggestions, issues, or feature requests, please report them via GitHub.  
