local ADDON_NAME, MH = ...

--[[
  The core achievement registry.

  An expansion data module authors nested trees for
  readability, but nothing outside this file should ever walk that raw
  nested shape. RegisterExpansion() normalizes each incoming tree into flat,
  ID-keyed tables at registration time:

    - achievementsByID    canonical record per achievement ID (what it IS)
    - childrenByParentID  structural edges, keyed by (rootID, parentID) --
                           NOT by parentID alone (see note on ChildrenKey)
    - placements          contextual record per (rootID, parentID, id)
                           tree position (WHERE it appears, and how)
    - rootsByExpansion     ordered meta roots per expansion
    - primaryByVariantID   variantID -> primary achievementID reverse lookup

  An achievement genuinely referenced from more than one tree position gets
  one canonical record and multiple placement records -- never a conflict
  on a single "parentID" field.

  Authored nodes need `achievementID`, `title`, OR `oneOfAchievementIDs`.
  Nodes without a resolved achievementID are parked in `pendingByTitle` until
  the title->ID resolver calls PromoteTitle() to move them into the real indexes.
  `criteria` is optional -- leaf achievements simply omit it.

  Known, documented limitation: an unresolved (title-only) node returns
  before recursing into its `criteria`, so its whole subtree -- including
  any descendants that already have a known achievementID -- stays parked
  until the node itself resolves. This is not data loss (the nested
  `criteria` table is preserved as-is on the parked node and gets walked
  normally once promoted), but it does mean a known-ID descendant of an
  unresolved root is invisible to every index until that root's title
  resolves too. The resolver accounts for this with a fixed-point loop, so
  cascading resolution does not require multiple reloads.
]]

local Registry = {}
MH.Registry = Registry

Registry.achievementsByID = {}
Registry.childrenByParentID = {}
Registry.placements = {}
Registry.rootsByExpansion = {}
Registry.primaryByVariantID = {}

-- Expansions in registration order (module load order / TOC order). The
-- UI's default ordering (current expansion first, then reverse
-- chronological) is applied on top of this list by the UI
-- layer -- this is just registration order, not display order.
Registry.expansionOrder = {}

-- title -> array of pending contexts (NOT a single context -- the same
-- title can legitimately be unresolved in more than one placement at once,
-- e.g. a standalone root and a meta's criterion sharing a title before
-- either resolves; a single-slot table would silently drop one of them).
--
-- Known assumption, not enforced: this assumes achievement titles are
-- unique -- i.e. that two DIFFERENT achievements never share the exact same
-- title string. If that assumption is ever wrong, PromoteTitle(title, id)
-- has no way to tell the achievements apart and will promote every pending
-- context under that title to the same achievementID. There's no
-- discriminator for this today. Treated as acceptable for now since real
-- WoW achievement titles are effectively unique in practice, but flagged
-- here rather than assumed silently.
Registry.pendingByTitle = {}

local function OneOfVirtualID(rootID, parentID, siblingIndex)
  return "oneOf:" .. tostring(rootID or 0) .. ":" .. tostring(parentID or 0) .. ":" .. tostring(siblingIndex or 0)
end

local function PlacementKey(rootID, parentID, achievementID)
  return tostring(rootID) .. ":" .. tostring(parentID or 0) .. ":" .. tostring(achievementID)
end
Registry.PlacementKey = PlacementKey

-- Structural edges are keyed by (rootID, parentID), not by parentID alone:
-- the same achievement can be a parent in more than one tree (rare, but the
-- identity/placement split exists precisely to allow it), and a bare
-- parentID key would merge those trees' child lists together.
local function ChildrenKey(rootID, parentID)
  return tostring(rootID) .. ":" .. tostring(parentID)
end
Registry.ChildrenKey = ChildrenKey

-- Canonical fields simple enough to compare by value (used to detect
-- conflicting re-registration below). `waypoints`/`variantIDs` are tables
-- and deliberately excluded -- comparing those meaningfully needs a deep
-- compare this doesn't attempt yet.
local SCALAR_CANONICAL_FIELDS = { "title", "icon", "guide", "faction", "deprecated" }

local function Warn(msg)
  print("|cffffd200MetaHunter:|r " .. msg)
end

-- Order-independent equality check for two variantIDs lists. Used only to
-- decide whether a re-registration's variantIDs actually differ from what's
-- already registered (see RegisterCanonical) -- not a general table-compare
-- utility.
local function VariantListsEqual(a, b)
  if a == b then return true end -- same reference, or both nil
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  if #a ~= #b then return false end
  local set = {}
  for _, v in ipairs(a) do set[v] = true end
  for _, v in ipairs(b) do
    if not set[v] then return false end
  end
  return true
