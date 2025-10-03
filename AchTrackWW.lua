local ADDON, ns = ...

-- =========================================================
-- Watch list
-- Each entry may be:
--   "Title"                        -> auto-resolve by in-game title at runtime
--   { label="Name", id=123 }       -> fixed single achievement
--   { label="Name", any={...} }    -> any of these IDs count as complete
--   { ..., requires={...} }        -> numeric-ID prerequisites (must be complete)
--   { ..., requires_labels={...} } -> label-based prerequisites; each is another row's label
-- Clicking opens the completed ID if possible; otherwise the first ID or unmet prerequisite.
-- =========================================================
local WATCH_LIST = {

  -- K'aresh Warrant chain: Moonlighter -> (Bounty Seeker OR Vigilante)
  { label = "Moonlighter", id = 41978 },
  { label = "Bounty Seeker", any = { 41979, 41980 }, requires = { 41978 } }, -- 41980 (Vigilante) supersedes

  -- Raids (any-of variants)
  { label = "Nerub-ar Palace", any = { 40244, 40245, 40246 } },
  { label = "Liberation of Undermine", any = { 41222, 41223, 41224 } },
  { label = "Manaforge Omega", any = { 41598, 41599, 41600 } },

  -- Meta / Zone metas
  -- All That Khaz requires the following to be complete:
  { label = "All That Khaz", requires_labels = {
      "Khaz Algar Flight Master",
      "Khaz Algar Glyph Hunter",
      "Loremaster of Khaz Algar",
      "Khaz Algar Lore Hunter",
      "Khaz Algar Diplomat",
      "Allied Races: Earthen",
  }},

  "Khaz Algar Flight Master",
  "Khaz Algar Glyph Hunter",
  "Loremaster of Khaz Algar",
  "Khaz Algar Lore Hunter",
  "Khaz Algar Diplomat",
  { label = "Allied Races: Earthen", any = { 40307, 40309 } },

  -- You Xal Not Pass requires:
  { label = "You Xal Not Pass", requires_labels = {
      "Slate of the Union",
      "Rage Aside the Machine",
      "Crystal Chronicled",
      "Azj the World Turns",
      "Isle Remember You",
  }},

  "Slate of the Union",
  "Rage Aside the Machine",
  "Crystal Chronicled",
  "Azj the World Turns",
  "Isle Remember You",

  -- The War Within Pathfinder requires:
  { label = "The War Within Pathfinder", requires_labels = {
      "The Isle of Dorn",
      "The Ringing Deeps",
      "Hallowfall",
      "Azj-Kahet",
      "Khaz Algar Explorer",
  }},

  "The Isle of Dorn",
  "The Ringing Deeps",
  "Hallowfall",
  "Azj-Kahet",
  "Khaz Algar Explorer",

  -- Delves meta requires (keep the individual nemesis rows):
  { label = "Glory of the Delver", requires_labels = {
      "Delve Loremaster: War Within",
      "Leave No Treasure Unfound",
      "Sporesweeper",
      "Spider Senses",
      "Daystormer",
      "Brann Development",
      "My First Nemesis",
      "My New Nemesis",
      "My Stab-Happy Nemesis",
  }},

  "Delve Loremaster: War Within",
  "Leave No Treasure Unfound",
  "Sporesweeper",
  "Spider Senses",
  "Daystormer",
  "Brann Development",
  { label = "My First Nemesis", id = 40103 },
  { label = "My New Nemesis", id = 41530 },
  { label = "My Stab-Happy Nemesis", id = 42193 },

  -- Undermine meta requires:
  { label = "Going Goblin Mode", requires_labels = {
      "Adventurer of Undermine",
      "Treasures of Undermine",
      "Nine-Tenths of the Law",
      "Read Between the Lines",
      "That Can-Do Attitude",
      "You're My Friend Now",
  }},

  "Adventurer of Undermine",
  "Treasures of Undermine",
  "Nine-Tenths of the Law",
  "Read Between the Lines",
  "That Can-Do Attitude",
  "You're My Friend Now",
  "Owner of a Radiant Heart",

  -- K'aresh meta requires:
  { label = "Unraveled and Persevering", requires_labels = {
      "Remnants of a Shattered World",
      "Treasures of K'aresh",
      "Explore K'aresh",
      "Bounty Seeker",
      "Dangerous Prowlers of K'aresh",
      "Power of the Reshii",
      "Secrets of the K'areshi",
  }},

  "Remnants of a Shattered World",
  "Treasures of K'aresh",
  "Explore K'aresh",
  -- (Bounty Seeker handled above with IDs + prerequisite)
  "Dangerous Prowlers of K'aresh",
  "Power of the Reshii",
  "Secrets of the K'areshi",
}

