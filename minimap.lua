-- minimap.lua (AchTrackWW)
-- LibDataBroker + LibDBIcon minimap launcher for AchTrackWW
local ADDON, ns = ...

AchTrackWWDB = AchTrackWWDB or {}
AchTrackWWDB.minimap = AchTrackWWDB.minimap or { hide = false }

local DEFAULT_ICON = "Interface\\AddOns\\AchTrackWW\\Images\\AchTrackWWLogo"

local function ToggleMainWindow()
  if ns and ns.ToggleWindow then
    ns.ToggleWindow()
    return
  end
  if SlashCmdList and SlashCmdList["ACHTRACKWW"] then
    SlashCmdList["ACHTRACKWW"]()
  end
end

local function SetupMinimapIcon()
  AchTrackWWDB = AchTrackWWDB or {}
  AchTrackWWDB.minimap = AchTrackWWDB.minimap or { hide = false }
  local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
  local DBI = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
  if not LDB or not DBI then return end

  if ns and ns._minimapRegistered then return end
  if ns then ns._minimapRegistered = true end

  local obj = LDB:NewDataObject("AchTrackWW", {
    type = "launcher",
    text = "AchTrackWW",
    icon = DEFAULT_ICON,
    OnClick = function(_, button)
      if button == "LeftButton" then
        ToggleMainWindow()
      elseif button == "RightButton" then
        AchTrackWWDB.minimap.hide = not AchTrackWWDB.minimap.hide
        if AchTrackWWDB.minimap.hide then
          DBI:Hide("AchTrackWW")
        else
          DBI:Show("AchTrackWW")
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddLine("AchTrackWW", 1, 0.82, 0)
      tooltip:AddLine(" ", 1, 1, 1)
      tooltip:AddLine("Left-click: Toggle window", 1, 1, 1)
      tooltip:AddLine("Right-click: Show/Hide minimap icon", 1, 1, 1)
      tooltip:AddLine(" ", 1, 1, 1)
      tooltip:AddLine("Slash commands:", 0.9, 0.9, 0.9)
      tooltip:AddLine("/achtrack  - Toggle the tracker window", 1, 1, 1)
      tooltip:AddLine("/achincomplete  - Toggle 'Incomplete only'", 1, 1, 1)
      tooltip:AddLine("/achfind <keyword>  - Search achievements by name", 1, 1, 1)
      tooltip:AddLine("/achrefresh  - Refresh/rebuild the list", 1, 1, 1)
      tooltip:AddLine("/achminimap  - Show/Hide the minimap icon", 1, 1, 1)
    end,
    })

  DBI:Register("AchTrackWW", obj, AchTrackWWDB.minimap)
  if AchTrackWWDB.minimap.hide then DBI:Hide("AchTrackWW") end
end

function ns.InitMinimap()
  SetupMinimapIcon()
end
