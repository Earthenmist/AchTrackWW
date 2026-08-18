local ADDON_NAME, MH = ...

--[[
  Shared color/font table -- every UI-layer file reads colors from here
  rather than hardcoding them per-file.
]]

local Theme = {}
MH.Theme = Theme

Theme.colors = {
  bg = { 0.06, 0.06, 0.08, 0.98 },
  bgRow = { 0.10, 0.10, 0.12, 1 },
  bgRowAlt = { 0.08, 0.08, 0.10, 1 }, -- alternating row shading (leaf rows only)
  bgCompositeComplete = { 0.09, 0.13, 0.13, 1 }, -- complete parent rows keep
                                                 -- the current green/teal tint
  bgCompositeIncomplete = { 0.16, 0.08, 0.08, 1 }, -- incomplete parent rows
                                                  -- get a restrained red tint
  bgHover = { 0.14, 0.14, 0.17, 1 }, -- row/button mouseover
  bgHeader = { 0.05, 0.05, 0.07, 1 }, -- the window's own title bar -- dark, not
                                       -- a flat accent-colored slab
  bgViewport = { 0.045, 0.045, 0.060, 0.96 }, -- fixed right-pane surface behind
                                               -- scrolled content
  bgPanel = { 0.08, 0.08, 0.10, 1 }, -- category panel background
  bgPanelRows = { 0.065, 0.070, 0.080, 0.98 }, -- row well inside a section;
                                                -- stays visually solid while
                                                -- section headers scroll away
  bgPanelHeader = { 0.075, 0.080, 0.095, 1 },
  bgNotice = { 0.055, 0.055, 0.070, 0.98 },
  border = { 0.25, 0.25, 0.30, 1 },
  warning = { 1.00, 0.82, 0.12, 1 },
  warningBorder = { 0.48, 0.34, 0.10, 1 },
  -- Teal/cyan accent used throughout the main window.
  accent = { 0.22, 0.78, 0.68, 1 },
  textBright = { 1, 1, 1, 1 }, -- composite/parent node labels
  textNormal = { 0.85, 0.85, 0.85, 1 }, -- leaf node labels
  textDim = { 0.55, 0.55, 0.55, 1 }, -- progress fractions, secondary text
  complete = { 0.30, 0.90, 0.30, 1 },
  incomplete = { 0.55, 0.55, 0.55, 1 },
  connector = { 0.35, 0.35, 0.40, 1 }, -- tree connector lines
}

Theme.fonts = {
  rowComposite = "GameFontNormal", -- parent/composite node labels
  rowLeaf = "GameFontHighlight", -- leaf node labels
  progress = "GameFontDisableSmall",
}

--- Returns r, g, b, a for a named color, falling back to textNormal if the
--- name isn't recognized (fails visibly-but-safely rather than erroring on
--- a typo'd color name deep in UI code).
function Theme:GetColor(name)
  local c = self.colors[name] or self.colors.textNormal
  return c[1], c[2], c[3], c[4] or 1
end
