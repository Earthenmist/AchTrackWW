local ADDON_NAME, MH = ...
local Registry = MH.Registry

--[[
  Achievement completion and lock-state resolution. Walks the indexed registry
  (achievementsByID/childrenByParentID/placements) to arbitrary depth.

  Completion is never re-derived from our own tree. Blizzard already tracks
  whether a composite ("meta") achievement is complete server-side, the same
  as any leaf achievement -- our tree exists to organize and group IDs for
  browsing/progress display. The one exception is an authored virtual
  `oneOfAchievementIDs` criterion row: that row represents one Blizzard
  criterion satisfied by any one of several real achievements, so IsEarned()
  checks the listed alternates directly.

  Lock state is not modeled yet. The schema has no prerequisiteIDs-style field
  for sequential unlock gates, so GetLockState() currently reports unlocked.
]]

local Engine = {}
MH.Engine = Engine

-- Prefer the namespaced API where present, falling back to the classic global
-- on older clients.
local function GetAchievementInfoCompat(id)
  if C_AchievementInfo and C_AchievementInfo.GetAchievementInfo then
    return C_AchievementInfo.GetAchievementInfo(id)
  end
  return GetAchievementInfo(id)
end
Engine.GetAchievementInfoCompat = GetAchievementInfoCompat

-- Whether a single, bare achievementID (not resolved against variantIDs --
-- see Engine:IsEarned for that) is completed. Returns nil, not false, if
-- the client has no data for this ID at all (unknown/not-yet-existing on
-- this game version) -- distinct from a known "not completed," so callers
-- can tell the two apart rather than silently treating both as false.
local function IsIDEarned(id)
  if not id then return nil end
  local achID, _, _, completed = GetAchievementInfoCompat(id)
  if not achID then return nil end
  return completed and true or false
end
Engine.IsIDEarned = IsIDEarned

--- Whether the achievement identified by `achievementID` (a canonical,
--- registered ID -- not necessarily one of its own variantIDs) counts as
--- earned: true if its own ID is complete, or if ANY of its registered
--- variantIDs is complete (raid-difficulty tiers, an upgraded achievement
--- superseding an earlier one).
--- Returns nil only if `achievementID` isn't registered at all.
function Engine:IsEarned(achievementID)
  local record = Registry:GetAchievement(achievementID)
  if not record then return nil end

  if type(record.oneOfAchievementIDs) == "table" then
    for _, alternateID in ipairs(record.oneOfAchievementIDs) do
      if IsIDEarned(alternateID) == true then return true end
    end
    return false
  end

  if type(achievementID) ~= "number" then return false end

  if IsIDEarned(achievementID) == true then return true end

  if type(record.variantIDs) == "table" then
    for _, variantID in ipairs(record.variantIDs) do
      if IsIDEarned(variantID) == true then return true end
    end
  end

  -- Own ID or a variant may individually come back nil (unknown to this
  -- client) without the achievement as a whole being unearned -- but once
  -- nothing came back true, "not earned" is the honest answer either way.
  --
  -- This deliberately collapses IsIDEarned's nil ("unknown to this client")
  -- vs. false ("known, not completed") distinction into a single boolean.
  -- Add a separate GetEarnedState() if the UI ever needs to preserve the
  -- three-way unknown/not-done/done distinction.
  return false
end

--- Immediate-children completion progress for `achievementID` at one
--- specific tree position: rootID identifies which tree, achievementID is
--- this node's own ID (used as the parentID key for ITS children, per
--- Registry:GetChildren). Returns { total, earned, childIDs }. A leaf node
--- (no children registered at this position) returns total = 0, earned = 0.
--- Does not recurse past immediate children -- a composite grandchild's own
--- completion is asked about directly (per the module note above), not
--- expanded into its own children's progress here.
function Engine:GetProgress(rootID, achievementID)
  local children = Registry:GetChildren(rootID, achievementID)
  local progress = { total = 0, earned = 0, childIDs = {} }
  if not children then return progress end

  progress.total = #children
  for _, childID in ipairs(children) do
    table.insert(progress.childIDs, childID)
    if self:IsEarned(childID) == true then
      progress.earned = progress.earned + 1
    end
  end
  return progress
end

--- Recursively counts total/earned across achievementID's ENTIRE subtree
--- within rootID's tree (achievementID itself plus every descendant, at
--- any depth) -- unlike GetProgress above, which only looks at immediate
--- children for a single row's own display. Used for whole-expansion or
--- whole-branch summary counts (e.g. a picker's "45/60" badge), not
--- per-row progress fractions. Walks Registry:GetChildren recursively;
--- cost is proportional to subtree size, so callers should cache the
--- result rather than calling this every frame (see
--- ExpansionManifest:RefreshSummary, which persists it).
function Engine:GetProgressRecursive(rootID, achievementID)
  local total, earned = 0, 0
  local function Walk(id)
    total = total + 1
    if self:IsEarned(id) == true then
      earned = earned + 1
    end
    local children = Registry:GetChildren(rootID, id)
    if children then
      for _, childID in ipairs(children) do
        Walk(childID)
      end
    end
  end
  Walk(achievementID)
  return { earned = earned, total = total }
end

--- Lock state for one tree position; see the module-level note.
--- Always reports unlocked today; no registered data carries a
--- prerequisite-gate relationship yet.
function Engine:GetLockState(rootID, parentID, achievementID)
  return { locked = false, unmetID = nil }
end
