RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.DefaultClassic = RPE.Data.DefaultClassic or {}

RPE.Data.DefaultClassic.AURAS_RACIAL = {
    ------ Human Racial Traits ------
    -- Perception (Advantage on PERCEPTION rolls)
    ["aura-oCARaHum1"] = {
        id = "aura-oCARaHum1",
        name = "Perception",
        description = "You have advantage on Perception rolls.",
        icon = 136090,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:human"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "PERCEPTION",
                value = "1"
            }
        }
    },

    -- The Human Spirit (Increases WIS by 1)
    ["aura-oCARaHum2"] = {
        id = "aura-oCARaHum2",
        name = "The Human Spirit",
        description = "Increases your Wisdom by 1.",
        icon = 132874,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:human"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "WIS",
                value = "1"
            }
        }
    },

    -- Diplomacy (Increases CHA by 1)
    ["aura-oCARaHum3"] = {
        id = "aura-oCARaHum3",
        name = "Diplomacy",
        description = "Increases your Charisma by 1.",
        icon = 134328,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:human"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CHA",
                value = "1"
            }
        }
    },

    ------ Dwarf Racial Traits ------
    -- Gun Specialisation (RANGED_HIT increased by 2 when using a gun)
    ["aura-oCARaDwa1"] = {
        id = "aura-oCARaDwa1",
        name = "Gun Specialisation",
        description = "Increases your Ranged critical strike rating by 1 when using a gun.",
        icon = 134537,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:dwarf",
            [2] = "equip.ranged.gun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1",
            }
        }
    },

    -- Frost Resistance (Increases FROST_RESIST by 2)
    ["aura-oCARaDwa2"] = {
        id = "aura-oCARaDwa2",
        name = "Frost Resistance",
        description = "Increases your Frost Resistance by 2.",
        icon = 135865,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:dwarf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "FROST_RESIST",
                value = "2"
            }
        }
    },

    -- Dwarven Constitution (Increases CON by 2)
    ["aura-oCARaDwa3"] = {
        id = "aura-oCARaDwa3",
        name = "Dwarven Constitution",
        description = "Increases your Constitution by 2.",
        icon = 136112,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:dwarf",
            [2] = "race:darkiron"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "2"
            }
        }
    },

    -- Stoneform (for 2 turns, increase armour and grant immunity to "poison", "disease")
    ["aura-oCARaDwa4"] = {
        id = "aura-oCARaDwa4",
        name = "Stoneform",
        description = "Increases your armour by 10% and grants immunity to poison and disease effects for 2 turns.",
        icon = 136225,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "buff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = { "POISON", "DISEASE" },
            tags = {
                [1] = "poison",
                [2] = "disease"
            },
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARMOUR",
                value = "10"
            }
        }
    },

    ------ Gnome Racial Traits ------
    -- Arcane Resistance (Increases ARCANE_RESIST by 2)
    ["aura-oCARaGno1"] = {
        id = "aura-oCARaGno1",
        name = "Arcane Resistance",
        description = "Increases your Arcane Resistance by 2.",
        icon = 136116,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:gnome"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARCANE_RESIST",
                value = "2"
            }
        }
    },

    -- Expansive Mind (Increases INT by 2)
    ["aura-oCARaGno2"] = {
        id = "aura-oCARaGno2",
        name = "Expansive Mind",
        description = "Increases your maximum mana by 10%.",
        icon = 132864,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:gnome",
            [2] = "race:mechagnome"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_MANA",
                value = "10"
            }
        }
    },

    -- Escape Artist (Advantage on DODGE rolls)
    ["aura-oCARaGno3"] = {
        id = "aura-oCARaGno3",
        name = "Escape Artist",
        description = "You gain one level of advantage on Dodge rolls.",
        icon = 132294,
        isTrait = true,
        isHelpful = true,
        hidden = true,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:gnome"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    ------ Meechagnome Racial Traits ------
    -- Combat Analysis (each turn, gain 2 MELEE_AP, 2 RANGED_AP and 2 SPELL_AP, stacking 10 times)
    ["aura-oCARaMec1"] = {
        id = "aura-oCARaMec1",
        name = "Combat Analysis",
        description = "Gain 2 melee and ranged attack power and 2 spell power per stack each turn. Stacks up to 10 times.",
        icon = 3192685,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 10,
        tags = {
            [1] = "race:mechagnome"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "APPLY_AURA",
                            args = {
                                auraId = "aura-oCARaMec1-Buff"
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCARaMec1-Buff"] = {
        id = "aura-oCARaMec1-Buff",
        name = "Combat Analysis",
        description = "Attack power increased by 2 per stack.",
        icon = 3192685,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 10,
        tags = {
            [1] = "buff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "RANGED_AP",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "SPELL_AP",
                value = "2"
            }
        }
    },

    ------ Night Elf Racial Traits ------
    -- Nature Resistance (Increases NATURE_RESIST by 2)
    ["aura-oCARaNel1"] = {
        id = "aura-oCARaNel1",
        name = "Nature Resistance",
        description = "Increases your Nature Resistance by 2.",
        icon = 136094,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:nightelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "2"
            }
        }
    },

    -- Quickness (advantage on DODGE rolls)
    ["aura-oCARaNel2"] = {
        id = "aura-oCARaNel2",
        name = "Quickness",
        description = "You have advantage on Dodge rolls.",
        icon = 132279,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:nightelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    -- Shadowmeld (advantage on STEALTH rolls)
    ["aura-oCARaNel3"] = {
        id = "aura-oCARaNel3",
        name = "Shadowmeld",
        description = "You have advantage on Stealth rolls.",
        icon = 132089,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:nightelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "STEALTH",
                value = "1"
            }
        }
    },

    -- Draenei Racial Traits ------
    -- Shadow Resistance (Increases SHADOW_RESIST by 2)
    ["aura-oCARaDra1"] = {
        id = "aura-oCARaDra1",
        name = "Shadow Resistance",
        description = "Increases your Shadow Resistance by 2.",
        icon = 136152,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:draenei"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SHADOW_RESIST",
                value = "2"
            }
        }
    },

    -- Heroic Presence (Increases STR, DEX and INT by 1)
    ["aura-oCARaDra2"] = {
        id = "aura-oCARaDra2",
        name = "Heroic Presence",
        description = "Increases your Strength, Dexterity and Intelligence by 1.",
        icon = 133123,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:draenei",
            [2] = "race:lightforged"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "1"
            }
        }
    },

    -- Gift of the Naaru (tick heal 10 HP per turn for 6 turns, increase HEAL_TAKEN by 0.1)
    ["aura-oCARaDra3"] = {
        id = "aura-oCARaDra3",
        name = "Gift of the Naaru",
        description = "Heals you for 10 health per turn for 6 turns and increases healing received by 10%.",
        icon = 135923,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "hot",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "HEAL",
                            args = {
                                amount = "10",
                                targets = { targeter = "TARGET" }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_TAKEN",
                value = "0.1"
            }
        }
    },

    ------ Worgen Racial Traits ------
    -- Aberration (nature and shadow resistance increased by 1)
    ["aura-oCARaWor1"] = {
        id = "aura-oCARaWor1",
        name = "Aberration",
        description = "Increases your Nature and Shadow Resistance by 1.",
        icon = 136121,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:worgen"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SHADOW_RESIST",
                value = "1"
            }
        }
    },

    -- Viciousness (MELEE_CRIT, RANGED_CRIT and SPELL_CRIT increased by 1)
    ["aura-oCARaWor2"] = {
        id = "aura-oCARaWor2",
        name = "Viciousness",
        description = "Increases your Melee, Ranged and Spell critical strike rating by 1.",
        icon = 132203,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:worgen"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1",
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1",
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "1",
            }
        }
    },

    ------ Orc Racial Traits ------
    -- Axe Specialisation (MELEE_HIT increased by 2 when using an axe)
    ["aura-oCARaOrc1"] = {
        id = "aura-oCARaOrc1",
        name = "Axe Specialisation",
        description = "Increases your Melee hit rating by 2 when using an axe.",
        icon = 132316,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:orc",
            [2] = "equip.melee.axe",
            [3] = "race:magharorc",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_HIT",
                value = "2",
            }
        }
    },

    -- Hardiness (Increases CON and STR by 1)
    ["aura-oCARaOrc2"] = {
        id = "aura-oCARaOrc2",
        name = "Hardiness",
        description = "Increases your Constitution and Strength by 1.",
        icon = 133125,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:orc",
            [2] = "race:magharorc",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "1"
            }
        }
    },

    -- Blood Fury (20% MELEE_AP and reduce HEAL_TAKEN by 0.5 for 2 turns)
    ["aura-oCARaOrc3"] = {
        id = "aura-oCARaOrc3",
        name = "Blood Fury",
        description = "Increases your melee attack power by 20% but reduces all healing you receive by 50% for 2 turns.",
        icon = 135726,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:orc",
            [2] = "buff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "HEAL_TAKEN",
                value = "0.5"
            }
        }
    },

    ------ Maghar Racial Traits ------
    -- Nature Resistance (Increases NATURE_RESIST by 2)
    ["aura-oCARaMag1"] = {
        id = "aura-oCARaMag1",
            name = "Nature Resistance",
            description = "Increases your Nature Resistance by 2.",
            icon = 136094,
            isTrait = true,
            isHelpful = true,
            hidden = false,
            unpurgable = true,
            stackingPolicy = "REFRESH_DURATION",
            conflictPolicy = "KEEP_HIGHER",
            uniqueByCaster = false,
            removeOnDamageTaken = false,
            maxStacks = 1,
            tags = {
                [1] = "race:magharorc"
            },
            triggers = {},
            crowdControl = {
                blockAllActions = false,
                blockActionsByTag = {},
                slowMovement = 0,
                failDefencesByStats = {},
                failAllDefences = false
            },
            immunity = {
                dispelTypes = {},
                tags = {},
                damageSchools = {},
                helpful = false,
                harmful = false,
                ids = {}
            },
            modifiers = {
                {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "2"
                }
            }
    },

    ------ Troll Racial Traits ------
    -- Regeneration (HEAL_TAKEN increased by 0.1, and heals for 3% of max health every turn)
    ["aura-oCARaTro1"] = {
        id = "aura-oCARaTro1",
        name = "Regeneration",
        description = "Increases all healing you receive by 10% and heals you for 3% of your maximum health at the start of each of your turns.",
        icon = 136077,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:troll",
            [2] = "race:zandalari"
        }, 
        tick = {
            period = 1,
            actions = {
                {
                    targets = { ref = "caster" },
                    key = "HEAL",
                    args = { amount = "0.03 * $MAX_HEALTH$" }
                }
            }
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_TAKEN",
                value = "0.1"
            }
        }
    },

    -- Crossbow Specialisation (RANGED_CRIT increased by 1 when using a crossbow)
    ["aura-oCARaTro2"] = {
        id = "aura-oCARaTro2",
        name = "Crossbow Specialisation",
        description = "Increases your Ranged critical strike rating by 1 when using a crossbow.",
        icon = 135531,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:troll",
            [2] = "equip.ranged.crossbow"   
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1",
            }
        }
    },

    ------ Zandalari Racial Traits ------
    -- Embrace of Akunda (Increase your HEAL_POWER by 20% of your MELEE_AP)
    ["aura-oCARaZan1"] = {
        id = "aura-oCARaZan1",
        name = "Embrace of Akunda",
        description = "Increases your healing power by 20% of your melee attack power.",
        icon = 2446015,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:zandalari"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "0.2 * $stat.MELEE_AP$"
            }
        }
    },

    -- Embrace of Bwonsamdi (copy from undead racial trait "Touch of the Grave")
    ["aura-oCARaZan2"] = {
        id = "aura-oCARaZan2",
        name = "Embrace of Bwonsamdi",
        description = "Your successful attacks deal an additional 5 Shadow damage and heal you for 5 health.",
        icon = 2446016,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:zandalari"
        },
        triggers = {
            {
                event = "ON_HIT",
                actions = {
                    {
                        targets = { ref = "target" },
                        key = "DAMAGE",
                        args = { amount = "5", school = "Shadow" }
                    },
                    {
                        targets = { ref = "caster" },
                        key = "HEAL",
                        args = { amount = "5" }
                    }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Embrace of Kimbul (ON_HIT: cause the target to bleed for 5 Physical damage, stacks 3 times, last 2 turns)
    ["aura-oCARaZan3"] = {
        id = "aura-oCARaZan3",
        name = "Embrace of Kimbul",
        description = "Your attacks cause the target to bleed for 5 Physical damage per stack, stacking up to 3 times, lasting 2 turns.",
        icon = 2446018,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:zandalari"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCARaZan3-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCARaZan3-Debuff"] = {
        id = "aura-oCARaZan3-Debuff",
        name = "Embrace of Kimbul",
        description = "Taking 5 Physical damage per stack per turn.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 2
        },
        icon = 2446018,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "bleed"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "DAMAGE",
                            args = {
                                amount = "5",
                                school = "Physical",
                                targets = { targeter = "TARGET" }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Embrace of Krag'wa (ON_HIT_TAKEN: gain MAX_HEALTH and ARMOR equal to 20% of your MELEE_AP for 2 turns)
    ["aura-oCARaZan4"] = {
        id = "aura-oCARaZan4",
        name = "Embrace of Krag'wa",
        description = "Whenever you take damage, gain maximum health and armor equal to 20% of your melee attack power for 2 turns.",
        icon = 2446019,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:zandalari"
        },
        triggers = {
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCARaZan4-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCARaZan4-Buff"] = {
        id = "aura-oCARaZan4-Buff",
        name = "Embrace of Krag'wa",
        description = "Maximum health and armor increased by 20% of melee attack power.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 2
        },
        icon = 2446019,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "zandalaritroll"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MAX_HEALTH",
                value = "0.2 * $stat.MELEE_AP$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARMOR",
                value = "0.2 * $stat.MELEE_AP$"
            }
        }
    },

    -- Embrace of Pa'ku (ON_CRIT: Increase MELEE_CRIT, RANGED_CRIT and SPELL_CRIT by 1 for 2 turns)
    ["aura-oCARaZan5"] = {
        id = "aura-oCARaZan5",
        name = "Embrace of Pa'ku",
        description = "Your critical strikes increase your Melee, Ranged and Spell critical strike rating by 1 for 2 turns.",
        icon = 2446020,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:zandalari"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCARaZan5-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCARaZan5-Buff"] = {
        id = "aura-oCARaZan5-Buff",
        name = "Embrace of Pa'ku",
        description = "Melee, Ranged and Spell critical strike rating increased by 1.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 2
        },
        icon = 2446020,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "zandalaritroll"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "1"
            }
        }
    },

    ------ Kul Tiran Racial Traits ------
    -- Rime of the Ancient Mariner (nature and frost resistance increased by 1)
    ["aura-oCARaKul1"] = {
        id = "aura-oCARaKul1",
        name = "Rime of the Ancient Mariner",
        description = "Increases your Nature and Frost Resistance by 1.",
        icon = 2447784,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:kultiran"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
            source = "CASTER",
            snapshot = "DYNAMIC",
            scaleWithStacks = "",
            mode = "ADD",
            stat = "NATURE_RESIST",
            value = "1"
            },
            {
            source = "CASTER",
            snapshot = "DYNAMIC",
            scaleWithStacks = "",
            mode = "ADD",
            stat = "FROST_RESIST",
            value = "1"
            }
        }
    },

    -- Brush it Off (armor increased by 10%. ON_HIT_TAKEN: heal for 5 hp per turn for 3 turns)
    ["aura-oCARaKul2"] = {
        id = "aura-oCARaKul2",
        name = "Brush it Off",
        description = "Armor increased by 10%. Whenever you take damage, heal for 5 health per turn for 3 turns.",
        icon = 2447780,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:kultiran"
        },
        triggers = {
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCARaKul2-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    ["aura-oCARaKul2-Buff"] = {
        id = "aura-oCARaKul2-Buff",
        name = "Brush it Off",
        description = "Restoring 5 health per turn.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 3
        },
        icon = 2447780,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "kultiran"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "HEAL",
                            args = {
                                amount = "5",
                                targets = { targeter = "TARGET" }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ------ Dark Iron Dwarf Racial Traits ------
    -- Forged in Flames (armour increased by 10% and FIRE_RESIST increased by 2)
    ["aura-oCARaDia1"] = {
        id = "aura-oCARaDia1",
        name = "Forged in Flames",
        description = "Armour increased by 10%. Fire resistance increased by 2.",
        icon = 1786407,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:darkiron"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "FIRE_RESIST",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    -- Fireblood (same as stoneform)
    ["aura-oCARaDia2"] = {
        id = "aura-oCARaDia2",
        name = "Fireblood",
        description = "Immune to all poison, disease, curse, and bleed effects. Melee and ranged attack power and spell power increased by 2 turns.",
        icon = 1786406,
        isTrait = false,
        isHelpful = true,
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 2
        },
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:darkiron"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = { "POISON", "DISEASE", "CURSE" },
            tags = {
                [1] = "poison",
                [2] = "disease",
                [3] = "curse",
                [4] = "bleed"
            },
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "RANGED_AP",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "20"
            }
        }
    },

    ------ Pandaren Racial Traits ------
    -- Inner Peace (Increases HEAL_TAKEN by 0.1)
    ["aura-oCSPanInt001"] = {
        id = "aura-oCSPanInt001",
        name = "Inner Peace",
        description = "Healing received increased by 10%.",
        icon = 136107,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:pandaren"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEAL_TAKEN",
                value = "10"
            }
        }
    },

    -- Quaking Palm (incapacitate for 1 turn, break on damage taken)
    ["aura-oCSPanInt003"] = {
        id = "aura-oCSPanInt003",
        name = "Quaking Palm",
        description = "Incapacitated for 1 turn. Breaks on damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 572035,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "pandaren",
            [2] = "incapacitate"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Epicurean (Increases MAX_HEALTH and MAX_MANA by 5%)
    ["aura-oCSPanInt002"] = {
        id = "aura-oCSPanInt002",
        name = "Epicurean",
        description = "Maximum health and maximum mana increased by 5%.",
        icon = 571692,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:pandaren"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "5"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_MANA",
                value = "5"
            }
        }
    },

    ------ Undead Racial Traits ------
    -- Shadow Resistance (Increases SHADOW_RESIST by 2)
    ["aura-oCARaUnd1"] = {
        id = "aura-oCARaUnd1",
        name = "Shadow Resistance",
        description = "Increases your Shadow Resistance by 2.",
        icon = 136123,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:undead"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SHADOW_RESIST",
                value = "2"
            }
        }
    },

    -- Touch of the Grave (ON_HIT: deal 5 Shadow damage and heal for 5 health)
    ["aura-oCARaUnd2"] = {
        id = "aura-oCARaUnd2",
        name = "Touch of the Grave",
        description = "Your successful attacks deal an additional 5 Shadow damage and heal you for 5 health.",
        icon = 136169,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:undead"
        },
        triggers = {
            {
                event = "ON_HIT",
                actions = {
                    {
                        targets = { ref = "target" },
                        key = "DAMAGE",
                        args = { amount = "5", school = "Shadow" }
                    },
                    {
                        targets = { ref = "caster" },
                        key = "HEAL",
                        args = { amount = "5" }
                    }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Will of the Forsaken (immune to "sleep" and "charm" effects)
    ["aura-oCARaUnd3"] = {
        id = "aura-oCARaUnd3",
        name = "Will of the Forsaken",
        description = "You are immune to sleep and charm effects.",
        icon = 136206,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:undead"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {
                "sleep", "charm"
            },
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ------ Blood Elf Racial Traits ------
    -- Arcane Resistance
    ["aura-oCARaBle1"] = {
        id = "aura-oCARaBle1",
        name = "Arcane Resistance",
        description = "Increases your Arcane Resistance by 2.",
        icon = 136116,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:bloodelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARCANE_RESIST",
                value = "2"
            }
        }
    },

    -- Arcane Acuity 
    ["aura-oCARaBle2"] = {
        id = "aura-oCARaBle2",
        name = "Arcane Acuity",
        description = "Increases your Melee, Ranged and Spell critical strike rating by 1.",
        icon = 135754,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:bloodelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1",
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1",
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "1",
            }
        }
    },

    ------ Goblin Racial Traits ------
    -- Gift of the Gob (Increases CHA by 2)
    ["aura-oCARaGob1"] = {
        id = "aura-oCARaGob1",
        name = "Gift of the Gob",
        description = "Increases your Charisma by 2.",
        icon = 369760,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:goblin"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CHA",
                value = "2"
            }
        }
    },

    ------ Vulpera Racial Traits ------
    -- Fire Resistance (Increases FIRE_RESIST by 2)
    ["aura-oCARaVul1"] = {
        id = "aura-oCARaVul1",
        name = "Fire Resistance",
        description = "Increases your Fire Resistance by 2.",
        icon = 3193417,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:vulpera"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "FIRE_RESIST",
                value = "2"
            }
        }
    },

    -- Nimbleness (increases DEX by 2)
    ["aura-oCARaVul2"] = {
        id = "aura-oCARaVul2",
        name = "Nimbleness",
        description = "Increases your Dexterity by 2.",
        icon = 3193418,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:vulpera"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "2"
            }
        }
    },

    ------ Lightforged Draenei Racial Traits ------
    -- Holy Providence (Increases HOLY_RESIST by 2 and HEAL_POWER by 10)
    ["aura-oCARaLfd1"] = { 
    id = "aura-oCARaLfd1",
        name = "Holy Providence",
        description = "Increases your Holy Resistance by 2 and your healing power by 10.",
        icon = 1723996,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:lightforged"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
            source = "CASTER",
            snapshot = "DYNAMIC",
            scaleWithStacks = "",
            mode = "ADD",
            stat = "HOLY_RESIST",
            value = "2"
            },
            {
            source = "CASTER",
            snapshot = "DYNAMIC",
            scaleWithStacks = "",
            mode = "ADD",
            stat = "HEAL_POWER",
            value = "10"
            }
        }
    },

    -- Light's Reckoning (ON_DEATH: heal ALL_ALLIES maxTargets 3 for 50% of your max mana, and damage ALL_ENEMIES maxTargets 3 for 50% of your max health)
    ["aura-oCARaLfd2"] = {
        id = "aura-oCARaLfd2",
        name = "Light's Reckoning",
        description = "When you are reduced to 0 HP, heal all allies for 50% of your maximum mana and deal damage to all enemies for 33% of your maximum health.",
        icon = 1723994,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:lightforged"
        },
        triggers = {
            {
                event = "ON_DEATH",
                actions = {
                    {
                        targets = { ref = "ALL_ALLIES", maxTargets = 3 },
                        key = "HEAL",
                        args = { amount = "0.5 * $MAX_MANA$" }
                    },
                    {
                        targets = { ref = "ALL_ENEMIES", maxTargets = 3 },
                        key = "DAMAGE",
                        args = { amount = "0.33 * $MAX_HEALTH$", school = "Holy" }
                    }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ------ Void Elf Racial Traits ------
    -- Chill of Night (Increases SHADOW_RESIST by 2)
    ["aura-oCARaVoi1"] = {
        id = "aura-oCARaVoi1",
        name = "Chill of Night",
        description = "Increases your Shadow Resistance by 2.",
        icon = 1723989,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:voidelf"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SHADOW_RESIST",
                value = "2"
            }
        }
    },

    -- Entropic Embrace (ON_CRIT: apply aura which deals 2 Shadow and 2 Frost damage each turn)
    ["aura-oCARaVoi2"] = {
        id = "aura-oCARaVoi2",
        name = "Entropic Embrace",
        description = "Your critical strikes apply a debuff dealing 2 Shadow and 2 Frost damage each turn for 3 turns.",
        icon = 1723992,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:voidelf"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCARaVoi2-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCARaVoi2-Debuff"] = {
        id = "aura-oCARaVoi2-Debuff",
        name = "Entropic Embrace",
        description = "Taking 2 Shadow and 2 Frost damage per turn.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 3
        },
        icon = 1723992,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "dot"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "DAMAGE",
                            args = {
                                amount = "2",
                                school = "Shadow",
                                targets = { targeter = "TARGET" }
                            }
                        },
                        [2] = {
                            key = "DAMAGE",
                            args = {
                                amount = "2",
                                school = "Frost",
                                targets = { targeter = "TARGET" }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ------ Highmountain Tauren and Tauren Racial Traits ------
    -- Endurance (Increases CON by 2)
    ["aura-oCARaTau1"] = {
        id = "aura-oCARaTau1",
        name = "Endurance",
        description = "Increases your Constitution by 2.",
        icon = 136112,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:tauren",
            [2] = "race:highmountaintauren"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "2"
            }
        }
    },

    -- Nature Resistance (Increases NATURE_RESIST by 2)
    ["aura-oCARaTau2"] = {
        id = "aura-oCARaTau2",
        name = "Nature Resistance",
        description = "Increases your Nature Resistance by 2.",
        icon = 136094,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:tauren",
            [2] = "race:highmountaintauren"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "2"
            }
        }
    },

    -- Brawn (MELEE_CRIT_MULT increased by 0.1 and HEAL_POWER increased by 10)
    ["aura-oCARaTau3"] = {
        id = "aura-oCARaTau3",
        name = "Brawn",
        description = "Increases your Melee critical strike damage by 10% and your healing power by 10.",
        icon = 134174,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:tauren",
            [2] = "race:highmountaintauren"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT_MULT",
                value = "0.1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "10"
            }
        }
    },

    ------ Dracthyr Racial Traits ------
    -- Awakened (increases MELEE_HIT, RANGED_HIT and SPELL_HIT by 1)
    ["aura-oCARaDry0"] = {
        id = "aura-oCARaDry0",
        name = "Awakened",
        description = "Melee, ranged and spell hit rating increased by 1.",
        icon = 4622481,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:dracthyr"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_HIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_HIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_HIT",
                value = "1"
            }
        }
    },

    -- Discerning Eye (copy from human racial "Perception")
    ["aura-oCARaDry1"] = {
        id = "aura-oCARaDry1",
        name = "Discerning Eye",
        description = "You have advantage on Perception rolls.",
        icon = 4630415,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:dracthyr"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "PERCEPTION",
                value = "1"
            }
        }
    },

    ------ Nightborne Racial Traits ------
    -- Magical Affinity (INT increased by 2)
    ["aura-oCARaNbn1"] = {
        id = "aura-oCARaNbn1",
        name = "Magical Affinity",
        description = "Increases your Intelligence by 2.",
        icon = 1723986,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:nightborne"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "2"
            }
        }
    },

    -- Arcane Resistance
    ["aura-oCARaNbn2"] = {
        id = "aura-oCARaNbn2",
        name = "Arcane Resistance",
        description = "Increases your Arcane Resistance by 2.",
        icon = 136116,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "race:nightborne"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
            source = "CASTER",
            snapshot = "DYNAMIC",
            scaleWithStacks = "",
            mode = "ADD",
            stat = "ARCANE_RESIST",
            value = "2"
            }
        }
    },

}

