local ADDON_NAME, MH = ...
local Registry = MH.Registry

--[[
  Corrections/overlay mechanism: fixes or
  annotates data already registered by an expansion module, without
  hand-editing that module's data file directly. Two-tier keying, matching
  the identity/placement split in Registry.lua:

    - Canonical patches (title/icon/guide/waypoints/faction/deprecated/
      variantIDs/oneOfAchievementIDs) are keyed by achievementID alone. A
      `variantIDs` patch routes through Registry:SetVariantIDs so the
      primaryByVariantID reverse index can never go stale relative to what
      PatchAchievement just set.
    - Placement patches (expansion/patch/season/category/hidden/order) are
      keyed by the full {rootID, parentID, achievementID} composite, since
      placement isn't purely a property of the achievement -- the same
      achievement can have more than one placement.

  Re-parenting (moving an achievement to a different root/parent) is a
  structural change, not a field patch -- it needs a placement removed from
  one tree position and added at another, its childrenByParentID edges
  updated to match, and -- if the position is a root (parentID == nil) --
  its expansion's rootsByExpansion list updated too, since a root placement
  has no parent edge to carry that bookkeeping. AddPlacement/RemovePlacement/
  MovePlacement below cover all of that; PatchPlacement only ever mutates
  fields on a placement that already exists at a fixed position.

  RemovePlacement (and any cross-root MovePlacement) refuses to touch a
  placement that has children: removing it would orphan the subtree (its
  placements and edges would stay in the tables but become unreachable from
  the root), and a cross-root move would leave descendants keyed to a root
  they're no longer under. Cascading removal/move isn't implemented -- move
  or remove the children first. A same-root move is fine even with
  children, since the child edges are keyed by (rootID, achievementID),
  which doesn't change when only the node's *parent* changes within the
  same root.

  No overlay data exists yet (nothing shipped needs correcting on day one);
  this file is the mechanism other modules call into as fixes come up.
]]

local Overlay = {}
MH.Overlay = Overlay

local CANONICAL_FIELDS = {
  title = true, icon = true, guide = true, waypoints = true,
  faction = true, deprecated = true, variantIDs = true,
  oneOfAchievementIDs = true,
}

local PLACEMENT_FIELDS = {
  expansion = true, patch = true, season = true, category = true,
  hidden = true, order = true,
}

--- Patches canonical fields on an already-registered achievement.
--- `fields` is a table of any CANONICAL_FIELDS to overwrite. A `variantIDs`
--- entry routes through Registry:SetVariantIDs rather than being written
--- directly, so the reverse index stays in sync.
function Overlay:PatchAchievement(achievementID, fields)
  local record = Registry.achievementsByID[achievementID]
  if not record then
    error("MetaHunter: overlay target achievementID " .. tostring(achievementID) .. " is not registered")
  end
  for field, value in pairs(fields) do
    if field == "variantIDs" then
      Registry:SetVariantIDs(achievementID, value)
    elseif CANONICAL_FIELDS[field] then
      record[field] = value
    elseif PLACEMENT_FIELDS[field] then
      error("MetaHunter: '" .. tostring(field) .. "' is a placement field; use PatchPlacement instead")
    else
      error("MetaHunter: '" .. tostring(field) .. "' is not a recognized achievement field")
    end
  end
end

--- Patches placement fields on one specific, already-existing tree
--- position. rootID/parentID/achievementID together identify the
--- placement, because the same achievement can appear in more than one spot
--- and a placement patch has to say which one it means. To change WHICH
--- position an achievement occupies, use MovePlacement below instead.
function Overlay:PatchPlacement(rootID, parentID, achievementID, fields)
  local placement = Registry:GetPlacement(rootID, parentID, achievementID)
  if not placement then
    error(string.format(
      "MetaHunter: overlay target placement (%s:%s:%s) is not registered",
      tostring(rootID), tostring(parentID), tostring(achievementID)))
  end
  for field, value in pairs(fields) do
    if PLACEMENT_FIELDS[field] then
      placement[field] = value
    elseif CANONICAL_FIELDS[field] then
      error("MetaHunter: '" .. tostring(field) .. "' is a canonical field; use PatchAchievement instead")
    else
      error("MetaHunter: '" .. tostring(field) .. "' is not a recognized placement field")
    end
  end
end

local function HasChildren(rootID, achievementID)
  local siblings = Registry:GetChildren(rootID, achievementID)
  return siblings ~= nil and #siblings > 0
end

-- Internal, unguarded: removes a placement record and its structural
-- effects (its edge from its parent's child list, or -- if it was a root --
-- its entry in rootsByExpansion). No child-having check; callers decide
-- when that's safe. Returns the removed placement record, or nil if there
-- wasn't one.
local function RemovePlacementRecord(rootID, parentID, achievementID)
  local key = Registry.PlacementKey(rootID, parentID, achievementID)
  local placement = Registry.placements[key]
  if not placement then return nil end
  Registry.placements[key] = nil

  if parentID then
    local siblings = Registry:GetChildren(rootID, parentID)
    if siblings then
      for i, id in ipairs(siblings) do
        if id == achievementID then
          table.remove(siblings, i)
          break
        end
      end
    end
  else
    local expansion = placement.expansion
    local roots = expansion and Registry.rootsByExpansion[expansion]
    if roots then
      for i, id in ipairs(roots) do
        if id == achievementID then
          table.remove(roots, i)
          break
        end
      end
    end
  end

  return placement
end

