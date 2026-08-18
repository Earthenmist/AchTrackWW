local ADDON_NAME, MH = ...
local Theme = MH.Theme

--[[
  The real, persistent Meta Hunter window: header + left sidebar (expansion
  navigation) + right content pane (the selected expansion's achievement tree,
  grouped into bordered category panels and rendered via TreeRow).

  Expand/collapse state is tracked here (expandedState, keyed by
  "rootID:nodeID"), not on the pooled row objects themselves. A row's
  identity is ephemeral (it gets reused for a totally different node next
  render), but which nodes are expanded needs to persist across re-renders
  triggered by clicking a toggle. Session-only, not persisted: every
  window open starts from the category defaults below.
]]

MH.UI = MH.UI or {}
MH.UI.MainFrame = {}

local mainFrame = nil
local selectedExpansionID = nil
local showingSettings = false
local expandedState = {}
local activeTreeRows = {}
local rowCounter = 0

local panelPool = {}
local activePanels = {}
local settingControlPool = {}
local activeSettingControls = {}

local sidebarButtons = {} -- expansionID -> button, built once, updated in place on selection change
local settingsButton = nil
local UpdateHeaderSummary
local RefreshSidebarHighlight

-- Preferred display order for category panels. Anything not listed here falls
-- after these.
local CATEGORY_ORDER = { main = 1, expectedMeta = 2, notable = 3, exploration = 4, dungeon = 5, raid = 6, season = 7, pathfinder = 8, delves = 9, zone = 10, pvp = 11, misc = 12 }

local CATEGORY_LABELS = {
  main = "Expansion Meta",
  expectedMeta = "Expected Towards Meta",
  notable = "Notable Achievements",
  dungeon = "Dungeons",
  raid = "Raids",
}

local function NodeKey(rootID, nodeID)
  return tostring(rootID) .. ":" .. tostring(nodeID)
end

local function GetOneOfTargetID(record)
  if not record or type(record.oneOfAchievementIDs) ~= "table" then return nil end

  local firstID = nil
  local firstEarnedID = nil
  local firstIncompleteID = nil
  local firstUnknownID = nil
  for _, alternateID in ipairs(record.oneOfAchievementIDs) do
    firstID = firstID or alternateID
    local earned = MH.Engine.IsIDEarned(alternateID)
    if earned == true and not firstEarnedID then
      firstEarnedID = alternateID
    elseif earned == false and not firstIncompleteID then
      firstIncompleteID = alternateID
    elseif earned == nil and not firstUnknownID then
      firstUnknownID = alternateID
    end
  end
  return firstEarnedID or firstIncompleteID or firstUnknownID or firstID
end

local function GetActionAchievementID(nodeID, record)
  if type(nodeID) == "number" then return nodeID end
  return GetOneOfTargetID(record)
end

local function GetProfile()
  return (MH.db and MH.db.profile) or {}
end

local function ShouldAutoExpandMainMeta()
  local entry = MH.ExpansionManifest and MH.ExpansionManifest:Get(selectedExpansionID)
  if entry and entry.autoExpandMainMeta == false then return false end
  return GetProfile().autoExpandMainMeta ~= false
end

local function GetRootSummary(rootID)
  local entry = selectedExpansionID and MH.ExpansionManifest:Get(selectedExpansionID)
  if entry and entry.summaryMode == "immediate" then
    local progress = MH.Engine:GetProgress(rootID, rootID)
    return {
      earned = progress.earned + (MH.Engine:IsEarned(rootID) == true and 1 or 0),
      total = progress.total + 1,
    }
  end
  return MH.Engine:GetProgressRecursive(rootID, rootID)
end

local SCROLLBAR_WIDTH = 6
local SCROLLBAR_GUTTER = 4
local CONTENT_PADDING = 8
local NOTICE_HEIGHT = 58
local NOTICE_GAP = 10
local SIDEBAR_WIDTH = 190
local LOGO_TEXTURE = "Interface\\AddOns\\MetaHunter\\Media\\MetaHunterLogo"

-- Local clamp avoids relying on a client-provided global.
local function Clamp(value, minValue, maxValue)
  if value < minValue then return minValue end
  if value > maxValue then return maxValue end
  return value
end