end

-- Canonical fields describe what an achievement IS, true regardless of
-- where it's referenced from. Placement fields describe WHERE/HOW it shows
-- up in one specific tree position.
local function SplitNode(node)
  local canonical = {
    achievementID = node.achievementID,
    title = node.title,
    icon = node.icon,
    guide = node.guide,
    waypoints = node.waypoints,
    faction = node.faction,
    deprecated = node.deprecated,
    -- Alternate achievement IDs where completing ANY of them satisfies this
    -- node (raid-difficulty variants, or an upgraded achievement that
    -- supersedes an earlier one). Canonical because it is a property of the
    -- achievement's identity, not of a placement.
    variantIDs = node.variantIDs,
    -- Virtual criterion rows where completing ANY listed real achievement
    -- satisfies this single tree node. Unlike variantIDs, these are not
    -- "same achievement in disguise"; they are distinct achievements that
    -- Blizzard treats as alternate ways to satisfy one parent criterion.
    oneOfAchievementIDs = node.oneOfAchievementIDs,
  }
  local placement = {
    expansion = node.expansion,
    patch = node.patch,
    season = node.season,
    category = node.category,
    hidden = node.hidden,
    order = node.order,
  }
  return canonical, placement
end
Registry.SplitNode = SplitNode

-- Registers the canonical record for `id`, or -- if one already exists --
-- warns on any scalar field that disagrees with what's already registered.
-- Identical re-registration (e.g. the same achievement placed a second
-- time with the same canonical data) stays silent, as does a second
-- registration that simply leaves a field nil/unspecified.
local function RegisterCanonical(id, canonical)
  local existing = Registry.achievementsByID[id]
  if not existing then
    Registry.achievementsByID[id] = canonical
    Registry:SetVariantIDs(id, canonical.variantIDs)
    return
  end

  for _, field in ipairs(SCALAR_CANONICAL_FIELDS) do
    local a, b = existing[field], canonical[field]
    if a ~= nil and b ~= nil and a ~= b then
      Warn(string.format(
        "achievementID %s registered twice with conflicting %s (kept %q, saw %q)",
        tostring(id), field, tostring(a), tostring(b)))
    end
  end

  if canonical.variantIDs ~= nil and not VariantListsEqual(existing.variantIDs, canonical.variantIDs) then
    Warn(string.format(
      "achievementID %s registered twice with differing variantIDs; keeping the latest",
      tostring(id)))
    Registry:SetVariantIDs(id, canonical.variantIDs)
  end
end

-- Registers one authored node (and its criteria, recursively) under the
-- given root/parent. rootID/parentID are achievementIDs; parentID is nil
-- for a root node itself. Returns the node's achievementID, or nil if it's
-- still pending title resolution (in which case its whole subtree, still
-- nested, is parked as-is -- see the module-level note on this limitation).
local function RegisterNode(node, expansion, rootID, parentID, siblingIndex)
  local hasOneOf = type(node.oneOfAchievementIDs) == "table" and #node.oneOfAchievementIDs > 0
  if not node.achievementID and not node.title and not hasOneOf then
    error("MetaHunter: achievement node needs achievementID, title, or oneOfAchievementIDs (expansion: " .. tostring(expansion) .. ")")
  end

  node.expansion = node.expansion or expansion

  if not node.achievementID and hasOneOf then
    node.achievementID = node.virtualID or OneOfVirtualID(rootID, parentID, siblingIndex)
  end

  if not node.achievementID then
    local pendingList = Registry.pendingByTitle[node.title]
    if not pendingList then
      pendingList = {}
      Registry.pendingByTitle[node.title] = pendingList
    end
    table.insert(pendingList, {
      node = node,
      expansion = expansion,
      rootID = rootID,
      parentID = parentID,
      siblingIndex = siblingIndex,
    })
    return nil
  end

  local id = node.achievementID
  local canonical, placement = SplitNode(node)
  RegisterCanonical(id, canonical)

  placement.rootID = rootID
  placement.parentID = parentID
  placement.achievementID = id
  Registry.placements[PlacementKey(rootID, parentID, id)] = placement

  if parentID then
    local key = ChildrenKey(rootID, parentID)
    local siblings = Registry.childrenByParentID[key]
    if not siblings then
      siblings = {}
      Registry.childrenByParentID[key] = siblings
    end
    table.insert(siblings, id)
  end

  if type(node.criteria) == "table" then
    for i, childNode in ipairs(node.criteria) do
      RegisterNode(childNode, expansion, rootID, id, i)
    end
  end

  return id