-- Optional SavedVariables (declared in the .toc)
AchTrackWWDB = AchTrackWWDB or {}

-- =========================================================
-- Achievement resolution + runtime building
-- =========================================================
local function BuildAchievementTitleIndex()
  local index = {}
  if not GetCategoryList then return index end
  local cats = GetCategoryList()
  if not cats then return index end
  for _, catID in ipairs(cats) do
    local num = GetCategoryNumAchievements(catID)
    for i = 1, num do
      local id, name = GetAchievementInfo(catID, i)
      if id and name and name ~= "" then
        index[name] = id
      end
    end
  end
  return index
end

-- Runtime structures
local RUNTIME = nil        -- array of { label, ids, requires (IDs), requires_labels }
local LABEL_INDEX = nil    -- map label -> item (same table refs as in RUNTIME)

-- Returns array of { label, ids = {...}, requires = {... or nil}, requires_labels = {... or nil} }
local function BuildRuntimeList()
  local items = {}
  local idx = BuildAchievementTitleIndex()

  for _, entry in ipairs(WATCH_LIST) do
    if type(entry) == "string" then
      local id = idx[entry]
      table.insert(items, { label = entry, ids = id and { id } or {} })
    elseif type(entry) == "table" then
      local label = entry.label or entry.title or "(unnamed)"
      local ids = {}
      if entry.id then table.insert(ids, entry.id) end
      if type(entry.any) == "table" then
        for _, id in ipairs(entry.any) do table.insert(ids, id) end
      end
      if #ids == 0 then
        local key = entry.title or label
        local rid = idx[key]
        if rid then table.insert(ids, rid) end
      end
      local requires = nil
      if entry.requires then
        requires = type(entry.requires) == "table" and entry.requires or { entry.requires }
      end
      local requires_labels = nil
      if entry.requires_labels then
        requires_labels = {}
        for _, lname in ipairs(entry.requires_labels) do
          table.insert(requires_labels, lname)
        end
      end
      table.insert(items, { label = label, ids = ids, requires = requires, requires_labels = requires_labels })
    end
  end

  -- Build label map for quick lookups
  local map = {}
  for _, item in ipairs(items) do
    map[item.label] = item
  end

  RUNTIME = items
  LABEL_INDEX = map
  return items
end

-- =========================================================
-- Completion helpers
-- =========================================================
local function IsIDEarned(id)
  if not id then return false end
  local _, _, _, completed = GetAchievementInfo(id)
  return completed
end

local function IsAnyAchievementEarned(ids)
  if not ids or #ids == 0 then return nil end
  for _, id in ipairs(ids) do
    if IsIDEarned(id) then return true end
  end
  return false
end

local function PreferredOpenID(ids)
  if not ids or #ids == 0 then return nil end
  for _, id in ipairs(ids) do
    if IsIDEarned(id) then return id end
  end
  return ids[1]
end

-- Returns true if the labeled item is complete (any-of its ids)
local function IsLabelItemComplete(label)
  local item = LABEL_INDEX and LABEL_INDEX[label]
  if not item then return false end
  return IsAnyAchievementEarned(item.ids) == true
end

-- Returns lock state and first unmet prerequisite (by ID) if any
local function GetLockInfo(item)
  -- Numeric-ID prerequisites
  if item.requires and #item.requires > 0 then
    for _, rid in ipairs(item.requires) do
      if not IsIDEarned(rid) then
        return true, rid, nil -- locked, unmetID, unmetLabel=nil
      end
    end
  end
  -- Label-based prerequisites
  if item.requires_labels and #item.requires_labels > 0 then
    for _, lname in ipairs(item.requires_labels) do
      local sub = LABEL_INDEX and LABEL_INDEX[lname]
      if not sub or IsAnyAchievementEarned(sub.ids) ~= true then
        -- unmet label; prefer an ID from that label to open
        local openID = sub and PreferredOpenID(sub.ids) or nil
        return true, openID, lname
      end
    end
  end
  return false, nil, nil
end

-- =========================================================
-- Open Blizzard Achievement UI
-- =========================================================
local function OpenToAchievement(achID)
  if not achID then return end
  if not AchievementFrame then UIParentLoadAddOn("Blizzard_AchievementUI") end
  if not AchievementFrame then return end
  ShowUIPanel(AchievementFrame)
  if AchievementFrame_SelectAchievement then
    AchievementFrame_SelectAchievement(achID)
  elseif AchievementFrame_DisplayAchievement then
    AchievementFrame_DisplayAchievement(achID)
  end
