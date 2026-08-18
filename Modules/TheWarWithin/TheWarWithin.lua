-- LoadOnDemand expansion data module. The shared Meta Hunter namespace is
-- published by the main addon and used here to reach the registry.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  -- Dependencies should load the main addon first; fail clearly if the install
  -- or global namespace is broken.
  error("MetaHunter_TheWarWithin: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

--[[
  The War Within + Undermine (Season 2) + K'aresh (Season 3).

  AchievementID 61451 is the true top-level meta; the major zone, raid,
  delve, and season metas below it are modeled as criteria of that root.

  Not modeled to full depth: several branches (e.g. the Khaz
  Algar zone glyph-hunter achievements, the individual delve-story/discovery
  achievements under the delve loremaster achievements) go several levels
  deeper in the real game data than what's authored here. This module tracks
  the achievement-backed rows most useful for meta progress.

  Known gap: "Moonlighter" isn't
  part of this meta's official criteria tree, so it is kept as its own
  standalone root.

  Moonlighter -> Bounty Seeker -> Vigilante is a three-part sequential unlock
  chain. Bounty Seeker is the achievement required by "Unraveled and
  Persevering"; the prerequisite gate itself is not represented until the
  schema supports prerequisite-style relationships.
]]

local ROOTS = {

  -- The true top-level meta for The War Within.
  {
    achievementID = 61451,
    title = "Worldsoul-Searching",
    category = "main",
    criteria = {

      -- Raids (any difficulty tier counts)
      { achievementID = 40244, title = "Nerub-ar Palace", category = "raid", variantIDs = { 40245, 40246 } },
      { achievementID = 41222, title = "Liberation of Undermine", category = "raid", variantIDs = { 41223, 41224 } },
      { achievementID = 41598, title = "Manaforge Omega", category = "raid", variantIDs = { 41599, 41600 } },

      -- Khaz Algar zone meta
      {
        achievementID = 41555,
        title = "All That Khaz",
        category = "zone",
        criteria = {
          { achievementID = 40430, title = "Khaz Algar Flight Master" },
          { achievementID = 40702, title = "Khaz Algar Glyph Hunter" },
          { achievementID = 20596, title = "Loremaster of Khaz Algar" },
          { achievementID = 40762, title = "Khaz Algar Lore Hunter" },
          { achievementID = 41169, title = "Khaz Algar Diplomat" },
          { achievementID = 40307, title = "Allied Races: Earthen", variantIDs = { 40309 } },
        },
      },

      -- Cross-zone side-content meta spanning the four launch zones plus
      -- Siren Isle.
      {
        achievementID = 41201,
        title = "You Xal Not Pass",
        category = "zone",
        criteria = {
          { achievementID = 41186, title = "Slate of the Union" },
          { achievementID = 41187, title = "Rage Aside the Machine" },
          { achievementID = 41188, title = "Crystal Chronicled" },
          { achievementID = 41189, title = "Azj the World Turns" },
          { achievementID = 41133, title = "Isle Remember You" },
        },
      },

      -- Expansion Pathfinder meta
      {
        achievementID = 40231,
        title = "The War Within Pathfinder",
        category = "pathfinder",
        criteria = {
          { achievementID = 20118, title = "The Isle of Dorn" },
          { achievementID = 19560, title = "The Ringing Deeps" },
          { achievementID = 20598, title = "Hallowfall" },
          { achievementID = 19559, title = "Azj-Kahet" },
          { achievementID = 40790, title = "Khaz Algar Explorer" },
        },
      },

      -- Delves meta
      {
        achievementID = 40438,
        title = "Glory of the War Within Delver",
        category = "delves",
        criteria = {
          { achievementID = 40445, title = "Sporesweeper" },
          { achievementID = 40453, title = "Spider Senses" },
          { achievementID = 40454, title = "Daystormer" },
          { achievementID = 40537, title = "Delve Loremaster: War Within" },
          { achievementID = 40506, title = "The War Within: Leave No Treasure Unfound" },
          {
            title = "Brann Development",
            oneOfAchievementIDs = { 40538, 40635 },
            guide = "Complete either Brann Development or Branntastic; either one satisfies this Delver criterion.",
          },
          {
            title = "Defeat the current Seasonal Nemesis",
            oneOfAchievementIDs = { 40103, 41530, 42193 },
            guide = "Complete any one The War Within seasonal nemesis achievement.",
          },
        },
      },

      -- Season 2 (Undermine) zone meta
      {
        achievementID = 41586,
        title = "Going Goblin Mode",
        category = "season",
        criteria = {
          { achievementID = 41216, title = "Adventurer of Undermine" },
          { achievementID = 41217, title = "Treasures of Undermine" },
          { achievementID = 40948, title = "Nine-Tenths of the Law" },
          { achievementID = 41588, title = "Read Between the Lines" },
          { achievementID = 41589, title = "That Can-Do Attitude" },
          { achievementID = 41708, title = "You're My Friend Now" },
        },
      },

      -- Direct criterion of the top meta, not of "Going Goblin Mode".
      { achievementID = 41997, title = "Owner of a Radiant Heart", category = "season" },

      -- Season 3 (K'aresh) meta
      {
        achievementID = 60889,
        title = "Unraveled and Persevering",
        category = "season",
        criteria = {
          { achievementID = 42761, title = "Remnants of a Shattered World" },
          { achievementID = 42741, title = "Treasures of K'aresh" },
          { achievementID = 42740, title = "Explore K'aresh" },
          -- Vigilante is the next tier in the same warrant chain; completing
          -- it also satisfies the lower Bounty Seeker requirement.
          { achievementID = 41979, title = "Bounty Seeker", variantIDs = { 41980 } },
          { achievementID = 42729, title = "Dangerous Prowlers of K'aresh" },
          { achievementID = 42742, title = "Power of the Reshii" },
          { achievementID = 60890, title = "Secrets of the K'areshi" },
        },
      },
    },
  },

  -- Standalone Glory metas. These are useful The War Within tracking roots,
  -- but they are not criteria of the expansion-wide Worldsoul-Searching meta.
  {
    achievementID = 61566,
    title = "Glory of the War Within Hero",
    category = "dungeon",
    guide = "Complete the War Within Mythic dungeon achievements listed below.",
    criteria = {
      { achievementID = 40375, title = "Mythic: Ara-Kara, City of Echoes" },
      { achievementID = 40379, title = "Mythic: City of Threads" },
      { achievementID = 40596, title = "Mythic: Priory of the Sacred Flame" },
      { achievementID = 40642, title = "Mythic: The Rookery" },
      { achievementID = 41341, title = "Mythic: Operation: Floodgate" },
      { achievementID = 40366, title = "Mythic: Cinderbrew Meadery" },
      { achievementID = 40429, title = "Mythic: Darkflame Cleft" },
      { achievementID = 40604, title = "Mythic: The Dawnbreaker" },
      { achievementID = 40648, title = "Mythic: The Stonevault" },
      { achievementID = 42782, title = "Mythic: Eco-Dome Al'dani" },
    },
  },

  {
    achievementID = 40232,
    title = "Glory of the Nerub-ar Raider",
    category = "raid",
    guide = "Complete the Nerub-ar Palace raid achievements listed below.",
    criteria = {
      { achievementID = 40261, title = "Slimy Yet Satisfying" },
      { achievementID = 40255, title = "Sik Parry Bro" },
      { achievementID = 40263, title = "Would You Still /love Me if I Was a Worm..." },
      { achievementID = 40730, title = "Love is in the Lair" },
      { achievementID = 40260, title = "You Can't See Me" },
      { achievementID = 40262, title = "Cowabunga" },
      { achievementID = 40264, title = "Kill Streak" },
      { achievementID = 40266, title = "Missed 'Em by That Much" },
    },
  },

  {
    achievementID = 41286,
    title = "Glory of the Liberation of Undermine Raider",
    category = "raid",
    guide = "Complete the Liberation of Undermine raid achievements listed below.",
    criteria = {
      { achievementID = 41208, title = "Hold My Gear!" },
      { achievementID = 41554, title = "The Splash Zone" },
      { achievementID = 41711, title = "Conveyor Slayer" },
      { achievementID = 41337, title = "Sleep with the Fishes" },
      { achievementID = 41119, title = "One Rank Higher" },
      { achievementID = 41338, title = "Just /Dance" },
      { achievementID = 41596, title = "Garbage In, Garbage Out" },
      { achievementID = 41347, title = "Scheming on a Thing" },
    },
  },

  {
    achievementID = 41597,
    title = "Glory of the Omega Raider",
    category = "raid",
    guide = "Complete the Manaforge Omega raid achievements listed below.",
    criteria = {
      { achievementID = 42118, title = "Of Mice and Manaforges" },
      { achievementID = 41614, title = "Mother of All Tantrums" },
      { achievementID = 41616, title = "I See... Absolutely Nothing" },
      { achievementID = 41618, title = "King's Ransom" },
      { achievementID = 41613, title = "Time to Vote! Cute or Scary?" },
      { achievementID = 41615, title = "Cheat Meal" },
      { achievementID = 41617, title = "Breaking the Fourth Wall" },
      { achievementID = 41619, title = "Defying Gravity" },
    },
  },

  -- K'aresh warrant chain opener. Not part of the Worldsoul-Searching criteria
  -- tree, so the prerequisite relationship is explained in the guide text.
  {
    title = "Moonlighter",
    category = "misc",
    achievementID = 41978,
    guide = "Part 1 of 3 in a sequential K'aresh warrant chain: "
      .. "Moonlighter -> Bounty Seeker -> Vigilante. Bounty Seeker "
      .. "(shown under \"Unraveled and Persevering\", not here) is the "
      .. "one actually required for that meta -- complete this first to "
      .. "unlock it.",
  },
}

Registry:RegisterExpansion("the-war-within", ROOTS)