RPE.Data.DefaultClassic.AURAS_CONSUMABLE = {
    -- Strength
    ["aura-oCAScrStr"] = {
        id = "aura-oCAScrStr",
        name = "Strength",
        description = "Increases your Strength by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134938,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    -- Agility
    ["aura-oCAScrDex"] = {
        id = "aura-oCAScrDex",
        name = "Agility",
        description = "Increases your Agility by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134938,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    -- Stamina
    ["aura-oCAScrSta"] = {
        id = "aura-oCAScrSta",
        name = "Stamina",
        description = "Increases your Stamina by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134943,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    -- Intellect
    ["aura-oCAScrInt"] = {
        id = "aura-oCAScrInt",
        name = "Intellect",
        description = "Increases your Intellect by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134937,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    -- Spirit
    ["aura-oCAScrSpi"] = {
        id = "aura-oCAScrSpi",
        name = "Spirit",
        description = "Increases your Spirit by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134937,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "WIS",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    ["aura-oCAScrArmor"] = {
        id = "aura-oCAScrArmor",
        name = "Armor",
        description = "Increases your Armor by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 135975,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARMOR",
                value = "$amount$",
                perRank = "2"
            }
        }
    },

    ["aura-oCCElixirStr"] = {
        id = "aura-oCCElixirStr",
        name = "Elixir of Strength",
        description = "Increases your Strength by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134838,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    ["aura-oCCElixirDex"] = {
        id = "aura-oCCElixirDex",
        name = "Elixir of Agility",
        description = "Increases your Agility by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134873,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    ["aura-oCCElixirCon"] = {
        id = "aura-oCCElixirCon",
        name = "Elixir of Fortitude",
        description = "Increases your Fortitude by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134824,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    ["aura-oCCElixirInt"] = {
        id = "aura-oCCElixirInt",
        name = "Elixir of Intellect",
        description = "Increases your Intellect by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134866,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "$amount$",
                perRank = "1"
            }
        }
    },

    ["aura-oCCElixirWis"] = {
        id = "aura-oCCElixirWis",
        name = "Elixir of Spirit",
        description = "Increases your Spirit by $amount$.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 0
        },
        icon = 134859,
        isTrait = false,
        isHelpful = true,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "consumable"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "WIS",
                value = "$amount$",
                perRank = "1"
            }
        }
    }
}