end

-- =========================================================
-- UI
-- =========================================================
local UI = {}

local function CreateMainFrame()
  if UI.frame then return UI.frame end

  local f = CreateFrame("Frame", "AchTrackWWFrame", UIParent, "BackdropTemplate")
  f:SetSize(520, 560)
  f:SetPoint("CENTER")
  f:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  f:SetBackdropColor(0, 0, 0, 0.85)
  f:SetBackdropBorderColor(0.8, 0.65, 0.2, 1)
  f:Hide()

  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -10)
  title:SetText("Achievement Tracker – The War Within Meta")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 12, -36)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(1, 1)
  scrollFrame:SetScrollChild(content)

  UI.frame = f
  UI.scroll = scrollFrame
  UI.content = content
  UI.rows = {}

  return f
end

local function ColorText(fs, status)
  if status == true then
    fs:SetTextColor(0.2, 1.0, 0.2) -- green
  elseif status == false then
    fs:SetTextColor(1.0, 0.25, 0.25) -- red
  elseif status == "locked" then
    fs:SetTextColor(0.7, 0.7, 0.7) -- grey for locked/unavailable
  else
    fs:SetTextColor(1.0, 0.8, 0.2) -- amber (not found)
  end
end

-- ===== Sorting helpers: locked -> incomplete -> complete -> unresolved
local function GetStatusForSort(item)
  local locked = false
  local _, _, _ = nil, nil, nil
  if LABEL_INDEX then
    locked = GetLockInfo(item)
    if type(locked) == "table" then locked = locked[1] end
  end
  if not locked then
    local done = IsAnyAchievementEarned(item.ids)
    return done -- true/false/nil
  end
  return "locked"
end

local function sortVal(v)
  if v == "locked" then return 0 end
  if v == false      then return 1 end
  if v == true       then return 2 end
  return 3 -- unresolved by title
end
-- ===== End helpers

local function CreateOrUpdateRows()
  CreateMainFrame()
  local parent = UI.content
  local y = -4

  for _, row in ipairs(UI.rows) do
    row:Hide()
  end
  wipe(UI.rows)

  local runtime = BuildRuntimeList()

  -- Sort using helpers so label-based dependencies affect placement
  table.sort(runtime, function(a, b)
    local av = sortVal(GetStatusForSort(a))
    local bv = sortVal(GetStatusForSort(b))
    if av == bv then return a.label < b.label end
    return av < bv
  end)

  for _, data in ipairs(runtime) do
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(460, 22)
    row:SetPoint("TOPLEFT", 6, y)
    y = y - 24

    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row:GetHighlightTexture():SetAlpha(0.25)
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp")

    row.titleFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.titleFS:SetPoint("LEFT")

    -- Determine locked state from numeric + label prerequisites
    local locked, unmetID, unmetLabel = GetLockInfo(data)

    local label = data.label
    local status

    if not data.ids or #data.ids == 0 then
      status = nil
      label = label .. "  (not found – try /achfind \"" .. data.label .. "\")"
    elseif locked then
      status = "locked"
      label = label .. "  (locked: complete prerequisite)"
    else
      status = IsAnyAchievementEarned(data.ids)
    end

    row.titleFS:SetText(label)
    ColorText(row.titleFS, status)

    row:SetScript("OnClick", function()
      if locked then
        if unmetID then
          OpenToAchievement(unmetID)
        elseif unmetLabel and LABEL_INDEX[unmetLabel] then
          local openID = PreferredOpenID(LABEL_INDEX[unmetLabel].ids)
          if openID then OpenToAchievement(openID) end
        else
          -- Fall back to opening this row if we can't resolve the unmet target
          local openID = PreferredOpenID(data.ids)
          if openID then OpenToAchievement(openID) end
        end
      else
        local openID = PreferredOpenID(data.ids)
        if openID then OpenToAchievement(openID) end
      end
    end)

    row:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(data.label)

      -- Show label-based prerequisites
      if data.requires_labels and #data.requires_labels > 0 then
        GameTooltip:AddLine("Prerequisite(s) by label:", 0.9, 0.9, 0.9)
        for _, lname in ipairs(data.requires_labels) do
          local complete = IsLabelItemComplete(lname)
          local mark = complete and "|cff20ff20✓|r" or "|cffff4040✗|r"
          GameTooltip:AddLine(string.format("  %s %s", mark, lname))
        end
      end

      -- Show numeric-ID prerequisites
      if data.requires and #data.requires > 0 then
        GameTooltip:AddLine("Prerequisite(s):", 0.9, 0.9, 0.9)
        for _, rid in ipairs(data.requires) do
          local rname = select(1, GetAchievementInfo(rid))
          local reqDone = IsIDEarned(rid)
          local mark = reqDone and "|cff20ff20✓|r" or "|cffff4040✗|r"
          GameTooltip:AddLine(string.format("  %s %s (ID %d)", mark, rname or "?", rid))
        end
      end

      if locked then
        GameTooltip:AddLine("This achievement is locked until prerequisites are complete.", 1, 0.82, 0)
      end

      if data.ids and #data.ids > 0 then
        GameTooltip:AddLine("Progress:", 0.9, 0.9, 0.9)
        for _, id in ipairs(data.ids) do
          local name, _, _, completed, _, _, _, _, _, icon = GetAchievementInfo(id)
          local mark = completed and "|cff20ff20✓|r" or "|cffff4040✗|r"
          GameTooltip:AddLine(string.format("  %s %s (ID %d)", mark, name or "?", id))
          if icon then GameTooltip:AddTexture(icon) end
        end
        GameTooltip:AddLine(locked and "Click to open an unmet prerequisite." or "Click to open in the Achievement UI.", 0.8, 0.8, 0.8)
      else
        GameTooltip:AddLine("Not auto-resolved. Use /achfind and update the list.", 1, 1, 1, true)
      end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    table.insert(UI.rows, row)
  end

  parent:SetSize(460, -y + 8)
