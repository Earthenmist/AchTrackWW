local ADDON_NAME, MH = ...

--[[
  Always-loaded expansion identity and load targets. Achievement trees live in
  LoadOnDemand sub-addons and register themselves only when selected.
]]

local Manifest = {}
MH.ExpansionManifest = Manifest

local NO_EXPANSION_META_NOTICE = {
  title = "No Expansion-Wide Meta",
  body = "This expansion does not appear to have a single expansion-wide meta achievement. Meta Hunter tracks notable dungeon, raid, and expansion achievements instead.",
}

-- Display order for the sidebar: newest/current expansion first, then reverse
-- chronological. Keep this list to identity and load metadata only.
Manifest.entries = {
  {
    id = "midnight",
    displayName = "Midnight",
    subAddon = "MetaHunter_Midnight",
    notice = {
      title = "Midnight Criteria May Change",
      body = "Midnight's overall expansion-wide meta has not been announced yet. The achievements shown here are expected preparation targets and may change as the expansion progresses.",
    },
  },
  {
    id = "the-war-within",
    displayName = "The War Within",
    subAddon = "MetaHunter_TheWarWithin",
  },
  {
    id = "dragonflight",
    displayName = "Dragonflight",
    subAddon = "MetaHunter_Dragonflight",
  },
  {
    id = "shadowlands",
    displayName = "Shadowlands",
    subAddon = "MetaHunter_Shadowlands",
  },
  {
    id = "bfa",
    displayName = "Battle for Azeroth",
    subAddon = "MetaHunter_BFA",
    summaryMode = "immediate",
  },
  {
    id = "legion",
    displayName = "Legion",
    subAddon = "MetaHunter_Legion",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "warlords-of-draenor",
    displayName = "Warlords of Draenor",
    subAddon = "MetaHunter_WarlordsOfDraenor",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "mists-of-pandaria",
    displayName = "Mists of Pandaria",
    subAddon = "MetaHunter_MistsOfPandaria",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "cataclysm",
    displayName = "Cataclysm",
    subAddon = "MetaHunter_Cataclysm",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "wrath",
    displayName = "Wrath of the Lich King",
    subAddon = "MetaHunter_Wrath",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "the-burning-crusade",
    displayName = "The Burning Crusade",
    subAddon = "MetaHunter_TBC",
    notice = NO_EXPANSION_META_NOTICE,
  },
  {
    id = "classic",
    displayName = "Classic",
    subAddon = "MetaHunter_Classic",
    notice = NO_EXPANSION_META_NOTICE,
  },
}

local byID = {}
for _, entry in ipairs(Manifest.entries) do
  byID[entry.id] = entry
end

function Manifest:Get(expansionID)
  return byID[expansionID]
end

function Manifest:GetAll()
  return self.entries
end

--- Ensures an expansion sub-addon is loaded, then calls
--- `callback(success, reason)`. Unknown expansion IDs are programmer errors;
--- load failures are reported through the callback for the UI to handle.
function Manifest:EnsureLoaded(expansionID, callback)
  local entry = byID[expansionID]
  if not entry then
    error("MetaHunter: unknown expansionID " .. tostring(expansionID))
  end

  if MH.Compat.IsAddOnLoaded(entry.subAddon) then
    if callback then callback(true) end
    return
  end

  local loaded, reason = MH.Compat.LoadAddOn(entry.subAddon)
  if callback then callback(loaded and true or false, reason) end
end

--- Returns expansionID's cached summary ({earned, total}), or nil if one has
--- not been computed yet. Does not load the expansion sub-addon.
function Manifest:GetCachedSummary(expansionID)
  local cache = MH.db and MH.db.global.expansionSummaries
  return cache and cache[expansionID]
end

--- Recomputes expansionID's summary from live registered data and persists it
--- to the SavedVariables cache. Requires the sub-addon to be loaded first.
function Manifest:RefreshSummary(expansionID)
  local roots = MH.Registry:GetRoots(expansionID)
  if not roots or #roots == 0 then return nil end

  local entry = self:Get(expansionID)
  local earned, total = 0, 0
  for _, rootID in ipairs(roots) do
    if entry and entry.summaryMode == "immediate" then
      local progress = MH.Engine:GetProgress(rootID, rootID)
      earned = earned + progress.earned + (MH.Engine:IsEarned(rootID) == true and 1 or 0)
      total = total + progress.total + 1
    else
      local progress = MH.Engine:GetProgressRecursive(rootID, rootID)
      earned = earned + progress.earned
      total = total + progress.total
    end
  end

  local summary = { earned = earned, total = total }
  local cache = MH.db and MH.db.global.expansionSummaries
  if cache then
    cache[expansionID] = summary
  end
  return summary
end
