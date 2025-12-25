-- RPE/Data/Default5e.lua
-- Default 5e dataset - always present, cannot be deleted

RPE = RPE or {}
RPE.Data = RPE.Data or {}

-- Stat definitions for 5e (D&D Fifth Edition)
local STATS_5E = RPE.Data.Default5e.STATS

local function MergeTables(t1, t2)
    local result = {}
    if t1 then for k, v in pairs(t1) do result[k] = v end end
    if t2 then for k, v in pairs(t2) do result[k] = v end end
    return result
end

RPE.Data.Default5e = {
    name = "Default5e",
    version = 1,
    author = "RPEngine",
    notes = "Default 5e (D&D Fifth Edition) dataset. Cannot be deleted.",
    description = "The default D&D 5th Edition dataset with core items, spells, auras, and NPCs.",
    securityLevel = "Viewable",
    guid = "Default5e-system",
    createdAt = 0,
    updatedAt = 0,
    items = {},
    spells = {},
    auras = {},
    npcs = {},
    extra = {
        stats = STATS_5E,
        interactions = RPE.Data.Default.INTERACTIONS_COMMON,
    },
}

return RPE.Data.Default5e