RPE.Data.DefaultClassic.AURAS_PALADIN = {
    ------ Paladin Seals (Traits) ------
    -- Seal of Righteousness (damage on hit)
    ["aura-oCAPaSeal1"] = {
        id = "aura-oCAPaSeal1",
        name = "Seal of Righteousness",
        description = "Your successful attacks deal an additional $[1].amount$ $[1].school$ damage.",
        icon = 132325,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        requirements = {
            "equip.mainhand"  -- Requires a main hand weapon to use this seal
        },
        tags = {
            [1] = "class:paladin"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "5d2", school = "Holy" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Seal of Light (heal on hit)
    ["aura-oCAPaSeal2"] = {
        id = "aura-oCAPaSeal2",
        name = "Seal of Light",
        description = "Your successful attacks heal you for $[1].amount$ health.",
        icon = 135917,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "caster" },
                    key = "HEAL",
                    args = { amount = "2d2" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Seal of Wisdom (mana on hit)
    ["aura-oCAPaSeal3"] = {
        id = "aura-oCAPaSeal3",
        name = "Seal of Wisdom",
        description = "Your successful restore $[1].amount$ mana.",
        icon = 135960,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "caster" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "MANA", amount = "2d2" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Seal of the Crusader (action on crit)
    ["aura-oCAPaSeal4"] = {
        id = "aura-oCAPaSeal4",
        name = "Seal of the Crusader",
        description = "Critical strikes grant you $[1].amount$ action on the same turn.",
        icon = 135924,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "caster" },
                    key = "GAIN_RESOURCE",
                    args = { auraId = "ACTION", amount = "1" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Seal of Command (holy damage on crit)
    ["aura-oCAPaSeal5"] = {
        id = "aura-oCAPaSeal5",
        name = "Seal of Command",
        description = "Critical strikes deal an additional $[1].amount$ $[1].school$ damage.",
        icon = 132347,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "math.floor($wep.mainhand$ * 0.7)", school = "Holy" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    ------ Paladin Auras (Traits) ------
    -- Vindication (hits reduce target's melee AP by 10% for 1 turn)
    ["aura-oCAPaAura1"] = {
        id = "aura-oCAPaAura1",
        name = "Vindication",
        description = "Your successful attacks reduce the target's melee attack power by 10% for 1 turn.",
        icon = 135985,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCAPaAura1-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    ["aura-oCAPaAura1-Debuff"] = {
        id = "aura-oCAPaAura1-Debuff",
        name = "Vindication",
        description = "Melee attack power reduced by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 135985,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin",
            [2] = "debuff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Aura of Mercy (heal allies each turn)
    ["aura-oCAPaAura2"] = {
        id = "aura-oCAPaAura2",
        name = "Aura of Mercy",
        description = "Heals up to 5 allies for 5 health per turn.",
        icon = 135876,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
        },
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onTick",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "5",
                            targets = { targeter = "ALL_ALLIES", maxTargets = 5, flags = "A" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },
    
    -- Righteous Fury (increases THREAT by 0.8)
    ["aura-oCAPaAura3"] = {
        id = "aura-oCAPaAura3",
        name = "Righteous Fury",
        description = "Increases your threat generation by 80%.",
        icon = 135962,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:paladin",
        },
        triggers = {
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            }
        }
    },

    ------ Paladin Spell Effects ------
    -- Armor of the Righteous (armor buff)
    ["aura-oCSPaPro002"] = {
        id = "aura-oCSPaPro002",
        name = "Armour of the Righteous",
        description = "Armour increased by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 236265,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    ------ Paladin Blessings ------
    -- Blesing of Might (melee attack power buff)
    ["aura-oCAPaBles1"] = {
        id = "aura-oCAPaBles1",
        name = "Blessing of Might",
        description = "Melee attack power increased by 10.",
        icon = 135906,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },
    
    -- Blessing of Wisdom (mana regen buff)
    ["aura-oCAPaBles2"] = {
        id = "aura-oCAPaBles2",
        name = "Blessing of Wisdom",
        description = "Restores 2 mana per turn.",
        icon = 135970,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onTick",
                    actions = {
                        [1] = {
                            key = "GAIN_RESOURCE",
                            args = {
                                amount = "2",
                                targets = { targeter = "TARGET", maxTargets = 1, flags = "A" },
                                resourceId = "MANA"
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },   

    -- Blessing of Protection (physical damage immunity buff)
    ["aura-oCAPaBles3"] = {
        id = "aura-oCAPaBles3",
        name = "Blessing of Protection",
        description = "Immune to physical damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 135964,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin"
        },
        triggers = {},
        tick = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = { "Physical" },
            tags = {},
            damageSchools = { "Physical" },
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },
    
    ------ Paladin Blessings ------
    -- Hammer of Justice (stun)
    ["aura-oCAPaCC1"] = {
        id = "aura-oCAPaCC1",
        name = "Hammer of Justice",
        description = "Stunned.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 135963,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "paladin",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },
}

RPE.Data.DefaultClassic.AURAS_MAGE = {
    ------ Mage Armours (Traits) ------
    -- Frost Armor (increases armor by 10 and causes attackers to gain 1 level of disadvantage on MELEE_HIT)
    ["aura-ocSMaArm001"] = {
        id = "aura-ocSMaArm001",
        name = "Frost Armor",
        description = "Armor increased by 10. Attackers gain 1 level of disadvantage on melee attack rolls.",
        icon = 135843,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:mage"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "attacker" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-ocSMaArm001-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    ["aura-ocSMaArm001-Debuff"] = {
        id = "aura-ocSMaArm001-Debuff",
        name = "Frost Armor Disadvantage",
        description = "Disadvantage level on melee attack rolls increased by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 135843,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "mage",
            [2] = "debuff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "MELEE_HIT",
                value = "-1"
            }
        }
    },

    -- Molten Armor (causes fire damage to attackers)
    ["aura-ocSMaArm002"] = {
        id = "aura-ocSMaArm002",
        name = "Molten Armor",
        description = "Causes 10 fire damage to attackers. Spell critical strike rating increased by 1.",
        icon = 132221,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "NONE",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:mage"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "attacker" },
                    key = "DAMAGE",
                    args = { amount = "5", school = "Fire" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "1"
            }
        }
    },

    -- Mage Armor (restores 5 mana per turn and increases arcane and fel resistance by 2)
    ["aura-oCSMaArm003"] = {
        id = "aura-oCSMaArm003",
        name = "Mage Armor",
        description = "Restores 5 mana per turn. Arcane and Fel resistances increased by 2.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=0
        },
        icon = 135991,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:mage"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            amount = "5",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "A" },
                            resourceId = "MANA"
                        }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "ARCANE_RESISTANCE",
                value = "2"
            },
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "FEL_RESISTANCE",
                value = "2"
            }
        }
    },

    ------ Spell Hit Effects (Traits) ------
    -- Ignite (spell hits cause damage over time - 10 fire damage every turn for 3 turns, refresh duration)
    ["aura-oCSMaTrait001"] = {
        id = "aura-oCSMaTrait001",
        name = "Ignite",
        description = "Taking 10 Fire damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 135818,
        isTrait = true,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:mage",
            [2] = "debuff"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onTick",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Fire",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "A" }
                        }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Arcane Subtlety (lower arcane resistance of target by 1, stacking)
    ["aura-oCSMaTrait002"] = {
        id = "aura-oCSMaTrait002",
        name = "Arcane Subtlety",
        description = "Arcane resistance reduced by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135894,
        isTrait = true,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "class:mage",
            [2] = "debuff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "ARCANE_RESISTANCE",
                value = "1"
            }
        }
    },

    -- Frostbite (lower attack power, copy from vindication)
    ["aura-oCSMaTrait003"] = {
        id = "aura-oCSMaTrait003",
        name = "Frostbite",
        description = "Melee attack power reduced by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135834,
        isTrait = true,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:mage",
            [2] = "debuff"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    ------ Mage Spell Effects ------
    -- Polymorph (incapacitate, break on damage)
    ["aura-oCSMaArc002"] = {
        id = "aura-oCSMaArc002",
        name = "Polymorph",
        description = "Incapacitated. Breaks on damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136071,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "mage",
            [2] = "incapacitate"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "",
                value = ""
            }
        }
    },

    -- Arcane Intellect (intellect buff)
    ["aura-oCSMaInt001"] = {
        id = "aura-oCSMaInt001",
        name = "Arcane Intellect",
        description = "Intelligence score increased by 2.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135932,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "mage"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "2"
            }
        }
    },

    -- Combustion (critical strike buff)
    ["aura-oCSMaFir003"] = {
        id = "aura-oCSMaFir003",
        name = "Combustion",
        description = "Spell critical strike threshold reduced by 10. Your spell critical damage multiplier is increased by 0.5.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135824,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "mage"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT_MULT",
                value = "0.5"
            },
        }
    },

    -- Arcane Charges 
    ["aura-oCSMaArc003"] = {
        id = "aura-oCSMaArc003",
        name = "Arcane Charge",
        description = "Increases spell damage by 5 per charge. Max 5 charges.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135732,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "mage"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "SPELL_AP",
                value = "5"
            }
        }
    },

    -- Blizzard
    ["aura-oCSMaFro002"] = {
        id = "aura-oCSMaFro002",
        name = "Blizzard",
        description = "Taking 5 Frost damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135857,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "mage",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Frost",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Deep Freeze (1 turn stun)
    ["aura-oCSMaFro003"] = {
        id = "aura-oCSMaFro003",
        name = "Deep Freeze",
        description = "Stunned.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 236214,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "mage",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Ice Barrier (damage absorption)
    ["aura-oCSMaFro004"] = {
        id = "aura-oCSMaFro004",
        name = "Ice Barrier",
        description = "Absorbing damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135988,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "mage"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },
}

RPE.Data.DefaultClassic.AURAS_WARRIOR = {
    ------ Warrior Specialisations (Traits) ------
    -- Sword Specialisation - critical strikes grant 1 bonus action.
    ["aura-oCAWaSpec01"] = {
        id = "aura-oCAWaSpec01",
        name = "Sword Specialisation",
        description = "Melee critical strikes grant 1 bonus action.",
        icon = 135328,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        requirements = {
            "equip.mainhand.sword"  -- Requires a sword in main hand
        },
        tags = {
            [1] = "class:warrior",
            [2] = "equip.mainhand.sword"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "TARGET" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "BONUS_ACTION", amount = "1" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Axe Specialisation - increases MELEE_CRIT by 1.
    ["aura-oCAWaSpec02"] = {
        id = "aura-oCAWaSpec02",
        name = "Axe Specialisation",
        description = "Melee critical strike rating increased by 1.",
        icon = 132395,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        requirements = {
            "equip.mainhand.axe"  -- Requires an axe in main hand
        },
        tags = {
            [1] = "class:warrior",
            [2] = "equip.mainhand.axe"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1"
            }
        }
    },

    -- Mace Specialisation - critical strikes stun the target.
    ["aura-oCAWaSpec03"] = {
        id = "aura-oCAWaSpec03",
        name = "Mace Specialisation",
        description = "Melee critical strikes stun the target for 1 turn.",
        icon = 133482,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        requirements = {
            "equip.mainhand.mace"  -- Requires a mace in main hand
        },
        tags = {
            [1] = "class:warrior",
            [2] = "equip.mainhand.mace"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "TARGET" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCAWaSpec03-Stun" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCAWaSpec03-Stun"] = {
        id = "aura-oCAWaSpec03-Stun",
        name = "Mace Stun",
        description = "Stunned.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 133482,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Polearm Specialisation - increases MELEE_CRIT by 1.
    ["aura-oCAWaSpec04"] = {
        id = "aura-oCAWaSpec04",
        name = "Polearm Specialisation",
        description = "Melee critical strike rating increased by 1.",
        icon = 135128,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        requirements = {
            "equip.mainhand.polearm"  -- Requires a polearm in main hand
        },
        tags = {
            [1] = "class:warrior",
            [2] = "equip.mainhand.polearm"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1"
            }
        }
    },

    ------ Warrior Stances (Traits) ------
    -- Battle Stance - gain 5 rage per turn.
    ["aura-oCAWaStance02"] = {
        id = "aura-oCAWaStance02",
        name = "Battle Stance",
        description = "Gain 5 rage per turn.",
        icon = 132349,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warrior"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            amount = "5",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "A" },
                            resourceId = "RAGE"
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Defensive Stance - increases block rating by 2, reduces melee attack power by 10%.
    ["aura-oCAWaStance01"] = {
        id = "aura-oCAWaStance01",
        name = "Defensive Stance",
        description = "Block rating increased by 2. Melee attack power reduced by 10%. Threat generation increased by 80%.",
        icon = 132341,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "BLOCK",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            }
        }
    },

    -- Berserker Stance - increase MELEE_CRIT by 1, reduce armor by 30%.
    ["aura-oCAWaStance03"] = {
        id = "aura-oCAWaStance03",
        name = "Berserker Stance",
        description = "Melee critical strike rating increased by 1. Armour reduced by 30%.",
        icon = 132275,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "ARMOR",
                value = "30"
            }
        }
    },

    ------ Warrior Spell Effects ------
    -- Battle Shout (10% attack power buff)
    ["aura-oCSWaFur001"] = {
        id = "aura-oCSWaFur001",
        name = "Battle Shout",
        description = "Melee attack power increased by 20%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 132333,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "20"
            }
        }
    },

    -- Shield Block (increases Block stat and grants advantage on Block)
    ["aura-oCSWaPro001"] = {
        id = "aura-oCSWaPro001",
        name = "Shield Block",
        description = "Block rating increased by 5. Advantage level on Block rolls increased by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132110,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "BLOCK",
                value = "5"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "BLOCK",
                value = "1"
            }
        }
    },

    -- Intimidating Shout (2 turn incapacitate, breaks on damage taken)
    ["aura-oCSWaFur003"] = {
        id = "aura-oCSWaFur003",
        name = "Intimidating Shout",
        description = "Incapacitated. Breaks on damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 132154,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "warrior",
            [2] = "fear"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Death Wish (30% AP increase, 75% armour reduction)
    ["aura-oCSWaFur004"] = {
        id = "aura-oCSWaFur004",
        name = "Death Wish",
        description = "Melee attack power increased by 30%. Armour reduced by 75%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 136010,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            [1] = {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "30"
            },
            [2] = {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "ARMOR",
                value = "75"
            }
        }
    },

    -- Sunder Armor (reduce stat.ARMOR by 5% per stack, max 5 stacks)
    ["aura-oCSWaPro002"] = {
        id = "aura-oCSWaPro002",
        name = "Sunder Armor",
        description = "Armour reduced by 5% per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 132363,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_SUB",
                stat = "ARMOR",
                value = "5"
            }
        }
    },

    -- Charge (prevent defences but not actions)
    ["aura-oCSWaArm003"] = {
        id = "aura-oCSWaArm003",
        name = "Charge",
        description = "Cannot use defensive actions.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132337,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = { "$stat.BLOCK$", "$stat.DODGE$", "$stat.PARRY$" },
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Mortal Strike (reduces HEALING_TAKEN by 50%)
    ["aura-oCSWaArm004"] = {
        id = "aura-oCSWaArm004",
        name = "Mortal Strike",
        description = "Healing received reduced by 50%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 132355,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "HEALING_TAKEN",
                value = "50"
            }
        }
    },

    -- Render (3 damage bleed for 5 turns)
    ["aura-oCSWaArm002"] = {
        id = "aura-oCSWaArm002",
        name = "Rend",
        description = "Taking 10 Physical damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 132155,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Physical",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Last Stand (30% max health increase)
    ["aura-oCSWaPro004"] = {
        id = "aura-oCSWaPro004",
        name = "Last Stand",
        description = "Maximum health increased by 30%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 135871,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "30"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEALTH",
                value = "30"
            }
        }
    },

    -- Ignore Pain (damage shield buff, doesnt do anything, just visual)
    ["aura-oCSWaPro003"] = {
        id = "aura-oCSWaPro003",
        name = "Ignore Pain",
        description = "Absorbing damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 1377132,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "warrior"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_DEATH_KNIGHT = {
    ----- Death Knight Specialisations (Traits) -----
    -- Frost Presence (Generates 5 runic power per turn. Critical strikes reduce the cooldown of frost dk spells by 1)
    ["aura-oCADkPre01"] = {
        id = "aura-oCADkPre01",
        name = "Frost Presence",
        description = "Generates 5 runic power per turn. Critical strikes reduce the cooldown of frost death knight spells by 1.",
        icon = 135773,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "source" },
                    key = "REDUCE_COOLDOWN",
                    args = { schoolTag = "dk_frost_spells", amount = "1" }
                }
            }
        },
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            amount = "5",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "A" },
                            resourceId = "RUNIC_POWER"
                        }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Unholy Presence (Every turn, heals SUMMONED units for 30 health. Critical strikes reduce the cooldown of unholy dk spells by 1)
    ["aura-oCADkPre02"] = {
        id = "aura-oCADkPre02",
        name = "Unholy Presence",
        description = "Every turn, heals your summoned minions for 30 health. Critical strikes reduce the cooldown of unholy death knight spells by 1.",
        icon = 135775,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "source" },
                    key = "REDUCE_COOLDOWN",
                    args = { schoolTag = "dk_unholy_spells", amount = "1" }
                }
            }
        },
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "HEAL",
                            args = {
                                amount = "30",
                                targets = { targeter = "SUMMONED" },
                                }
                            }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Blood Presence (Increases maximum health by 10% and threat generation by 80%. Critical strikes reduce the cooldown of blood dk spells by 1)
    ["aura-oCADkPre03"] = {
        id = "aura-oCADkPre03",
        name = "Blood Presence",
        description = "Maximum health increased by 10% and threat generation increased by 80%. Critical strikes reduce the cooldown of blood death knight spells by 1.",
        icon = 135770,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "source" },
                    key = "REDUCE_COOLDOWN",
                    args = { schoolTag = "dk_blood_spells", amount = "1" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            }
        }
    },

    ----- Death Knight Traits -----
    -- Vendetta (ON_KILL heal for 20% of max health)
    ["aura-oCADkVen001"] = {
        id = "aura-oCADkVen001",
        name = "Vendetta",
        description = "When you kill an enemy, you heal for 6% of your maximum health.",
        icon = 237536,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_KILL",
                action = {
                    targets = { ref = "source" },
                    key = "HEAL",
                    args = { amount = "$stat.MAX_HEALTH$ * 0.06" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Necrosis (copy from Seal of Righteousness, deal shadow damage)
    ["aura-oCADkNec001"] = {
        id = "aura-oCADkNec001",
        name = "Necrosis",
        description = "Your melee attacks deal an additional 5 Shadow damage.",
        icon = 135695,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "5", school = "Shadow" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Might of the Frozen Wastes (ON_HIT generate 2 runic power)
    ["aura-oCADkMig001"] = {
        id = "aura-oCADkMig001",
        name = "Might of the Frozen Wastes",
        description = "All attacks generate an 2 Runic Power.",
        icon = 135303,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:deathknight"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "source" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "2", resourceId = "RUNIC_POWER" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ----- Death Knight Spell Effects -----
    -- Frost Fever (disease debuff, frost damage, same damage as Rend )
    ["aura-oCSDkFro001"] = {
        id = "aura-oCSDkFro001",
        name = "Frost Fever",
        description = "Taking 5 Frost damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 237522,
        isTrait = false,
        isHelpful = false,
        dispelType = "DISEASE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "death_knight",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Frost",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Blood Plague (disease debuff, shadow damage, same damage as Rend )
    ["aura-oCSDkUnh001"] = {
        id = "aura-oCSDkSha001",
        name = "Blood Plague",
        description = "Taking 5 Shadow damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 237514,
        isTrait = false,
        isHelpful = false,
        dispelType = "DISEASE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "death_knight",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Shadow",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Vampiric Blood (last stand 30% health buff and ON_HIT HEAL trigger)
    ["aura-oCSDkBlo004"] = {
        id = "aura-oCSDkBlo004",
        name = "Vampiric Blood",
        description = "Maximum health increased by 30%. You regain hitpoints when dealing damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136168,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "death_knight"
        },
        triggers = {
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "source" },
                key = "HEAL",
                args = { amount = "$stat.MELEE_AP$" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "30"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEALTH",
                value = "30"
            }
        }
    },

    -- Soul Reaper (ON_KILL trigger apply aura to player)
    ["aura-oCSDkUnh004"] = {
        id = "aura-oCSDkUnh004",
        name = "Soul Reaper",
        description = "When you kill an enemy, generate 10 runic power and gain 40% melee attack power for 2 turns.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 3
        },
        icon = 636333,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "death_knight"
        },
        triggers = {
            {
                event = "ON_KILL",
                action = {
                    targets = { ref = "source" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCSDkUnh004a" }
                }
            },
            {
                event = "ON_KILL",
                action = {
                    targets = { ref = "source" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "RUNIC_POWER", amount = "10" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Reaped Soul (increases attack power by 40% for 2 turns)
    ["aura-oCSDkUnh004a"] = {
        id = "aura-oCSDkUnh004a",
        name = "Reaped Soul",
        description = "Melee attack power increased by 40%.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 2
        },
        icon = 3528295,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "death_knight"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "40"
            }
        }
    },

    -- Unholy frenzy (increases melee hit by 1, stacks up to 10 times)
    ["aura-oCSDkUnh003"] = {
        id = "aura-oCSDkUnh003",
        name = "Unholy Frenzy",
        description = "Melee hit chance increased by 1 per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 237512,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 10,
        tags = {
            [1] = "death_knight"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "MELEE_HIT",
                value = "1"
            }
        }
    }
}

RPE.Data.DefaultClassic.AURAS_SHAMAN = {
    ------ Shaman Weapon Imbues (Traits) ------
    -- Rockbiter Weapon (10% MELEE_AP, 40% additional THREAT)
    ["aura-oCSShaEnh001"] = {
        id = "aura-oCSShaEnh001",
        name = "Rockbiter Weapon",
        description = "Melee attack power increased by 10%. Threat generation increased by 40%.",
        icon = 136086,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.4"
            }
        }
    },

    -- Flametongue Weapon (10% SPELL_AP, 10 FIRE_DAMAGE)
    ["aura-oCSShaEnh002"] = {
        id = "aura-oCSShaEnh002",
        name = "Flametongue Weapon",
        description = "Spell power increased by 10%. Melee attacks deal an additional 10 Fire damage.",
        icon = 135814,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "10", school = "Fire" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "10"
            }
        }
    },

    -- Frostbrand Weapon (8 frost damage on hit, disadvantage on DODGE, DEFENCE, AC)
    ["aura-oCSShaEnh003"] = {
        id = "aura-oCSShaEnh003",
        name = "Frostbrand Weapon",
        description = "Melee attacks deal an additional 8 Frost damage. Reduces the target's Dodge rating by 1. If your roll system uses Defence or Armor Class, these are reduced by 1 instead.",
        icon = 135847,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "8", school = "Frost" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "DODGE",
                value = "1"
            },
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "DEFENCE",
                value = "1"
            },
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "AC",
                value = "1"
            }
        }
    },

    -- Windfury Weapon (critical strikes deal damage equal to 40% of your MELEE_AP)
    ["aura-oCSShaEnh005"] = {
        id = "aura-oCSShaEnh005",
        name = "Windfury Weapon",
        description = "Critical strikes with melee attacks deal additional damage equal to 40% of your melee attack power.",
        icon = 136018,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "DAMAGE",
                    args = { amount = "$stat.MELEE_AP$ * 0.4", school = "Physical" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ------ Shaman Specialisations (Traits) ------
    -- Elemental Precision (SPELL_HIT increased by 1, threat generation reduce by 10%)
    ["aura-oCSShaTrait001"] = {
        id = "aura-oCSShaEle001",
        name = "Elemental Precision",
        description = "Spell hit chance increased by 1. Threat generation reduced by 10%.",
        icon = 136028,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_HIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "THREAT",
                value = "0.1"
            }
        }
    },

    -- Mental Dexterity (increases your MELEE_AP by 5 * INT_MOD)
    ["aura-oCSShaTrait002"] = {
        id = "aura-oCSShaTrait002",
        name = "Mental Dexterity",
        description = "Melee attack power increased by 5 per point of your Intelligence modifier.",
        icon = 136055,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "5 * $stat.INT_MOD$"
            }
        }
    },

    -- Nature's Blessing (increases your HEAL_POWER by 5 * INT_MOD)
    ["aura-oCSShaTrait003"] = {
        id = "aura-oCSShaTrait003",
        name = "Nature's Blessing",
        description = "Healing power increased by 5 per point of your Intelligence modifier.",
        icon = 136059,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:shaman"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "5 * $stat.INT_MOD$"
            }
        }
    },
    
    ------ Shaman Spell Effects -----
    -- Shamanistic Rage (30% MELEE_AP buff and ON_HIT mana regeneration)
    ["aura-oCSShaEnh004"] = {
        id = "aura-oCSShaEnh004",
        name = "Shamanistic Rage",
        description = "Melee attack power increased by 30%. You regain mana when dealing damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 136088,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "shaman"
        },
        triggers = {
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "source" },
                key = "GAIN_RESOURCE",
                args = { resourceId = "MANA", amount = "5" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "30"
            }
        }
    },

    -- Flame Shock (fire damage debuff, same damage as Rend )
    ["aura-oCSShaEle002"] = {
        id = "aura-oCSShaEle002",
        name = "Flame Shock",
        description = "Taking 10 Fire damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135818,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "shaman",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Fire",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Earth Shield (on_hit_taken heal)
    ["aura-oCSShaRes002"] = {
        id = "aura-oCSShaRes002",
        name = "Earth Shield",
        description = "Heals the target for $[1].amount$ whenever they take damage. Lasts 5 turns.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136089,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "shaman"
        },
        triggers = {
            {
            event = "ON_HIT_TAKEN",
            action = {
                targets = { ref = "TARGET" },
                key = "HEAL",
                args = { amount = "10" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Riptide (heal 5 health every turn for 3 turns)
    ["aura-oCSShaRes003"] = {
        id = "aura-oCSShaRes003",
        name = "Riptide",
        description = "Restoring 10 health per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 252995,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "shaman"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_HUNTER = {
    ------ Hunter Aspects -------
    -- Aspect of the Hawk (10% RANGED_AP buff)
    ["aura-OCSHuAsH001"] = {
        id = "aura-OCSHuAsH001",
        name = "Aspect of the Hawk",
        description = "Ranged attack power increased by 10%.",
        icon = 136076,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "RANGED_AP",
                value = "10"
            }
        }
    },

    -- Aspect of the Monkey (Advantage on DODGE rolls)
    ["aura-OCSHuAsM001"] = {
        id = "aura-OCSHuAsM001",
        name = "Aspect of the Monkey",
        description = "You have advantage on Dodge rolls.",
        icon = 132159,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    -- Aspect of the Viper (ON_HIT gain 5 mana or 5 focus)
    ["aura-OCSHuAsV001"] = {
        id = "aura-OCSHuAsV001",
        name = "Aspect of the Viper",
        description = "You regain 5 Focus and Mana whenever you deal damage, but your ranged AP is reduced by 10%.",
        icon = 132160,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "source" },
                key = "GAIN_RESOURCE",
                args = { resourceId = "FOCUS", amount = "5" }
                }
            },
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "source" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "MANA", amount = "5" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "RANGED_AP",
                value = "10"
            }
        }
    },

    -- Aspect of the Wild (nature resistance increased by 3, heal for 10 HP per turn)
    ["aura-OCSHuAsW001"] = {
        id = "aura-OCSHuAsW001",
        name = "Aspect of the Wild",
        description = "Nature resistance increased by 3. Restoring 10 health per turn.",
        icon = 136074,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "3"
            }
        }
    },

    ------ Hunter Specialisations (Traits) ------
    -- Spirit Bond (heal yourself for 5 health and the SUMMONED target for 20 health per turn)
    ["aura-OCSHuBeT001"] = {
        id = "aura-OCSHuBeT001",
        name = "Spirit Bond",
        description = "You and your summoned pet heal for 5 and 20 health respectively at the start of your turn.",
        icon = 132121,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "5",
                            targets = { targeter = "TARGET" },
                            }
                        },
                        [2] = {
                        key = "HEAL",
                        args = {
                            amount = "20",
                            targets = { targeter = "SUMMONED" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Rapid Killing (ON_KILL increases RANGED_HIT by 3 and RANGED_AP by 20% for 2 turns)
    ["aura-OCSHuBeT002"] = {
        id = "aura-OCSHuBeT002",
        name = "Rapid Killing",
        description = "Ranged hit chance increased by 3 and ranged attack power increased by 20% for 2 turns whenever you kill a target.",
        icon = 132205,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_HIT",
                value = "3"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "RANGED_AP",
                value = "20"
            }
        }
    },

    -- Master Tactician (increases your RANGED_CRIT by 1 per stack, gain a stack ON_HIT, lasts 2 turns)
    ["aura-OCSHuBeT003"] = {
        id = "aura-OCSHuBeT003",
        name = "Master Tactician",
        description = "Ranged critical strike chance increased by 1 per stack. Gain a stack whenever you deal damage. Lasts 2 turns.",
        icon = 132178,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "class:hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1"
            }
        }
    },
    
    ------ Hunter Spell Effects -----
    -- Beastial Wrath (100% MELEE_AP buff for 2 turns)
    ["aura-OCSHuBeM002"] = {
        id = "aura-OCSHuBeM002",
        name = "Bestial Wrath",
        description = "Melee attack power increased by 100%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 132127,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "TARGET",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "100"
            }
        }
    },

    -- Intimidation (1 turn stun)
    ["aura-OCSHuBeM003"] = {
        id = "aura-OCSHuBeM003",
        name = "Intimidation",
        description = "Stunned. Cannot act or defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132111,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "hunter",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    --- Raptor Strike (10% MELEE_AP buff, stacks 3 times, 3 turn duration)
    ["aura-oCSHuSur001"] = {
        id = "aura-oCSHuSur001",
        name = "Raptor Strike",
        description = "Melee attack power increased by 10% per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 1376046,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Serpent Sting (nature damage debuff, same damage as Rend )
    ["aura-oCSHuSur002"] = {
        id = "aura-oCSHuSur002",
        name = "Serpent Sting",
        description = "Taking 5 Nature damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 1033905,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "hunter",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Nature",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Deterrence (copy from blessing of protection)
    ["aura-oCSHuSur004"] = {
        id = "aura-oCSHuSur004",
        name = "Deterrence",
        description = "Immune to physical attacks.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132369,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = { "PHYSICAL" },
            tags = {},
            damageSchools = { "Physical" },
            helpful = true,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_EVOKER = {
    ------ Evoker Specialisations (Traits) ------
    -- Attuned to the Dream (Increase HEAL_POWER and HEAL_TAKEN by 10%)
    ["aura-oCSEvTrait001"] = {
        id = "aura-oCSEvTrait001",
        name = "Attuned to the Dream",
        description = "Healing power and healing received increased by 10%.",
        icon = 460692,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEAL_POWER",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEAL_TAKEN",
                value = "10"
            }
        }
    },

    -- Draconic Legacy (Max health increased by 8%)
    ["aura-oCSEvTrait002"] = {
        id = "aura-oCSEvTrait002",
        name = "Draconic Legacy",
        description = "Maximum health increased by 8%.",
        icon = 4558458,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "8"
            }
        }
    },

    -- Innate Magic (MAX_ESSENCE increased by 1)
    ["aura-oCSEvTrait003"] = {
        id = "aura-oCSEvTrait003",
        name = "Power Nexus",
        description = "Maximum Essence increased by 2.",
        icon = 4630464,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MAX_ESSENCE",
                value = "1"
            }
        }
    },

    -- Spellweaver's Dominance (Increase SPELL_CRIT_MULT by 0.3)
    ["aura-oCSEvTrait004"] = {
        id = "aura-oCSEvTrait004",
        name = "Spellweaver's Dominance",
        description = "Spell critical strike damage increased by 30%.",
        icon = 1020305,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT_MULT",
                value = "0.3"
            }
        }
    },
    
    ------ Evoker Spell Effects -----
    -- Prescience (MELEE_CRIT, RANGED_CRIT, SPELL_CRIT increased by 1)
    ["aura-oCSEvAug001"] = {
        id = "aura-oCSEvAug001",
        name = "Prescience",
        description = "Melee, ranged and spell critical strike thresholds reduced by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 5199639,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "RANGED_CRIT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "1"
            }
        }
    },

    -- Ebon Might stat buff (2 to STR, INT, DEX, CON, WIS, CHA)
    ["aura-oCSEvAug002a"] = {
        id = "aura-oCSEvAug002a",
        name = "Ebon Might",
        description = "All primary attributes increased by 2.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 5061347,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "WIS",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CHA",
                value = "2"
            }
        }
    },

    -- Ebon Might self SPELL_AP 20% buff.
    ["aura-oCSEvAug002b"] = {
        id = "aura-oCSEvAug002b",
        name = "Ebon Might",
        description = "Spell power increased by 20%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 5061347,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "20"
            }
        }
    },

    -- Blistering Scales (20% armor increase and ON_HIT_TAKEN deals damage to the source)
    ["aura-oCSEvAug004"] = {
        id = "aura-oCSEvAug004",
        name = "Blistering Scales",
        description = "Armor increased by 20%. Whenever you are hit, deal 10 Fire damage to the attacker.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 5199621,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {
            {
            event = "ON_HIT_TAKEN",
            action = {
                targets = { ref = "source" },
                key = "DAMAGE",
                args = { amount = "10", school = "Fire" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "20"
            }
        }
    },

    -- Reversion (heals 10 damage per turn for 3 turns)
    ["aura-oCSEvPre001"] = {
        id = "aura-oCSEvPre001",
        name = "Reversion",
        description = "Restoring 10 health per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 4630469,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Echo (ON_HEAL_TAKEN trigger, additional heal)
    ["aura-oCSEvPre003"] = {
        id = "aura-oCSEvPre003",
        name = "Echo",
        description = "Whenever you are healed, you are healed for an additional 10 health.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 4630470,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {
            {
            event = "ON_HEAL_TAKEN",
            action = {
                targets = { ref = "TARGET" },
                key = "HEAL",
                args = { amount = "10" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Spellshatter (reduces arcane, fire and frost resistance by 2)
    ["aura-oCSEvDev003"] = {
        id = "aura-oCSEvDev003",
        name = "Spellshatter",
        description = "Arcane, Fire and Frost resistance reduced by 2.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 4622449,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "ARCANE_RESISTANCE",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "FIRE_RESISTANCE",
                value = "2"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "FROST_RESISTANCE",
                value = "2"
            }
        }
    },

    -- Dragonrage (increases spell power by 25% for 2 turns)
    ["aura-oCSEvDev004"] = {
        id = "aura-oCSEvDev004",
        name = "Dragonrage",
        description = "Spell power increased by 30%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 4622452,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "evoker"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "30"
            }
        }
    }
}

RPE.Data.DefaultClassic.AURAS_ROGUE = {
    ------ Rogue Poisons ------
    -- Instant Poison (attacks deal 10 additional Nature damage)
    ["aura-oCSRoPoi001"] = {
        id = "aura-oCSRoPoi001",
        name = "Instant Poison",
        description = "Your attacks deal an additional 10 Nature damage.",
        icon = 132336,
        isTrait = true,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue",
            [2] = "poison"
        },
        triggers = {
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "target" },
                key = "DAMAGE",
                args = { amount = "10", school = "Nature" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Deadly Poison (attacks deal 5 additionnal Nature damage per stack, stacks up to 5 times, last 3 turns)
    ["aura-oCSRoPoi002"] = {
        id = "aura-oCSRoPoi002",
        name = "Deadly Poison",
        description = "Your attacks deal an additional 5 Nature damage per stack, stacking up to 5 times, lasting 3 turns.",
        icon = 132290,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue",
            [2] = "poison"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCSRoPoi002-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSRoPoi002-Debuff"] = {
        id = "aura-oCSRoPoi002-Debuff",
        name = "Deadly Poison",
        description = "Taking 5 Nature damage per stack each turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 132290,
        isTrait = false,
        isHelpful = false,
        dispelType = "POISON",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "rogue",
            [2] = "poison"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "DAMAGE",
                            args = {
                                amount = "5",
                                school = "Nature",
                                targets = { targeter = "TARGET" }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Wound Poison (attacks deal 5 additional Nature damage and reduce the target's HEAL_TAKEN by 20% for 1 turn)
    ["aura-oCSRoPoi004"] = {
        id = "aura-oCSRoPoi004",
        name = "Wound Poison",
        description = "Your attacks deal an additional 5 Nature damage and reduce the target's healing received by 20% for 1 turn.",
        icon = 134197,
        isTrait = true,
        isHelpful = false,
        dispelType = "POISON",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue",
            [2] = "poison"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCSRoPoi004-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSRoPoi004-Debuff"] = {
        id = "aura-oCSRoPoi004-Debuff",
        name = "Wound Poison",
        description = "Healing received reduced by 20%.",
        duration = {
            expires = "ON_OWNER_TURN_END",
            turns = 1
        },
        icon = 134197,
        isTrait = false,
        isHelpful = false,
        dispelType = "POISON",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
            [2] = "poison"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "HEAL_TAKEN",
                value = "20"
            }
        }
    },

    -- Mind Numbing Poison (attacks reduce the target's SPELL_HIT by 2 for 2 turns)
    ["aura-oCSRoPoi003"] = {
        id = "aura-oCSRoPoi003",
        name = "Mind Numbing Poison",
        description = "Your attacks reduce the target's spell hit by 2 for 2 turns.",
        icon = 136066,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue",
            [2] = "poison"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { auraId = "aura-oCSRoPoi003-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSRoPoi003-Debuff"] = {
        id = "aura-oCSRoPoi003-Debuff",
        name = "Mind Numbing Poison",
        description = "Spell hit reduced by 2.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136066,
        isTrait = false,
        isHelpful = false,
        dispelType = "POISON",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
            [2] = "poison"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "SPELL_HIT",
                value = "2"
            }
        }
    },

    ------ Rogue Specialisations (Traits) ------
    -- Vigor (increases MAX_ENERGY by 10)
    ["aura-oCSRoTrait001"] = {
        id = "aura-oCSRoTrait001",
        name = "Vigor",
        description = "Maximum energy increased by 10.",
        icon = 458737,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MAX_ENERGY",
                value = "10"
            }
        }
    },

    -- Just a Flesh Wound (threat generation increased by 80%, armor increased by 20%, melee attack power reduced by 10%)
    ["aura-oCSRoTrait002"] = {
        id = "aura-oCSRoTrait002",
        name = "Just a Flesh Wound",
        description = "Threat generation increased by 80%, armor increased by 20%, melee attack power reduced by 10%.",
        icon = 132284,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Precision (increases MELEE_HIT by 3)
    ["aura-oCSRoTrait003"] = {
        id = "aura-oCSRoTrait003",
        name = "Precision",
        description = "Melee hit increased by 3.",
        icon = 132222,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:rogue"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_HIT",
                value = "3"
            }
        }
    },
    
    ------ Rogue Spell Effects -----
    -- Rupture (20 damage per turn for 5 turns)
    ["aura-oCSRoAss002"] = {
        id = "aura-oCSRoAss002",
        name = "Rupture",
        description = "Taking 20 damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 132302,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "20",
                            school = "Physical",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Sap (incapacitate, breaks on damage, copy from polymorph)
    ["aura-oCSRoSub002"] = {
        id = "aura-oCSRoSub002",
        name = "Sap",
        description = "Incapacitated. Cannot act or defend. Breaks on damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 132310,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
            [2] = "incapacitate"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Adrenaline Rush (restores 20 energy per turn)
    ["aura-oCSRoCom004"] = {
        id = "aura-oCSRoCom004",
        name = "Adrenaline Rush",
        description = "Restores 20 energy per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 136206,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "ENERGY",
                            amount = "20",
                            targets = { targeter = "CASTER" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Gouge (1 turn stun, does not break on damage)
    ["aura-oCSRoCom003"] = {
        id = "aura-oCSRoCom003",
        name = "Gouge",
        description = "Stunned. Cannot act or defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132155,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Evasion (+5 DODGE and advantage on DODGE for 2 turns)
    ["aura-oCSRoCom002"] = {
        id = "aura-oCSRoCom002",
        name = "Evasion",
        description = "Dodge rating increased by 5. Advantage level on Dodge rolls increased by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136205,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "rogue"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DODGE",
                value = "5"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        },
    },

    -- Blind (incapacitate, breaks on damage, copy from polymorph, 2 turn duration)
    ["aura-oCSRoSub003"] = {
        id = "aura-oCSRoSub003",
        name = "Blind",
        description = "Incapacitated. Cannot act or defend. Breaks on damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136175,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "rogue",
            [2] = "incapacitate"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }

}

RPE.Data.DefaultClassic.AURAS_MONK = {
    ------ Monk Stances (Traits) ------
    -- Stance of the Fierce Tiger (MELEE_AP increased by 10%, MAX_CHI increased by 1)
    ["aura-oCSMoTrait001"] = {
        id = "aura-oCSMoTrait001",
        name = "Stance of the Fierce Tiger",
        description = "Melee attack power increased by 10%. Maximum chi increased by 1.",
        icon = 611420,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MAX_CHI",
                value = "1"
            }
        }
    },

    -- Stance of the Sturdy Ox (Threat increased by 0.8, max health increased by 10%, armour increased by 20%)
    ["aura-oCSMoTrait002"] = {
        id = "aura-oCSMoTrait002",
        name = "Stance of the Sturdy Ox",
        description = "Threat generation increased by 80%. Maximum health increased by 10%. Armor increased by 20%.",
        icon = 611419,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "20"
            }
        }
    },

    -- Stance of the Wise Serpent (HEAL_POWER increased by 5 per INT_MOD, increase MELEE_HIT by 1 per WIS_MOD, each tick heal ALL_ALLIES maxTargets = 1 for 10 health)
    ["aura-oCSMoTrait003"] = {
        id = "aura-oCSMoTrait003",
        name = "Stance of the Wise Serpent",
        description = "Healing power increased by 5 per Intelligence modifier. Melee hit increased by 1 per Wisdom modifier.",
        icon = 611421,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:monk"
        },
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                            key = "HEAL",
                            args = {
                                amount = "10",
                                targets = { targeter = "ALL_ALLIES", maxTargets = 1 }
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "5 * $stat.INT_MOD$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_HIT",
                value = "$stat.WIS_MOD$"
            }
        }
    },
    
    ------ Monk Spell Effects -----
    -- Tiger Palm (same as raptor strike)
    ["aura-oCSMoWin001"] = {
        id = "aura-oCSMoWin001",
        name = "Tiger Palm",
        description = "Melee attack power increased by 10% per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 132121,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Rising Sun Kick (reduce armor by 20% for 3 turns)
    ["aura-oCSMoWin002"] = {
        id = "aura-oCSMoWin002",
        name = "Rising Sun Kick",
        description = "Armor reduced by 20%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 642415,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "ARMOR",
                value = "20"
            }
        }
    },

    -- Touch of Karma (ON_HIT_TAKEN trigger, 30 Physical damage to attackers)
    ["aura-oCSMoWin004"] = {
        id = "aura-oCSMoWin004",
        name = "Touch of Karma",
        description = "Whenever you are hit, deal 30 Physical damage to the attacker.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 651728,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {
            {
            event = "ON_HIT_TAKEN",
            action = {
                targets = { ref = "source" },
                key = "DAMAGE",
                args = { amount = "30", school = "Physical" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Renewing Mist (10 health every turn for 5 turns)
    ["aura-oCSMoMis002"] = {
        id = "aura-oCSMoMis002",
        name = "Renewing Mist",
        description = "Restoring 10 health per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 627487,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Enveloping Mist (15 health every turn for 5 turns and increase HEALING_TAKEN by 30%)
    ["aura-oCSMoMis003"] = {
        id = "aura-oCSMoMis003",
        name = "Enveloping Mist",
        description = "Restoring 15 health per turn. Healing received increased by 30%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 627488,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "15",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEALING_TAKEN",
                value = "30"
            }
        }
    },

    -- Life Cocoon (increases HEALING_TAKEN by 50%)
    ["aura-oCSMoMis004"] = {
        id = "aura-oCSMoMis004",
        name = "Life Cocoon",
        description = "Healing received increased by 50%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 627485,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEALING_TAKEN",
                value = "50"
            }
        }
    },

    -- Fortifying Brew (30% max health and armour, copy from last stand)
    ["aura-oCSMoBre004"] = {
        id = "aura-oCSMoBre004",
        name = "Fortifying Brew",
        description = "Maximum health and armor increased by 30%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 615341,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "30"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "30"
            }
        }
    },

    -- Keg Smash (reduces melee attack power by 10% for 3 turns)
    ["aura-oCSMoBre002"]= {
        id = "aura-oCSMoBre002",
        name = "Dizzying Haze",
        description = "Melee attack power reduced by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 594274,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Guard (increase healing received by 10%)
    ["aura-oCSMoBre001"] = {
        id = "aura-oCSMoBre001",
        name = "Guard",
        description = "Healing received increased by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 611417,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEALING_TAKEN",
                value = "10"
            }
        }
    },

    -- Blackout Kick (increases Dodge rating by 1 for 3 turns, stacks up to 3 times)
    ["aura-oCSMoBre003"] = {
        id = "aura-oCSMoBre003",
        name = "Blackout Kick",
        description = "Dodge rating increased by 1 per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 574575,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "monk"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "ADD",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    -- Fist of Fury (stun for 1 turn, do not break on damage)
    ["aura-oCSMoWin003"] = {
        id = "aura-oCSMoWin003",
        name = "Fist of Fury",
        description = "Stunned. Cannot act or defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 627606,
        isTrait = false,
        isHelpful = false,
        dispelType = "PHYSICAL",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "monk",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_DRUID = {
    ------ Druid Forms (Traits) ------
    -- Cat Form (increases MELEE_AP by 5 per DEX_MOD, advantage on STEALTH and DODGE rolls)
    ["aura-oCSDrTrait001"] = {
        id = "aura-oCSDrTrait001",
        name = "Cat Form",
        description = "Melee attack power increased by 5 per Dexterity modifier. Advantage level on Stealth and Dodge rolls increased by 1.",
        icon = 132115,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "5 * $stat.DEX_MOD$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "STEALTH",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    -- Bear Form (increase MELEE_AP by 5 per STR_MOD, increase ARMOR by 20%, threat increased by 0.5, MAX_HEALTH by 10%)
    ["aura-oCSDrTrait002"] = {
        id = "aura-oCSDrTrait002",
        name = "Bear Form",
        description = "Melee attack power increased by 5 per Strength modifier. Armor increased by 20%. Threat generation increased by 50%. Maximum health increased by 10%.",
        icon = 132276,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_AP",
                value = "5 * $stat.STR_MOD$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.5"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "10"
            }
        }
    },

    -- Moonkin Form (increases SPELL_AP by 5 per INT_MOD and SPELL_CRIT by 1. ARMOR increased by 10%.)
    ["aura-oCSDrTrait003"] = {
        id = "aura-oCSDrTrait003",
        name = "Moonkin Form",
        description = "Spell attack power increased by 5 per Intelligence modifier. Spell critical strike increased by 1 per Intelligence modifier. Armor increased by 10%.",
        icon = 136036,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_AP",
                value = "5 * $stat.INT_MOD$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT",
                value = "$stat.INT_MOD$"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    -- Treant Form (increases HEAL_POWER by 5 per INT_MOD, ON_HEAL gain mana equal to WIS_MOD)
    ["aura-oCSDrTrait004"] = {
        id = "aura-oCSDrTrait004",
        name = "Treant Form",
        description = "Healing power increased by 5 per Intelligence modifier. Whenever you heal, restore mana equal to your Wisdom modifier.",
        icon = 132145,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "source" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "$stat.WIS_MOD$", resource = "MANA" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "5 * $stat.INT_MOD$"
            }
        }
    },

    ------ Druid Specialisations (Traits) ------
    -- Dreamstate (gain 3 mana per turn)
    ["aura-oCSDrSpec001"] = {
        id = "aura-oCSDrSpec001",
        name = "Dreamstate",
        description = "Restoring 3 mana per turn.",
        icon = 135860,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            amount = "3",
                            resource = "MANA",
                            targets = { targeter = "CASTER" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Infected Wounds (attacks apply a debuff that reduces MELEE_HIT by 1 for 2 turns)
    ["aura-oCSDrSpec002"] = {
        id = "aura-oCSDrSpec002",
        name = "Infected Wounds",
        description = "Your attacks apply Infected Wounds to the target, reducing their melee hit rating by 1 for 2 turns.",
        icon = 236158,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "target" },
                    key = "APPLY_AURA",
                    args = { aura = "aura-oCSDrSpec002-Debuff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSDrSpec002-Debuff"] = {
        id = "aura-oCSDrSpec002-Debuff",
        name = "Infected Wounds",
        description = "Melee hit rating reduced by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 236158,
        isTrait = false,
        isHelpful = false,
        dispelType = "DISEASE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "SUB",
                stat = "MELEE_HIT",
                value = "1"
            }
        }
    },

    -- Revitalise (ON_HEAL restore to the target: 1 energy, 1 rage, 1 fury, 1 runic_power, 1 mana)
    ["aura-oCSDrSpec003"] = {
        id = "aura-oCSDrSpec003",
        name = "Revitalise",
        description = "Whenever you heal, restore 3 energy, rage, fury, runic power, and mana to the target.",
        icon = 236166,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:druid"
        },
        triggers = {
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "target" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "1", resourceId= "ENERGY" }
                }
            },
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "target" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "1", resourceId= "RAGE" }
                }
            },
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "target" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "1", resourceId = "FURY" }
                }
            },
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "target" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "1", resourceId = "RUNIC_POWER" }
                }
            },
            {
                event = "ON_HEAL",
                action = {
                    targets = { ref = "target" },
                    key = "GAIN_RESOURCE",
                    args = { amount = "1", resourceId = "MANA" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },
    
    ------ Druid Spell Effects -----
    -- Moonfire (same as flame shock, but fire damage)
    ["aura-oCSDuBal002"] = {
        id = "aura-oCSDuBal002",
        name = "Moonfire",
        description = "Taking 10 Arcane damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136096,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Arcane",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Thorns (attackers take 10 Nature damage)
    ["aura-oCSDrBal003"] = {
        id = "aura-oCSDrBal003",
        name = "Thorns",
        description = "Dealing 10 Nature damage to attackers.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136104,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid"
        },
        triggers = {
            {
            event = "ON_HIT_TAKEN",
            action = {
                targets = { ref = "source" },
                key = "DAMAGE",
                args = { amount = "10", school = "Nature" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Entangling Roots (prevents using DODGE defense)
    ["aura-oCSDrBal004"] = {
        id = "aura-oCSDrBal004",
        name = "Entangling Roots",
        description = "Cannot use Dodge to defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136100,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid",
            [2] = "root"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = { "DODGE" },
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Pounce (1 turn stun)
    ["aura-oCSDrFer004"] = {
        id = "aura-oCSDrFer004",
        name = "Pounce",
        description = "Stunned. Cannot act or defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=1
        },
        icon = 132142,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid",
            [2] = "stun"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Savage Roar (increase MELEE_AP by 100% for 3 turns)
    ["aura-oCSDrFer005"] = {
        id = "aura-oCSDrFer005",
        name = "Savage Roar",
        description = "Melee attack power increased by 100%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 236167,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MELEE_AP",
                value = "100"
            }
        }
    },

    -- Mark of the Wild (all attributes increased by 1, nature resistance increased by 3)
    ["aura-oCSDrRes002"] = {
        id = "aura-oCSDrRes002",
        name = "Mark of the Wild",
        description = "All attributes increased by 1. Nature resistance increased by 3.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=0
        },
        icon = 136078,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "STR",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "DEX",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CON",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "INT",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "WIS",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "CHA",
                value = "1"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "NATURE_RESIST",
                value = "3"
            }
        }
    },

    -- Rejuvenation (10 health every turn for 5 turns)
    ["aura-oCSDrRes003"] = {
        id = "aura-oCSDrRes003",
        name = "Rejuvenation",
        description = "Restoring 10 health per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136081,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "druid"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false,
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_WARLOCK = {
    ------ Warlock Traits ------
    -- Soul Link (ON_HIT_TAKEN heal for $stat.INT_MOD$. Deal equivalent damage to SUMMONED)
    ["aura-oCSWaTrait001"] = {
        id = "aura-oCSWaTrait001",
        name = "Soul Link",
        description = "Whenever you take damage, heal yourself proportional to Intelligence modifier and deal equivalent damage to your summoned creature.",
        icon = 136160,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "CASTER" },
                    key = "HEAL",
                    args = { amount = "$stat.INT_MOD$ * 5" }
                }
            },
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "SUMMONED" },
                    key = "DAMAGE",
                    args = { amount = "$stat.INT_MOD$ * 5" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Suppression (increases SPELL_HIT by 2)
    ["aura-oCSWaTrait002"] = {
        id = "aura-oCSWaTrait002",
        name = "Suppression",
        description = "Spell hit rating increased by 2.",
        icon = 136230,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_HIT",
                value = "2"
            }
        }
    },

    -- Fel Synergy (heal SUMMONED units for 50% of your SPELL_AP ON_HIT)
    ["aura-oCSWaTrait003"] = {
        id = "aura-oCSWaTrait003",
        name = "Fel Synergy",
        description = "Whenever you deal damage, heal your summoned creature for 15% of your spell power.",
        icon = 237564,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "SUMMONED" },
                    key = "HEAL",
                    args = { amount = "0.15 * $stat.SPELL_AP$" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Demon Armor (increases armor by 60% and HEALING_TAKEN by 10%)
    ["aura-oCSWaTrait004"] = {
        id = "aura-oCSWaTrait004",
        name = "Demon Armor",
        description = "Armor increased by 60%. Healing received increased by 10%.",
        icon = 136185,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "60"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "HEAL_TAKEN",
                value = "10"
            }
        }
    },

    -- Pyroclasm (ON_CRIT: Increase SPELL_AP by 20% for 2 turns.)
    ["aura-oCSWaTrait005"] = {
        id = "aura-oCSWaTrait005",
        name = "Pyroclasm",
        description = "Whenever you land a critical strike, increase your spell power by 20% for 2 turns.",
        icon = 135830,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { aura = "aura-oCSWaTrait005-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSWaTrait005-Buff"] = {
        id = "aura-oCSWaTrait005-Buff",
        name = "Pyroclasm",
        description = "Spell attack power increased by 20%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135830,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "20"
            }
        }
    },
    
    -- Ruin (Increases SPELL_CRIT_MULT by 1)
    ["aura-oCSWaTrait006"] = {
        id = "aura-oCSWaTrait006",
        name = "Ruin",
        description = "Spell critical strike damage increased by 80%.",
        icon = 136207,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:warlock"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_CRIT_MULT",
                value = "0.8"
            }
        }
    },

    ------ Warlock Spell Effects -----
    -- Corruption (10 shadow damage every turn for 6 turns)
    ["aura-oCSWaAff001"] = {
        id = "aura-oCSWaAff001",
        name = "Corruption",
        description = "Taking 10 Shadow damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=6
        },
        icon = 136118,
        isTrait = false,
        isHelpful = false,
        dispelType = "CURSE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Shadow",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Fear (3 turn incapacitate, breaks on damage)
    ["aura-oCSWaAff003"] = {
        id = "aura-oCSWaAff003",
        name = "Fear",
        description = "Incapacitated. Cannot act or defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 136183,
        isTrait = false,
        isHelpful = false,
        dispelType = "CURSE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
            [2] = "fear"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Rain of Fire (5 fire damage every turn for 5 turns)
    ["aura-oCSWaDes003"] = {
        id = "aura-oCSWaDes003",
        name = "Rain of Fire",
        description = "Taking 5 Fire damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136186,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Fire",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Immolate (copy from Flame Shock)
    ["aura-oCSWaDes002"] = {
        id = "aura-oCSWaDes002",
        name = "Immolate",
        description = "Taking 15 Fire damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135817,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "15",
                            school = "Fire",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Curse of Weakness (reduces MELEE_AP by 10%)
    ["aura-oCSWaAff002"] = {
        id = "aura-oCSWaAff002",
        name = "Curse of Weakness",
        description = "Melee attack power reduced by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 136138,
        isTrait = false,
        isHelpful = false,
        dispelType = "CURSE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },

    -- Banish (banish, immune to all effects, does not break on damage, cannot act)
    ["aura-oCSWaDem003"] = {
        id = "aura-oCSWaDem003",
        name = "Banish",
        description = "Banished. Cannot act or defend. Immune to all effects.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=3
        },
        icon = 136135,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "warlock",
            [2] = "banish"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = true,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = true
        },
        immunity = {
            dispelTypes = { "MAGIC", "PHYSICAL", "DISEASE", "POISON" },
            tags = { "melee", "ranged", "spell" },
            damageSchools = { "physical", "fire", "frost", "arcane", "nature", "shadow", "holy", "fel" },
            helpful = true,
            harmful = true,
            ids = {}
        },
        modifiers = {}
    }
}

RPE.Data.DefaultClassic.AURAS_PRIEST = {
    ------ Priest Specialisations (Traits) ------
    -- Meditation (copy from Dreamstate)
    ["aura-oCSPrTrait001"] = {
        id = "aura-oCSPrTrait001",
        name = "Meditation",
        description = "Restore 3 mana per turn.",
        icon = 136090,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:priest"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "MANA",
                            amount = "3",
                            targets = { targeter = "CASTER" },
                            }
                        }
                    },
                    logic = "ALL",
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
        }
    },

    -- Focused Will (ON_HIT_TAKEN: Increase HEAL_POWER and ARMOR by 10%, stacking 3 times, lasting 2 turns.)
    ["aura-oCSPrTrait002"] = {
        id = "aura-oCSPrTrait002",
        name = "Focused Will",
        description = "Whenever you take damage, increase your healing power and armor by 10% for 2 turns. Stacks up to 3 times.",
        icon = 135737,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "STACKS",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "class:priest"
        },
        triggers = {
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { aura = "aura-oCSPrTrait002-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSPrTrait002-Buff"] = {
        id = "aura-oCSPrTrait002-Buff",
        name = "Focused Will",
        description = "Healing power and armor increased by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 135737,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "STACKS",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 3,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_ADD",
                stat = "HEAL_POWER",
                value = "10"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "10"
            }
        }
    },

    -- Blessed Recovery (ON_HIT_TAKEN: Apply Renew to self)
    ["aura-oCSPrTrait003"] = {
        id = "aura-oCSPrTrait003",
        name = "Blessed Recovery",
        description = "Whenever you take damage, apply Renew to yourself.",
        icon = 135877,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:priest"
        },
        triggers = {
            {
                event = "ON_HIT_TAKEN",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { aura = "aura-oCSPrHol003" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Spiritual Guidance (Increase HEAL_POWER by 5 x $stat.WIS_MOD$)
    ["aura-oCSPrTrait004"] = {
        id = "aura-oCSPrTrait004",
        name = "Spiritual Guidance",
        description = "Healing power increased by proportional to your Wisdom modifier.",
        icon = 135977,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "HEAL_POWER",
                value = "5 * $stat.WIS_MOD$"
            }
        }
    },

    -- Shadow Weaving (ON_HIT: increase SPELL_AP by 5% per stack, up to 5 times, lasting 2 turns)
    ["aura-oCSPrTrait005"] = {
        id = "aura-oCSPrTrait005",
        name = "Shadow Weaving",
        description = "Whenever you deal damage, increase your spell power by 5% for 2 turns. Stacks up to 5 times.",
        icon = 136123,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:priest"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "CASTER" },
                    key = "APPLY_AURA",
                    args = { aura = "aura-oCSPrTrait005-Buff" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    ["aura-oCSPrTrait005-Buff"] = {
        id = "aura-oCSPrTrait005-Buff",
        name = "Shadow Weaving",
        description = "Spell power increased by 5% per stack.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136123,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "ADD_MAGNITUDE",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 5,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "STACKS",
                mode = "PCT_ADD",
                stat = "SPELL_AP",
                value = "5"
            }
        }
    },

    -- Twisted Faith (Increases SPELL_POWER by 5 x $stat.WIS_MOD$)
    ["aura-oCSPrTrait006"] = {
        id = "aura-oCSPrTrait006",
        name = "Twisted Faith",
        description = "Spell power increased by proportional to your Wisdom modifier.",
        icon = 237566,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SPELL_AP",
                value = "5 * $stat.WIS_MOD$"
            }
        }
    },
    
    ------ Priest Spell Effects -----
    -- Renew (same as Rejuvenation)
    ["aura-oCSPrHol003"] = {
        id = "aura-oCSPrHol003",
        name = "Renew",
        description = "Restoring 10 health per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135953,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "HEAL",
                        args = {
                            amount = "10",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false,
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Vampiric Embrace (ON_HIT heal for 10 HP and gain 10 Mana)
    ["aura-oCSPrSha004"] = {
        id = "aura-oCSPrSha004",
        name = "Vampiric Embrace",
        description = "Heals for 10 health and restores 10 mana on dealing damage.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 136230,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest"
        },
        triggers = {
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "source" },
                key = "HEAL",
                args = { amount = "10" }
                }
            },
            {
            event = "ON_HIT",
            action = {
                targets = { ref = "source" },
                key = "GAIN_RESOURCE",
                args = { resourceId = "MANA", amount = "10" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },
    
    -- Prayer of Shadow Resistance (+3 SHADOW_RESIST)
    ["aura-oCSPrSha002"] = {
        id = "aura-oCSPrSha002",
        name = "Prayer of Shadow Protection",
        description = "Shadow resistance increased by 3.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=0
        },
        icon = 135945,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "SHADOW_RESIST",
                value = "3"
            }
        }
    },

    -- Vampiric Touch (15 shadow damage per turn for 5 turns, heal the cast for 15 per tick as well)
    ["aura-oCSPrSha003"] = {
        id = "aura-oCSPrSha003",
        name = "Vampiric Touch",
        description = "Taking 15 Shadow damage per turn. Caster healed for 15 per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135978,
        isTrait = false,
        isHelpful = false,
        dispelType = "CURSE",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "15",
                            school = "Shadow",
                            targets = { ref = "TARGET" },
                            }
                        },
                        [2] = {
                        key = "HEAL",
                        args = {
                            amount = "15",
                            targets = { ref = "CASTER" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Fear ward (immunity to fear auras for 5 turns)
    ["aura-oCSPrDis003"] = {
        id = "aura-oCSPrDis003",
        name = "Fear Ward",
        description = "Immune to fear effects.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 135902,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = { },
            tags = { "fear" },
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Power Word: Fortitude (10% max health)
    ["aura-oCSPrDis001"] = {
        id = "aura-oCSPrDis001",
        name = "Power Word: Fortitude",
        description = "Maximum health increased by 10%.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=0
        },
        icon = 135941,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "MAX_HEALTH",
                value = "10"
            }
        }
    },

    -- Shadow Word: Pain (10 shadow damage every turn for 5 turns)
    ["aura-oCSPriSha001"] = {
        id = "aura-oCSPriSha001",
        name = "Shadow Word: Pain",
        description = "Taking 10 Shadow damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=6
        },
        icon = 136207,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "priest",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "10",
                            school = "Shadow",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },
}

