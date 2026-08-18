local ADDON_NAME, MH = ...

MH.ADDON_NAME = ADDON_NAME

local LDB_NAME = "MetaHunter"
local LOGO_TEXTURE = "Interface\\AddOns\\MetaHunter\\Media\\MetaHunterLogo"

-- Publish the shared namespace for LoadOnDemand expansion modules. Files in
-- the main addon still use their local `...` namespace.
_G[ADDON_NAME] = MH

-- The addon object only carries the Ace3 mixins needed for events and slash
-- commands; shared modules attach their APIs directly to MH.
MH.Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

local Addon = MH.Addon

local function ToggleMainWindow()
  if MH.UI and MH.UI.MainFrame then
    MH.UI.MainFrame:Toggle()
  end
end

local function AddLauncherTooltipLines(tooltip)
  tooltip:SetText("Meta Hunter", 1, 1, 1)
  tooltip:AddLine("Left-click to open Meta Hunter.", nil, nil, nil, true)
  tooltip:AddLine("Drag to move the minimap button.", nil, nil, nil, true)
end

function MH:SetMinimapButtonShown(shown)
  if not self.db or not self.db.profile then return end
  self.db.profile.minimap = self.db.profile.minimap or {}
  local minimap = self.db.profile.minimap
  minimap.hide = not shown

  if self.Launcher and self.Launcher.icon then
    if shown then
      self.Launcher.icon:Show(LDB_NAME)
    else
      self.Launcher.icon:Hide(LDB_NAME)
    end
  end
end

function MH:IsMinimapButtonShown()
  return not (self.db and self.db.profile and self.db.profile.minimap and self.db.profile.minimap.hide)
end

function MetaHunter_OnAddonCompartmentClick()
  ToggleMainWindow()
end

function MetaHunter_OnAddonCompartmentEnter(addonName, menuButtonFrame)
  if not GameTooltip or not menuButtonFrame then return end
  GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
  AddLauncherTooltipLines(GameTooltip)
  GameTooltip:Show()
end

function MetaHunter_OnAddonCompartmentLeave()
  if GameTooltip then GameTooltip:Hide() end
end

-- AceDB defaults. `profile` stores per-character UI preferences; account-wide
-- lookup caches live under `global`.
local DEFAULTS = {
  global = {
    resolvedByLabel = {}, -- title -> achievementID
    -- expansionID -> { earned, total }; refreshed when an expansion is opened.
    expansionSummaries = {},
  },
  profile = {
    showExpansionNotices = true,
    autoExpandMainMeta = true,
    minimap = {
      hide = false,
    },
  },
}

function Addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", DEFAULTS, true)
  MH.db = self.db
  self.db.profile.minimap = self.db.profile.minimap or {}

  local ldb = LibStub("LibDataBroker-1.1", true)
  local icon = LibStub("LibDBIcon-1.0", true)
  if not ldb or not icon then return end

  local dataObject = ldb:NewDataObject(LDB_NAME, {
    type = "launcher",
    label = "Meta Hunter",
    text = "Meta Hunter",
    icon = LOGO_TEXTURE,
    OnClick = function(_, button)
      if button == "LeftButton" then
        ToggleMainWindow()
      end
    end,
    OnTooltipShow = AddLauncherTooltipLines,
  })

  MH.Launcher = {
    dataObject = dataObject,
    icon = icon,
  }
  icon:Register(LDB_NAME, dataObject, self.db.profile.minimap)
end
