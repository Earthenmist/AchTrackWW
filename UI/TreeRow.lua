local ADDON_NAME, MH = ...
local Theme = MH.Theme

--[[
  Pooled tree-row widget for the collapsible outline-tree detail view:
  one row = one achievement node at one depth, with a drawn connector line to its parent, an
  expand/collapse toggle for composite nodes, a status glyph, name text,
  and a progress fraction for composite nodes.

  Rows are pooled: collapsed subtrees acquire no row frames, and released rows
  are reused on later renders.

  Connector lines: classic outline-tree guide-line rendering. For a row at
  `depth`, each ancestor column (1..depth-1) draws a full-height vertical
  guide IF that ancestor still has more siblings below it (the tree line
  needs to keep going down past this row to reach them); if that ancestor
  was itself a last child, no line draws in that column for this row. The
  row's OWN column (at `depth`) always draws a top-half vertical (the line
  arriving at this node) plus a horizontal branch into the toggle/label
  area, and ALSO a bottom-half vertical if this row isn't the last sibling
  in its own group (continuing the line down to the next sibling).
]]

local UI = MH.UI or {}
MH.UI = UI
local TreeRow = {}
UI.TreeRow = TreeRow

-- Layout constants keep row sizing consistent across the main tree.
local ROW_HEIGHT = 27
TreeRow.ROW_HEIGHT = ROW_HEIGHT -- exported for callers positioning rows
local INDENT_PER_DEPTH = 16
-- Pre-created ancestor-guide-line columns per row. Past this depth, older
-- ancestor columns simply stop drawing while indentation still works.
local MAX_GUIDE_DEPTH = 16
local TOGGLE_SIZE = 16
local TOGGLE_GAP = 18 -- horizontal space the toggle reserves before the next element
local ICON_SIZE = 22
local ICON_BORDER_SIZE = 26
local ICON_GAP = 30
local STATUS_ICON_SIZE = 14
local STATUS_GAP = 18
local ROW_RIGHT_PADDING = 8 -- progress text right-aligns this far from the row's edge

local pool = {}

local function CreateGuide(row)
  local guide = row:CreateTexture(nil, "ARTWORK")
  guide:SetColorTexture(Theme:GetColor("connector"))
  guide:SetWidth(1)
  guide:Hide()
  return guide
end

local function CreateRowFrame(parent)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(ROW_HEIGHT)
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()

  -- Hover restores the base color set by Populate() and shows optional guide
  -- text for the current pooled row.
  row:SetScript("OnEnter", function(self)
    self.bg:SetColorTexture(Theme:GetColor("bgHover"))
    if self.guideText and self.guideText ~= "" then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.rowTitle or "", 1, 1, 1)
      GameTooltip:AddLine(self.guideText, nil, nil, nil, true)
      GameTooltip:Show()
    end
  end)
  row:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(Theme:GetColor(self.baseColorName or "bgRow"))
    GameTooltip:Hide()
  end)

  row.guides = {}
  for i = 1, MAX_GUIDE_DEPTH do
    row.guides[i] = CreateGuide(row)
  end

  row.branchTop = row:CreateTexture(nil, "ARTWORK")
  row.branchTop:SetColorTexture(Theme:GetColor("connector"))
  row.branchTop:SetWidth(1)

  row.branchBottom = row:CreateTexture(nil, "ARTWORK")
  row.branchBottom:SetColorTexture(Theme:GetColor("connector"))
  row.branchBottom:SetWidth(1)

  row.branchHorizontal = row:CreateTexture(nil, "ARTWORK")
  row.branchHorizontal:SetColorTexture(Theme:GetColor("connector"))
  row.branchHorizontal:SetHeight(1)

  row.toggle = CreateFrame("Button", nil, row)
  row.toggle:SetSize(TOGGLE_SIZE, TOGGLE_SIZE)
  row.toggle.text = row.toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.toggle.text:SetAllPoints()

  -- Use checkbox textures so completion state does not collide visually with
  -- the +/- expand toggle.
  row.statusIcon = row:CreateTexture(nil, "OVERLAY")
  row.statusIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)

  -- Per-achievement icon with a thin tile border.
  row.iconBorder = row:CreateTexture(nil, "BORDER")
  row.iconBorder:SetColorTexture(Theme:GetColor("border"))
  row.iconBorder:SetSize(ICON_BORDER_SIZE, ICON_BORDER_SIZE)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(ICON_SIZE, ICON_SIZE)
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trims the default icon's own border art

  row.label = row:CreateFontString(nil, "OVERLAY", Theme.fonts.rowLeaf)
  row.progress = row:CreateFontString(nil, "OVERLAY", Theme.fonts.progress)

  return row
