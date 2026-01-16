📜 Changelog – Version 1.0.5  
  
📅 Release Date: 16-01-2026  
  
🛠️ Changes & Improvements  
  
Right-clicking an achievement now tracks it in the objective tracker  
Registered the frame with WoW’s Escape handling system  
  Pressing ESC will:  
  Close the window  
  Respect UI order (it won’t break other panels)  
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
  
🚀 Thank you for using AchTrackWW!  
If you have suggestions, issues, or feature requests, please report them via GitHub.  
