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
    guid = "DefaultClassic-system",
    createdAt = 0,
    updatedAt = 0,
    items = {
        -- Weapon: Shortsword
        shortsword_classic = {
            id = "shortsword_classic",
            name = "Shortsword",
            category = "EQUIPMENT",
            icon = 237451, -- INV_Sword_04
            stackable = false,
            maxStack = 1,
            description = "A simple blade, easy to wield.",
            rarity = "common",
            data = {
                slot = "mainhand",
                stat_MELEE_AP = 1,
                stat_INT = 5,
            },
        },
        -- Chest: Leather Armor
        leather_armor_classic = {
            id = "leather_armor_classic",
            name = "Leather Armor",
            category = "EQUIPMENT",
            icon = 231001, -- INV_Chest_Leather_09
            stackable = false,
            maxStack = 1,
            description = "Flexible armor made from toughened hide.",
            rarity = "uncommon",
            data = {
                slot = "chest",
                stat_AC = 2,
            },
        },
        -- Crafting Material: Iron Ore
        iron_ore_classic = {
            id = "iron_ore_classic",
            name = "Iron Ore",
            category = "MATERIAL",
            icon = 134572, -- INV_Ore_Iron_01
            stackable = true,
            maxStack = 20,
            description = "A chunk of iron ore, useful for smithing.",
            rarity = "common",
            data = {},
        },
    },
    spells = {},
    auras = {},
    npcs = {},
    extra = {
        stats = STATS_CLASSIC,
        interactions = RPE.Data.Default.INTERACTIONS_COMMON,
    },
}

return RPE.Data.DefaultClassic
