-- MetaHunter_Classic -- a LoadOnDemand sub-addon.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_Classic: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

local ROOTS = {
  {
    achievementID = 1283,
    title = "Classic Dungeonmaster",
    category = "dungeon",
    guide = "Complete the classic dungeon achievements listed by Blizzard.",
    criteria = {
      { achievementID = 628, title = "Deadmines" },
      { achievementID = 629, title = "Ragefire Chasm" },
      { achievementID = 630, title = "Wailing Caverns" },
      { achievementID = 631, title = "Shadowfang Keep" },
      { achievementID = 632, title = "Blackfathom Deeps" },
      { achievementID = 633, title = "Stormwind Stockade" },
      { achievementID = 634, title = "Gnomeregan" },
      { achievementID = 635, title = "Razorfen Kraul" },
      { achievementID = 636, title = "Razorfen Downs" },
      { achievementID = 637, title = "Scarlet Monastery" },
      { achievementID = 638, title = "Uldaman" },
      { achievementID = 639, title = "Zul'Farrak" },
      { achievementID = 640, title = "Maraudon" },
      { achievementID = 641, title = "Sunken Temple" },
      { achievementID = 642, title = "Blackrock Depths" },
      { achievementID = 643, title = "Lower Blackrock Spire" },
      { achievementID = 644, title = "King of Dire Maul" },
      { achievementID = 645, title = "Scholomance" },
      { achievementID = 646, title = "Stratholme" },
    },
  },
  {
    achievementID = 1285,
    title = "Classic Raider",
    category = "raid",
    guide = "Complete the classic raid achievements listed by Blizzard.",
    criteria = {
      { achievementID = 686, title = "Molten Core" },
      { achievementID = 685, title = "Blackwing Lair" },
      { achievementID = 689, title = "Ruins of Ahn'Qiraj" },
      { achievementID = 687, title = "Temple of Ahn'Qiraj" },
    },
  },
}

Registry:RegisterExpansion("classic", ROOTS)
