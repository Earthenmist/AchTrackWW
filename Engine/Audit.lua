local ADDON_NAME, MH = ...
local Registry = MH.Registry

--[[
  In-game data-quality audit. Cross-references the selected expansion's
  registered data against Blizzard's live achievement API via /mhaudit.

  Two checks:
  1. CheckTitles -- for every registered achievement, confirms the ID still
     exists on this client and its real title matches what we stored.
  2. CheckChildren -- for every composite (parent) achievement, walks
     Blizzard's own GetAchievementCriteriaInfo data and compares the
     achievement-type criteria it reports against our own registered
     children, flagging both directions of mismatch (children we have that
     Blizzard doesn't confirm as sub-achievements, and children Blizzard
     reports that we're missing).

  CheckChildren uses the legacy criteria globals directly because the criteria
  APIs have client-version differences that are not always drop-in compatible.

  OR-satisfaction alternates are now represented by virtual
  `oneOfAchievementIDs` rows in the registry. CheckChildren understands that
  those rows are NOT ordinary Blizzard child edges themselves; instead, their
  listed alternate achievement IDs count as covered if Blizzard reports any
  of them as achievement-backed criteria.
]]

local Audit = {}
MH.Audit = Audit

-- Criteria type value for "satisfied by completing another achievement."
-- Kept literal because Enum names vary across clients.
local ACHIEVEMENT_CRITERIA_TYPE = 8

local function Warn(msg)
  print("|cffffd200MetaHunter Audit:|r " .. msg)
end

local function GetExpansionRootSet(expansionID)
  local roots = Registry:GetRoots(expansionID)
  if not roots or #roots == 0 then return nil end

  local rootSet = {}
  for _, rootID in ipairs(roots) do
    rootSet[rootID] = true
  end
  return rootSet
end

local function CollectExpansionAchievementIDs(expansionID)
  local rootSet = GetExpansionRootSet(expansionID)
  if not rootSet then return nil end

  local ids = {}
  for _, placement in pairs(Registry.placements) do
    if rootSet[placement.rootID] then
      ids[placement.achievementID] = true
    end
  end
  return ids
end

--- Checks every registered achievement's title against Blizzard's live
--- data. Returns the number of mismatches found (0 = all clean).
function Audit:CheckTitles(expansionID)
  local checked, mismatches = 0, 0
  local scopedIDs = expansionID and (CollectExpansionAchievementIDs(expansionID) or {}) or nil

  for id, record in pairs(Registry.achievementsByID) do
    if type(id) == "number" and (not scopedIDs or scopedIDs[id]) then
      checked = checked + 1
      local realID, realTitle = MH.Engine.GetAchievementInfoCompat(id)
      if not realID then
        mismatches = mismatches + 1
        Warn(string.format("achievementID %d (%q) no longer exists on this client", id, tostring(record.title)))
      elseif record.title and realTitle and record.title ~= realTitle then
        mismatches = mismatches + 1
        Warn(string.format("achievementID %d title mismatch -- we have %q, Blizzard has %q", id, record.title, realTitle))
      end
    end
  end
  Warn(string.format("Title check%s: %d achievement(s) checked, %d mismatch(es)",
    expansionID and (" [" .. expansionID .. "]") or "",
    checked,
    mismatches))
  return mismatches
end

--- Cross-checks every registered achievement against Blizzard's own
--- criteria data as a possible parent. Walks Registry.placements directly
--- (each record already carries explicit rootID/parentID/achievementID
--- fields) rather than parsing the internal composite-key string format, so
--- this doesn't depend on Registry's key encoding staying the same shape.
--- Deduplicates so the same (rootID, parentID) pair -- an achievement can be
--- a parent in more than one tree -- is only checked once.
function Audit:CheckChildren(expansionID)
  local issues = 0
  local oneOfCovered = 0
  local checkedParents = {}
  local rootSet = expansionID and (GetExpansionRootSet(expansionID) or {}) or nil

  local function CheckParent(rootID, parentID)
    if type(parentID) ~= "number" then return end
    if rootSet and not rootSet[rootID] then return end

    local dedupeKey = tostring(rootID) .. ":" .. tostring(parentID)
    if checkedParents[dedupeKey] then return end
    checkedParents[dedupeKey] = true

    local numCriteria = GetAchievementNumCriteria(parentID) or 0
    local blizzardChildren = {}
    for i = 1, numCriteria do
      local _, criteriaType, _, _, _, _, _, assetID = GetAchievementCriteriaInfo(parentID, i)
      if criteriaType == ACHIEVEMENT_CRITERIA_TYPE and assetID then
        blizzardChildren[assetID] = true
      end
    end

    local ours = {}
    local coveredByOneOf = {}
    for _, childID in ipairs(Registry:GetChildren(rootID, parentID) or {}) do
      local childRecord = Registry:GetAchievement(childID)
      if childRecord and type(childRecord.oneOfAchievementIDs) == "table" then
        for _, alternateID in ipairs(childRecord.oneOfAchievementIDs) do
          coveredByOneOf[alternateID] = true
        end
      else
        ours[childID] = true
      end

      if not childRecord or type(childRecord.oneOfAchievementIDs) ~= "table" then
        if not blizzardChildren[childID] then
          issues = issues + 1
          Warn(string.format(
            "parent %s (root %s): we have child %s, Blizzard's criteria data doesn't confirm it as a sub-achievement",
            tostring(parentID), tostring(rootID), tostring(childID)))
        end
      end
    end
    for blizzChildID in pairs(blizzardChildren) do
      if not ours[blizzChildID] then
        if coveredByOneOf[blizzChildID] then
          oneOfCovered = oneOfCovered + 1
        else
          issues = issues + 1
          Warn(string.format(
            "parent %s (root %s): Blizzard reports child %s, we don't have it registered",
            tostring(parentID), tostring(rootID), tostring(blizzChildID)))
        end
      end
    end
  end

  if expansionID then
    for _, rootID in ipairs(Registry:GetRoots(expansionID) or {}) do
      CheckParent(rootID, rootID)
    end
  else
    for _, roots in pairs(Registry.rootsByExpansion) do
      for _, rootID in ipairs(roots) do
        CheckParent(rootID, rootID)
      end
    end
  end

  for _, placement in pairs(Registry.placements) do
    CheckParent(placement.rootID, placement.achievementID)
  end

  Warn(string.format(
    "Children check%s: %d issue(s) found (%d OR-satisfaction alternate(s) covered)",
    expansionID and (" [" .. expansionID .. "]") or "",
    issues,
    oneOfCovered))
  return issues
end

--- Runs both checks and prints a summary.
function Audit:RunExpansion(expansionID)
  Warn("Starting audit for " .. tostring(expansionID) .. "...")
  local titleIssues = self:CheckTitles(expansionID)
  local childIssues = self:CheckChildren(expansionID)
  Warn(string.format("Audit complete -- %d title issue(s), %d children issue(s)", titleIssues, childIssues))
end

--- Audits exactly the expansion currently selected in Meta Hunter's UI.
--- This deliberately does not load every manifest entry. A module already
--- loaded earlier in the session may remain in memory, but it is ignored here
--- unless it is the selected expansion.
MH.Addon:RegisterChatCommand("mhaudit", function()
  local expansionID = MH.UI
    and MH.UI.MainFrame
    and MH.UI.MainFrame.GetSelectedExpansionID
    and MH.UI.MainFrame:GetSelectedExpansionID()

  if not expansionID then
    Warn("no expansion selected -- open Meta Hunter with /mh and select an expansion first")
    return
  end

  MH.ExpansionManifest:EnsureLoaded(expansionID, function(ok, reason)
    if not ok then
      Warn("couldn't load " .. tostring(expansionID) .. " for the audit -- " .. tostring(reason))
      return
    end
    Audit:RunExpansion(expansionID)
  end)
end)