-- Category panel with a header strip, progress summary, and rows container.
local function AcquirePanel(parent)
  local p = table.remove(panelPool)
  if not p then
    p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    p:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8x8",
      edgeFile = "Interface/Buttons/WHITE8x8",
      edgeSize = 1,
    })
    p:SetBackdropColor(Theme:GetColor("bgPanel"))
    p:SetBackdropBorderColor(Theme:GetColor("border"))

    p.headerBg = p:CreateTexture(nil, "BACKGROUND")
    p.headerBg:SetPoint("TOPLEFT", 1, -1)
    p.headerBg:SetPoint("TOPRIGHT", -1, -1)
    p.headerBg:SetHeight(30)
    p.headerBg:SetColorTexture(Theme:GetColor("bgPanelHeader"))

    p.header = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.header:SetPoint("TOPLEFT", 10, -8)
    p.header:SetTextColor(Theme:GetColor("accent"))

    p.headerProgress = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.headerProgress:SetPoint("TOPRIGHT", -10, -8)
    p.headerProgress:SetTextColor(Theme:GetColor("textDim"))

    p.rows = CreateFrame("Frame", nil, p)
    p.rows:SetPoint("TOPLEFT", p.header, "BOTTOMLEFT", -2, -8)
    p.rows:SetPoint("RIGHT", p, "RIGHT", -8, 0)

    p.rowsBg = p.rows:CreateTexture(nil, "BACKGROUND")
    p.rowsBg:SetPoint("TOPLEFT", -4, 2)
    p.rowsBg:SetPoint("BOTTOMRIGHT", 4, -2)
    p.rowsBg:SetColorTexture(Theme:GetColor("bgPanelRows"))
  else
    p:SetParent(parent)
  end
  p:Show()
  return p
end

local function ReleaseContent()
  for _, row in ipairs(activeTreeRows) do
    MH.UI.TreeRow:Release(row)
  end
  activeTreeRows = {}
  rowCounter = 0

  for _, control in ipairs(activeSettingControls) do
    control:Hide()
    control:ClearAllPoints()
    table.insert(settingControlPool, control)
  end
  activeSettingControls = {}

  for _, p in ipairs(activePanels) do
    p:Hide()
    p:ClearAllPoints()
    table.insert(panelPool, p)
  end
  activePanels = {}
end

local function AcquireSettingControl(parent)
  local control = table.remove(settingControlPool)
  if not control then
    control = CreateFrame("Button", nil, parent)
    control:SetHeight(30)

    control.bg = control:CreateTexture(nil, "BACKGROUND")
    control.bg:SetAllPoints()

    control.check = control:CreateTexture(nil, "OVERLAY")
    control.check:SetSize(14, 14)
    control.check:SetPoint("LEFT", 8, 0)

    control.label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    control.label:SetPoint("LEFT", 32, 0)
    control.label:SetPoint("RIGHT", -10, 0)
    control.label:SetJustifyH("LEFT")
  else
    control:SetParent(parent)
  end
  control:Show()
  table.insert(activeSettingControls, control)
  return control
end

local function PopulateSettingControl(control, text, checked, onClick)
  control.bg:SetColorTexture(Theme:GetColor("bgRowAlt"))
  control.check:Show()
  control.check:SetTexture(checked and "Interface\\Buttons\\UI-CheckBox-Check" or "Interface\\Buttons\\WHITE8x8")
  if checked then
    control.check:SetVertexColor(Theme:GetColor("complete"))
  else
    control.check:SetVertexColor(Theme:GetColor("incomplete"))
  end
  control.label:ClearAllPoints()
  control.label:SetPoint("LEFT", 32, 0)
  control.label:SetPoint("RIGHT", -10, 0)
  control.label:SetText(text)
  control:SetScript("OnClick", onClick)
  control:SetScript("OnEnter", function(self)
    self.bg:SetColorTexture(Theme:GetColor("bgHover"))
  end)
  control:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(Theme:GetColor("bgRowAlt"))
  end)
end

