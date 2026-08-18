-- MetaHunter_Legion -- a LoadOnDemand sub-addon, not part of the main
-- MetaHunter startup file set.
local MH = _G.MetaHunter
if not MH or not MH.Registry then
  error("MetaHunter_Legion: MetaHunter (the main addon) isn't loaded -- check the Dependencies declaration in this addon's .toc")
end
local Registry = MH.Registry

-- Legion has no confirmed live expansion-wide meta in the modern
-- "meta-of-metas" style. This first pass registers conservative notable,
-- dungeon, and raid roots so the in-game audit can harden the data.
local ROOTS = {
  {
    achievementID = 11446,
    title = "Broken Isles Pathfinder, Part Two",
    category = "notable",
    guide = "Unlock flying in the Broken Isles.",
    criteria = {
      {
        achievementID = 11190,
        title = "Broken Isles Pathfinder, Part One",
        criteria = {
          {
            achievementID = 11188,
            title = "Broken Isles Explorer",
            criteria = {
              { achievementID = 10665, title = "Explore Azsuna" },
              { achievementID = 10667, title = "Explore Highmountain" },
              { achievementID = 10669, title = "Explore Suramar" },
              { achievementID = 10666, title = "Explore Val'sharah" },
              { achievementID = 10668, title = "Explore Stormheim" },
            },
          },
          { achievementID = 11189, title = "Variety is the Spice of Life" },
          { achievementID = 10994, title = "A Glorious Campaign" },
          {
            achievementID = 11157,
            title = "Loremaster of Legion",
            criteria = {
              { achievementID = 10763, title = "Azsuna Matata" },
              { achievementID = 10790, title = "Vrykul Story, Bro" },
              { achievementID = 11124, title = "Good Suramaritan" },
              { achievementID = 10698, title = "That's Val'sharah Folks!" },
              { achievementID = 10059, title = "Ain't No Mountain High Enough" },
            },
          },
          { achievementID = 10672, title = "Broken Isles Diplomat" },
        },
      },
      { achievementID = 11545, title = "Legionfall Commander" },
      { achievementID = 11543, title = "Explore Broken Shore" },
    },
  },
  {
    achievementID = 11163,
    title = "Glory of the Legion Hero",
    category = "dungeon",
    guide = "Complete the Legion dungeon achievements listed by Blizzard.",
    criteria = {
      { achievementID = 10456, title = "But You Say He's Just a Friend" },
      { achievementID = 10458, title = "Ready for Raiding V" },
      { achievementID = 10769, title = "Burning Down the House" },
      { achievementID = 10875, title = "Can't Eat Just One" },
      { achievementID = 10542, title = "I Got What You Mead" },
      { achievementID = 10554, title = "I Made a Food!" },
      { achievementID = 10680, title = "Who's Afraid of the Dark?" },
      { achievementID = 10709, title = "You Used to Scrawl Me In Your Fel Tome" },
      { achievementID = 10711, title = "Adds? More Like Bads" },
      { achievementID = 10411, title = "Helheim Hath No Fury" },
      { achievementID = 10776, title = "No Time to Waste" },
      { achievementID = 10773, title = "Arcanic Cling" },
      { achievementID = 10611, title = "Dropping Some Eaves" },
      { achievementID = 10457, title = "Stay Salty" },
      { achievementID = 10766, title = "Egg-cellent!" },
      { achievementID = 10996, title = "Got to Ketchum All" },
      { achievementID = 10544, title = "Stag Party" },
      { achievementID = 10543, title = "Surge Protector" },
      { achievementID = 10553, title = "You're Just Making It WORSE!" },
      { achievementID = 10707, title = "A Specter, Illuminated" },
      { achievementID = 10710, title = "Black Rook Moan" },
      { achievementID = 10413, title = "Instant Karma" },
      { achievementID = 10412, title = "Poor Unfortunate Souls" },
      { achievementID = 10775, title = "Clean House" },
      { achievementID = 10610, title = "Waiting for Gerdo" },
    },
  },
  {
    achievementID = 11180,
    title = "Glory of the Legion Raider",
    category = "raid",
    guide = "Complete the Emerald Nightmare and Nighthold raid achievements listed by Blizzard.",
    criteria = {
      { achievementID = 10555, title = "Buggy Fight" },
      { achievementID = 10753, title = "Scare Bear" },
      { achievementID = 10663, title = "Imagined Dragons World Tour" },
      { achievementID = 10755, title = "I Attack the Darkness" },
      { achievementID = 10697, title = "Grand Opening" },
      { achievementID = 10817, title = "A Change In Scenery" },
      { achievementID = 10704, title = "Not For You" },
      { achievementID = 10699, title = "Infinitesimal" },
      { achievementID = 10771, title = "Webbing Crashers" },
      { achievementID = 10830, title = "Took the Red Eye Down" },
      { achievementID = 10772, title = "Use the Force(s)" },
      { achievementID = 10678, title = "Cage Rematch" },
      { achievementID = 10742, title = "Gluten Free" },
      { achievementID = 10851, title = "Elementalry!" },
      { achievementID = 10575, title = "Burning Bridges" },
      { achievementID = 10696, title = "I've Got My Eyes On You" },
    },
  },
  {
    achievementID = 11763,
    title = "Glory of the Tomb Raider",
    category = "raid",
    guide = "Complete the Tomb of Sargeras raid achievements listed by Blizzard.",
    criteria = {
      { achievementID = 11724, title = "Fel Turkey!" },
      { achievementID = 11683, title = "Bingo!" },
      { achievementID = 11675, title = "Sky Walker" },
      { achievementID = 11773, title = "Wax On, Wax Off" },
      { achievementID = 11699, title = "Grand Fin-ale" },
      { achievementID = 11696, title = "Grin and Bear It" },
      { achievementID = 11676, title = "Five Course Seafood Buffet" },
      { achievementID = 11674, title = "Great Soul, Great Purpose" },
      { achievementID = 11770, title = "Dark Souls" },
    },
  },
  {
    achievementID = 11987,
    title = "Glory of the Argus Raider",
    category = "raid",
    guide = "Complete the Antorus, the Burning Throne raid achievements listed by Blizzard.",
    criteria = {
      { achievementID = 11949, title = "Hard to Kill" },
      { achievementID = 11930, title = "Worm-monger" },
      { achievementID = 11915, title = "Don't Sweat the Technique" },
      { achievementID = 12129, title = "This is the War Room!" },
      { achievementID = 12030, title = "The World Revolves Around Me" },
      { achievementID = 12257, title = "Stardust Crusaders" },
      { achievementID = 11948, title = "Together We Stand" },
      { achievementID = 11928, title = "Portal Combat" },
      { achievementID = 12065, title = "Hounds Good To Me" },
      { achievementID = 12067, title = "Spheres of Influence" },
      { achievementID = 12046, title = "Remember the Titans" },
    },
  },
}

Registry:RegisterExpansion("legion", ROOTS)
