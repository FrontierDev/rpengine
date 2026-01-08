-- RPE/Data/DefaultClassic.lua
-- Default Classic dataset - always present, cannot be deleted

RPE = RPE or {}
RPE.Data = RPE.Data or {}

-- Stat definitions for Classic (5e-style)
local STATS_CLASSIC = RPE.Data.DefaultClassic.STATS

RPE.Data.DefaultClassic = {
    name = "DefaultClassic",
    version = 1,
    author = "RPEngine",
    notes = "Default Classic dataset. Cannot be deleted.",
    description = "The default RPT dataset with core items, spells, auras, NPCs, recipes, and interactions.",
    securityLevel = "Viewable",
    guid = "DefaultClassic-system",
    createdAt = 0,
    updatedAt = 0,
    items = RPE.Data.DefaultClassic.Items and RPE.Data.DefaultClassic.Items() or {},
    spells = RPE.Data.DefaultClassic.Spells and RPE.Data.DefaultClassic.Spells() or {},
    auras = RPE.Data.DefaultClassic.Auras and RPE.Data.DefaultClassic.Auras() or {},
    npcs = RPE.Data.DefaultClassic.NPC and RPE.Data.DefaultClassic.NPC() or {},
    recipes = RPE.Data.DefaultClassic.Recipes and RPE.Data.DefaultClassic.Recipes() or {},
    extra = {
        stats = STATS_CLASSIC,
        interactions = RPE.Data.Default.INTERACTIONS_COMMON,
    },
    setupWizard = {
        pages = {
            [1]={enabled=true,title="Select your Race",customRaces={},phase="onResolve",pageType="SELECT_RACE",logic="ALL",actions={}},
            [2]={enabled=true,title="Select your Primary Class",customClasses={},phase="onResolve",pageType="SELECT_CLASS",actions={},logic="ALL"},
            [3]={enabled=true,stats="STR, DEX, CON, INT, WIS, CHA",phase="onResolve",pageType="SELECT_STATS",statType="STANDARD_ARRAY",title="Select your Primary Stats",maxPerStat="",incrementBy=1,logic="ALL",actions={},maxPoints=""},
            [4]={enabled=true,stats="ACROBATICS,ANIMAL HANDLING,ARCANA,ATHLETICS,DECEPTION,HISTORY,INSIGHT,INTIMIDATION,INVESTIGATION,MEDICINE,NATURE,PERCEPTION,PERFORMANCE,PERSUASION,RELIGION,SLEIGHT OF HAND,STEALTH,SURVIVAL",phase="onResolve",pageType="SELECT_STATS",statType="SIMPLE_ASSIGN",title="Select your Proficiencies",maxPerStat=3,incrementBy=1,logic="ALL",actions={},maxPoints=10},
            [5]={enabled=true,phase="onResolve",pageType="SELECT_SPELLS",firstRankOnly=true,maxSpellPoints=8,restrictToRace=true,title="Select your Spells",maxSpellsTotal=8,allowRacial=true,actions={},logic="ALL",restrictToClass=false},
            [6]={enabled=true,excludeTags="",phase="onResolve",pageType="SELECT_ITEMS",maxAllowance=3300,allowedCategory="EQUIPMENT",title="Select your Equipment",spareChange=true,actions={},includeTags="starter",logic="ALL",maxRarity="uncommon"},
            [7]={enabled=true,excludeTags="",phase="onResolve",pageType="SELECT_ITEMS",maxAllowance=300,allowedCategory="CONSUMABLE",title="Select your Consumables",spareChange=true,actions={},includeTags="tier_0",logic="ALL",maxRarity="uncommon"},
            [8]={enabled=true,professionPointsAllowance=2,title="Select your Professions",maxLevel=1,phase="onResolve",pageType="SELECT_PROFESSIONS",actions={},logic="ALL"},
            [9]={enabled=true,title="Select your Languages",phase="onResolve",pageType="SELECT_LANGUAGE",logic="ALL",actions={}},
        }
    }
}

return RPE.Data.DefaultClassic