-- Renders `nodeID` and its expanded children into `parent`, returning the next
-- y position.
local function RenderNode(parent, rootID, nodeID, depth, ancestorContinues, isLastSibling, y, defaultExpanded)
  local record = MH.Registry:GetAchievement(nodeID)
  local children = MH.Registry:GetChildren(rootID, nodeID)
  local hasChildren = children ~= nil and #children > 0
  local key = NodeKey(rootID, nodeID)
  local storedExpanded = expandedState[key]
  local shouldExpandByDefault = defaultExpanded == true and storedExpanded == nil
  local expanded = hasChildren and (shouldExpandByDefault or storedExpanded == true)

  rowCounter = rowCounter + 1
  local actionAchievementID = GetActionAchievementID(nodeID, record)
  local icon = record and record.icon or nil
  if not icon and actionAchievementID then
    icon = select(10, MH.Engine.GetAchievementInfoCompat(actionAchievementID))
  end

  local row = MH.UI.TreeRow:Acquire(parent)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
  row:SetPoint("RIGHT", parent, "RIGHT", -4, 0)

  local progressText = nil
  if hasChildren then
    local progress = MH.Engine:GetProgress(rootID, nodeID)
    progressText = progress.earned .. "/" .. progress.total
  end

  MH.UI.TreeRow:Populate(
    row,
    {
      depth = depth,
      isLastSibling = isLastSibling,
      ancestorContinues = ancestorContinues,
      text = record and record.title or ("#" .. tostring(nodeID)),
      icon = icon,
      earned = MH.Engine:IsEarned(nodeID),
      hasChildren = hasChildren,
      expanded = expanded,
      progressText = progressText,
      rowIndex = rowCounter,
      guide = record and record.guide,
    },
    function() -- onToggle: real, click-driven expand/collapse
      expandedState[key] = not expanded
      MH.UI.MainFrame:RefreshContent()
    end,
    function() -- onClick: open the Blizzard achievement panel to this node
      if actionAchievementID then
        MH.Engine:OpenToAchievement(actionAchievementID)
      end
    end,
    function() -- onRightClick: toggle tracking
      if not actionAchievementID then return end
      local tracked = MH.Engine:ToggleTracked(actionAchievementID)
      local name = record and record.title or tostring(nodeID)
      print("|cff33ccbcMetaHunter:|r " .. (tracked and ("Tracking " .. name) or ("Untracked " .. name)))
    end
  )
  table.insert(activeTreeRows, row)

  local nextY = y - MH.UI.TreeRow.ROW_HEIGHT
  if expanded and children then
    for i, childID in ipairs(children) do
      local childIsLast = (i == #children)
      local childAncestors = {}
      for j = 1, depth - 1 do childAncestors[j] = ancestorContinues[j] end
      childAncestors[depth] = not isLastSibling
      nextY = RenderNode(parent, rootID, childID, depth + 1, childAncestors, childIsLast, nextY, false)
    end
  end

  return nextY
end

local function CategoryOrder(category)
  return CATEGORY_ORDER[category] or 99
end

local function RenderExpansionContent()
  local content = mainFrame.content
  ReleaseContent()

  if not selectedExpansionID then
    content:SetHeight(1)
    return
  end

  local roots = MH.Registry:GetRoots(selectedExpansionID)
  if not roots or #roots == 0 then
    content:SetHeight(1)
    return
  end

  local byCategory = {}
  local categories = {}
  for _, rootID in ipairs(roots) do
    local placement = MH.Registry:GetPlacement(rootID, nil, rootID)
    local category = (placement and placement.category) or "misc"
    if not byCategory[category] then
      byCategory[category] = {}
      table.insert(categories, category)
    end
    table.insert(byCategory[category], rootID)
  end
  table.sort(categories, function(a, b) return CategoryOrder(a) < CategoryOrder(b) end)

  local y = -4
  for _, category in ipairs(categories) do
    local panel = AcquirePanel(content)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
    panel:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    table.insert(activePanels, panel)

    panel.header:SetText(CATEGORY_LABELS[category] or (category:sub(1, 1):upper() .. category:sub(2)))

    local categoryEarned, categoryTotal = 0, 0
    for _, rootID in ipairs(byCategory[category]) do
      local progress = GetRootSummary(rootID)
      categoryEarned = categoryEarned + progress.earned
      categoryTotal = categoryTotal + progress.total
    end
    panel.headerProgress:SetText(categoryEarned .. " / " .. categoryTotal)

    local rowY = 0
    for _, rootID in ipairs(byCategory[category]) do
      rowY = RenderNode(panel.rows, rootID, rootID, 0, {}, true, rowY, category == "main" and ShouldAutoExpandMainMeta())
      rowY = rowY - 10
    end
    panel.rows:SetHeight(math.max(-rowY, 1))

    -- Panel height = header strip + rows container + top/bottom padding.
    local panelHeight = 8 + panel.header:GetStringHeight() + 8 + (-rowY) + 8
    panel:SetHeight(panelHeight)

    y = y - panelHeight - 12 -- gap between panels
  end

  content:SetHeight(math.max(-y, 1))

  -- Defer scrollbar refresh by one frame so WoW has resolved the scroll
  -- child's new height before GetVerticalScrollRange() is read.
  if mainFrame.UpdateScrollbar then
    C_Timer.After(0, mainFrame.UpdateScrollbar)
  end
end

local function RenderSettingsContent()
  local content = mainFrame.content
  ReleaseContent()

  local panel = AcquirePanel(content)
  panel:ClearAllPoints()
  panel:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
  panel:SetPoint("RIGHT", content, "RIGHT", -4, 0)
  table.insert(activePanels, panel)

  panel.header:SetText("Settings")
  panel.headerProgress:SetText("")

  local profile = GetProfile()
  local rowY = 0

  local notices = AcquireSettingControl(panel.rows)
  notices:SetPoint("TOPLEFT", panel.rows, "TOPLEFT", 4, rowY)
  notices:SetPoint("RIGHT", panel.rows, "RIGHT", -4, 0)
  PopulateSettingControl(notices, "Show current-expansion notices", profile.showExpansionNotices ~= false, function()
    profile.showExpansionNotices = not (profile.showExpansionNotices ~= false)
    RenderSettingsContent()
  end)
  rowY = rowY - 34

  local expandMain = AcquireSettingControl(panel.rows)
  expandMain:SetPoint("TOPLEFT", panel.rows, "TOPLEFT", 4, rowY)
  expandMain:SetPoint("RIGHT", panel.rows, "RIGHT", -4, 0)
  PopulateSettingControl(expandMain, "Open expansion meta by default", profile.autoExpandMainMeta ~= false, function()
    profile.autoExpandMainMeta = not (profile.autoExpandMainMeta ~= false)
    expandedState = {}
    RenderSettingsContent()
  end)
  rowY = rowY - 34

  local minimap = AcquireSettingControl(panel.rows)
  minimap:SetPoint("TOPLEFT", panel.rows, "TOPLEFT", 4, rowY)
  minimap:SetPoint("RIGHT", panel.rows, "RIGHT", -4, 0)
  PopulateSettingControl(minimap, "Show minimap button", MH:IsMinimapButtonShown(), function()
    MH:SetMinimapButtonShown(not MH:IsMinimapButtonShown())
    RenderSettingsContent()
  end)
  rowY = rowY - 44

  local reset = AcquireSettingControl(panel.rows)
  reset:SetPoint("TOPLEFT", panel.rows, "TOPLEFT", 4, rowY)
  reset:SetPoint("RIGHT", panel.rows, "RIGHT", -4, 0)
  PopulateSettingControl(reset, "Reset cached sidebar summaries", false, function()
    if MH.db and MH.db.global then
      MH.db.global.expansionSummaries = {}
    end
    RefreshSidebarHighlight()
    UpdateHeaderSummary()
    print("|cff33ccbcMetaHunter:|r Cached expansion summaries reset.")
  end)
  reset.check:Hide()
  reset.label:ClearAllPoints()
  reset.label:SetPoint("LEFT", 12, 0)
  reset.label:SetPoint("RIGHT", -10, 0)
  rowY = rowY - 34

  panel.rows:SetHeight(math.max(-rowY, 1))
  local panelHeight = 8 + panel.header:GetStringHeight() + 8 + (-rowY) + 8
  panel:SetHeight(panelHeight)
  content:SetHeight(panelHeight + 16)

  if mainFrame.UpdateScrollbar then
    C_Timer.After(0, mainFrame.UpdateScrollbar)
  end
end

local function UpdateExpansionNotice()
  if not mainFrame then return end

  if showingSettings or GetProfile().showExpansionNotices == false then
    mainFrame.notice:Hide()
    mainFrame.scroll:ClearAllPoints()
    mainFrame.scroll:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    mainFrame.scroll:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    mainFrame.track:ClearAllPoints()
    mainFrame.track:SetPoint("TOPLEFT", mainFrame.viewport, "TOPRIGHT", SCROLLBAR_GUTTER, 0)
    mainFrame.track:SetPoint("BOTTOMLEFT", mainFrame.viewport, "BOTTOMRIGHT", SCROLLBAR_GUTTER, 0)
    return
  end

  local entry = selectedExpansionID and MH.ExpansionManifest:Get(selectedExpansionID)
  local notice = entry and entry.notice
  if not notice then
    mainFrame.notice:Hide()
    mainFrame.scroll:ClearAllPoints()
    mainFrame.scroll:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    mainFrame.scroll:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    mainFrame.track:ClearAllPoints()
    mainFrame.track:SetPoint("TOPLEFT", mainFrame.viewport, "TOPRIGHT", SCROLLBAR_GUTTER, 0)
    mainFrame.track:SetPoint("BOTTOMLEFT", mainFrame.viewport, "BOTTOMRIGHT", SCROLLBAR_GUTTER, 0)
    return
  end

  mainFrame.noticeTitle:SetText(notice.title or "")
  mainFrame.noticeBody:SetText(notice.body or "")
  mainFrame.notice:Show()
  mainFrame.scroll:ClearAllPoints()
  mainFrame.scroll:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
  mainFrame.scroll:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING + NOTICE_HEIGHT + NOTICE_GAP)
  mainFrame.track:ClearAllPoints()
  mainFrame.track:SetPoint("TOPLEFT", mainFrame.viewport, "TOPRIGHT", SCROLLBAR_GUTTER, 0)
  mainFrame.track:SetPoint("BOTTOMLEFT", mainFrame.viewport, "BOTTOMRIGHT", SCROLLBAR_GUTTER, NOTICE_HEIGHT + NOTICE_GAP)
