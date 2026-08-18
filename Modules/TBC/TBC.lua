-- MetaHunter_TBC -- a LoadOnDemand sub-addon.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_TBC: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

local ROOTS = {
  {
    achievementID = 1284,
    title = "Outland Dungeonmaster",
    category = "dungeon",
    guide = "Complete the Outland dungeon achievements listed by Blizzard.",
    criteria = {
      { achievementID = 647, title = "Hellfire Ramparts" },
      { achievementID = 648, title = "The Blood Furnace" },
      { achievementID = 649, title = "The Slave Pens" },
      { achievementID = 650, title = "Underbog" },
      { achievementID = 651, title = "Mana-Tombs" },
      { achievementID = 666, title = "Auchenai Crypts" },
      { achievementID = 653, title = "Sethekk Halls" },
      { achievementID = 654, title = "Shadow Labyrinth" },
      { achievementID = 652, title = "The Escape From Durnholde" },
      { achievementID = 655, title = "Opening of the Dark Portal" },
      { achievementID = 656, title = "The Steamvault" },
      { achievementID = 657, title = "The Shattered Halls" },
      { achievementID = 658, title = "The Mechanar" },
      { achievementID = 659, title = "The Botanica" },
      { achievementID = 660, title = "The Arcatraz" },
      { achievementID = 661, title = "Magister's Terrace" },
    },
  },
  {
    achievementID = 1287,
    title = "Outland Dungeon Hero",
    category = "dungeon",
    guide = "Complete the Outland heroic dungeon achievements listed by Blizzard.",
    criteria = {
      { achievementID = 667, title = "Heroic: Hellfire Ramparts" },
      { achievementID = 668, title = "Heroic: The Blood Furnace" },
      { achievementID = 669, title = "Heroic: The Slave Pens" },
      { achievementID = 670, title = "Heroic: Underbog" },
      { achievementID = 671, title = "Heroic: Mana-Tombs" },
      { achievementID = 672, title = "Heroic: Auchenai Crypts" },
      { achievementID = 674, title = "Heroic: Sethekk Halls" },
      { achievementID = 675, title = "Heroic: Shadow Labyrinth" },
      { achievementID = 673, title = "Heroic: The Escape From Durnholde" },
      { achievementID = 676, title = "Heroic: Opening of the Dark Portal" },
      { achievementID = 677, title = "Heroic: The Steamvault" },
      { achievementID = 678, title = "Heroic: The Shattered Halls" },
      { achievementID = 679, title = "Heroic: The Mechanar" },
      { achievementID = 680, title = "Heroic: The Botanica" },
      { achievementID = 681, title = "Heroic: The Arcatraz" },
      { achievementID = 682, title = "Heroic: Magister's Terrace" },
    },
  },
  {
    achievementID = 1286,
    title = "Outland Raider",
    category = "raid",
    guide = "Complete the Burning Crusade raid achievements listed by Blizzard.",
    criteria = {
      { achievementID = 690, title = "Karazhan" },
      { achievementID = 692, title = "Gruul's Lair" },
      { achievementID = 693, title = "Magtheridon's Lair" },
      { achievementID = 694, title = "Serpentshrine Cavern" },
      { achievementID = 695, title = "The Battle for Mount Hyjal" },
      { achievementID = 696, title = "Tempest Keep" },
      { achievementID = 697, title = "The Black Temple" },
      { achievementID = 698, title = "Sunwell Plateau" },
    },
  },
}

Registry:RegisterExpansion("the-burning-crusade", ROOTS)
