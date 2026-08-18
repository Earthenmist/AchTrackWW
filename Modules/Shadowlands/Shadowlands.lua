-- MetaHunter_Shadowlands -- a LoadOnDemand sub-addon (see
-- MetaHunter_Shadowlands.toc), not part of the main MetaHunter addon's own
-- startup file set. This keeps Shadowlands data out of memory until the
-- player selects it in the expansion sidebar.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_Shadowlands: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

--[[
  Shadowlands expansion meta.

  Back from the Beyond (achievementID 20501) is the current Shadowlands
  expansion-wide meta achievement. The older legacy achievementID 15654 is
  kept as a variant so existing legacy completion can satisfy the same row.

  This module follows Meta Hunter's expansion format: confirmed expansion
  meta first, then standalone dungeon/raid Glory metas for tracking
  convenience. Ordinary non-Glory dungeon completion metas are deliberately
  not included as standalone roots. Where Back from the Beyond criteria expose
  real child achievement IDs, those child branches are included; plain
  criteria-only checklists remain at parent-row depth.
]]

local ROOTS = {
  {
    achievementID = 20501,
    title = "Back from the Beyond",
    variantIDs = { 15654 },
    category = "main",
    guide = "Complete the Shadowlands expansion-wide meta achievement.",
    criteria = {
      { achievementID = 14715, title = "Castle Nathria" },
      { achievementID = 15126, title = "Sanctum of Domination" },
      { achievementID = 15417, title = "Sepulcher of the First Ones" },
      {
        achievementID = 15651,
        title = "Myths of the Shadowlands Dungeons",
        criteria = {
          { achievementID = 14368, title = "Mythic: The Necrotic Wake" },
          { achievementID = 14415, title = "Mythic: Plaguefall" },
          { achievementID = 14413, title = "Mythic: Mists of Tirna Scithe" },
          { achievementID = 14411, title = "Mythic: Halls of Atonement" },
          { achievementID = 14325, title = "Mythic: Spires of Ascension" },
          { achievementID = 14417, title = "Mythic: Theater of Pain" },
          { achievementID = 14409, title = "Mythic: De Other Side" },
          { achievementID = 14199, title = "Mythic: Sanguine Depths" },
          { achievementID = 15177, title = "Tazavesh, the Veiled Market" },
        },
      },
      { achievementID = 15647, title = "Dead Men Tell Some Tales" },
      { achievementID = 14961, title = "Chains of Domination" },
      {
        achievementID = 15336,
        title = "From A to Zereth",
        criteria = {
          { achievementID = 15259, title = "Secrets of the First Ones" },
          { achievementID = 15331, title = "Treasures of Zereth Mortis" },
          { achievementID = 15392, title = "Dune Dominance" },
          { achievementID = 15391, title = "Adventurer of Zereth Mortis" },
          { achievementID = 15402, title = "Cyphers of the First Ones" },
          { achievementID = 15407, title = "Synthe-fived!" },
          { achievementID = 15220, title = "The Enlightened" },
        },
      },
      { achievementID = 15646, title = "Re-Re-Re-Renowned" },
      {
        achievementID = 15324,
        title = "Tower Ranger",
        criteria = {
          { achievementID = 15322, title = "Flawless Master (Layer 16)" },
          { achievementID = 15067, title = "Adamant Vaults" },
          { achievementID = 14570, title = "Twisting Corridors: Layer 8" },
          { achievementID = 15254, title = "The Jailer's Gauntlet: Layer 4" },
          { achievementID = 15092, title = "Master of Torment" },
        },
      },
      { achievementID = 15178, title = "Fake It 'Til You Make It" },
      { achievementID = 15079, title = "Many, Many Things" },
      {
        achievementID = 15035,
        title = "On the Offensive",
        criteria = {
          { achievementID = 15000, title = "United Front" },
          { achievementID = 15001, title = "Jailer's Personal Stash" },
          { achievementID = 15037, title = "This Army" },
          { achievementID = 15039, title = "Up For Grabs" },
          { achievementID = 15041, title = "The Zovaal Shuffle" },
          { achievementID = 15043, title = "Hoarder of Torghast" },
          { achievementID = 15004, title = "A Sly Fox" },
          { achievementID = 15042, title = "Tea for the Troubled" },
          { achievementID = 15044, title = "Krrprripripkraak's Heroes" },
        },
      },
      { achievementID = 15025, title = "Sanctum Superior" },
      { achievementID = 15259, title = "Secrets of the First Ones" },
      {
        achievementID = 15649,
        title = "Shadowlands Dilettante",
        criteria = {
          { achievementID = 14502, title = "Pursuing Loyalty" },
          { achievementID = 14723, title = "Be Our Guest" },
          { achievementID = 14752, title = "Things To Do When You're Dead" },
          { achievementID = 14775, title = "Mush Appreciated" },
        },
      },
      {
        achievementID = 15648,
        title = "Walking in Maw-mphis",
        criteria = {
          { achievementID = 14895, title = "'Ghast Five" },
          { achievementID = 14744, title = "Better to Be Lucky Than Dead" },
          { achievementID = 14660, title = "It's About Sending a Message" },
          { achievementID = 14738, title = "Hunting Party" },
          { achievementID = 14656, title = "Trading Partners" },
          { achievementID = 14658, title = "Soulkeeper's Burden" },
          { achievementID = 14663, title = "Explore The Maw" },
        },
      },
    },
  },

  {
    achievementID = 14322,
    title = "Glory of the Shadowlands Hero",
    category = "dungeon",
    guide = "Complete the Shadowlands Mythic dungeon achievements listed below.",
    criteria = {
      { achievementID = 14295, title = "Bountiful Harvest" },
      { achievementID = 14285, title = "Ready for Raiding VII" },
      { achievementID = 14291, title = "Someone Could Trip on These!" },
      { achievementID = 14347, title = "Full Gores Meal" },
      { achievementID = 14292, title = "Riding with my Slimes" },
      { achievementID = 14284, title = "Breaking Bad" },
      { achievementID = 14374, title = "Couple's Therapy" },
      { achievementID = 14606, title = "Thinking with..." },
      { achievementID = 14323, title = "ExSPEARiential" },
      { achievementID = 14297, title = "Three Choose One" },
      { achievementID = 14533, title = "Royal Rumble" },
      { achievementID = 14290, title = "I Only Have Eyes For You" },
      { achievementID = 14320, title = "Surgeon's Supplies" },
      { achievementID = 14503, title = "Hooked On Hydroponics" },
      { achievementID = 14375, title = "Hunger for Knowledge" },
      { achievementID = 14296, title = "Going Viral" },
      { achievementID = 14567, title = "Picking Up the Pieces" },
      { achievementID = 14352, title = "Nobody Puts Denathrius in a Corner" },
      { achievementID = 14354, title = "Highly Communicable" },
      { achievementID = 14331, title = "Goliath Offline" },
      { achievementID = 14327, title = "I Can See My House From Here" },
      { achievementID = 14607, title = "Fresh Meat!" },
      { achievementID = 14286, title = "Residue Evil" },
      { achievementID = 14289, title = "Kaal-ed Shot" },
    },
  },

  {
    achievementID = 14355,
    title = "Glory of the Nathria Raider",
    category = "raid",
    guide = "Complete the Castle Nathria raid achievements listed below.",
    criteria = {
      { achievementID = 14293, title = "Blind as a Bat" },
      { achievementID = 14608, title = "Burning Bright" },
      { achievementID = 14376, title = "Feed the Beast" },
      { achievementID = 14619, title = "Pour Decision Making" },
      { achievementID = 14525, title = "Feed Me, Seymour!" },
      { achievementID = 14523, title = "Taking Care of Business" },
      { achievementID = 14617, title = "Private Stock" },
      { achievementID = 14524, title = "I Don't Know What I Expected" },
      { achievementID = 14294, title = "Dirtflap's Revenge" },
      { achievementID = 14610, title = "Clear Conscience" },
    },
  },

  {
    achievementID = 15130,
    title = "Glory of the Dominant Raider",
    category = "raid",
    guide = "Complete the Sanctum of Domination raid achievements listed below.",
    criteria = {
      { achievementID = 14998, title = "Name A Better Duo, I'll Wait" },
      { achievementID = 15065, title = "Eye Wish You Were Here" },
      { achievementID = 15003, title = "To the Nines" },
      { achievementID = 15058, title = "I Used to Bullseye Deeprun Rats Back Home" },
      { achievementID = 15131, title = "Whack-A-Soul" },
      { achievementID = 15132, title = "Knowledge is Power" },
      { achievementID = 15133, title = "This World is a Prism" },
      { achievementID = 15105, title = "Tormentor's Tango" },
      { achievementID = 15040, title = "Flawless Fate" },
      { achievementID = 15108, title = "Together Forever" },
    },
  },

  {
    achievementID = 15491,
    title = "Glory of the Sepulcher Raider",
    category = "raid",
    guide = "Complete the Sepulcher of the First Ones raid achievements listed below.",
    criteria = {
      { achievementID = 15381, title = "Power ON" },
      { achievementID = 15401, title = "Wisdom Comes From the Desert" },
      { achievementID = 15397, title = "Four Ring Circus" },
      { achievementID = 15398, title = "Xy Never, Ever Marks the Spot." },
      { achievementID = 15386, title = "Shimmering Secrets" },
      { achievementID = 15400, title = "Where the Wild Corgis Are" },
      { achievementID = 15419, title = "The Protoform Matrix" },
      { achievementID = 15315, title = "Amidst Ourselves" },
      { achievementID = 15494, title = "Damnation Aviation" },
      { achievementID = 15396, title = "We Are All Made of Stars" },
    },
  },
}

Registry:RegisterExpansion("shadowlands", ROOTS)
