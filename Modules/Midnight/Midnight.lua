-- MetaHunter_Midnight -- a LoadOnDemand sub-addon (see
-- MetaHunter_Midnight.toc), not part of the main MetaHunter addon's own
-- startup file set. This keeps Midnight data out of memory until the player
-- selects it in the expansion sidebar.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_Midnight: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

--[[
  Midnight Patch 12.0 expected-meta preparation.

  The overall expansion-wide Midnight meta has not been announced yet, so this
  module does not claim these roots are confirmed criteria for it.
  Instead, it groups likely long-tail requirements into an "Expected Towards
  Meta" UI panel so players can start working on likely long-tail requirements
  without waiting for Blizzard's final expansion-wide meta announcement.

  Light Up the Night (achievementID 62386): exploration meta spanning the
  first four Midnight zones. Wowhead lists four direct criteria: Forever Song,
  That's Aln, Folks!, Making an Amani Out of You, and Yelling into the
  Voidstorm. Icy Veins identifies it as the exploration/zone meta reward path.

  Glory of the Midnight Raider (achievementID 61380): standalone Season 1 raid
  Glory meta, rewarding the Tenebrous Harrower mount. Wowhead lists ten direct
  achievement-backed criteria across Voidspire, Dreamrift, and March on
  Quel'Danas. Shown under the normal Raid category, not Expected Towards Meta.

  Glory of the Midnight Delver (achievementID 61906): Midnight delve Glory
  meta. Wowhead lists Delve Loremaster: Midnight, Curio Fanatic: Midnight,
  Midnight: Leave No Treasure Unfound, plus seasonal-nemesis criteria. The
  current in-game criteria data does not confirm My Shady Nemesis (61797) or
  My Venomous Nemesis (63326) as direct sub-achievement children of 61906, even
  though those achievement IDs are real and Wowhead lists them around the
  seasonal-nemesis requirement. They are modeled as a virtual
  `oneOfAchievementIDs` row so the UI can show the likely "any one seasonal
  nemesis" requirement without creating false ordinary child edges.

  Glory of the Midnight Hero (achievementID 61568): standalone Midnight Mythic
  dungeon meta. Wowhead lists eight Mythic dungeon completion achievements.
  Shown under the normal Dungeon category, not Expected Towards Meta.

  Raid completion achievements: The Voidspire (61366), Chimaerus, the Undreamt
  God (61487, The Dreamrift), March on Quel'Danas (61367), and The Venomous
  Abyss (63521) are included as likely useful progress targets because previous
  expansion-wide metas have commonly included raid-clear achievement
  requirements without necessarily including raid Glory metas.

  Authored to the depth currently useful for player-facing meta tracking:
  zone metas, Midnight delve metas, the likely raid-clear targets, dungeon
  Glory, and raid Glory roots include their immediate achievement-backed
  children. The source data goes deeper in many places (individual story
  variants, individual treasures, rares, events, etc.), but this stops at the
  same practical "track the child achievements" level used by The War Within.
]]