end

function UpdateHeaderSummary()
  if showingSettings then
    mainFrame.titleText:SetText("Settings")
    mainFrame.summaryText:SetText("")
    return
  end

  local entry = selectedExpansionID and MH.ExpansionManifest:Get(selectedExpansionID)
  if not entry then
    mainFrame.titleText:SetText("Meta Hunter")
    mainFrame.summaryText:SetText("")
    return
  end
  mainFrame.titleText:SetText(entry.displayName)
  local summary = MH.ExpansionManifest:GetCachedSummary(selectedExpansionID)
  mainFrame.summaryText:SetText(summary and (summary.earned .. " / " .. summary.total) or "")
end

function RefreshSidebarHighlight()
  for id, btn in pairs(sidebarButtons) do
    local isSelected = (id == selectedExpansionID and not showingSettings)
    btn.baseColorName = isSelected and "bgRowAlt" or "bg"
    btn.highlight:SetColorTexture(Theme:GetColor(btn.baseColorName))
    btn.nameText:SetTextColor(Theme:GetColor(isSelected and "accent" or "textBright"))
    local cached = MH.ExpansionManifest:GetCachedSummary(id)
    btn.summaryText:SetText(cached and (cached.earned .. "/" .. cached.total) or "")
    -- Left-edge stripe for selected nav rows.
    btn.selectedStripe:SetShown(isSelected)
  end

  if settingsButton then
    settingsButton.baseColorName = showingSettings and "bgRowAlt" or "bg"
    settingsButton.highlight:SetColorTexture(Theme:GetColor(settingsButton.baseColorName))
    settingsButton.label:SetTextColor(Theme:GetColor(showingSettings and "accent" or "textBright"))
    settingsButton.selectedStripe:SetShown(showingSettings)
  end
