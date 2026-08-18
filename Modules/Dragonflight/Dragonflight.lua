-- MetaHunter_Dragonflight -- a LoadOnDemand sub-addon (see
-- MetaHunter_Dragonflight.toc), not part of the main MetaHunter addon's own
-- startup file set. This keeps Dragonflight data out of memory until the
-- player selects it in the expansion sidebar.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_Dragonflight: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

--[[
  Dragonflight expansion meta.

  A World Awoken (achievementID 19458) is the Dragonflight expansion-wide meta
  achievement, awarding Good Boy's Leash. Wowhead lists fourteen direct
  achievement-backed criteria. The first deepening pass adds the immediate
  achievement-backed children for those direct criteria where Blizzard exposes
  child achievement IDs. Some criteria, such as raid boss checklists and
  Friend of the Dragon Isles' renown-campaign checklist, are plain criteria
  rather than child achievements and are deliberately left as their parent row
  until the schema has a separate way to render non-achievement checklist text.
]]

local ROOTS = {
  {
    achievementID = 19458,
    title = "A World Awoken",
    category = "main",
    guide = "Complete Dragonflight's expansion-wide meta achievement to earn Good Boy's Leash.",
    criteria = {
      { achievementID = 16343, title = "Vault of the Incarnates" },
      { achievementID = 18160, title = "Aberrus, the Shadowed Crucible" },
      { achievementID = 19331, title = "Amirdrassil, the Dream's Hope" },
      {
        achievementID = 16339,
        title = "Myths of the Dragonflight Dungeons",
        criteria = {
          { achievementID = 16271, title = "Mythic: Algeth'ar Academy" },
          { achievementID = 16257, title = "Mythic: Brackenhide Hollow" },
          { achievementID = 16262, title = "Mythic: Halls of Infusion" },
          { achievementID = 16265, title = "Mythic: Neltharus" },
          { achievementID = 16268, title = "Mythic: Ruby Life Pools" },
          { achievementID = 16274, title = "Mythic: The Azure Vault" },
          { achievementID = 16277, title = "Mythic: The Nokhud Offensive" },
          { achievementID = 16280, title = "Mythic: Uldaman: Legacy of Tyr" },
        },
      },
      {
        achievementID = 16585,
        title = "Loremaster of the Dragon Isles",
        criteria = {
          { achievementID = 16334, title = "Waking Hope" },
          { achievementID = 16401, title = "Sojourner of the Waking Shores" },
          { achievementID = 15394, title = "Ohn'a'Roll" },
          { achievementID = 16405, title = "Sojourner of Ohn'ahran Plains" },
          { achievementID = 16336, title = "Azure Spanner" },
          { achievementID = 16428, title = "Sojourner of Azure Span" },
          { achievementID = 16363, title = "Just Don't Ask Me to Spell It" },
          { achievementID = 16398, title = "Sojourner of Thaldraszus" },
        },
      },
      { achievementID = 16808, title = "Friend of the Dragon Isles" },
      {
        achievementID = 19463,
        title = "Dragon Quests",
        criteria = {
          { achievementID = 17773, title = "A Blue Dawn" },
          { achievementID = 17734, title = "Active Listening Skills" },
          { achievementID = 18958, title = "Of the Tyr's Guard" },
          { achievementID = 17546, title = "A New Beginning" },
          { achievementID = 16683, title = "In Tyr's Footsteps" },
          { achievementID = 19507, title = "Fringe Benefits" },
        },
      },
      {
        achievementID = 19466,
        title = "Oh My God, They Were Clutchmates",
        criteria = {
          { achievementID = 41174, title = "A True Explorer" },
          { achievementID = 41180, title = "Joining the Khansguard" },
          { achievementID = 41181, title = "Joining the Community" },
          { achievementID = 41182, title = "Ally of the Flights" },
          { achievementID = 41183, title = "There's No Place Like Loamm" },
          { achievementID = 41177, title = "Warden of the Dream" },
          { achievementID = 18615, title = "Legend of the Multiverse" },
          { achievementID = 16494, title = "Loyalty to the Prince" },
          { achievementID = 16760, title = "The Obsidian Bloodline" },
          { achievementID = 16539, title = "In High Esteem" },
          { achievementID = 16537, title = "Maximum Power!" },
          { achievementID = 17427, title = "Winterpelt Conversationalist" },
        },
      },
      {
        achievementID = 19307,
        title = "Dragon Isles Pathfinder",
        criteria = {
          { achievementID = 16334, title = "Waking Hope" },
          { achievementID = 15394, title = "Ohn'a'Roll" },
          { achievementID = 16336, title = "Azure Spanner" },
          { achievementID = 16363, title = "Just Don't Ask Me to Spell It" },
          { achievementID = 17739, title = "Embers of Neltharion" },
          { achievementID = 16761, title = "Dragon Isles Explorer" },
          { achievementID = 17766, title = "Explore Zaralek Cavern" },
          { achievementID = 19309, title = "Explore the Emerald Dream" },
        },
      },
      {
        achievementID = 19486,
        title = "Across the Isles",
        criteria = {
          { achievementID = 19479, title = "Wake Me Up" },
          { achievementID = 19481, title = "Centaur of Attention" },
          { achievementID = 19482, title = "Army of the Fed" },
          { achievementID = 19483, title = "Flight Club" },
          { achievementID = 19485, title = "Closing Time" },
          { achievementID = 16492, title = "Into the Storm" },
          { achievementID = 18209, title = "Nothing Stops the Research" },
          { achievementID = 18867, title = "Through the Ashes and Flames" },
          { achievementID = 19008, title = "Dream Shaper" },
        },
      },
      {
        achievementID = 17543,
        title = "You Know How to Reach Me",
        criteria = {
          { achievementID = 17534, title = "Explore the Forbidden Reach" },
          { achievementID = 17526, title = "Treasures of the Forbidden Reach" },
          { achievementID = 17528, title = "Hoarder of the Forbidden Reach" },
          { achievementID = 17525, title = "Champion of the Forbidden Reach" },
          { achievementID = 17529, title = "Forbidden Spoils" },
          { achievementID = 17530, title = "Librarian of the Reach" },
          { achievementID = 17532, title = "Scroll Hunter" },
          { achievementID = 17540, title = "Under the Weather" },
          { achievementID = 17413, title = "Door Buster" },
          { achievementID = 17509, title = "Every Door, Everywhere, All At Once" },
          { achievementID = 17315, title = "While We Were Sleeping" },
        },
      },
      {
        achievementID = 17785,
        title = "Que Zara(lek), Zara(lek)",
        criteria = {
          { achievementID = 17739, title = "Embers of Neltharion" },
          { achievementID = 17783, title = "Adventurer of Zaralek Cavern" },
          { achievementID = 17781, title = "The Smell of Money" },
          { achievementID = 17766, title = "Explore Zaralek Cavern" },
          { achievementID = 41183, title = "There's No Place Like Loamm" },
          { achievementID = 17786, title = "Treasures of Zaralek Cavern" },
          { achievementID = 17832, title = "Sniffen Around" },
        },
      },
      {
        achievementID = 19318,
        title = "Dream On",
        criteria = {
          { achievementID = 19026, title = "Defenders of the Dream" },
          { achievementID = 19316, title = "Adventurer of the Emerald Dream" },
          { achievementID = 19317, title = "Treasures of the Emerald Dream" },
          { achievementID = 19013, title = "I Dream of Seeds" },
          { achievementID = 19309, title = "Explore the Emerald Dream" },
          { achievementID = 19312, title = "Super Duper Bloom" },
        },
      },
      {
        achievementID = 19478,
        title = "Now THIS is Dragon Racing!",
        criteria = {
          { achievementID = 15939, title = "Dragon Racing Completionist: Bronze" },
          { achievementID = 17294, title = "Forbidden Reach Racing Completionist" },
          { achievementID = 17492, title = "Zaralek Cavern Racing Completionist" },
          { achievementID = 19118, title = "Emerald Dream Racing Completionist" },
          { achievementID = 16575, title = "Waking Shores Glyph Hunter" },
          { achievementID = 16576, title = "Ohn'ahran Plains Glyph Hunter" },
          { achievementID = 16577, title = "Azure Span Glyph Hunter" },
          { achievementID = 16578, title = "Thaldraszus Glyph Hunter" },
          { achievementID = 17411, title = "Forbidden Reach Glyph Hunter" },
          { achievementID = 18150, title = "Zaralek Cavern Glyph Hunter" },
          { achievementID = 19306, title = "Emerald Dream Glyph Hunter" },
        },
      },
    },
  },

  {
    achievementID = 16295,
    title = "Glory of the Dragonflight Hero",
    category = "dungeon",
    guide = "Complete the Dragonflight Mythic dungeon achievements listed below.",
    criteria = {
      { achievementID = 16434, title = "See Me After Class" },
      { achievementID = 16441, title = "Squad Goals" },
      { achievementID = 16430, title = "All Bark, All Bite" },
      { achievementID = 16517, title = "Toxicity Strike Team" },
      { achievementID = 16427, title = "Go With the Flow" },
      { achievementID = 16432, title = "Ready for Raiding VIII" },
      { achievementID = 16440, title = "Are You My Broodmother?" },
      { achievementID = 16320, title = "Does Steam Do Fire Damage?" },
      { achievementID = 16445, title = "Icy What You Did There" },
      { achievementID = 16447, title = "What Are The Chances..." },
      { achievementID = 16620, title = "Ohuna Incubation" },
      { achievementID = 16337, title = "It's a Trogg Eat Trogg World" },
      { achievementID = 16281, title = "Like Sands Through the Hourglass" },
      { achievementID = 16329, title = "Duck, Duck, Spruce!" },
      { achievementID = 16296, title = "Growlbossify" },
      { achievementID = 16404, title = "So You Can Kill This in a Way That Matters..." },
      { achievementID = 16426, title = "Hungry Hungry Hornswog" },
      { achievementID = 16438, title = "Knowledge is... Preserved?" },
      { achievementID = 16453, title = "Liquid Hot Magma" },
      { achievementID = 16402, title = "Dragon Kill Points" },
      { achievementID = 16330, title = "You Must Be Made of Hide" },
      { achievementID = 16331, title = "The Cracked Crystal" },
      { achievementID = 16456, title = "Weapons of the Maruukai" },
      { achievementID = 16602, title = "Nokhud Deed Goes Unnoticed" },
      { achievementID = 16282, title = "No, You're Stunning!" },
    },
  },

  {
    achievementID = 16355,
    title = "Glory of the Vault Raider",
    category = "raid",
    guide = "Complete the Vault of the Incarnates raid achievements listed below.",
    criteria = {
      { achievementID = 16335, title = "What Frozen Things Do" },
      { achievementID = 16364, title = "The Lunker Below" },
      { achievementID = 16458, title = "Nothing But Air" },
      { achievementID = 16442, title = "Incubation Extermination" },
      { achievementID = 16365, title = "Little Friends" },
      { achievementID = 16419, title = "I Was Saving That For Later" },
      { achievementID = 16450, title = "The Power is MINE!" },
      { achievementID = 16451, title = "The Ol Raszle Daszle" },
    },
  },

  {
    achievementID = 18251,
    title = "Glory of the Aberrus Raider",
    category = "raid",
    guide = "Complete the Aberrus, the Shadowed Crucible raid achievements listed below.",
    criteria = {
      { achievementID = 18229, title = "Cosplate" },
      { achievementID = 18173, title = "Tabula Rasa" },
      { achievementID = 18230, title = "Whac-A-Swog" },
      { achievementID = 18172, title = "Escar-Go-Go-Go" },
      { achievementID = 17877, title = "We'll Never See That Again, Surely" },
      { achievementID = 18168, title = "I'll Make My Own Shadowflame" },
      { achievementID = 18228, title = "Are You Even Trying?" },
      { achievementID = 18193, title = "Eggscellent Eggsecution" },
      { achievementID = 18149, title = "Objects in Transit May Shatter" },
    },
  },

  {
    achievementID = 19349,
    title = "Glory of the Dream Raider",
    category = "raid",
    guide = "Complete the Amirdrassil, the Dream's Hope raid achievements listed below.",
    criteria = {
      { achievementID = 19322, title = "Meaner Pastures" },
      { achievementID = 19320, title = "Cruelty Free" },
      { achievementID = 19321, title = "Swog Champion" },
      { achievementID = 19193, title = "Ducks In A Row" },
      { achievementID = 19089, title = "Don't Let the Doe Hit You On The Way Out" },
      { achievementID = 19394, title = "A Dream Within a Dream" },
      { achievementID = 19319, title = "Haven't We Done This Before?" },
      { achievementID = 19393, title = "Whelp, I'm Lost" },
      { achievementID = 19390, title = "Memories of Teldrassil" },
    },
  },
}

Registry:RegisterExpansion("dragonflight", ROOTS)
