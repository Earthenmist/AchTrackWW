local ADDON_NAME, MH = ...
local Registry = MH.Registry

--[[
  Runtime title -> achievementID resolution. Lets a data module author a node
  by `title` alone before its real achievementID is known, then promotes parked
  nodes (Registry.pendingByTitle) into the real indexes.

  Two-tier lookup per title:
    1. `MetaHunterDB.global.resolvedByLabel` -- a SavedVariables-backed
       cache, so a title resolved once doesn't need a live achievement scan
       again next login. Addon/account state, not a display preference --
       lives under `global`, not
       `profile`. Checking this is synchronous and cheap -- no throttling
       needed for a cache hit.
    2. A live scan of every achievement category, building a session-only
       title -> id index. Only built lazily, and only if something is
       actually still unresolved after checking the cache.

  Full achievement scans run asynchronously in small time-budgeted chunks so
  the client stays responsive. ResolveTitle/ResolvePending therefore use
  callbacks; cache hits still call back synchronously.

  ResolvePending() still runs as a FIXED-POINT loop, not a single pass --
  this accounts for the registry's known title-only root limitation:
  promoting a title-only ROOT causes RegisterNode to recurse into its
  `criteria` synchronously, which can park BRAND NEW pending titles
  (previously unwalked children of that root) mid-resolution. A single pass
  over a snapshot of pendingByTitle would miss those. So: snapshot the
  currently pending titles, resolve what can be resolved (async), and once
  that whole pass reports back, repeat if it made progress, until a pass
  makes none.

  A genuinely unresolvable title still costs one full scan before
  ResolvePending can conclude it is stuck. The category scan can also miss
  achievements that are available by direct ID on some clients, so title-first
  data should be treated as a fallback authoring path rather than preferred.

  A title that ResolvePending gives up on is no longer silent. It's returned
  via the callback's second argument
  (unresolvedTitles), and warned once per title (not once per call, so a
  title that stays stuck across repeated ResolvePending() calls doesn't
  spam chat).

  This is available for title-first-authored data modules; current shipped data
  is expected to be ID-backed wherever possible.
]]

local Resolver = {}
MH.Resolver = Resolver

local function Warn(msg)
  print("|cffffd200MetaHunter:|r " .. msg)
end