end

local function SelectExpansion(expansionID)
  showingSettings = false
  selectedExpansionID = expansionID
  RefreshSidebarHighlight()

  MH.ExpansionManifest:EnsureLoaded(expansionID, function(ok, reason)
    if not ok then
      print("|cffffd200MetaHunter:|r couldn't load " .. tostring(expansionID) .. " -- " .. tostring(reason))
      return
    end
    MH.ExpansionManifest:RefreshSummary(expansionID)
    UpdateHeaderSummary()
    RefreshSidebarHighlight() -- summary text on the sidebar button too
    UpdateExpansionNotice()
    RenderExpansionContent()
  end)
end

local function ShowSettings()
  showingSettings = true
  RefreshSidebarHighlight()
  UpdateHeaderSummary()
  UpdateExpansionNotice()
  RenderSettingsContent()
end

local function BuildSidebarButtons(sidebar)
  -- Section label for the expansion nav list.
  local sectionLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sectionLabel:SetPoint("TOPLEFT", 8, -8)
  sectionLabel:SetText("EXPANSIONS")
  sectionLabel:SetTextColor(Theme:GetColor("textDim"))

  local y = -26
  for _, entry in ipairs(MH.ExpansionManifest:GetAll()) do
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(36)
    btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 2, y)
    btn:SetPoint("RIGHT", sidebar, "RIGHT", -2, 0)

    btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(Theme:GetColor("bg"))

    btn.selectedStripe = btn:CreateTexture(nil, "ARTWORK")
    btn.selectedStripe:SetPoint("TOPLEFT")
    btn.selectedStripe:SetPoint("BOTTOMLEFT")
    btn.selectedStripe:SetWidth(3)
    btn.selectedStripe:SetColorTexture(Theme:GetColor("accent"))
    btn.selectedStripe:Hide()

    btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.nameText:SetPoint("TOPLEFT", 10, -7)
    btn.nameText:SetPoint("RIGHT", -6, 0)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetWordWrap(false)
    btn.nameText:SetText(entry.displayName)

    btn.summaryText = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    btn.summaryText:SetPoint("TOPLEFT", 10, -21)
    btn.summaryText:SetTextColor(Theme:GetColor("textDim"))
    local cached = MH.ExpansionManifest:GetCachedSummary(entry.id)
    btn.summaryText:SetText(cached and (cached.earned .. "/" .. cached.total) or "")

    btn:SetScript("OnClick", function() SelectExpansion(entry.id) end)
    btn:SetScript("OnEnter", function(self)
      self.highlight:SetColorTexture(Theme:GetColor("bgHover"))
    end)
    btn:SetScript("OnLeave", function(self)
      self.highlight:SetColorTexture(Theme:GetColor(self.baseColorName or "bg"))
    end)

    sidebarButtons[entry.id] = btn
    y = y - 36
  end
