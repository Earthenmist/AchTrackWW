-- MetaHunter_BFA -- a LoadOnDemand sub-addon (see MetaHunter_BFA.toc), not
-- part of the main MetaHunter addon's own startup file set. This keeps Battle
-- for Azeroth data out of memory until the player selects it in the expansion
-- sidebar.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_BFA: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

--[[
  Battle for Azeroth expansion meta.

  A Farewell to Arms (achievementID 40953) is the Battle for Azeroth
  expansion-wide meta achievement, awarding Jani's Trashpile. This module
  follows Meta Hunter's expansion format: expansion meta first, then
  standalone Glory roots for dungeons and raids.

  The expansion meta includes immediate achievement-backed children where the
  live criteria expose them. `Dressed to Kill: Battle for Azeroth` is left as a
  parent row for now because it is a "complete 4 of these 8" requirement, which
  needs a count-of-set schema field rather than ordinary AND children.
]]

local ROOTS = {
  {
    achievementID = 40953,
    title = "A Farewell to Arms",
    category = "main",
    guide = "Complete Battle for Azeroth's expansion-wide meta achievement to earn Jani's Trashpile.",
    criteria = {
      {
        achievementID = 40960,
        title = "Uldir",
        criteria = {
          { achievementID = 12521, title = "Halls of Containment" },
          { achievementID = 12522, title = "Crimson Descent" },
          { achievementID = 12523, title = "Heart of Corruption" },
        },
      },
      {
        achievementID = 40961,
        title = "Battle of Dazar'alor",
        criteria = {
          { title = "Opening wing", oneOfAchievementIDs = { 13289, 13286 } },
          { title = "Middle wing", oneOfAchievementIDs = { 13290, 13287 } },
          { title = "Final wing", oneOfAchievementIDs = { 13291, 13288 } },
        },
      },
      { achievementID = 13414, title = "Crucible of Storms" },
      {
        achievementID = 40962,
        title = "The Eternal Palace",
        criteria = {
          { achievementID = 13718, title = "The Grand Reception" },
          { achievementID = 13719, title = "Depths of the Devoted" },
          { achievementID = 13725, title = "The Circle of Stars" },
        },
      },
      {
        achievementID = 40963,
        title = "Ny'alotha, the Waking City",
        criteria = {
          { achievementID = 14193, title = "Vision of Destiny" },
          { achievementID = 14194, title = "Halls of Devotion" },
          { achievementID = 14195, title = "Gift of Flesh" },
          { achievementID = 14196, title = "The Waking Dream" },
        },
      },
      {
        achievementID = 12807,
        title = "Battle for Azeroth Dungeon Hero",
        criteria = {
          { achievementID = 12825, title = "Heroic: Atal'Dazar" },
          { achievementID = 12832, title = "Heroic: Freehold" },
          { achievementID = 12837, title = "Heroic: Shrine of the Storm" },
          { achievementID = 12505, title = "Heroic: The Temple of Sethraliss" },
          { achievementID = 12841, title = "Heroic: Tol Dagor" },
          { achievementID = 12845, title = "Heroic: The MOTHERLODE!!" },
          { achievementID = 12501, title = "Heroic: Underrot" },
          { achievementID = 12484, title = "Heroic: Waycrest Manor" },
        },
      },
      {
        achievementID = 40955,
        title = "War Stories",
        criteria = {
          { title = "Opening campaign", oneOfAchievementIDs = { 12555, 12582 } },
          {
            achievementID = 13517,
            title = "Two Sides to Every Tale",
            criteria = {
              { title = "Faction finale", oneOfAchievementIDs = { 12891, 12479 } },
              { title = "Tides of Vengeance", oneOfAchievementIDs = { 13467, 13466 } },
            },
          },
          { title = "The Fourth War", oneOfAchievementIDs = { 13925, 13924 } },
          { title = "Heritage campaign", oneOfAchievementIDs = { 13263, 12997 } },
          { title = "Faction epilogue", oneOfAchievementIDs = { 12719, 13251 } },
          { title = "The Mechagonian Threat", oneOfAchievementIDs = { 13700, 13553 } },
          { title = "Nazjatar campaign", oneOfAchievementIDs = { 13709, 13710 } },
          { achievementID = 14157, title = "The Corruptor's End" },
        },
      },
      {
        achievementID = 40956,
        title = "I'm On Island Time",
        criteria = {
          {
            achievementID = 41202,
            title = "Hot Tropic",
            criteria = {
              { achievementID = 12944, title = "Adventurer of Zuldazar" },
              { achievementID = 12851, title = "Treasures of Zuldazar" },
              { achievementID = 12614, title = "Loa Expectations" },
              { achievementID = 13020, title = "Bow to Your Masters" },
              { achievementID = 12482, title = "Get Hek'd" },
              { achievementID = 13036, title = "A Loa of a Tale" },
              { achievementID = 13029, title = "Eating Out of the Palm of My Tiny Hand" },
              { achievementID = 13038, title = "Raptari Rider" },
            },
          },
          {
            achievementID = 41205,
            title = "Sound Off",
            criteria = {
              { achievementID = 12939, title = "Adventurer of Tiragarde Sound" },
              { achievementID = 12852, title = "Treasures of Tiragarde Sound" },
              { achievementID = 13050, title = "Bless the Rains Down in Freehold" },
              { achievementID = 13057, title = "Sailed in Sea Minor" },
              { achievementID = 13061, title = "Three Sheets to the Wind" },
              { achievementID = 13058, title = "Kul Tiran Up the Dance Floor" },
              { achievementID = 13049, title = "The Long Con" },
            },
          },
          {
            achievementID = 41203,
            title = "Bwon Voyage",
            criteria = {
              { achievementID = 12942, title = "Adventurer of Nazmir" },
              { achievementID = 12771, title = "Treasures of Nazmir" },
              { achievementID = 13024, title = "Carved in Stone, Written in Blood" },
              { achievementID = 13023, title = "It's Really Getting Out of Hand" },
              { achievementID = 12588, title = "Eat Your Greens" },
              { achievementID = 13028, title = "Hoppin' Sad" },
              { achievementID = 13022, title = "Revenge is Best Served Speedily" },
              { achievementID = 13021, title = "A Most Efficient Apocalypse" },
            },
          },
          {
            achievementID = 41206,
            title = "Songs of Storms",
            criteria = {
              { achievementID = 12940, title = "Adventurer of Stormsong Valley" },
              { achievementID = 12853, title = "Treasures of Stormsong Valley" },
              { achievementID = 13047, title = "Clever Use of Mechanical Explosives" },
              { achievementID = 13046, title = "These Hills Sing" },
              { achievementID = 13051, title = "Legends of the Tidesages" },
              { achievementID = 13045, title = "Every Day I'm Truffling" },
              { achievementID = 13062, title = "Let's Bee Friends" },
              { achievementID = 13053, title = "Deadliest Cache" },
            },
          },
          {
            achievementID = 41204,
            title = "Dune Squad",
            criteria = {
              { achievementID = 12943, title = "Adventurer of Vol'dun" },
              { achievementID = 12849, title = "Treasures of Vol'dun" },
              { achievementID = 13016, title = "Scavenger of the Sands" },
              { achievementID = 13018, title = "Dune Rider" },
              { achievementID = 13011, title = "Scourge of Zem'lan" },
              { achievementID = 13009, title = "Adept Sandfisher" },
              { achievementID = 13017, title = "Champion of the Vulpera" },
              { achievementID = 13437, title = "Scavenge like a Vulpera" },
            },
          },
          {
            achievementID = 41207,
            title = "When the Drust Settles",
            criteria = {
              { achievementID = 12941, title = "Adventurer of Drustvar" },
              { achievementID = 12995, title = "Treasures of Drustvar" },
              { achievementID = 13087, title = "Sausage Sampler" },
              { achievementID = 13064, title = "Drust the Facts, Ma'am" },
              { achievementID = 13094, title = "Cursed Game Hunter" },
              { achievementID = 13082, title = "Everything Old Is New Again" },
            },
          },
          { achievementID = 13294, title = "Loremaster of Zandalar" },
          {
            achievementID = 12593,
            title = "Loremaster of Kul Tiras",
            criteria = {
              { achievementID = 12473, title = "A Sound Plan" },
              { achievementID = 12497, title = "Drust Do It." },
              { achievementID = 12496, title = "Stormsong and Dance" },
            },
          },
          {
            achievementID = 12988,
            title = "Battle for Azeroth Explorer",
            criteria = {
              { achievementID = 12556, title = "Explore Tiragarde Sound" },
              { achievementID = 12557, title = "Explore Drustvar" },
              { achievementID = 12558, title = "Explore Stormsong Valley" },
              { achievementID = 12559, title = "Explore Zuldazar" },
              { achievementID = 12561, title = "Explore Nazmir" },
              { achievementID = 12560, title = "Explore Vol'dun" },
            },
          },
          { achievementID = 13144, title = "Wide World of Quests" },
        },
      },
      { achievementID = 12947, title = "Azerothian Diplomat" },
      {
        achievementID = 13134,
        title = "Expedition Leader",
        criteria = {
          { achievementID = 13122, title = "Island Conqueror" },
          { achievementID = 13125, title = "Azerite Admiral" },
          { achievementID = 13126, title = "Give Me The Energy" },
          { achievementID = 13127, title = "Tell Me A Tale" },
          { achievementID = 13124, title = "Metal Detector" },
          { achievementID = 13128, title = "I'm Here for the Pets" },
          { achievementID = 13132, title = "Helping Hand" },
          { achievementID = 12595, title = "Expert Expeditioner" },
          { title = "Team Deathmatch", oneOfAchievementIDs = { 13135, 13133 } },
        },
      },
      {
        achievementID = 40957,
        title = "Maximum Effort",
        criteria = {
          { title = "War is Hell", oneOfAchievementIDs = { 12873, 12881 } },
          { title = "War for the Shore", oneOfAchievementIDs = { 13296, 13297 } },
          { achievementID = 12872, title = "The Dirty Five" },
          { title = "Azeroth at War", oneOfAchievementIDs = { 12867, 12896 } },
          { title = "Azeroth at War: After Lordaeron", oneOfAchievementIDs = { 12869, 12898 } },
          { title = "Azeroth at War: Kalimdor on Fire", oneOfAchievementIDs = { 12870, 12899 } },
          { title = "Frontline Warrior", oneOfAchievementIDs = { 13283, 13284 } },
        },
      },
      {
        achievementID = 13541,
        title = "Mecha-Done",
        criteria = {
          { title = "The Mechagonian Threat", oneOfAchievementIDs = { 13700, 13553 } },
          { achievementID = 13470, title = "Rest In Pistons" },
          { achievementID = 13556, title = "Outside Influences" },
          { achievementID = 13479, title = "Junkyard Architect" },
          { achievementID = 13477, title = "Junkyard Apprentice" },
          { achievementID = 13474, title = "Junkyard Machinist" },
          { achievementID = 13513, title = "Available in Eight Colors" },
          { achievementID = 13686, title = "Junkyard Melomaniac" },
          { achievementID = 13791, title = "Making the Mount" },
          { achievementID = 13790, title = "Armed for Action" },
        },
      },
      {
        achievementID = 13638,
        title = "Undersea Usurper",
        criteria = {
          { achievementID = 13635, title = "Tour of the Depths" },
          { achievementID = 13690, title = "Nazjatarget Eliminated" },
          { achievementID = 13691, title = "I Thought You Said They'd Be Rare?" },
          { title = "Aqua Team Murder Force", oneOfAchievementIDs = { 13761, 13762 } },
          { achievementID = 13711, title = "A Fistful of Manapearls" },
          { achievementID = 13722, title = "Terror of the Tadpoles" },
          { achievementID = 13699, title = "Periodic Destruction" },
          { achievementID = 13713, title = "Nothing To Scry About" },
          { achievementID = 13707, title = "Mrrl's Secret Stash" },
          { achievementID = 13764, title = "Puzzle Performer" },
          { title = "Ankoan or Unshackled Exalted", oneOfAchievementIDs = { 13558, 13559 } },
          { achievementID = 13765, title = "Subaquatic Support" },
          { achievementID = 13836, title = "Feline Figurines Found" },
          { achievementID = 13712, title = "Explore Nazjatar" },
          { achievementID = 13710, title = "Sunken Ambitions" },
          { achievementID = 13763, title = "Back to the Depths!" },
        },
      },
      {
        achievementID = 13994,
        title = "Through the Depths of Visions",
        criteria = {
          { achievementID = 14066, title = "The Most Horrific Vision of Stormwind" },
          { achievementID = 14060, title = "Unwavering Resolve" },
          { achievementID = 14067, title = "The Most Horrific Vision of Orgrimmar" },
          { achievementID = 14061, title = "We Have the Technology" },
        },
      },
      {
        achievementID = 40958,
        title = "Full Heart, Can't Lose",
        criteria = {
          { achievementID = 12918, title = "Have a Heart" },
          { achievementID = 13572, title = "The Heart Forge" },
          { achievementID = 13771, title = "Power Is Beautiful" },
          { achievementID = 13777, title = "My Heart Container is Full" },
        },
      },
      {
        achievementID = 40959,
        title = "Black Empire State of Mind",
        criteria = {
          { achievementID = 14154, title = "Defend the Vale" },
          { achievementID = 14153, title = "Uldum Under Assault" },
          { achievementID = 14156, title = "The Rajani" },
          { achievementID = 14155, title = "Uldum Accord" },
          { achievementID = 14159, title = "Combating the Corruption" },
          { achievementID = 14158, title = "It's Not A Tumor!" },
          { achievementID = 14161, title = "All Consuming" },
        },
      },
      { achievementID = 41209, title = "Dressed to Kill: Battle for Azeroth" },
      { achievementID = 14730, title = "To All the Squirrels I Set Sail to See" },
    },
  },

  {
    achievementID = 12812,
    title = "Glory of the Wartorn Hero",
    category = "dungeon",
    guide = "Complete the Battle for Azeroth dungeon achievements listed below.",
    criteria = {
      { achievementID = 12550, title = "Pecking Order" },
      { achievementID = 12998, title = "That Sweete Booty" },
      { achievementID = 12495, title = "Run Wild Like a Man On Fire" },
      { achievementID = 12600, title = "Breath of the Shrine" },
      { achievementID = 12602, title = "Trust No One" },
      { achievementID = 12272, title = "Gold Fever" },
      { achievementID = 12549, title = "Not a Fun Guy" },
      { achievementID = 12499, title = "Sporely Alive" },
      { achievementID = 12507, title = "Snake Eater" },
      { achievementID = 12457, title = "Remix to Ignition" },
      { achievementID = 12855, title = "Pitch Invasion" },
      { achievementID = 12727, title = "Stand by Me" },
      { achievementID = 12722, title = "It Belongs in a Mausoleum!" },
      { achievementID = 12721, title = "Wrap God" },
      { achievementID = 12548, title = "I'm in Charge Now!" },
      { achievementID = 12489, title = "Losing My Profession" },
      { achievementID = 12490, title = "Alchemical Romance" },
      { achievementID = 12601, title = "The Void Lies Sleeping" },
      { achievementID = 12270, title = "Bringing Hexy Back" },
      { achievementID = 12273, title = "It's Lit!" },
      { achievementID = 12498, title = "Taint Nobody Got Time For That" },
      { achievementID = 12503, title = "Snake Eyes" },
      { achievementID = 12508, title = "Good Night, Sweet Prince" },
      { achievementID = 12462, title = "Shot Through the Heart" },
      { achievementID = 12854, title = "Ready for Raiding VI" },
      { achievementID = 12726, title = "A Fish Out of Water" },
      { achievementID = 12723, title = "How to Keep a Mummy" },
    },
  },

  {
    achievementID = 12806,
    title = "Glory of the Uldir Raider",
    category = "raid",
    guide = "Complete the Uldir raid achievements listed below.",
    criteria = {
      { achievementID = 12551, title = "Double Dribble" },
      { achievementID = 12938, title = "Parental Controls" },
      { achievementID = 12823, title = "Thrash Mouth - All Stars" },
      { achievementID = 12830, title = "Edgelords" },
      { achievementID = 12828, title = "What's in the Box?" },
      { achievementID = 12937, title = "Elevator Music" },
      { achievementID = 12772, title = "Now We Got Bad Blood" },
      { achievementID = 12836, title = "Existential Crisis" },
    },
  },

  {
    achievementID = 13315,
    title = "Glory of the Dazar'alor Raider",
    category = "raid",
    guide = "Complete the Battle of Dazar'alor raid achievements listed below.",
    criteria = {
      { achievementID = 13316, title = "Can I Get a Hek Hek Hek Yeah?" },
      { achievementID = 13383, title = "Barrel of Monkeys" },
      { achievementID = 13430, title = "De Lurker Be'loa" },
      { achievementID = 13345, title = "Praise the Sunflower" },
      { achievementID = 13325, title = "Walk the Dinosaur" },
      { achievementID = 13431, title = "Hidden Dragon" },
      { achievementID = 13410, title = "Snow Fun Allowed" },
      { achievementID = 13401, title = "I Got Next!" },
      { achievementID = 13425, title = "We Got Spirit, How About You?" },
    },
  },

  {
    achievementID = 13687,
    title = "Glory of the Eternal Raider",
    category = "raid",
    guide = "Complete the Eternal Palace raid achievements listed below.",
    criteria = {
      { achievementID = 13684, title = "You and What Army?" },
      { achievementID = 13628, title = "Intro to Marine Biology" },
      { achievementID = 13633, title = "If It Pleases the Court" },
      { achievementID = 13767, title = "Fun Run" },
      { achievementID = 13724, title = "A Smack of Jellyfish" },
      { achievementID = 13629, title = "Simple Geometry" },
      { achievementID = 13716, title = "Lactose Intolerant" },
      { achievementID = 13768, title = "The Best of Us" },
    },
  },

  {
    achievementID = 14146,
    title = "Glory of the Ny'alotha Raider",
    category = "raid",
    guide = "Complete the Ny'alotha, the Waking City raid achievements listed below.",
    criteria = {
      { achievementID = 14019, title = "Smoke Test" },
      { achievementID = 14008, title = "Mana Sponge" },
      { achievementID = 14037, title = "Phase 3: Prophet" },
      { achievementID = 14024, title = "Buzzer Beater" },
      { achievementID = 14139, title = "Total Annihilation" },
      { achievementID = 14023, title = "Realizing Your Potential" },
      { achievementID = 13999, title = "How? Isn't it Obelisk?" },
      { achievementID = 13990, title = "You Can Pet the Dog, But..." },
      { achievementID = 14026, title = "Temper Tantrum" },
      { achievementID = 14038, title = "Bloody Mess" },
      { achievementID = 14147, title = "Cleansing Treatment" },
      { achievementID = 14148, title = "It's Not A Cult" },
    },
  },
}

Registry:RegisterExpansion("bfa", ROOTS)