-- Titles already warned about being stuck unresolved during this login, so
-- repeated ResolvePending() calls don't repeat the same stuck
-- title every time -- warned once per title, not once per call. Reset only
-- by reload (matches sessionTitleIndex's lifetime below).
local warnedUnresolvedTitles = {}

local function GetAchievementCategoryListCompat()
  if C_AchievementInfo and C_AchievementInfo.GetCategoryList then
    return C_AchievementInfo.GetCategoryList()
  end
  if GetCategoryList then
    return GetCategoryList()
  end
  return nil
end

local function GetCategoryNumAchievementsCompat(categoryID)
  if C_AchievementInfo and C_AchievementInfo.GetCategoryNumAchievements then
    return C_AchievementInfo.GetCategoryNumAchievements(categoryID)
  end
  if GetCategoryNumAchievements then
    return GetCategoryNumAchievements(categoryID)
  end
  return 0
end

-- High-resolution "now", in milliseconds, for time-budgeting scan chunks.
-- debugprofilestop() is the standard choice for this across the addon
-- ecosystem; GetTime() (second resolution) is a safe fallback if it's ever
-- unavailable.
local function NowMS()
  if debugprofilestop then return debugprofilestop() end
  return GetTime() * 1000
end

--------------------------------------------------------------------------
-- Async, throttled category scan
--------------------------------------------------------------------------

-- How long (ms) a single scan chunk is allowed to run before yielding back
-- to the game and scheduling the rest for the next frame. Deliberately
-- small and time-based, not a fixed "N categories/achievements" count, so
-- it adapts to different hardware rather than assuming a fixed workload is
-- always cheap enough.
local SCAN_CHUNK_BUDGET_MS = 10

-- Session cache of the finished scan, so re-resolving across multiple
-- ResolvePending() calls in one session doesn't re-scan every achievement
-- category each time. Cleared only by a reload/relog (not persisted --
-- resolvedByLabel is the persisted cache; this is scratch space for the
-- scan that populates it).
local sessionTitleIndex = nil

-- In-progress scan state (nil when no scan is running) and the callbacks
-- waiting on it to finish. Multiple callers asking for the index while a
-- scan is already running all queue onto the SAME scan rather than each
-- starting their own.
local scanState = nil
local scanWaiters = {}

local function StepScan()
  local state = scanState
  local deadline = NowMS() + SCAN_CHUNK_BUDGET_MS

  while NowMS() < deadline do
    local categoryID = state.categories[state.categoryIndex]
    if not categoryID then
      -- Every category walked -- the scan is done.
      sessionTitleIndex = state.index
      scanState = nil
      local waiters = scanWaiters
      scanWaiters = {}
      for _, callback in ipairs(waiters) do
        callback(sessionTitleIndex)
      end
      return
    end

    if state.achievementIndex == 0 then
      state.achievementCount = GetCategoryNumAchievementsCompat(categoryID) or 0
      state.achievementIndex = 1
    end

    if state.achievementIndex > state.achievementCount then
      state.categoryIndex = state.categoryIndex + 1
      state.achievementIndex = 0
    else
      -- The classic global supports the two-argument "category + index"
      -- enumeration form used for category scans.
      local id, name = GetAchievementInfo(categoryID, state.achievementIndex)
      if id and name and name ~= "" then
        state.index[name] = id
      end
      state.achievementIndex = state.achievementIndex + 1
    end
  end

  -- Out of time for this chunk -- yield back to the game, continue next frame.
  C_Timer.After(0, StepScan)
end

--- Ensures the full title index exists, calling `callback(index)` once it
--- does. Fires immediately (synchronously) if the index is already built;
--- otherwise queues onto whatever scan is in progress (starting one if none
--- is), which completes over one or more frames via StepScan.
function Resolver:EnsureTitleIndex(callback)
  if sessionTitleIndex then
    callback(sessionTitleIndex)
    return
  end

  table.insert(scanWaiters, callback)

  if not scanState then
    scanState = {
      categories = GetAchievementCategoryListCompat() or {},
      categoryIndex = 1,
      achievementIndex = 0,
      achievementCount = 0,
      index = {},
    }
    StepScan()
  end
end

--------------------------------------------------------------------------
-- Public resolution API
--------------------------------------------------------------------------

--- Returns an array of every title currently sitting in
--- Registry.pendingByTitle with no achievementID found for it yet.
--- Synchronous -- just inspects the registry directly, no scan involved.
--- Also used by ResolvePending when reporting unresolved titles.
function Resolver:GetPendingTitles()
  local titles = {}
  for title in pairs(Registry.pendingByTitle) do
    table.insert(titles, title)
  end
  return titles
end

--- Resolves one title to an achievementID, calling `callback(id)` (`id` is
--- nil if the title matches no known achievement). SavedVariables cache
--- first (synchronous); falls back to the (possibly async) category scan,
--- persisting a freshly-found result back into the cache.
---
--- SINGLE-TITLE CONVENIENCE, NOT A BULK API. If
--- a scan is needed, this queues its own EnsureTitleIndex waiter -- calling
--- it in a loop over many titles would create one waiter per title. A caller
--- that needs to resolve many titles at once should call EnsureTitleIndex once
--- and do its own loop against the returned index, the same way RunPass
--- does, rather than calling this in bulk.
function Resolver:ResolveTitle(title, callback)
  local cache = MH.db and MH.db.global.resolvedByLabel
  if cache and cache[title] then
    callback(cache[title])
    return
  end

  self:EnsureTitleIndex(function(index)
    local id = index[title]
    if id and cache then
      cache[title] = id
    end
    callback(id)
  end)
end

--- Resolves every currently-pending title it can, as a fixed-point loop
--- (see the module-level note on why a single pass isn't enough), and calls
--- `callback(totalPromoted, unresolvedTitles)` once it's done -- which may
--- be several frames later than the call, if a category scan is needed.
--- `unresolvedTitles` is whatever's still stuck in pendingByTitle after the
--- loop gives up (empty if everything resolved); each one is also warned
--- about once (not once per call) via chat.
---
--- Does NOT call self:ResolveTitle per title (that would queue one
--- EnsureTitleIndex waiter per title, and
--- StepScan fires every queued waiter in one tight loop when the scan
--- finishes -- fine for a couple of titles, but a future title-heavy data
--- module could still cause a large completion burst). Instead: checks the
--- SavedVariables cache for the whole pass
--- up front (so an already-cached pass never triggers a scan at all), calls
--- EnsureTitleIndex at most ONCE for whatever's left, and then promotes
--- resolved titles via its own time-budgeted chunk loop (same pattern as
--- StepScan) rather than one synchronous burst -- since PromoteTitle can
--- recurse into RegisterNode for a resolved root's children, a large batch
--- promoted all at once has the same burst-freeze risk as the scan did.
function Resolver:ResolvePending(callback)
  local totalPromoted = 0

  local function Finish(unresolved)
    for _, title in ipairs(unresolved) do
      if not warnedUnresolvedTitles[title] then
        warnedUnresolvedTitles[title] = true
        Warn(string.format(
          "title %q could not be resolved to an achievementID -- it will stay invisible until this is fixed.",
          title))
      end
    end
    if callback then callback(totalPromoted, unresolved) end
  end

  local function RunPass()
    local titles = self:GetPendingTitles()
    if #titles == 0 then
      Finish({})
      return
    end

    local cache = MH.db and MH.db.global.resolvedByLabel

    -- Resolve whatever the persisted cache already knows, synchronously,
    -- before ever considering a scan.
    local resolved = {}
    local needsScan = false
    for _, title in ipairs(titles) do
      local id = cache and cache[title]
      if id then
        resolved[title] = id
      else
        needsScan = true
      end
    end

    local function PromoteResolved()
      local promotedThisPass = 0
      local i = 1

      local function StepPromote()
        local deadline = NowMS() + SCAN_CHUNK_BUDGET_MS
        while i <= #titles and NowMS() < deadline do
          local title = titles[i]
          local id = resolved[title]
          if id then
            local results = Registry:PromoteTitle(title, id)
            promotedThisPass = promotedThisPass + (results and #results or 0)
          end
          i = i + 1
        end

        if i <= #titles then
          C_Timer.After(0, StepPromote)
          return
        end

        totalPromoted = totalPromoted + promotedThisPass
        if promotedThisPass == 0 then
          -- No progress this pass -- whatever's left is genuinely
          -- unresolved (not a real achievement title, one this client
          -- doesn't know about yet, or the documented category-scan gap).
          Finish(self:GetPendingTitles())
        else
          -- Made progress -- promoting a title-only ROOT can synchronously
          -- park brand-new pending titles (see module note), so run
          -- another pass rather than assuming this one cleared everything.
          RunPass()
        end
      end

      StepPromote()
    end

    if not needsScan then
      PromoteResolved()
      return
    end

    self:EnsureTitleIndex(function(index)
      for _, title in ipairs(titles) do
        if not resolved[title] then
          local id = index[title]
          if id then
            resolved[title] = id
            if cache then cache[title] = id end
          end
        end
      end
      PromoteResolved()
    end)
  end

  RunPass()
end
