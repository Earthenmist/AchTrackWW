local ADDON_NAME, MH = ...
-- Extends the shared Engine table created by Completion.lua.
local Engine = MH.Engine

--[[
  Blizzard achievement-UI navigation and objective-tracker integration.

  Tracking targets C_ContentTracking (the modern API) first, falling back to
  the legacy AddTrackedAchievement/RemoveTrackedAchievement/
  GetTrackedAchievements globals for clients where ContentTracking isn't
  present -- same two-tier pattern Completion.lua uses for
  GetAchievementInfo/C_AchievementInfo.
]]

-- Nudges the objective tracker / achievement frame to redraw after a track
-- state change. Best-effort: each hook is only called if it actually
-- exists on this client.
local function RefreshTrackerUI()
  if AchievementFrameAchievements_ForceUpdate then
    AchievementFrameAchievements_ForceUpdate()
  end
  if WatchFrame_Update then
    WatchFrame_Update()
  end
  if ObjectiveTracker_Update then
    ObjectiveTracker_Update()
  end
end

--- Opens the Blizzard achievement UI focused on `achievementID`. Loads
--- Blizzard_AchievementUI on demand if it isn't already loaded. No-op
--- (with a chat warning) if the achievement UI isn't available right now
--- (e.g. in combat lockdown on some clients).
function Engine:OpenToAchievement(achievementID)
  if not achievementID then return end

  if CanShowAchievementUI and not CanShowAchievementUI() then
    print("|cffffd200MetaHunter:|r Achievement UI is not available right now.")
    return
  end

  if not AchievementFrame then
    MH.Compat.LoadAddOn("Blizzard_AchievementUI")
  end
  if not AchievementFrame then return end

  ShowUIPanel(AchievementFrame)

  if AchievementFrame_SelectAchievement then
    AchievementFrame_SelectAchievement(achievementID)
  elseif AchievementFrame_DisplayAchievement then
    AchievementFrame_DisplayAchievement(achievementID)
  end
end

--- Whether `achievementID` is currently tracked (objective tracker /
--- ContentTracking), checking the modern API first and falling back to the
--- legacy one.
function Engine:IsTracked(achievementID)
  if not achievementID then return false end

  if C_ContentTracking and C_ContentTracking.IsTracking and Enum and Enum.ContentTrackingType then
    local ok, tracked = pcall(C_ContentTracking.IsTracking, Enum.ContentTrackingType.Achievement, achievementID)
    if ok then return tracked and true or false end
  end

  if GetTrackedAchievements then
    for _, trackedID in ipairs(GetTrackedAchievements()) do
      if trackedID == achievementID then return true end
    end
  end

  return false
end

--- Toggles tracking for `achievementID`. Returns the new tracked state
--- (true/false), or nil plus an error string if `achievementID` is nil or
--- neither tracking API is available on this client.
function Engine:ToggleTracked(achievementID)
  if not achievementID then return nil, "NoID" end

  if C_ContentTracking and Enum and Enum.ContentTrackingType and C_ContentTracking.ToggleTracking then
    local stopType = Enum.ContentTrackingStopType and Enum.ContentTrackingStopType.Manual or 2
    local err = C_ContentTracking.ToggleTracking(Enum.ContentTrackingType.Achievement, achievementID, stopType)
    RefreshTrackerUI()
    if err ~= nil then return nil, err end
    return self:IsTracked(achievementID)
  end

  if AddTrackedAchievement and RemoveTrackedAchievement and GetTrackedAchievements then
    if self:IsTracked(achievementID) then
      RemoveTrackedAchievement(achievementID)
      RefreshTrackerUI()
      return false
    else
      AddTrackedAchievement(achievementID)
      RefreshTrackerUI()
      return true
    end
  end

  return nil, "NoTrackingAPI"
end