RPE.Data.DefaultClassic.AURAS_DEMON_HUNTER = {
    ------ Demon Hunter Specialisations (Traits) ------
    -- Critical Chaos (ON_CRIT: Generate 20 Fury)
    ["aura-oCSDhTrait001"] = {
        id = "aura-oCSDhTrait001",
        name = "Critical Chaos",
        description = "Generates 20 Fury on landing a critical strike.",
        icon = 1970140,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:demonhunter"
        },
        triggers = {
            {
                event = "ON_CRIT",
                action = {
                    targets = { ref = "CASTER" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "FURY", amount = "20" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Demon Blades (ON_HIT: Gain 1 additional Fury and deal 10 Shadow damage)
    ["aura-oCSDhTrait002"] = {
        id = "aura-oCSDhTrait002",
        name = "Demon Blades",
        description = "Generates 1 additional Fury and deals 10 Shadow damage on hit.",
        icon = 237507,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:demonhunter"
        },
        triggers = {
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "CASTER" },
                    key = "GAIN_RESOURCE",
                    args = { resourceId = "FURY", amount = "1" }
                }
            },
            {
                event = "ON_HIT",
                action = {
                    targets = { ref = "TARGET" },
                    key = "DAMAGE",
                    args = { amount = "10", school = "Shadow" }
                }
            }
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Know Your Enemy (increase MELEE_CRIT_MULT by 0.1 x (1 + MELEE_CRIT))
    ["aura-oCSDhTrait003"] = {
        id = "aura-oCSDhTrait003",
        name = "Know Your Enemy",
        description = "Melee critical strike damage multiplier increased based on your melee critical strike rating.",
        icon = 1380366,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:demonhunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MELEE_CRIT_MULT",
                value = "0.1 * (1 + $stat.MELEE_CRIT$)"
            }
        }
    },

    -- Untethered Fury (increases MAX_FURY by 50)
    ["aura-oCSDhTrait004"] = {
        id = "aura-oCSDhTrait004",
        name = "Untethered Fury",
        description = "Maximum Fury increased by 50.",
        icon = 2032602,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:demonhunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "MAX_FURY",
                value = "50"
            }
        }
    },

    -- Demonic Spikes (THREAT increased by 0.8, armor by 30%, melee attack power reduced by 10%)
    ["aura-oCSDhTrait005"] = {
        id = "aura-oCSDhTrait005",
        name = "Demonic Spikes",
        description = "Increases threat generation by 80% and armor by 20%, but reduces melee attack power by 10%.",
        icon = 1344645,
        isTrait = true,
        isHelpful = true,
        hidden = false,
        unpurgable = true,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "class:demonhunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADD",
                stat = "THREAT",
                value = "0.8"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_ADD",
                stat = "ARMOR",
                value = "20"
            },
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "PCT_SUB",
                stat = "MELEE_AP",
                value = "10"
            }
        }
    },
    
    ------ Demon Hunter Spell Effects -----
    -- Immolation Aura (5 fel damage per turn for 5 turns)
    ["aura-oCSDhBal001"] = {
        id = "aura-oCSDhHav003a",
        name = "Immolation Aura",
        description = "Taking 5 Fel damage per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 1344649,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "demon_hunter",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "DAMAGE",
                        args = {
                            amount = "5",
                            school = "Fel",
                            targets = { targeter = "TARGET" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Immolation Aura (oCSDhHav003b) - Generate 10 Fury per tick.
    ["aura-oCSDhHav003b"] = {
        id = "aura-oCSDhHav003b",
        name = "Immolation Aura",
        description = "Generates 10 Fury per turn.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=5
        },
        icon = 1344649,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "demon_hunter",
        },
        triggers = {},
        tick = {
            period = 1,
            actions = {
                [1] = {
                    phase = "onResolve",
                    actions = {
                        [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "10",
                            targets = { ref = "CASTER" },
                            }
                        }
                    },
                    logic = "ALL",
                    requirements = {}
                }
            },
        },
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    },

    -- Darkness (advantage on DODGE rolls for 2 turns)
    ["aura-oCSDhHav004"] = {
        id = "aura-oCSDhHav004",
        name = "Darkness",
        description = "Advantage level on Dodge rolls increased by 1.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 1305154,
        isTrait = false,
        isHelpful = true,
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = false,
        removeOnDamageTaken = false,
        maxStacks = 1,
        tags = {
            [1] = "demon_hunter"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = {},
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {
            {
                source = "CASTER",
                snapshot = "DYNAMIC",
                scaleWithStacks = "",
                mode = "ADVANTAGE",
                stat = "DODGE",
                value = "1"
            }
        }
    },

    -- Sigil of Chains (copy from Entangling Roots)
    ["aura-oCSDhVen004"] = {
        id = "aura-oCSDhVen004",
        name = "Sigil of Chains",
        description = "Cannot use Dodge to defend.",
        duration = {
            expires="ON_OWNER_TURN_END",
            turns=2
        },
        icon = 1418286,
        isTrait = false,
        isHelpful = false,
        dispelType = "MAGIC",
        hidden = false,
        unpurgable = false,
        stackingPolicy = "REFRESH_DURATION",
        conflictPolicy = "KEEP_HIGHER",
        uniqueByCaster = true,
        removeOnDamageTaken = true,
        maxStacks = 1,
        tags = {
            [1] = "demon_hunter",
            [2] = "root"
        },
        triggers = {},
        crowdControl = {
            blockAllActions = false,
            blockActionsByTag = {},
            slowMovement = 0,
            failDefencesByStats = { "DODGE" },
            failAllDefences = false
        },
        immunity = {
            dispelTypes = {},
            tags = {},
            damageSchools = {},
            helpful = false,
            harmful = false,
            ids = {}
        },
        modifiers = {}
    }
}