end
Registry.RegisterNode = RegisterNode

--- Registers one expansion's meta root(s). `roots` is an array of authored
--- node tables; each becomes an
--- independent tree registered under `expansion`. Call once per expansion
--- data module (Data\Expansions\*.lua).
function Registry:RegisterExpansion(expansion, roots)
  if not self.rootsByExpansion[expansion] then
    self.rootsByExpansion[expansion] = {}
    table.insert(self.expansionOrder, expansion)
  end

  for _, rootNode in ipairs(roots) do
    local rootID = RegisterNode(rootNode, expansion, rootNode.achievementID, nil)
    if rootID then
      table.insert(self.rootsByExpansion[expansion], rootID)
    end
    -- A root still pending title resolution isn't added to
    -- rootsByExpansion until PromoteTitle() resolves it.
  end
end

--- Called once a pending title resolves to a real achievementID. Promotes EVERY pending context parked under
--- that title -- not just one, since the same title can legitimately be
--- unresolved in more than one placement at once. Returns an array of the
--- resulting achievementIDs (normally all equal to `achievementID`, one
--- per promoted placement), or nil if nothing was pending under that title.
function Registry:PromoteTitle(title, achievementID)
  local pendingList = self.pendingByTitle[title]
  if not pendingList then return nil end
  self.pendingByTitle[title] = nil

  local results = {}
  for _, pending in ipairs(pendingList) do
    pending.node.achievementID = achievementID

    local wasRoot = not pending.parentID
    local rootID = pending.rootID or achievementID -- promoting a root resolves its own rootID
    local id = RegisterNode(pending.node, pending.expansion, rootID, pending.parentID, pending.siblingIndex)

    if wasRoot and id then
      local roots = self.rootsByExpansion[pending.expansion]
      if roots then
        table.insert(roots, id)
      end
    end

    table.insert(results, id)
  end

  return results
end

--- Sets (or replaces) an achievement's variantIDs and keeps
--- `primaryByVariantID` in sync -- the only path that should ever write to
--- either. `achievementID` must already have a canonical record; `variantIDs`
--- may be nil (clears them). Centralized here rather than left to callers so
--- the reverse index can never go stale relative to what's actually on the
--- canonical record (Overlay's PatchAchievement routes `variantIDs` patches
--- through this too, for the same reason).
function Registry:SetVariantIDs(achievementID, variantIDs)
  local record = self.achievementsByID[achievementID]
  if not record then
    error("MetaHunter: SetVariantIDs target achievementID " .. tostring(achievementID) .. " is not registered")
  end

  if type(record.variantIDs) == "table" then
    for _, oldVariant in ipairs(record.variantIDs) do
      if self.primaryByVariantID[oldVariant] == achievementID then
        self.primaryByVariantID[oldVariant] = nil
      end
    end
  end

  record.variantIDs = variantIDs

  if type(variantIDs) == "table" then
    for _, variantID in ipairs(variantIDs) do
      local existingPrimary = self.primaryByVariantID[variantID]
      if existingPrimary and existingPrimary ~= achievementID then
        Warn(string.format(
          "variantID %s already mapped to achievementID %s; overwriting to %s",
          tostring(variantID), tostring(existingPrimary), tostring(achievementID)))
      end
      self.primaryByVariantID[variantID] = achievementID
    end
  end
end

function Registry:GetAchievement(achievementID)
  return self.achievementsByID[achievementID]
end

--- Resolves a variant achievementID to its primary/canonical achievementID.
--- Returns `achievementID` unchanged if it isn't a known variant of
--- anything (including if it's already a primary ID). Every read path that
--- takes a bare achievementID from the game (e.g. from an achievement-
--- earned event) should run it through this before looking it up in
--- achievementsByID, so a variant ID resolves to the same record its
--- primary ID would.
function Registry:ResolvePrimaryID(achievementID)
  return self.primaryByVariantID[achievementID] or achievementID
end

--- Children of `parentID` within the tree rooted at `rootID` specifically
--- -- NOT a global list of every place `parentID` has children, since the
--- same achievement can be a parent in more than one tree.
function Registry:GetChildren(rootID, parentID)
  return self.childrenByParentID[ChildrenKey(rootID, parentID)]
end

function Registry:GetPlacement(rootID, parentID, achievementID)
  return self.placements[PlacementKey(rootID, parentID, achievementID)]
end

function Registry:GetRoots(expansion)
  return self.rootsByExpansion[expansion]
end

function Registry:GetExpansions()
  return self.expansionOrder
end
