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
        name = "Summoned Beast",
        displayId = 52035,
        fileDataId = 1579537,
        team = 1,
        unitType = "Undead",
        unitSize = "Medium",
        summonType = "Minion",
        cam = 0.7,
        rot = 0.75,
        z = 0,
        hp = {
            base = 200,
            perPlayer = 0
        },
        stats = {
            AC = 10,
            DEFENCE = 1,
            DODGE = 1,
            PARRY = 1,
            BLOCK = 1,
            MELEE_AP = 60,
            MELEE_HIT = 2,
            RANGED_AP = 60,
            RANGED_HIT = 2,
            SPELL_AP = 60,
            SPELL_HIT = 2,
            SHADOW_RESIST = 5,
        },
        spells = {
            [1] = "spell-oCSC0001",
        },
    },

    ["NPC-dkpet"] = {
        id = "NPC-dkpet",
        name = "Risen Ghoul",
        displayId = 52035,
        fileDataId = 1579537,
        team = 1,
        unitType = "Undead",
        unitSize = "Medium",
        summonType = "Minion",
        cam = 0.7,
        rot = 0.75,
        z = 0,
        hp = {
            base = 200,
            perPlayer = 0
        },
        stats = {
            AC = 10,
            DEFENCE = 1,
            DODGE = 1,
            PARRY = 1,
            BLOCK = 1,
            MELEE_AP = 60,
            MELEE_HIT = 2,
            RANGED_AP = 60,
            RANGED_HIT = 2,
            SPELL_AP = 60,
            SPELL_HIT = 2,
            SHADOW_RESIST = 5,
        },
        spells = {
            [1] = "spell-oCSC0001",
        },
    },
    
    ["NPC-wlImp"] = {
        id = "NPC-wlImp",
        name = "Summoned Imp",
        displayId = 4449,
        fileDataId = 1098889,
        team = 1,
        unitType = "Demon",
        unitSize = "Small",
        summonType = "Minion",
        cam = 1.2,
        rot = -0.1,
        z = -0.05,
        hp = {
            base = 200,
            perPlayer = 0
        },
        stats = {
            AC = 10,
            DEFENCE = 1,
            DODGE = 5,
            PARRY = 1,
            BLOCK = 1,
            MELEE_AP = 40,
            MELEE_HIT = 2,
            RANGED_AP = 40,
            RANGED_HIT = 2,
            SPELL_AP = 60,
            SPELL_HIT = 4,
            FEL_RESIST = 5,
        },
        spells = {
            [1] = "spell-oCSC0001",
            [2] = "spell-oCSMaFir001",
        },
    },

    ["NPC-wlVw"] = {
        id = "NPC-wlVw",
        name = "Summoned Voidwalker",
        displayId = 1130,
        fileDataId = 1410363,
        team = 1,
        unitType = "Demon",
        unitSize = "Medium",
        summonType = "Minion",
        cam = 1.2,
        rot = -0.1,
        z = -0.05,
        hp = {
            base = 300,
            perPlayer = 0
        },
        stats = {
            AC = 10,
            DEFENCE = 5,
            DODGE = 5,
            PARRY = 1,
            BLOCK = 1,
            MELEE_AP = 50,
            MELEE_HIT = 4,
            RANGED_AP = 20,
            RANGED_HIT = 2,
            SPELL_AP = 50,
            SPELL_HIT = 2,
            THREAT = 2,
            SHADOW_RESIST = 5,
        },
        spells = {
            [1] = "spell-oCSC0001",
            [2] = "spell-oCSWaDes001"
        },
    },

}

function RPE.Data.DefaultClassic.NPC()
    local items = {}
    for k,v in pairs(RPE.Data.DefaultClassic.NPC_LIST) do
        items[k] = v
    end
    return items
end