end

--- Acquires a row frame parented to `parent`, ready to be positioned
--- (SetPoint) and populated via TreeRow:Populate(). Reuses a released row
--- if one's available rather than always creating a new frame.
function TreeRow:Acquire(parent)
  local row = table.remove(pool)
  if not row then
    row = CreateRowFrame(parent)
  else
    row:SetParent(parent)
  end
  row:Show()
  return row
end

--- Returns a row to the pool: hides it, clears its anchors and click
--- handlers, so the next Acquire() gets a frame with no stale state.
function TreeRow:Release(row)
  row:Hide()
  row:ClearAllPoints()
  row:SetScript("OnClick", nil)
  row.toggle:SetScript("OnClick", nil)
  table.insert(pool, row)
end

-- Positions the connector-line pieces for one row. `depth` is 0 for a root
-- (no connector at all -- nothing above a root to connect to).
-- `ancestorContinues` is an array (length depth-1) of booleans: whether the
-- ancestor at that column still has more siblings below (needs its guide
-- line to keep going past this row). `isLastSibling` controls whether this
-- row's own column continues a bottom-half line to the next sibling.
local function LayoutConnectors(row, depth, ancestorContinues, isLastSibling)
  for i = 1, MAX_GUIDE_DEPTH do
    row.guides[i]:Hide()
  end

  if depth == 0 then
    row.branchTop:Hide()
    row.branchBottom:Hide()
    row.branchHorizontal:Hide()
    return 0
  end

  for i = 1, math.min(depth - 1, MAX_GUIDE_DEPTH) do
    if ancestorContinues[i] then
      local x = (i - 1) * INDENT_PER_DEPTH + INDENT_PER_DEPTH / 2
      local guide = row.guides[i]
      guide:ClearAllPoints()
      guide:SetPoint("TOP", row, "TOPLEFT", x, 0)
      guide:SetPoint("BOTTOM", row, "BOTTOMLEFT", x, 0)
      guide:Show()
    end
  end

  local ownX = (depth - 1) * INDENT_PER_DEPTH + INDENT_PER_DEPTH / 2
  local midY = -ROW_HEIGHT / 2

  row.branchTop:ClearAllPoints()
  row.branchTop:SetPoint("TOP", row, "TOPLEFT", ownX, 0)
  row.branchTop:SetPoint("BOTTOM", row, "TOPLEFT", ownX, midY)
  row.branchTop:Show()

  row.branchHorizontal:ClearAllPoints()
  row.branchHorizontal:SetPoint("LEFT", row, "TOPLEFT", ownX, midY)
  row.branchHorizontal:SetWidth(INDENT_PER_DEPTH / 2)
  row.branchHorizontal:Show()

  if not isLastSibling then
    row.branchBottom:ClearAllPoints()
    row.branchBottom:SetPoint("TOP", row, "TOPLEFT", ownX, midY)
    row.branchBottom:SetPoint("BOTTOM", row, "BOTTOMLEFT", ownX, 0)
    row.branchBottom:Show()
  else
    row.branchBottom:Hide()
  end

  return depth * INDENT_PER_DEPTH
end

