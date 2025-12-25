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
    items = RPE.Data.DefaultClassic.Items(),
    spells = RPE.Data.DefaultClassic.Spells(),
    auras = RPE.Data.DefaultClassic.Auras(),
    npcs = RPE.Data.DefaultClassic.NPC(),
    recipes = RPE.Data.DefaultClassic.Recipes(),
    extra = {
        stats = STATS_CLASSIC,
        interactions = RPE.Data.Default.INTERACTIONS_COMMON,
    },
}

return RPE.Data.DefaultClassic
