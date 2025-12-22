RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.DefaultClassic = RPE.Data.DefaultClassic or {}

RPE.Data.DefaultClassic.NPC_LIST = {
    ["NPC-04c32e80"] = {
        id = "NPC-04c32e80",
        name = "Raider's Training Dummy",
        displayId = 99693,
        fileDataId = 1064205,
        team = 1,
        unitType = "Mechanical",
        unitSize = "Medium",
        summonType = "Minion",
        cam = 1,
        rot = 0.6,
        z = -0.05,
        hp = {
            base = 300,
            perPlayer = 0
        },
        stats = {
            AC = 0,
            DEFENCE = 0,
            DODGE = 0,
            PARRY = 0,
            BLOCK = 0,
            MELEE_AP = 20,
            MELEE_HIT = 2,
            RANGED_AP = 20,
            RANGED_HIT = 2,
            SPELL_AP = 20,
            SPELL_HIT = 2
        },
        spells = {
            [1] = "spell-oCSMaFir001",
            [2] = "spell-oCSPaHol001",
            [3] = "spell-oCSC0001",
            [4] = "spell-oCSMaArc002",
            [5] = "spell-oCSWaArm004",
            [6] = "spell-oCSWaAff003",
            [7] = "spell-oCSWaFur001b",
        },
    },

    ["NPC-summonedpet"] = {
        id = "NPC-summonedpet",
        name = "Summoned Pet",
        displayId = 99693,
        fileDataId = 1064205,
        team = 1,
        unitType = "Beast",
        unitSize = "Medium",
        summonType = "Pet",
        cam = 1,
        rot = 0.6,
        z = -0.05,
        hp = {
            base = 200,
            perPlayer = 0
        },
        stats = {
            AC = 0,
            DEFENCE = 0,
            DODGE = 0,
            PARRY = 0,
            BLOCK = 0,
            MELEE_AP = 100,
            MELEE_HIT = 2,
            RANGED_AP = 100,
            RANGED_HIT = 2,
            SPELL_AP = 100,
            SPELL_HIT = 2
        },
        spells = {
            [1] = "spell-oCSC0001",
        },
    }
}

function RPE.Data.DefaultClassic.NPC()
    local items = {}
    for k,v in pairs(RPE.Data.DefaultClassic.NPC_LIST) do
        items[k] = v
    end
    return items
end