end

local function BuildSettingsButton(sidebar)
  local btn = CreateFrame("Button", nil, sidebar)
  btn:SetHeight(28)
  btn:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 8, 12)
  btn:SetPoint("RIGHT", sidebar, "RIGHT", -8, 0)

  btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
  btn.highlight:SetAllPoints()
  btn.highlight:SetColorTexture(Theme:GetColor("bg"))

  btn.selectedStripe = btn:CreateTexture(nil, "ARTWORK")
  btn.selectedStripe:SetPoint("TOPLEFT")
  btn.selectedStripe:SetPoint("BOTTOMLEFT")
  btn.selectedStripe:SetWidth(3)
  btn.selectedStripe:SetColorTexture(Theme:GetColor("accent"))
  btn.selectedStripe:Hide()

  btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  btn.label:SetPoint("CENTER")
  btn.label:SetText("Settings")

  btn:SetScript("OnClick", ShowSettings)
  btn:SetScript("OnEnter", function(self)
    self.highlight:SetColorTexture(Theme:GetColor("bgHover"))
  end)
  btn:SetScript("OnLeave", function(self)
    self.highlight:SetColorTexture(Theme:GetColor(self.baseColorName or "bg"))
  end)

  settingsButton = btn
end

local function BuildFrame()
  if mainFrame then return mainFrame end

  -- Dashboard-sized detail panel.
  local f = CreateFrame("Frame", "MetaHunterMainFrame", UIParent, "BackdropTemplate")
  f:SetSize(940, 680)
  f:SetPoint("CENTER")
  -- Keep the window above the default HUD and common Blizzard panels.
  f:SetFrameStrata("HIGH")
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
  })
  f:SetBackdropColor(Theme:GetColor("bg"))
  f:SetBackdropBorderColor(Theme:GetColor("border"))
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetClampRectInsets(0, 0, 0, 0)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  -- Created frames start shown, so hide before Toggle() can manage visibility.
  f:Hide()

  -- Header with accent stripe and underline.
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", 3, -3)
  header:SetPoint("TOPRIGHT", -3, -3)
  header:SetHeight(40)

  local headerBg = header:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  headerBg:SetColorTexture(Theme:GetColor("bgHeader"))

  local headerStripe = header:CreateTexture(nil, "ARTWORK")
  headerStripe:SetPoint("TOPLEFT")
  headerStripe:SetPoint("BOTTOMLEFT")
  headerStripe:SetWidth(4)
  headerStripe:SetColorTexture(Theme:GetColor("accent"))

  local headerUnderline = header:CreateTexture(nil, "ARTWORK")
  headerUnderline:SetPoint("BOTTOMLEFT")
  headerUnderline:SetPoint("BOTTOMRIGHT")
  headerUnderline:SetHeight(2)
  headerUnderline:SetColorTexture(Theme:GetColor("accent"))

  -- Header text is parented to the header frame so it draws above the header
  -- background.
  local brand = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  brand:SetPoint("TOPLEFT", header, "TOPLEFT", 14, -6)
  brand:SetText("Meta Hunter")
  brand:SetTextColor(Theme:GetColor("accent"))

  f.titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.titleText:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -3)
  f.titleText:SetTextColor(Theme:GetColor("textBright"))

  f.summaryText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.summaryText:SetPoint("RIGHT", header, "RIGHT", -48, 0)
  f.summaryText:SetTextColor(Theme:GetColor("accent"))

  local close = CreateFrame("Button", nil, header, "BackdropTemplate")
  close:SetSize(24, 24)
  close:SetPoint("RIGHT", header, "RIGHT", -10, 0)
  close:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Buttons/WHITE8x8",
    edgeSize = 1,
  })
  close:SetBackdropColor(Theme:GetColor("bgRowAlt"))
  close:SetBackdropBorderColor(Theme:GetColor("border"))

  close.icon = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  close.icon:SetPoint("CENTER", 0, 0)
  close.icon:SetText("X")
  close.icon:SetTextColor(Theme:GetColor("textDim"))

  close:SetScript("OnClick", function() f:Hide() end)
  close:SetScript("OnEnter", function(self)
    self:SetBackdropColor(Theme:GetColor("bgHover"))
    self:SetBackdropBorderColor(Theme:GetColor("accent"))
    self.icon:SetTextColor(Theme:GetColor("accent"))
  end)
  close:SetScript("OnLeave", function(self)
    self:SetBackdropColor(Theme:GetColor("bgRowAlt"))
    self:SetBackdropBorderColor(Theme:GetColor("border"))
    self.icon:SetTextColor(Theme:GetColor("textDim"))
  end)
  close:SetScript("OnMouseDown", function(self)
    self.icon:ClearAllPoints()
    self.icon:SetPoint("CENTER", 1, -1)
  end)
  close:SetScript("OnMouseUp", function(self)
    self.icon:ClearAllPoints()
    self.icon:SetPoint("CENTER", 0, 0)
  end)

  -- Left sidebar: expansion picker.
  local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
  sidebar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
  sidebar:SetPoint("BOTTOMLEFT", 6, 6)
  sidebar:SetWidth(SIDEBAR_WIDTH)
  sidebar:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
  sidebar:SetBackdropColor(Theme:GetColor("bgRowAlt"))
  f.sidebar = sidebar

  local sidebarLogo = sidebar:CreateTexture(nil, "ARTWORK")
  sidebarLogo:SetSize(84, 84)
  sidebarLogo:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 42)
  sidebarLogo:SetTexture(LOGO_TEXTURE)
  sidebarLogo:SetAlpha(0.85)
  f.sidebarLogo = sidebarLogo

  -- Right content pane with a themed scrollbar and fixed viewport backdrop.
  local viewport = CreateFrame("Frame", nil, f, "BackdropTemplate")
  viewport:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
  viewport:SetPoint("BOTTOMRIGHT", -(SCROLLBAR_WIDTH + SCROLLBAR_GUTTER + 6), 6)
  viewport:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Buttons/WHITE8x8",
    edgeSize = 1,
  })
  viewport:SetBackdropColor(Theme:GetColor("bgViewport"))
  viewport:SetBackdropBorderColor(Theme:GetColor("border"))
  if viewport.SetClipsChildren then viewport:SetClipsChildren(true) end

  local scroll = CreateFrame("ScrollFrame", "MetaHunterMainFrameScroll", viewport)
  scroll:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
  scroll:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
  if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end

  local notice = CreateFrame("Frame", nil, viewport, "BackdropTemplate")
  notice:SetPoint("BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
  notice:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
  notice:SetHeight(NOTICE_HEIGHT)
  notice:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Buttons/WHITE8x8",
    edgeSize = 1,
  })
  notice:SetBackdropColor(Theme:GetColor("bgNotice"))
  notice:SetBackdropBorderColor(Theme:GetColor("warningBorder"))
  notice:Hide()

  notice.icon = notice:CreateTexture(nil, "ARTWORK")
  notice.icon:SetSize(22, 22)
  notice.icon:SetPoint("LEFT", 12, 0)
  notice.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")

  notice.title = notice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  notice.title:SetPoint("TOPLEFT", notice, "TOPLEFT", 46, -12)
  notice.title:SetTextColor(Theme:GetColor("warning"))

  notice.body = notice:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  notice.body:SetPoint("TOPLEFT", notice.title, "BOTTOMLEFT", 0, -3)
  notice.body:SetPoint("RIGHT", notice, "RIGHT", -12, 0)
  notice.body:SetTextColor(Theme:GetColor("textNormal"))
  notice.body:SetJustifyH("LEFT")
  notice.body:SetWordWrap(true)

  local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
  track:SetWidth(SCROLLBAR_WIDTH)
  track:SetPoint("TOPLEFT", viewport, "TOPRIGHT", SCROLLBAR_GUTTER, 0)
  track:SetPoint("BOTTOMLEFT", viewport, "BOTTOMRIGHT", SCROLLBAR_GUTTER, 0)
  track:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
  track:SetBackdropColor(Theme:GetColor("bgHeader"))

  local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
  thumb:SetWidth(SCROLLBAR_WIDTH)
  thumb:SetPoint("TOP")
  thumb:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
  thumb:SetBackdropColor(Theme:GetColor("accent"))
  thumb:EnableMouse(true)

  local UpdateScrollbar -- assigned below and used by scroll/thumb scripts

  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = Clamp((self:GetVerticalScroll() or 0) - delta * 40, 0, maxScroll)
    self:SetVerticalScroll(newScroll)
    UpdateScrollbar()
  end)

  thumb:SetScript("OnMouseDown", function(self)
    self.dragging = true
    self.startY = select(2, GetCursorPosition())
    self.startScroll = scroll:GetVerticalScroll() or 0
  end)
  thumb:SetScript("OnMouseUp", function(self) self.dragging = false end)
  thumb:SetScript("OnUpdate", function(self)
    if not self.dragging then return end
    local maxScroll = scroll:GetVerticalScrollRange()
    local travel = track:GetHeight() - self:GetHeight()
    if travel <= 0 or maxScroll <= 0 then return end
    local _, y = GetCursorPosition()
    local scale = track:GetEffectiveScale()
    local movedDownPixels = (self.startY - y) / scale
    local deltaScroll = (movedDownPixels / travel) * maxScroll
    scroll:SetVerticalScroll(Clamp(self.startScroll + deltaScroll, 0, maxScroll))
    UpdateScrollbar()
  end)

  UpdateScrollbar = function()
    local maxScroll = scroll:GetVerticalScrollRange() or 0
    if maxScroll <= 0 then
      track:Hide()
      return
    end
    track:Show()
    local trackHeight = track:GetHeight()
    local viewportHeight = scroll:GetHeight()
    local contentHeight = viewportHeight + maxScroll
    local thumbHeight = math.max(20, trackHeight * (viewportHeight / contentHeight))
    thumb:SetHeight(thumbHeight)
    local travel = trackHeight - thumbHeight
    local scrollFrac = (scroll:GetVerticalScroll() or 0) / maxScroll
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -travel * scrollFrac)
  end
  f.UpdateScrollbar = UpdateScrollbar -- exposed for content refreshes

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)
  content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
  content:SetScript("OnSizeChanged", UpdateScrollbar)
  f.content = content
  f.notice = notice
  f.noticeTitle = notice.title
  f.noticeBody = notice.body
  -- Exposed via GetFrame().
  f.scroll = scroll
  f.viewport = viewport
  f.track = track
  f.thumb = thumb

  scroll:SetScript("OnSizeChanged", function(self, width)
    content:SetWidth(math.max(width or self:GetWidth(), 1))
    UpdateScrollbar()
  end)
  C_Timer.After(0, function()
    if scroll and content then
      content:SetWidth(math.max(scroll:GetWidth(), 1))
      UpdateScrollbar()
    end
  end)

  mainFrame = f
  BuildSidebarButtons(sidebar)
  BuildSettingsButton(sidebar)
  RefreshSidebarHighlight()
  return f