--- Populates an acquired row's visuals and click behavior for one tree
--- node. `data` fields:
---   depth              -- 0 for a root
---   isLastSibling       -- this row's own position among its siblings
---   ancestorContinues    -- array, length depth-1, per LayoutConnectors above
---   text                 -- achievement name
---   icon                 -- texture (fileID or path), the achievement's own
---                           Blizzard icon; nil shows no icon tile
---   earned               -- true/false/nil (nil = unknown to this client)
---   hasChildren          -- whether to show the expand/collapse toggle
---   expanded             -- current expand state, if hasChildren
---   progressText          -- e.g. "6/6", nil for a leaf
---   rowIndex              -- 1-based position among currently-displayed
---                           rows, for alternating row-background shading
---                           (purely cosmetic; the caller's own bookkeeping,
---                           not related to tree structure)
---   guide                 -- optional guide text (the achievement's
---                           canonical `guide` field); shown as a tooltip
---                           on hover if present, nothing extra if not
--- `onToggle(row)`/`onClick(row)`/`onRightClick(row)` are optional
--- callbacks; onToggle fires only from the +/- button, onClick/onRightClick
--- fire from clicking the row itself (icon/name/status area).
function TreeRow:Populate(row, data, onToggle, onClick, onRightClick)
  local indent = LayoutConnectors(row, data.depth, data.ancestorContinues or {}, data.isLastSibling)

  row.rowTitle = data.text
  row.guideText = data.guide

  -- Composite (parent) rows get a status tint rather than just structural
  -- tint: complete parents keep the current green/teal read, incomplete
  -- parents use a muted red so partial branches stand out immediately.
  -- Stored on the row (baseColorName) so OnLeave knows what to restore to
  -- after a hover.
  local altColor = data.rowIndex and (data.rowIndex % 2 == 0)
  if data.hasChildren then
    if data.earned == true then
      row.baseColorName = "bgCompositeComplete"
    elseif data.earned == false then
      row.baseColorName = "bgCompositeIncomplete"
    else
      row.baseColorName = altColor and "bgRowAlt" or "bgRow"
    end
  else
    row.baseColorName = altColor and "bgRowAlt" or "bgRow"
  end
  row.bg:SetColorTexture(Theme:GetColor(row.baseColorName))

  local left = indent
  if data.hasChildren then
    row.toggle:ClearAllPoints()
    row.toggle:SetPoint("LEFT", row, "LEFT", left, 0)
    row.toggle.text:SetText(data.expanded and "-" or "+")
    row.toggle:Show()
    row.toggle:SetScript("OnClick", function()
      if onToggle then onToggle(row) end
    end)
  else
    row.toggle:Hide()
    row.toggle:SetScript("OnClick", nil)
  end
  -- Always reserve the toggle column so leaf and composite rows align at the
  -- same tree depth.
  left = left + TOGGLE_GAP

  if data.icon then
    row.iconBorder:ClearAllPoints()
    row.iconBorder:SetPoint("LEFT", row, "LEFT", left, 0)
    row.iconBorder:Show()
    row.icon:ClearAllPoints()
    row.icon:SetPoint("CENTER", row.iconBorder, "CENTER", 0, 0)
    row.icon:SetTexture(data.icon)
    row.icon:Show()
  else
    row.iconBorder:Hide()
    row.icon:Hide()
  end
  left = left + ICON_GAP

  row.statusIcon:ClearAllPoints()
  row.statusIcon:SetPoint("LEFT", row, "LEFT", left, 0)
  if data.earned == true then
    row.statusIcon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.statusIcon:SetVertexColor(Theme:GetColor("complete"))
    row.statusIcon:Show()
  elseif data.earned == false then
    row.statusIcon:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
    row.statusIcon:SetVertexColor(Theme:GetColor("incomplete"))
    row.statusIcon:Show()
  else
    -- Unknown to this client; leave the status slot empty.
    row.statusIcon:Hide()
  end
  left = left + STATUS_GAP

  row.label:ClearAllPoints()
  row.label:SetPoint("LEFT", row, "LEFT", left, 0)
  row.label:SetFontObject(data.hasChildren and Theme.fonts.rowComposite or Theme.fonts.rowLeaf)
  row.label:SetText(data.text or "")
  if data.hasChildren then
    row.label:SetTextColor(Theme:GetColor("textBright"))
  else
    row.label:SetTextColor(Theme:GetColor("textNormal"))
  end

  if data.progressText then
    row.progress:Show()
    row.progress:ClearAllPoints()
    row.progress:SetJustifyH("RIGHT")
    row.progress:SetPoint("RIGHT", row, "RIGHT", -ROW_RIGHT_PADDING, 0)
    row.progress:SetTextColor(Theme:GetColor("textDim"))
    row.progress:SetText(data.progressText)
    row.label:SetPoint("RIGHT", row.progress, "LEFT", -8, 0)
  else
    row.progress:Hide()
    row.label:SetPoint("RIGHT", row, "RIGHT", -ROW_RIGHT_PADDING, 0)
  end

  row:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      if onRightClick then onRightClick(row) end
    else
      if onClick then onClick(row) end
    end
  end)
end