local ROOTS = {
  {
    achievementID = 62386,
    title = "Light Up the Night",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: complete the Midnight exploration meta across Eversong Woods, Zul'Aman, Harandar, and Voidstorm.",
    criteria = {
      {
        achievementID = 62261,
        title = "Forever Song",
        category = "zone",
        guide = "Complete the Eversong Woods achievements listed below.",
        criteria = {
          { achievementID = 61960, title = "Treasures of Eversong Woods" },
          { achievementID = 61507, title = "A Bloody Song" },
          { achievementID = 62186, title = "The Party Must Go On" },
          { achievementID = 61855, title = "Explore Eversong Woods" },
          { achievementID = 61961, title = "Runestone Rush" },
          { achievementID = 62185, title = "Ever Painting" },
        },
      },
      {
        achievementID = 61453,
        title = "Making an Amani Out of You",
        category = "zone",
        guide = "Complete all of the Zul'Aman achievements listed below.",
        criteria = {
          { achievementID = 62125, title = "Treasures of Zul'Aman" },
          { achievementID = 61856, title = "Explore Zul'Aman" },
          { achievementID = 62121, title = "Altar of Blessings: Sacred Buffet Devotee" },
          { achievementID = 62122, title = "Tallest Tree in the Forest" },
          { achievementID = 61943, title = "Abundance: Prosperous Plentitude!" },
        },
      },
      {
        achievementID = 62260,
        title = "That's Aln, Folks!",
        category = "zone",
        guide = "Aid the Hara'ti by completing the achievements below.",
        criteria = {
          { achievementID = 61263, title = "Treasures of Harandar" },
          { achievementID = 61264, title = "Leaf None Behind" },
          { achievementID = 61574, title = "Legends Never Die" },
          { achievementID = 61052, title = "Dust 'Em Off" },
          { achievementID = 61520, title = "Explore Harandar" },
          { achievementID = 61344, title = "Chronicler of the Haranir" },
          { achievementID = 61219, title = "No Time to Paws" },
          { achievementID = 61860, title = "From The Cradle to the Grave" },
        },
      },
      {
        achievementID = 62256,
        title = "Yelling into the Voidstorm",
        category = "zone",
        guide = "Complete all of the Voidstorm achievements listed below.",
        criteria = {
          { achievementID = 62130, title = "The Ultimate Predator" },
          { achievementID = 61857, title = "Explore Voidstorm" },
          { achievementID = 61913, title = "A Singular Problem" },
          { achievementID = 62126, title = "Treasures of Voidstorm" },
          { achievementID = 62133, title = "Thrill of the Chase" },
        },
      },
    },
  },
  {
    achievementID = 61906,
    title = "Glory of the Midnight Delver",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: complete the Midnight delve Glory meta.",
    criteria = {
      {
        achievementID = 61741,
        title = "Delve Loremaster: Midnight",
        criteria = {
          { achievementID = 61724, title = "The Grudge Pit Stories" },
          { achievementID = 61726, title = "Collegiate Calamity Stories" },
          { achievementID = 61728, title = "The Darkway Stories" },
          { achievementID = 61730, title = "Twilight Crypts Stories" },
          { achievementID = 61732, title = "Sunkiller Sanctum Stories" },
          { achievementID = 63437, title = "Gnarldor Isle Stories" },
          { achievementID = 61725, title = "Parhelion Plaza Stories" },
          { achievementID = 61727, title = "The Shadow Enclave Stories" },
          { achievementID = 61729, title = "Atal'Aman Stories" },
          { achievementID = 61731, title = "The Gulf of Memory Stories" },
          { achievementID = 61733, title = "Shadowguard Point Stories" },
          { achievementID = 63436, title = "The Ring of Glory Stories" },
        },
      },
      { achievementID = 61723, title = "Curio Fanatic: Midnight" },
      {
        achievementID = 61901,
        title = "Midnight: Leave No Treasure Unfound",
        criteria = {
          { achievementID = 61863, title = "Atal'Aman Discoveries" },
          { achievementID = 61893, title = "Parhelion Plaza Discoveries" },
          { achievementID = 61895, title = "The Darkway Discoveries" },
          { achievementID = 61897, title = "The Grudge Pit Discoveries" },
          { achievementID = 61899, title = "Sunkiller Sanctum Discoveries" },
          { achievementID = 63170, title = "Gnarldor Isle Discoveries" },
          { achievementID = 61892, title = "The Shadow Enclave Discoveries" },
          { achievementID = 61894, title = "Collegiate Calamity Discoveries" },
          { achievementID = 61896, title = "Twilight Crypts Discoveries" },
          { achievementID = 61898, title = "The Gulf of Memory Discoveries" },
          { achievementID = 61900, title = "Shadowguard Point Discoveries" },
          { achievementID = 63171, title = "The Ring of Glory Discoveries" },
        },
      },
      {
        title = "Defeat the Seasonal Nemesis",
        oneOfAchievementIDs = { 61797, 63326 },
        guide = "Complete any one Midnight seasonal nemesis achievement.",
      },
    },
  },
  {
    achievementID = 61568,
    title = "Glory of the Midnight Hero",
    category = "dungeon",
    guide = "Complete the Midnight Mythic dungeon achievements listed below.",
    criteria = {
      { achievementID = 61643, title = "Mythic: Den of Nalorakk" },
      { achievementID = 61645, title = "Mythic: Maisara Caverns" },
      { achievementID = 61647, title = "Mythic: Nexus-Point Xenas" },
      { achievementID = 61510, title = "Mythic: Voidscar Arena" },
      { achievementID = 61214, title = "Mythic: Magisters' Terrace" },
      { achievementID = 41962, title = "Mythic: Murder Row" },
      { achievementID = 61649, title = "Mythic: The Blinding Vale" },
      { achievementID = 41291, title = "Mythic: Windrunner Spire" },
    },
  },
  {
    achievementID = 61366,
    title = "The Voidspire",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: defeat the bosses in The Voidspire.",
  },
  {
    achievementID = 61487,
    title = "Chimaerus, the Undreamt God",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: defeat Chimaerus, the Undreamt God in The Dreamrift.",
  },
  {
    achievementID = 61367,
    title = "March on Quel'Danas",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: defeat the bosses in March on Quel'Danas.",
  },
  {
    achievementID = 63521,
    title = "The Venomous Abyss",
    category = "expectedMeta",
    guide = "Likely expansion-meta preparation: defeat the bosses in The Venomous Abyss.",
  },
  {
    achievementID = 61380,
    title = "Glory of the Midnight Raider",
    category = "raid",
    guide = "Complete the Midnight Season 1 raid Glory achievements across Voidspire, Dreamrift, and March on Quel'Danas.",
    criteria = {
      { achievementID = 62352, title = "Nothing to See Here" },
      { achievementID = 62058, title = "Hungry Hungry Hatchlings" },
      { achievementID = 61911, title = "Ready, Set, Snap!" },
      { achievementID = 61346, title = "We Will, In Fact, See It Again" },
      { achievementID = 61381, title = "Eggsistential Crisis" },
      { achievementID = 62106, title = "The Only Winning Move Is Not To Play" },
      { achievementID = 61514, title = "It's Treason Then" },
      { achievementID = 61936, title = "Aura Farming" },
      { achievementID = 61454, title = "Falling Between The Quacks" },
      { achievementID = 62406, title = "All the Things She Said" },
    },
  },
}

Registry:RegisterExpansion("midnight", ROOTS)