-- Internal, unguarded: adds a placement record and its structural effects.
-- Assumes the caller already checked the achievement is registered and the
-- target position doesn't already have a placement. A root placement
-- (parentID == nil) requires `fields.expansion` -- there's no parent edge to
-- infer it from, and rootsByExpansion is keyed by expansion.
local function AddPlacementRecord(rootID, parentID, achievementID, fields)
  local placement = {}
  if fields then
    for field, value in pairs(fields) do
      placement[field] = value
    end
  end
  placement.rootID = rootID
  placement.parentID = parentID
  placement.achievementID = achievementID
  Registry.placements[Registry.PlacementKey(rootID, parentID, achievementID)] = placement

  if parentID then
    local childKey = Registry.ChildrenKey(rootID, parentID)
    local siblings = Registry.childrenByParentID[childKey]
    if not siblings then
      siblings = {}
      Registry.childrenByParentID[childKey] = siblings
    end
    table.insert(siblings, achievementID)
  else
    if not placement.expansion then
      error("MetaHunter: a root placement (parentID == nil) needs an `expansion` field")
    end
    local roots = Registry.rootsByExpansion[placement.expansion]
    if not roots then
      roots = {}
      Registry.rootsByExpansion[placement.expansion] = roots
      table.insert(Registry.expansionOrder, placement.expansion)
    end
    table.insert(roots, achievementID)
  end

  return placement
end

--- Removes one placement entirely: the placement record and its structural
--- effects (see the module-level note on root handling). Refuses to remove
--- a placement that has children -- see the module-level note on cascading.
--- Does not touch the canonical record: an achievement with no remaining
--- placements is still a valid canonical entry, just not shown anywhere
--- until a new placement is added.
function Overlay:RemovePlacement(rootID, parentID, achievementID)
  local key = Registry.PlacementKey(rootID, parentID, achievementID)
  if not Registry.placements[key] then
    error(string.format(
      "MetaHunter: overlay target placement (%s:%s:%s) is not registered",
      tostring(rootID), tostring(parentID), tostring(achievementID)))
  end
  if HasChildren(rootID, achievementID) then
    error(string.format(
      "MetaHunter: refusing to remove placement (%s:%s:%s) -- it has children; " ..
      "removing it would orphan its subtree. Move or remove its children first.",
      tostring(rootID), tostring(parentID), tostring(achievementID)))
  end
  RemovePlacementRecord(rootID, parentID, achievementID)
end

--- Adds a new placement for an already-registered (canonical) achievement
--- at a tree position it doesn't already occupy. `fields` may set any
--- PLACEMENT_FIELDS; a root placement (parentID == nil) requires `expansion`.
function Overlay:AddPlacement(rootID, parentID, achievementID, fields)
  if not Registry.achievementsByID[achievementID] then
    error("MetaHunter: overlay target achievementID " .. tostring(achievementID) .. " is not registered")
  end

  local key = Registry.PlacementKey(rootID, parentID, achievementID)
  if Registry.placements[key] then
    error(string.format(
      "MetaHunter: placement (%s:%s:%s) already exists; use PatchPlacement to modify it",
      tostring(rootID), tostring(parentID), tostring(achievementID)))
  end

  if fields then
    for field in pairs(fields) do
      if not PLACEMENT_FIELDS[field] then
        error("MetaHunter: '" .. tostring(field) .. "' is not a recognized placement field")
      end
    end
  end

  AddPlacementRecord(rootID, parentID, achievementID, fields)
end

--- Moves an achievement from one tree position to another: removes the old
--- placement and adds a new one, carrying over the old placement's fields
--- except where `fields` overrides them. Refuses a cross-root move
--- (fromRootID ~= toRootID) if the placement has children -- see the
--- module-level note. A same-root move (re-parenting within the same tree)
--- is allowed even with children.
function Overlay:MovePlacement(achievementID, fromRootID, fromParentID, toRootID, toParentID, fields)
  local old = Registry:GetPlacement(fromRootID, fromParentID, achievementID)
  if not old then
    error(string.format(
      "MetaHunter: overlay move source placement (%s:%s:%s) is not registered",
      tostring(fromRootID), tostring(fromParentID), tostring(achievementID)))
  end

  if fromRootID ~= toRootID and HasChildren(fromRootID, achievementID) then
    error(string.format(
      "MetaHunter: refusing to move placement (%s:%s:%s) to a different root (%s) -- " ..
      "it has children, and a cross-root move would leave them keyed to the old root. " ..
      "Same-root moves are fine; move the children first for a cross-root move.",
      tostring(fromRootID), tostring(fromParentID), tostring(achievementID), tostring(toRootID)))
  end

  local toKey = Registry.PlacementKey(toRootID, toParentID, achievementID)
  local fromKey = Registry.PlacementKey(fromRootID, fromParentID, achievementID)
  if toKey ~= fromKey and Registry.placements[toKey] then
    error(string.format(
      "MetaHunter: move target placement (%s:%s:%s) already exists",
      tostring(toRootID), tostring(toParentID), tostring(achievementID)))
  end

  local carried = {}
  for field in pairs(PLACEMENT_FIELDS) do
    carried[field] = old[field]
  end
  if fields then
    for field, value in pairs(fields) do
      if not PLACEMENT_FIELDS[field] then
        error("MetaHunter: '" .. tostring(field) .. "' is not a recognized placement field")
      end
      carried[field] = value
    end
  end

  RemovePlacementRecord(fromRootID, fromParentID, achievementID)
  AddPlacementRecord(toRootID, toParentID, achievementID, carried)
end
