local ADDON_NAME, MH = ...

--[[
  Shared compatibility wrappers for Blizzard APIs that have moved between
  global functions and C_* namespaces across client versions.
]]

local Compat = {}
MH.Compat = Compat

--- Loads an addon by folder name, trying the current API first and older
--- fallbacks after that.
function Compat.LoadAddOn(name)
  if C_AddOns and C_AddOns.LoadAddOn then
    return C_AddOns.LoadAddOn(name)
  end
  if LoadAddOn then
    return LoadAddOn(name)
  end
  if UIParentLoadAddOn then
    return UIParentLoadAddOn(name)
  end
end

--- Whether an addon (by folder name) is currently loaded. Prefers
--- `C_AddOns.IsAddOnLoaded`, falls back to the older `IsAddOnLoaded`
--- global.
function Compat.IsAddOnLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name)
  end
  if IsAddOnLoaded then
    return IsAddOnLoaded(name)
  end
  return false
end