function RPE.Data.DefaultClassic.Auras()
    local items = {}
    local auraTables = {
        RPE.Data.DefaultClassic.AURAS_DEATH_KNIGHT,
        RPE.Data.DefaultClassic.AURAS_PALADIN,
        RPE.Data.DefaultClassic.AURAS_WARRIOR,
        RPE.Data.DefaultClassic.AURAS_DEATH_KNIGHT,
        RPE.Data.DefaultClassic.AURAS_SHAMAN,
        RPE.Data.DefaultClassic.AURAS_MAGE,
        RPE.Data.DefaultClassic.AURAS_HUNTER,
        RPE.Data.DefaultClassic.AURAS_EVOKER,
        RPE.Data.DefaultClassic.AURAS_ROGUE,
        RPE.Data.DefaultClassic.AURAS_MONK,
        RPE.Data.DefaultClassic.AURAS_DRUID,
        RPE.Data.DefaultClassic.AURAS_WARLOCK,
        RPE.Data.DefaultClassic.AURAS_PRIEST,
        RPE.Data.DefaultClassic.AURAS_DEMON_HUNTER,
        RPE.Data.DefaultClassic.AURAS_RACIAL,
        RPE.Data.DefaultClassic.AURAS_CONSUMABLE
    }
    
    for _, auraTable in ipairs(auraTables) do
        for k, v in pairs(auraTable) do
            items[k] = v
        end
    end
    
    return items
end