end

local function RefreshUI()
  if UI.frame and UI.frame:IsShown() then
    CreateOrUpdateRows()
  end
end

-- =========================================================
-- Events (with debounce for ACHIEVEMENT_EARNED)
-- =========================================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("ACHIEVEMENT_EARNED")

local refreshQueued = false

f:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name ~= "AchTrackWW" then return end
    AchTrackWWDB = AchTrackWWDB or {}
    CreateMainFrame()
    -- Small delay ensures achievement data is populated
    C_Timer.After(2, function() CreateOrUpdateRows() end)

  elseif event == "ACHIEVEMENT_EARNED" then
    if not refreshQueued then
      refreshQueued = true
      C_Timer.After(0.3, function()
        refreshQueued = false
        RefreshUI()
      end)
    end
  end
end)

-- =========================================================
-- Slash commands
-- =========================================================
SLASH_ACHTRACKWW1 = "/achtrack"
SlashCmdList["ACHTRACKWW"] = function()
  CreateMainFrame()
  if UI.frame:IsShown() then
    UI.frame:Hide()
  else
    UI.frame:Show()
    CreateOrUpdateRows()
  end
end

-- /achfind <keyword> : quick search helper
SLASH_ACHFINDWW1 = "/achfind"
SlashCmdList["ACHFINDWW"] = function(msg)
  local q = strtrim(msg or "")
  if q == "" then
    print("|cffffd200AchTrackWW:|r Usage: /achfind <keyword>")
    return
  end
  local cats = GetCategoryList and GetCategoryList() or nil
  if not cats then
    print("|cffff2020AchTrackWW:|r Achievement API not ready.")
    return
  end
  q = q:lower()
  local hits = {}
  for _, catID in ipairs(cats) do
    local num = GetCategoryNumAchievements(catID)
    for i = 1, num do
      local id, name = GetAchievementInfo(catID, i)
      if id and name and name:lower():find(q, 1, true) then
        table.insert(hits, { id = id, name = name })
      end
    end
  end
  table.sort(hits, function(a,b) return a.name < b.name end)
  if #hits == 0 then
    print("|cffffd200AchTrackWW:|r No achievements found for '"..msg.."'.")
  else
    print("|cffffd200AchTrackWW:|r Results for '"..msg.."':")
    for i = 1, math.min(#hits, 20) do
      local h = hits[i]
      print(string.format("  %s |cffa0a0a0(ID %d)|r", h.name, h.id))
    end
    if #hits > 20 then
      print(string.format("  ...and %d more.", #hits - 20))
    end
  end
end

-- Force rebuild/sort of the list
SLASH_ACHREFRESHWW1 = "/achrefresh"
SlashCmdList["ACHREFRESHWW"] = function()
  CreateOrUpdateRows()
  print("|cffffd200AchTrackWW:|r Refreshed.")
end