end

--- Returns the built main frame table, or nil if it has not been shown yet.
function MH.UI.MainFrame:GetFrame()
  return mainFrame
end

--- Returns the currently-selected expansion ID, or nil if none is selected.
function MH.UI.MainFrame:GetSelectedExpansionID()
  return selectedExpansionID
end

--- Re-renders the currently-selected content pane in place.
function MH.UI.MainFrame:RefreshContent()
  if mainFrame and mainFrame:IsShown() then
    UpdateExpansionNotice()
    if showingSettings then
      RenderSettingsContent()
    else
      RenderExpansionContent()
    end
  end
end

--- Shows the main window, selecting the first known expansion by default
--- if nothing's selected yet.
function MH.UI.MainFrame:Show()
  local f = BuildFrame()
  f:Show()
  if not selectedExpansionID then
    local first = MH.ExpansionManifest:GetAll()[1]
    if first then SelectExpansion(first.id) end
  else
    UpdateHeaderSummary()
    UpdateExpansionNotice()
    if showingSettings then
      RenderSettingsContent()
    else
      RenderExpansionContent()
    end
  end
end

function MH.UI.MainFrame:Toggle()
  local f = BuildFrame()
  if f:IsShown() then
    f:Hide()
  else
    self:Show()
  end
end

MH.Addon:RegisterChatCommand("metahunter", function() MH.UI.MainFrame:Toggle() end)
MH.Addon:RegisterChatCommand("mh", function() MH.UI.MainFrame:Toggle() end)
