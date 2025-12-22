RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.DefaultClassic = RPE.Data.DefaultClassic or {}

RPE.Data.DefaultClassic.SPELLS_COMMON = {
    -- Basic melee attack, main hand, STR modifier.
    ["spell-oCSC0001"] = {
        id = "spell-oCSC0001",
        name = "Main Hand Attack",
        description = "Deals $[1].amount$ Physical damage to the target, based on your main hand weapon and your Strength modifier.",
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\custom_spells\\melee_str.png",
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "general",
            [2] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Physical",
                            amount = "$wep.mainhand$ + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RAGE",
                            amount = "10 + $stat.STR_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "10 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Basic melee attack, main hand, DEX modifier.
    ["spell-oCSC0002"] = {
        id = "spell-oCSC0002",
        name = "Main Hand Attack",
        description = "Deals $[1].amount$ Physical damage to the target, based on your main hand weapon and your Dexterity modifier.",
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\custom_spells\\melee_dex.png",
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "general",
            [2] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Physical",
                            amount = "$wep.mainhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RAGE",
                            amount = "10 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "10 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Basic melee attack, off hand, STR modifier.
    ["spell-oCSC0003"] = {
        id = "spell-oCSC0003",
        name = "Off Hand Attack",
        description = "Deals $[1].amount$ Physical damage to the target, based on your off hand weapon and your Strength modifier.",
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\custom_spells\\melee_oh_str.png",
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.offhand"
        },
        tags = {
            [1] = "general",
            [2] = "melee"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Physical",
                            amount = "$wep.offhand$ + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "RAGE",
                            amount = "5 + $stat.STR_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "5 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Basic melee attack, off hand, DEX modifier.
    ["spell-oCSC0004"] = {
        id = "spell-oCSC0004",
        name = "Off Hand Attack",
        description = "Deals $[1].amount$ Physical damage to the target, based on your off hand weapon and your Dexterity modifier.",
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\custom_spells\\melee_oh_dex.png",
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.offhand"
        },
        tags = {
            [1] = "general",
            [2] = "melee"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Physical",
                            amount = "$wep.offhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "RAGE",
                            amount = "5 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "5 + $stat.DEX_MOD$",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    ["spell-oCSC0005"] = {
        id = "spell-oCSC0005",
        name = "Ranged Attack",
        description = "Deals $[1].amount$ Physical damage to the target, based on your ranged weapon and your Dexterity modifier.",
        icon = 132222,
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "general",
            [2] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Physical",
                            amount = "$wep.ranged$ + ($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DEFENCE$",
                            [4] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    ["spell-oCSC0006"] = {
        id = "spell-oCSC0006",
        name = "Wand Attack",
        description = "Deals $[1].amount$ $[1].school$ damage to the target, based on your wand and your Intelligence modifier.",
        icon = 132317,
        npcOnly = false,
        alwaysKnown = true,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged.wand"
        },
        tags = {
            [1] = "general",
            [2] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "$wep.ranged$",
                            amount = "$wep.ranged$ + ($stat.INT_MOD$ + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DEFENCE$",
                            [4] = "$stat.AC$",
                        },
                        critMult = "2",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_RACIAL = {
    -- Dwarf: Stoneform (apply aura)
    ["spell-oCSRaDwf1"] = {
        id = "spell-oCSRaDwf1",
        name = "Stoneform",
        description = "Removes all poison, disease, and bleed effects from you and increases your armor by 20% for 5 turns.",
        icon = 136225,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:dwarf"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCARaDwf1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Draenei: Gift of the Naaru (apply aura)
    ["spell-oCSRaDra1"] = {
        id = "spell-oCSRaDra1",
        name = "Gift of the Naaru",
        description = "Heals the target for 10 health per turn for 6 turns. During this time, they received 10% more healing from all sources.",
        icon = 135923,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:draenei"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCARaDra3",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Orc: Blood Fury (Increase MELEE_AP by 20% for 2 turns, HEAL_TAKEN reduced by 0.5)
    ["spell-oCSRaOrc1"] = {
        id = "spell-oCSRaOrc1",
        name = "Blood Fury",
        description = "Increases your melee attack power by 20% for 2 turns, but reduces healing received by 50%.",
        icon = 135726,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:orc"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCARaOrc1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Troll: Berserking (Immediately grants an ACTION)
    ["spell-oCSRaTro1"] = {
        id = "spell-oCSRaTro1",
        name = "Berserking",
        description = "Immediately grants 1 action and reduces the cooldown of all spells by 1.",
        icon = 135727,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:troll"
        },
        costs = {
            
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "ACTION",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [2] = {
                        key = "REDUCE_COOLDOWN",
                        args = {
                            amount = "1",
                            sharedGroup = "all",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Blood Elf: Arcane Torrent (Bonus action: Generate 20 energy, 20 Fury, 20 rage, 30 mana)
    ["spell-oCSRaBlf1"] = {
        id = "spell-oCSRaBlf1",
        name = "Arcane Torrent",
        description = "Generates 20 Energy, 20 Fury, 20 Rage, and 30 Mana.",
        icon = 136222,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:blood_elf"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "ENERGY",
                            amount = "20",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "FURY",
                            amount = "20",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RAGE",
                            amount = "20",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [4] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "MANA",
                            amount = "30",
                            targets = { targeter = "CASTER" }
                        }
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Pandaren: Quaking Palm (apply aura)
    ["spell-oCSRaPan1"] = {
        id = "spell-oCSRaPan1",
        name = "Quaking Palm",
        description = "Incapacitate the target for 1 turn. During this time, they cannot act or defend. Damage taken breaks the effect.",
        icon = 572035,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:pandaren"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRaPan001",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },                    
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Nightborne: Arcane Pulse (copy from arcane explosion)
    ["spell-oCSRaNig1"] = {
        id = "spell-oCSRaNig1",
        name = "Arcane Pulse",
        description = "Deals $[1].amount$ $[1].school$ damage, based on your maximum health, to up to 5 targets.",
        icon = 1851463,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:nightborne"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "0",
                            school = "Arcane",
                            amount = "(1d2 * 10) + math.floor(($stat.MAX_HEALTH$ * 0.20))",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Kul Tiran: Haymaker (apply aura)
    ["spell-oCSRaKul1"] = {
        id = "spell-oCSRaKul1",
        name = "Haymaker",
        description = "Stun the target for 1 turn. During this time, they cannot act or defend.",
        icon = 2447782,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:kultiran"
        },
        costs = {
            [1] = {
            resource = "BONUS_ACTION",
            amount = "1",
            when = "onStart",
            perRank = "",
            refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
            requirements = {},
            logic = "ALL",
            actions = {
                [1] = {
                key = "APPLY_AURA",
                args = {
                    auraId = "aura-oCSRaKulTiran001",
                    targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                },
                }
            },
            phase = "onResolve"
            }
        }
    },

    -- Dark Iron Dwarf: Fireblood (same as stoneform)
    ["spell-oCSRaDIr1"] = {
        id = "spell-oCSRaDIr1",
        name = "Fireblood",
        description = "Removes all poison, disease, curse, magic and bleed effects from you and increases your melee, spell and ranged attack power by 20% for 2 turns.",
        icon = 1786406,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "Racial",
            [2] = "race:darkiron"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCARaDia2",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_PALADIN = {
    ------ RETRIBUTION SPELLS ------
    -- Level 1: Crusader Strike (Single Target, Melee, Weapon Damage)
    ["spell-oCSPaRet001"] = {
        id = "spell-oCSPaRet001",
        name = "Crusader Strike",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage. Generates $[2].amount$ Holy Power.",
        icon = 135891,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "paladin",
            [2] = "retribution",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Holy",
                            amount = "$wep.mainhand$ + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "HOLY_POWER",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Templar's Verdict (Single Target, Melee, High Damage)
    ["spell-oCSPaRet002"] = {
        id = "spell-oCSPaRet002",
        name = "Templar's Verdict",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 461860,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 11,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "paladin",
            [2] = "retribution",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "HOLY_POWER",
                amount = "3",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Holy",
                            amount = "(3d6 * 10) + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Blessing of Might (+10 Melee Attack Power Buff)
    ["spell-oCSPaRet003"] = {
        id = "spell-oCSPaRet003",
        name = "Blessing of Might",
        description = "Increases the melee attack power of up to 5 allies by 10.",
        icon = 135906,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "retribution",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCAPaBles1",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Divine Storm (AoE Melee Attack)
    ["spell-oCSPaRet004"] = {
        id = "spell-oCSPaRet004",
        name = "Divine Storm",
        description = "Strikes up to 5 nearby enemies for $[1].amount$ $[1].school$ damage. All allies are healed for $[2].amount$, based on your Strength modifier.",
        icon = 236250,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 12,
        canCrit = true,
        targeter = { default = "PRECAST", maxTargets = 5, flags = "E" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "paladin",
            [2] = "retribution",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Holy",
                            amount = "math.floor(($wep.mainhand$ + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)) * 0.25)",
                            targets = { targeter = "PRECAST", maxTargets = 5, flages = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "HEAL",
                        args = {
                            threat = "0.8",
                            perRank = "1",
                            school = "Holy",
                            amount = "$stat.STR_MOD$",
                            targets = { targeter = "ALL_ALLIES" },
                            requiresHit = false
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                    }
                },
                phase = "onResolve"
            },
        }
    },

    ------ PROTECTION SPELLS ------
    -- Level 1: Shield of the Righteous (Single Target, Melee Attack + Armor Buff)
    ["spell-oCSPaPro002"] = {
        id = "spell-oCSPaPro002",
        name = "Shield of the Righteous",
        description = "Deals $[1].amount$ $[1].school$ damage, based on shield block rating, and increases your Armor by 10% for 2 turns. Generates a large amount of threat.",
        icon = 236265,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST", maxTargets = 1, flags = "E" },
        requirements = {
            [1] = "equip.offhand.shield"
        },
        tags = {
            [1] = "paladin",
            [2] = "protection",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 1.0",
                            perRank = "2",
                            school = "Holy",
                            amount = "(1d2 * 10) + $stat.SHIELD_BLOCK$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPaPro002",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    
    -- Level 3: Hammer of the Righteous (AoE Melee Attack)
    ["spell-oCSPaPro001"] = {
        id = "spell-oCSPaPro001",
        name = "Hammer of the Righteous",
        description = "Sends a holy wave of power out, striking up to 3 targets for $[1].amount$ $[1].school$ damage. Generates a large amount of threat and $[2].amount$ Holy Power.",
        icon = 236253,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 12,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "paladin",
            [2] = "protection",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 1.0",
                            perRank = "3",
                            school = "Holy",
                            amount = "(1d2 * 10) + math.floor(($stat.STR_MOD$ * 10 + $stat.MELEE_AP$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "HOLY_POWER",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Hammer of Justice (1 turn stun)
    ["spell-oCSPaCC1"] = {
        id = "spell-oCSPaCC1",
        name = "Hammer of Justice",
        description = "Stuns the target for 1 turn. During this time, they cannot act or defend.",
        icon = 135963,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "protection",
            [3] = "cc",
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 6,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCAPaCC1",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },                    
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    }, 
    
    -- Level 10: Blessing of Protection
    ["spell-oCSPaPro004"] = {
        id = "spell-oCSPaPro004",
        name = "Blessing of Protection",
        description = "Protects the target ally from all physical attacks for 1 turn.",
        icon = 135964,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "protection",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCAPaBles3",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },    

    ------ HOLY SPELLS ------
    -- Level 1: Holy Light (Slow, Powerful Heal)
    ["spell-oCSPaHol001"] = {
        id = "spell-oCSPaHol001",
        name = "Holy Light",
        description = "Heals the target for $[1].amount$.",
        icon = 135981,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "holy",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Holy",
                            amount = "(3d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                            requiresHit = false
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = nil,
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Flash of Light (Instant Heal)
    ["spell-oCSPaHol002"] = {
        id = "spell-oCSPaHol002",
        name = "Flash of Light",
        description = "Heals the target for $[1].amount$.",
        icon = 135907,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "holy",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Holy",
                            amount = "(2d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },    
                            requiresHit = false
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = nil,
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Blessing of Wisdom (mana regen buff)
    ["spell-oCSPaHol004"] = {
        id = "spell-oCSPaHol004",
        name = "Blessing of Wisdom",
        description = "Increase the mana regeneration of up to 5 allies by 2 mana per turn.",
        icon = 135970,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
         rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "retribution",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "50",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCAPaBles2",
                            targets = { targeter = "TARGET", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Holy Shock (Instant Heal, Reaction)
    ["spell-oCSPaHol003"] = {
        id = "spell-oCSPaHol003",
        name = "Holy Shock",
        description = "Heals the target for $[1].amount$. Can only be used as a reaction.",
        icon = 135972,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 9,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "paladin",
            [2] = "holy",
            [3] = "heal",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            school = "Holy",
                            amount = "(1d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.25)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                            requiresHit = false
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = nil,
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_WARRIOR = {
    -- Arms Spells (Levels 1, 2, 4, 8)
    -- Level 1: Heroic Strike (Single Target Melee Attack)
    ["spell-oCSWaArm001"] = {
        id = "spell-oCSWaArm001",
        name = "Heroic Strike",
        description = "A powerful melee attack that deals $[1].amount$ $[1].school$ damage. Has an increased chance to hit and generates a moderate amount of threat.",
        icon = 132282,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 4,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "arms",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "15",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 0.5",
                            perRank = "2",
                            amount = "(2d2 * 10) + $wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Physical",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$ * 2"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Rend (bleed DoT)
    ["spell-oCSWaArm002"] = {
        id = "spell-oCSWaArm002",
        name = "Rend",
        description = "Causes the target to bleed, dealing 5 Physical damage each turn for 5 turns.",
        icon = 132155,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 0,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "arms",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaArm002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Charge (Generate rage and prevents defences)
    ["spell-oCSWaArm003"] = {
        id = "spell-oCSWaArm003",
        name = "Charge",
        description = "Charges at the target, generating $[1].amount$ Rage and preventing them from defending against attacks for 1 turn.",
        icon = 132337,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "arms",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = true
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RAGE",
                            amount = "13",
                            perRank = "2",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaArm003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Mortal Strike (High Damage Melee Attack, reduces healing)
    ["spell-oCSWaArm004"] = {
        id = "spell-oCSWaArm004",
        name = "Mortal Strike",
        description = "A devastating melee attack that deals $[1].amount$ $[1].school$ damage and reduces healing received by the target by 50% for 3 turns.",
        icon = 132355,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "arms",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "25",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            amount = "(2d3 * 10) + $wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Physical",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaArm004",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Fury Spells (Levels 1, 3, 5, 10)
    -- Level 1: Battle Shout (10% Attack Power buff, all allies)
    ["spell-oCSWaFur001"] = {
        id = "spell-oCSWaFur001",
        name = "Battle Shout",
        description = "Increases the melee attack power of up to 5 allies by 20% for 5 turns.",
        icon = 132333,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "fury",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaFur001",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = { "A" } }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 1: Pummel (Interrupt)
    ["spell-oCSWaFur001b"] = {
        id = "spell-oCSWaFur001b",
        name = "Pummel",
        description = "Interrupts the target's spellcasting.",
        icon = 132938,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "fury",
            [3] = "interrupt"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 3: Whirlwind (RAID_MARKER attack, similar to divine storm)
    ["spell-oCSWaFur002"] = {
        id = "spell-oCSWaFur002",
        name = "Whirlwind",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and any adjacent enemies.",
        icon = 132369,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "fury",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "20",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            amount = "math.floor(($wep.mainhand$ + ($stat.STR_MOD$ * 10 + $stat.MELEE_AP$)) * 0.40)",
                            school = "Physical",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Intimidating Shout (Fear)
    ["spell-oCSWaFur003"] = {
        id = "spell-oCSWaFur003",
        name = "Intimidating Shout",
        description = "Fears the target enemy and their adjacent allies for 2 turns. Breaks on damage taken.",
        icon = 132154,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "fury",
            [3] = "cc"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 8,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaFur003",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" }
                        },
                    },
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 10, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 10: Death Wish (increase damage dealt and taken)
    ["spell-oCSWaFur004"] = {
        id = "spell-oCSWaFur004",
        name = "Death Wish",
        description = "Increases your melee attack power by 30% but reduces your armor by 75% for 2 turns.",
        icon = 136146,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "fury",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "5",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaFur004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Protection Spells (Levels 1, 4, 8, 12)
    -- Level 1: Shield Block (Increases BLOCK stat)
    ["spell-oCSWaPro001"] = {
        id = "spell-oCSWaPro001",
        name = "Shield Block",
        description = "Increases your Block rating by 5 for 1 turn and grants advantage on Block rolls. Can be used as a reaction.",
        icon = 132110,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "protection",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaPro001",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Sunder Armor (high threat, reduce AC/Defence/Block)
    ["spell-oCSWaPro002"] = {
        id = "spell-oCSWaPro002",
        name = "Sunder Armor",
        description = "Deals $[1].amount$ $[1].school$ damage and reduces the target's Armor by 5% for 3 turns. Stacks up to 5 times. Generates a high amount of threat.",
        icon = 132363,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "protection",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "10",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 0.5",
                            perRank = "2",
                            amount = "(1d4 * 10) + math.floor($wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$)*0.75",
                            school = "$wep.mainhand$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaPro002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Ignore Pain (1 turn cooldown, small absorb)
    ["spell-oCSWaPro003"] = {
        id = "spell-oCSWaPro003",
        name = "Ignore Pain",
        description = "Absorbs up to $[2].amount$ damage, equal to your armor rating, for 1 turn.",
        icon = 1377132,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "protection",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "RAGE",
                amount = "5",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaPro003",
                            targets = { targeter = "CASTER" }
                        },
                    },
                    [2] = {
                        key = "SHIELD",
                        args = {
                            amount = "$stat.ARMOR$",
                            duration = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Last Stand (Increase max HP temporarily)
    ["spell-oCSWaPro004"] = {
        id = "spell-oCSWaPro004",
        name = "Last Stand",
        description = "Increases your maximum health by 30% for 2 turns.",
        icon = 135871,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warrior",
            [2] = "protection",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaPro004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_DEATH_KNIGHT = {
    -- Frost Spells (Levels 1, 2, 4, 8)
    -- Level 1: Icy Touch (single target frost spell damage and apply frost fever aura)
    ["spell-oCSDkFro001"] = {
        id = "spell-oCSDkFro001",
        name = "Icy Touch",
        description = "Deals $[1].amount$ $[1].school$ damage and applies Frost Fever to the target, dealing 5 frost damage each turn for 5 turns. Generates $[3].amount$ Runic Power.",
        icon = 237526,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "frost",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            amount = "(2d2 * 10) + (($stat.STR_MOD$ * 10) + $stat.MELEE_AP$)",
                            school = "Frost",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.FROST_RESIST$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkFro001",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RUNIC_POWER",
                            amount = "10",
                            perRank = "2",
                            targets = { targeter = "CASTER" }
                        }
                    }
                }
            }
        }
    },

    -- Level 2: Frost Strike (costs runic power resource, melee weapon damage as frost damage)
    ["spell-oCSDkFro002"] = {
        id = "spell-oCSDkFro002",
        name = "Frost Strike",
        description = "A powerful melee attack that deals $[1].amount$ $[1].school$ damage.",
        icon = 237520,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "frost",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RUNIC_POWER",
                amount = "40",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            amount = "(2d3*10) + $wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Frost",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    }
                },

                phase = "onResolve"
            }
        }
    },

    -- Level 4: Howling Blast (AOE frost damage RAID_MARKER targeter, applies frost fever)
    ["spell-oCSDkFro003"] = {
        id = "spell-oCSDkFro003",
        name = "Howling Blast",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and any adjacent enemies, and applies Frost Fever to each target, dealing 5 frost damage each turn for 5 turns.",
        icon = 135833,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "frost",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "dk_frost_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            amount = "(2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            school = "Frost",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.FROST_RESIST$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkFro001",
                            targets = { targeter = "TARGET", maxTargets = 10, flags = "E" }
                        },
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RUNIC_POWER",
                            amount = "20",
                            perRank = "2",
                            targets = { targeter = "CASTER" }
                        }
                    }
                }
            }
        }
    },

    -- Level 8: Obliterate (high damage melee attack, frost rune spell, reduces cooldown on frost spell group)
    ["spell-oCSDkFro004"] = {
        id = "spell-oCSDkFro004",
        name = "Obliterate",
        description = "A powerful melee attack that deals $[1].amount$ $[1].school$ damage and reduces the cooldown of your blood and unholy spells by 1 turn.",
        icon = 135771,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "frost",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = "dk_frost_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            amount = "(2d3*10) + $wep.both$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Frost",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "RUNIC_POWER",
                            amount = "20",
                            perRank = "4",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "REDUCE_COOLDOWN",
                        args = {
                            sharedGroup = "dk_blood_spells",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [4] = {
                        key = "REDUCE_COOLDOWN",
                        args = {
                            sharedGroup = "dk_unholy_spells",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Blood Spells (Levels 1, 3, 5, 10)
    -- Level 1: Heart Strike (melee cleave, hits target and adjacent enemies, blood spell, high threat)
    ["spell-oCSDkBlo001"] = {
        id = "spell-oCSDkBlo001",
        name = "Heart Strike",
        description = "Strikes up to 2 enemies, dealing $[1].amount$ $[1].school$ damage to each, based on 60% of your main-hand weapon damage. Generates a moderate amount of threat.",
        icon = 135675,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST", maxTargets = 2, flags = "E" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "blood",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 0.5",
                            perRank = "2",
                            amount = "math.floor(($wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$) * 0.6)",
                            school = "Shadow",
                            targets = { targeter = "PRECAST", maxTargets = 2, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.SHADOW_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                [2] = {
                    key = "GAIN_RESOURCE",
                    args = {
                        resourceId = "RUNIC_POWER",
                        amount = "10",
                        perRank = "2",
                        targets = { targeter = "CASTER" }
                    }
                }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 3: Rune Tap (heals self, blood spell)
    ["spell-oCSDkBlo002"] = {
        id = "spell-oCSDkBlo002",
        name = "Rune Tap",
        description = "Heal yourself for $[1].amount$. Can be used as a reaction.",
        icon = 237529,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "blood",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "dk_blood_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "(1d2 * 10) + math.floor($stat.MELEE_AP$ * 0.5)",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" },
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                ,
                [2] = {
                    key = "GAIN_RESOURCE",
                    args = {
                        resourceId = "RUNIC_POWER",
                        amount = "5",
                        targets = { targeter = "CASTER" }
                    }
                }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Death Strike (weapon damage as shadow, heal for half of weapon damage)
    ["spell-oCSDkBlo003"] = {
        id = "spell-oCSDkBlo003",
        name = "Death Strike",
        description = "A powerful melee attack that deals $[1].amount$ $[1].school$ damage and heals you for 50% of the damage dealt. Generates a high amount of threat.",
        icon = 237517,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "blood",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "RUNIC_POWER",
                amount = "40",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 1.0",
                            perRank = "2",
                            amount = "$wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Shadow",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.SHADOW_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "math.floor(($wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$) * 0.5)",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" },
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 10: Vampiric Blood (increase max health temporarily, blood spell, heal on damage dealt)
    ["spell-oCSDkBlo004"] = {
        id = "spell-oCSDkBlo004",
        name = "Vampiric Blood",
        description = "Increases your maximum health by 30% for 2 turns. While active, dealing damage heals you for 10% of your melee attack power. Can be used as a reaction.",
        icon = 136168,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "blood",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "RUNIC_POWER",
                amount = "10",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkBlo004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Unholy Spells (Levels 1, 4, 8, 12)
    -- Level 1: Plague Strike (single target shadow spell and apply blood plague, same as frost fever)
    ["spell-oCSDkUnh001"] = {
        id = "spell-oCSDkUnh001",
        name = "Plague Strike",
        description = "Deals $[1].amount$ $[1].school$ damage and applies Blood Plague to the target, dealing 5 shadow damage each turn for 5 turns.",
        icon = 237519,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "unholy",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            amount = "(2d2 * 10) + (($stat.STR_MOD$ * 10) + $stat.MELEE_AP$)",
                            school = "Shadow",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.SHADOW_RESIST$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkUnh001",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                }
            }
        }
    },

    -- Level 4: Raise Dead (summon ghoul minion)
    ["spell-oCSDkUnh002"] = {
        id = "spell-oCSDkUnh002",
        name = "Raise Dead",
        description = "Summons a ghoul to fight for you.",
        icon = 136119,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "unholy",
            [3] = "summon"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "dk_unholy_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SUMMON",
                        args = {
                            npcId = "NPC-04c32e80",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Unholy Frenzy (stacking melee hit buff)
    ["spell-oCSDkUnh003"] = {
        id = "spell-oCSDkUnh003",
        name = "Unholy Frenzy",
        description = "Increases your melee hit by 1 for 3 turns. Stacks up to 10 times.",
        icon = 237512,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "unholy",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "RUNIC_POWER",
                amount = "5",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "dk_unholy_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkUnh003",
                            targets = { targeter = "CASTER" }
                        },
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Soul Reaper (applies ON_KILL buff to caster for 3 turns, deals weapon damage as shadow damage)
    ["spell-oCSDkUnh004"] = {
        id = "spell-oCSDkUnh004",
        name = "Soul Reaper",
        description = "Deals $[2].amount$ $[2].school$ damage and applies a buff to you that causes your next kill to heal you for 50% of your melee attack power. Lasts 3 turns.",
        icon = 636333,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "death_knight",
            [2] = "unholy",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = "dk_unholy_spells"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDkUnh004",
                            targets = { targeter = "CASTER" }
                        },
                    },
                    [2] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            amount = "(2d3 * 10) + $wep.mainhand$ + ($stat.STR_MOD$ * 10) + $stat.MELEE_AP$",
                            school = "Shadow",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.BLOCK$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.SHADOW_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    }
}

RPE.Data.DefaultClassic.SPELLS_SHAMAN = {
    -- Enhancement Spells (Levels 1, 2, 4, 8)
    -- Level 1: Primal Strike (weapon damage as nature damage)
    ["spell-oCSShaEnh001"] = {
        id = "spell-oCSShaEnh001",
        name = "Primal Strike",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage. Generates $[2].amount$ Maelstrom.",
        icon = 460956,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "shaman",
            [2] = "enhancement",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Nature",
                            amount = "$wep.mainhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.NATURE_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "MAELSTROM",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 2: Lava Lash (off hand weapon damage, bonus action, fire damage)
    ["spell-oCSShaEnh002"] = {
        id = "spell-oCSShaEnh002",
        name = "Lava Lash",
        description = "Deals $[1].amount$ $[1].school$ damage, based on off-hand weapon damage. Generates $[2].amount$ Maelstrom.",
        icon = 236289,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.offhand"
        },
        tags = {
            [1] = "shaman",
            [2] = "enhancement",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Fire",
                            amount = "$wep.offhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "MAELSTROM",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Stormstrike (heavy weapon damage based on both weapons, nature damage, costs 5 Maelstrom)
    ["spell-oCSShaEnh003"] = {
        id = "spell-oCSShaEnh003",
        name = "Stormstrike",
        description = "Deals $[1].amount$ $[1].school$ damage, based on both weapon damage.",
        icon = 132314,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.dual",
        },
        tags = {
            [1] = "shaman",
            [2] = "enhancement",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "MAELSTROM",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Nature",
                            amount = "(2d3 * 10) + $wep.both$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.PARRY$",
                            [2] = "$stat.DODGE$",
                            [3] = "$stat.BLOCK$",
                            [4] = "$stat.DEFENCE$",
                            [5] = "$stat.AC$",
                            [6] = "$stat.NATURE_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Shamanistic Rage (generates mana on hit, increases melee attack power by 30%)
    ["spell-oCSShaEnh004"] = {
        id = "spell-oCSShaEnh004",
        name = "Shamanistic Rage",
        description = "Increases your melee attack power by 30% for 3 turns. While active, dealing damage generates 5 mana.",
        icon = 136088,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "enhancement",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSShaEnh004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Elemental Spells (Levels 1, 3, 5, 10)
    -- Level 1: Lightning Bolt (1 turn cast nature damage spell)
    ["spell-oCSShaEle001"] = {
        id = "spell-oCSShaEle001",
        name = "Lightning Bolt",
        description = "Deals $[1].amount$ $[1].school$ damage to the target.",
        icon = 136048,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "elemental",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Nature",
                            amount = "(2d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.NATURE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "MAELSTROM",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Flame Shock (applies fire damage over time effect)
    ["spell-oCSShaEle002"] = {
        id = "spell-oCSShaEle002",
        name = "Flame Shock",
        description = "Deals $[3].amount$ $[3].school$ damage instantly, then an additional $[2].amount$ Fire damage over 3 turns.",
        icon = 135813,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "elemental",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSShaEle002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "MAELSTROM",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        }
                    },
                    [3] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(1d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.4)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 5: Chain Lightning (multi target nature damage spell, copy from hammer of righteousness)
    ["spell-oCSShaEle003"] = {
        id = "spell-oCSShaEle003",
        name = "Chain Lightning",
        description = "Deals $[1].amount$ $[1].school$ damage to up to 3 targets.",
        icon = 136015,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "elemental",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Nature",
                            amount = "(1d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.NATURE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "MAELSTROM",
                            amount = "3",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Lava Burst (high damage fire spell, costs maelstrom)
    ["spell-oCSShaEle004"] = {
        id = "spell-oCSShaEle004",
        name = "Lava Burst",
        description = "Deals $[1].amount$ $[1].school$ damage. Critical strikes from this spell deal 100% additional damage.",
        icon = 237582,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "elemental",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MAELSTROM",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "5",
                            school = "Fire",
                            amount = "(3d3 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$ + 1.0",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Restoration Spells (Levels 1, 4, 8, 12)
    -- Level 1: Healing Wave
    ["spell-oCSShaRes001"] = {
        id = "spell-oCSShaRes001",
        name = "Healing Wave",
        description = "Heals the target for $[1].amount$.",
        icon = 136052,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "restoration",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Nature",
                            amount = "(3d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Earth Shield (apply aura)
    ["spell-oCSShaRes002"] = {
        id = "spell-oCSShaRes002",
        name = "Earth Shield",
        description = "Applies an Earth Shield to the target, which heals them for $[1].amount$ whenever they take damage. Lasts 5 turns.",
        icon = 136089,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "restoration",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "10",
                            auraId = "aura-oCSShaRes002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Riptide (reaction spell, copy from holy shock)
    ["spell-oCSShaRes003"] = {
        id = "spell-oCSShaRes003",
        name = "Riptide",
        description = "Heals the target for $[1].amount$ instantly, and an additional 15 over 3 turns.",
        icon = 252995,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "restoration",
            [3] = "heal",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            school = "Nature",
                            amount = "(1d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.2)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "5",
                            auraId = "aura-oCSShaRes003",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 12: Chain Heal (multi target heal, copy from healing wave)
    ["spell-oCSShaRes004"] = {
        id = "spell-oCSShaRes004",
        name = "Chain Heal",
        description = "Heals up to 3 targets for $[1].amount$.",
        icon = 136042,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "shaman",
            [2] = "restoration",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            school = "Nature",
                            amount = "math.floor((1d2 * 10) + (($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "A" },
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_HUNTER = {
    -- Marksmanship Spells (Levels 1, 2, 4, 8)
    -- Level 1: Steady Shot (1 turn cast, generates 20 focus, deals ranged weapon damage)
    ["spell-oCSHuMar001"] = {
        id = "spell-oCSHuMar001",
        name = "Steady Shot",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage. Generates $[2].amount$ Focus.",
        icon = 132213,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "marksmanship",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Physical",
                            amount = "$wep.ranged$ + ($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.BLOCK$",
                            [5] = "$stat.PARRY$",
                        },
                        critMult = "$stat.RANGED_CRIT_MULT$",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            auraId = "FOCUS",
                            amount = "20",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Arcane Shot (instant cast, deals weapon damage as arcane damage)
    ["spell-oCSHuMar002"] = {
        id = "spell-oCSHuMar002",
        name = "Arcane Shot",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage.",
        icon = 132218,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "marksmanship",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "FOCUS",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Arcane",
                            amount = "$wep.ranged$ + ($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.ARCANE_RESIST$",
                            [5] = "$stat.PARRY$",
                            [6] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.RANGED_CRIT_MULT$",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Multi-Shot (instant cast, multi target)
    ["spell-oCSHuMar003"] = {
        id = "spell-oCSHuMar003",
        name = "Multi-Shot",
        description = "Deals $[1].amount$ $[1].school$ damage to up to 3 targets, based on weapon damage.",
        icon = 132330,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "marksmanship",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "FOCUS",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "physical",
                            amount = "(1d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.RANGED_CRIT_MULT$",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Aimed Shot (heavy damage based on ranged weapon, 1 turn cast)
    ["spell-oCSHuMar004"] = {
        id = "spell-oCSHuMar004",
        name = "Aimed Shot",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage.",
        icon = 135130,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "marksmanship",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "FOCUS",
                amount = "20",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Physical",
                            amount = "(2d3 * 10) + $wep.mainhand$ + ($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.RANGED_CRIT_MULT$",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$ + 5"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Beast Mastery Spells (Levels 1, 3, 5, 10)
    -- Level 1: Call Pet (copy from Raise Dead)
    ["spell-OCSHuBeM000"] = {
        id = "spell-OCSHuBeM000",
        name = "Call Pet",
        description = "Summons your pet to your side.",
        icon = 132161,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "hunter",
            [2] = "beast mastery",
            [3] = "summon"
        },
        costs = {
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SUMMON",
                        args = {
                            npcId = "NPC-summonedpet",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 1: Mend Pet (heals SUMMONED units)
    ["spell-OCSHuBeM001"] = {
        id = "spell-OCSHuBeM001",
        name = "Mend Pet",
        description = "Heals your pet for $[1].amount$ health.",
        icon = 132179,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "SUMMONED" },
        requirements = {
            [1] = "summoned.pet"
        },
        tags = {
            [1] = "hunter",
            [2] = "beast mastery",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "FOCUS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "(1d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.25)",
                            targets = { targeter = "SUMMONED", maxTargets = 1, flags = "A" },
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 3: Bestial Wrath (applies 100% MELEE_AP buff to SUMMONED units)
    ["spell-OCSHuBeM002"] = {
        id = "spell-OCSHuBeM002",
        name = "Bestial Wrath",
        description = "Increases your pet's melee attack power by 100% for 2 turns.",
        icon = 132127,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "SUMMONED" },
        requirements = {
            [1] = "summoned.pet"
        },
        tags = {
            [1] = "hunter",
            [2] = "beast mastery",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "10",
                            auraId = "aura-OCSHuBeM002",
                            targets = { targeter = "SUMMONED", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Intimidation (stuns your target, copy from hammer of justice, requires a pet)
    ["spell-OCSHuBeM003"] = {
        id = "spell-OCSHuBeM003",
        name = "Intimidation",
        description = "Stuns the target for 1 turn. During this time they cannot act or defend.",
        icon = 132111,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "summoned.pet"
        },
        tags = {
            [1] = "hunter",
            [2] = "beast mastery",
            [3] = "stun"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-OCSHuBeM003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Survival Spells (Levels 1, 4, 8, 12)
    -- Level 1: Raptor Strike (weapon damage based on dex, copy from heroic strike)
    ["spell-oCSHuSur001"] = {
        id = "spell-oCSHuSur001",
        name = "Raptor Strike",
        description = "Deals $[1].amount$ $[1].school$ damage, based on weapon damage. Increases melee attack power by 10% for 3 turns, stacking up to 3 times.",
        icon = 1376046,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "hunter",
            [2] = "survival",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "FOCUS",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Physical",
                            amount = "$wep.melee$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$",
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSHuSur001",
                            amount = 1,
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "B" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Serpent Sting (bonus action, applies nature damage over time, copy from flame shock)
    ["spell-oCSHuSur002"] = {
        id = "spell-oCSHuSur002",
        name = "Serpent Sting",
        description = "Applies a poison to the target that deals $[1].amount$ Nature damage over 3 turns.",
        icon = 1033905,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "survival",
            [3] = "ranged",
            [4] = "dot"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "FOCUS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "10",
                            auraId = "aura-oCSHuSur002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Explosive Shot (heavy RAID_MARKER fire damage)
    ["spell-oCSHuSur003"] = {
        id = "spell-oCSHuSur003",
        name = "Explosive Shot",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and any adjacent enemies.",
        icon = 236178,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged"
        },
        tags = {
            [1] = "hunter",
            [2] = "survival",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "FOCUS",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(2d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.RANGED_AP$) * 0.25)",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DODGE$",
                            [2] = "$stat.DEFENCE$",
                            [3] = "$stat.AC$",
                            [4] = "$stat.FIRE_RESIST$",
                            [6] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.RANGED_CRIT_MULT$",
                        critModifier = "$stat.RANGED_CRIT$",
                        hitModifier = "$stat.RANGED_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Deterrance (immunity to physical, copy from blessing of protection)
    ["spell-oCSHuSur004"] = {
        id = "spell-oCSHuSur004",
        name = "Deterrance",
        description = "Grants immunity to Physical damage for 1 turns but renders you unable to act.",
        icon = 132369,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "hunter",
            [2] = "survival",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSHuSur004",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_EVOKER = {
    -- Devestation Spells (Levels 1, 2, 4, 8)
    -- Level 1: Pyre (Costs 2 essence, action, RAID_MARKER fire damage)
    ["spell-oCSEvDev001"] = {
        id = "spell-oCSEvDev001",
        name = "Pyre",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and their adjacent allies.",
        icon = 4622468,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "devastation",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ESSENCE",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "evoker_red"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 2: Azure Strike (action, half arcane half frost damage to 3 targets)
    ["spell-oCSEvDev002"] = {
        id = "spell-oCSEvDev002",
        name = "Azure Strike",
        description = "Deals $[1].amount$ $[1].school$ damage to up to 3 targets.",
        icon = 4622447,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "devastation",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "evoker_blue"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    -- Arcane component
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "1",
                            school = "Arcane",
                            amount = "math.floor((1d2 * 10) + math.floor(($stat.STR_MOD$ * 10 + $stat.MELEE_AP$) * 0.66)) * 0.5",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    -- Frost component
                    [2] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "1",
                            school = "Frost",
                            amount = "math.floor((1d2 * 10) + math.floor(($stat.STR_MOD$ * 10 + $stat.MELEE_AP$) * 0.66)) * 0.5",
                            targets = { targeter = "TARGET" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FROST_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Shattering Star (spellfrost damage, instant cast, reduces arcane, frost and fire resistance by 2 for 1 turn)
    ["spell-oCSEvDev003"] = {
        id = "spell-oCSEvDev003",
        name = "Shattering Star",
        description = "Deals $[1].amount$ $[1].school$ damage. Reduces the target's Arcane, Frost and Fire resistance by 2 for 2 turns.",
        icon = 4622449,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "devastation",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "evoker_blue"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    -- Arcane component
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Frost",
                            amount = "math.floor((2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$)) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FROST_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    -- Frost Component,
                    [2] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Arcane",
                            amount = "math.floor((2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$)) * 0.5)",
                            targets = { targeter = "TARGET" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [3] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvDev003",
                            targets = { targeter = "TARGET" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Dragonrage (instant, hits 3 targets with Pyre, increases spell power by 30% for 2 turns).
    ["spell-oCSEvDev004"] = {
        id = "spell-oCSEvDev004",
        name = "Dragonrage",
        description = "Deals $[1].amount$ $[1].school$ damage to up to 3 targets. Increases your spell power by 30% for 2 turns.",
        icon = 4622452,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "devastation",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = "evoker_red"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvDev004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Preservation Spells (Levels 1, 3, 5, 10)
    -- Level 1: Reversion (healing over time, apply aura, bonus action)
    ["spell-oCSEvPre001"] = {
        id = "spell-oCSEvPre001",
        name = "Reversion",
        description = "Heals an ally for $[1].amount$ health plus an additional $[2].amount$ every turn for 3 turns.",
        icon = 4630469,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "ALLY" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "preservation",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "evoker_bronze"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "(2d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.4)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "10",
                            auraId = "aura-oCSEvPre001",
                            targets = { targeter = "TARGET" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Emerald Blossom (heals 3 allies)
    ["spell-oCSEvPre002"] = {
        id = "spell-oCSEvPre002",
        name = "Emerald Blossom",
        description = "Heals up to 3 allies for $[1].amount$ health.",
        icon = 4622457,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "preservation",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "ESSENCE",
                amount = "3",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "evoker_green"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "math.floor((1d2 * 10) + (($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "A" },
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 5: Echo (direct heal, then apply an ON_HEAL_TAKEN trigger)
    ["spell-oCSEvPre003"] = {
        id = "spell-oCSEvPre003",
        name = "Echo",
        description = "Heals an ally for $[1].amount$ health. For 3 turns, all direct healing applied to the target heals them for an additional 10 health.",
        icon = 4622456,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "preservation",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = "evoker_bronze"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "math.floor((1d2 * 10) + (($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            amount = "10",
                            auraId = "aura-oCSEvPre003",
                            targets = { targeter = "TARGET" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Verdant Embrace (instant, direct heal)
    ["spell-oCSEvPre004"] = {
        id = "spell-oCSEvPre004",
        name = "Verdant Embrace",
        description = "Heals an ally for $[1].amount$ health.",
        icon = 4622471,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "preservation",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "evoker_green"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Nature",
                            amount = "(2d2 * 10) + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Augmentation Spells (Levels 1, 4, 8, 12)
    -- Level 1: Prescience (increases melee, ranged and critical strike of an ally by 1 for 3 turns).
    ["spell-oCSEvAug001"] = {
        id = "spell-oCSEvAug001",
        name = "Prescience",
        description = "Increases an ally's melee, ranged and spell critical strike by 1 for 3 turns.",
        icon = 5199639,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "augmentation",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "evoker_bronze"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvAug001",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Ebon Might (1 turn cast, increases all allies' primary stats by 2 for 2 turns, grants you 20% spell power for 2 turns).
    ["spell-oCSEvAug002"] = {
        id = "spell-oCSEvAug002",
        name = "Ebon Might",
        description = "Increases up to 5 allies' primary stats by 2 for 2 turns. Grants you 20% spell power for 2 turns.",
        icon = 5061347,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "augmentation",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = "evoker_black"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvAug002a",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvAug002b",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Time Skip (1 turn cast, Reduces the cooldown of all allies' spells by 1 turn)
    ["spell-oCSEvAug003"] = {
        id = "spell-oCSEvAug003",
        name = "Time Skip",
        description = "Reduces the cooldown of all allies' spells by 1 turn.",
        icon = 5201905,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "augmentation",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = "evoker_bronze"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "REDUCE_COOLDOWN",
                        args = {
                            sharedGroup = "ALL",
                            amount = 1,
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Blistering Scales (Increases an ally's armor by 20% and causes them to deal fire damage to attackers for 2 turns).
    ["spell-oCSEvAug004"] = {
        id = "spell-oCSEvAug004",
        name = "Blistering Scales",
        description = "Increases an ally's armor by 20% and causes them to deal fire damage to attackers for 2 turns.",
        icon = 5199621,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "evoker",
            [2] = "augmentation",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = "evoker_black"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSEvAug004",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

}

RPE.Data.DefaultClassic.SPELLS_ROGUE = {
    -- Assassination Spells (Levels 1, 2, 4, 8)
    -- Level 1: Eviscerate (5 combo points, heavy physical damage)
    ["spell-oCSRoAss001"] = {
        id = "spell-oCSRoAss001",
        name = "Eviscerate",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 132292,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "rogue",
            [2] = "assassination",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "COMBO_POINTS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Physical",
                            amount = "(3d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Rupture (5 combo points, apply heavy bleed over time)
    ["spell-oCSRoAss002"] = {
        id = "spell-oCSRoAss002",
        name = "Rupture",
        description = "Causes the target to bleed for $[1].amount$ $[1].school$ damage over 5 turns.",
        icon = 132302,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "rogue",
            [2] = "assassination",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "COMBO_POINTS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoAss002",
                            amount = 1,
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Ambush (heavy damage with both weapons, requires hidden)
    ["spell-oCSRoAss003"] = {
        id = "spell-oCSRoAss003",
        name = "Ambush",
        description = "Deals $[1].amount$ $[1].school$ damage with both weapons. This ability has a very high chance to hit. Awards 3 combo points.",
        icon = 132282,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "hidden",
            [2] = "equip.dual"
        },
        tags = {
            [1] = "rogue",
            [2] = "assassination",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "60",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Physical",
                            amount = "(3d2 * 10) + $wep.both$ + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$) * 2.0)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$ + 10"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "3",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Mutilate (damage with both weapons, action, 60 energy cost)
    ["spell-oCSRoAss004"] = {
        id = "spell-oCSRoAss004",
        name = "Mutilate",
        description = "Deals $[1].amount$ $[1].school$ damage with both weapons. Awards 2 combo points.",
        icon = 132304,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.dual",
        },
        tags = {
            [1] = "rogue",
            [2] = "assassination",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "60",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Physical",
                            amount = "$wep.both$ + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        }
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        },
                    }
                }
            }
        }
    },

    -- Subtlety Spells (Levels 1, 3, 5, 10)
    -- Level 1: Stealth
    ["spell-oCSRoSub001"] = {
        id = "spell-oCSRoSub001",
        name = "Stealth",
        description = "Enter stealth, becoming invisible to enemies until you attack or are detected.",
        icon = 132320,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "rogue",
            [2] = "subtlety",
            [3] = "stealth"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HIDE",
                        args = {
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Sap (incapacitate target for 3 turns, must be hidden)
    ["spell-oCSRoSub002"] = {
        id = "spell-oCSRoSub002",
        name = "Sap",
        description = "Incapacitate a target for 3 turns. Can only be used while stealthed. During this time, they cannot attack or cast spells. Breaks when the target takes damage.",
        icon = 132310,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "hidden"
        },
        tags = {
            [1] = "rogue",
            [2] = "subtlety",
            [3] = "control"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoSub002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },                    
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Blind (incapacitate target for 2 turns)
    ["spell-oCSRoSub003"] = {
        id = "spell-oCSRoSub003",
        name = "Blind",
        description = "Incapacitate a target for 2 turns. During this time, they cannot attack or cast spells. Breaks when the target takes damage.",
        icon = 136175,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "rogue",
            [2] = "subtlety",
            [3] = "incapacitate"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 8,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoSub003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },                    
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Shuriken Toss (copy from multishot)
    ["spell-oCSRoSub004"] = {
        id = "spell-oCSRoSub004",
        name = "Shuriken Toss",
        description = "Throws shurikens at up to 3 enemies, dealing $[1].amount$ $[1].school$ damage to each target. Awards 1 combo point.",
        icon = 135431,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.ranged.thrown"
        },
        tags = {
            [1] = "rogue",
            [2] = "subtlety",
            [3] = "ranged"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "25",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Physical",
                            amount = "math.floor(($wep.ranged$ + ($stat.DEX_MOD$ * 10) + $stat.RANGED_AP$) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Combat Spells (Levels 1, 4, 8, 12)
    -- Level 1: Sinister Strike (main hand damage, action, 35 energy cost, awards 1 combo point)
    ["spell-oCSRoCom001"] = {
        id = "spell-oCSRoCom001",
        name = "Sinister Strike",
        description = "Deals $[1].amount$ $[1].school$ damage. Awards 1 combo point.",
        icon = 132223,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "rogue",
            [2] = "combat",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "35",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Physical",
                            amount = "(2d2 * 10) + $wep.mainhand$ + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Evasion (increase dodge chance for 2 turns, reaction)
    ["spell-oCSRoCom002"] = {
        id = "spell-oCSRoCom002",
        name = "Evasion",
        description = "Increases your dodge rating by 5 and grants advantage on dodge rolls for 2 turns.",
        icon = 136205,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "rogue",
            [2] = "combat",
            [3] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoCom002",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Gouge (1 turn stun, copy from hammer of justice)
    ["spell-oCSRoCom003"] = {
        id = "spell-oCSRoCom003",
        name = "Gouge",
        description = "Stuns the target for 1 turn. During this time, they cannot attack or cast spells. Awards 1 combo point.",
        icon = 132155,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "equip.mainhand"
        },
        tags = {
            [1] = "rogue",
            [2] = "combat",
            [3] = "stun"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoCom003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    },                    
                    [3] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 12: Adrenaline Rush (restores 20 additional energy per turn for 3 turns)
    ["spell-oCSRoCom004"] = {
        id = "spell-oCSRoCom004",
        name = "Adrenaline Rush",
        description = "Restores 20 additional energy per turn for 3 turns.",
        icon = 136206,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "rogue",
            [2] = "combat",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSRoCom004",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_MONK = {
    -- Windwalker Spells (Levels 1, 2, 4, 8)
    -- Level 1: Tiger Palm (damage and apply melee attack power buff, same as raptor strike, 35 energy cost and generate 1 chi)
    ["spell-oCSMoWin001"] = {
        id = "spell-oCSMoWin001",
        name = "Tiger Palm",
        description = "Deals $[1].amount$ $[1].school$ damage and increases your melee attack power by 5 for 3 turns. Generates 1 Chi.",
        icon = 606551,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "windwalker",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "35",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "3",
                            school = "Physical",
                            amount = "(2d2 * 10) + math.floor(($stat.AGI_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoWin001",
                            amount = 1,
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "CHI",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Rising Sun Kick (2 chi cost, apply debuff to reduce target's armor)
    ["spell-oCSMoWin002"] = {
        id = "spell-oCSMoWin002",
        name = "Rising Sun Kick",
        description = "Deals $[1].amount$ $[1].school$ damage and reduces the target's armor by 20% for 3 turns.",
        icon = 642415,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "windwalker",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "CHI",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Physical",
                            amount = "(3d2 * 10) + math.floor(($stat.AGI_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoWin002",
                            amount = 1,
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Fists of Fury (3 chi cost, damage and stun raid marker for 1 turn)
    ["spell-oCSMoWin003"] = {
        id = "spell-oCSMoWin003",
        name = "Fists of Fury",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and any adjacent targets. Stuns them for 1 turn.",
        icon = 627606,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "windwalker",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "CHI",
                amount = "3",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Physical",
                            amount = "(2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            targets = { targeter = "RAID_MARKER", maxTargets = 5, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoWin003",
                            amount = 1,
                            targets = { targeter = "TARGET", maxTargets = 5, flags = "E" }
                        },
                    },                    
                    [3] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 5, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Touch of Karma (absorb 100 damage, reaction, causes attackers to take physical damage)
    ["spell-oCSMoWin004"] = {
        id = "spell-oCSMoWin004",
        name = "Touch of Karma",
        description = "Absorbs up to $[1].amount$ damage for 2 turns. While active, attackers take 30 Physical damage when they hit you.",
        icon = 651728,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "windwalker",
            [3] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoWin004",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    },
                    [2] = {
                        key = "SHIELD",
                        args = {
                            amount = "100 + ($stat.DEX_MOD$ * 10)",
                            duration = "2",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Brewmaster Spells (Levels 1, 3, 5, 10)
    -- Level 1: Guard (absorbs damage, costs 2 chi)
    ["spell-oCSMoBre001"] = {
        id = "spell-oCSMoBre001",
        name = "Guard",
        description = "Absorbs up to $[1].amount$ damage for 5 turns. Increases healing received by 10% while active.",
        icon = 611417,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "brewmaster",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "CHI",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SHIELD",
                        args = {
                            amount = "100 + (($stat.DEX_MOD$ * 10) + $stat.MELEE_AP$)",
                            duration = "5",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoBre001",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 2: Keg Smash (damage and apply debuff to reduce target's attack power, generates 2 Chi, generates 1.5x threat)
    ["spell-oCSMoBre002"] = {
        id = "spell-oCSMoBre002",
        name = "Keg Smash",
        description = "Deals $[1].amount$ $[1].school$ damage and reduces the target's attack power by 10% for 3 turns. Generates 2 Chi.",
        icon = 594274,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "brewmaster",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "ENERGY",
                amount = "40",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 4,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ * 1.5",
                            perRank = "4",
                            school = "Physical",
                            amount = "(3d2 * 10) + math.floor(($stat.AGI_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoBre002",
                            amount = 1,
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    },
                    [3] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "CHI",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Blackout Kick (damage and increase dodge rating, stacks up to 3 times, costs 2 chi)
    ["spell-oCSMoBre003"] = {
        id = "spell-oCSMoBre003",
        name = "Blackout Kick",
        description = "Deals $[1].amount$ $[1].school$ damage and increases your Dodge rating by 1 for 5 turns. Stacks up to 3 times. Generates a large amount of threat.",
        icon = 574575,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "brewmaster",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "CHI",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 1.0",
                            perRank = "4",
                            school = "Physical",
                            amount = "(3d2 * 10) + math.floor(($stat.AGI_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoBre003",
                            amount = 1,
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Fortifying Brew (increases max health and armour by 30% for 3 turns, reaction)
    ["spell-oCSMoBre004"] = {
        id = "spell-oCSMoBre004",
        name = "Fortifying Brew",
        description = "Increases your maximum health and armor by 30% for 3 turns.",
        icon = 615341,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "brewmaster",
            [3] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoBre004",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Mistweaver Spells (Levels 1, 4, 8, 12)
    -- Level 1: Vivify (direct heal, copy from holy light)
    ["spell-oCSMoMis001"] = {
        id = "spell-oCSMoMis001",
        name = "Vivify",
        description = "Heals a target for $[1].amount$ health. Generates 1 chi.",
        icon = 1360980,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "mistweaver",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "ENERGY",
                amount = "30",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Nature",
                            amount = "(3d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "CHI",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Renewing Mist (heal over time)
    ["spell-oCSMoMis002"] = {
        id = "spell-oCSMoMis002",
        name = "Renewing Mist",
        description = "Heals the target for 10 health every turn for 5 turns.",
        icon = 627487,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "mistweaver",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoMis002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Enveloping Mist (heal over time and increase healing received by 30%, costs 3 chi)
    ["spell-oCSMoMis003"] = {
        id = "spell-oCSMoMis003",
        name = "Enveloping Mist",
        description = "Heals the target for 15 health every turn for 5 turns and increases healing received by 30%.",
        icon = 775461,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "mistweaver",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "CHI",
                amount = "3",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoMis003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 12: Life Cocoon (absorb shield and increase healing received by 50%)
    ["spell-oCSMoMis004"] = {
        id = "spell-oCSMoMis004",
        name = "Life Cocoon",
        description = "Absorbs up to $[2].amount$ damage for 1 turns and increases healing received by 50%.",
        icon = 627485,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "monk",
            [2] = "mistweaver",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMoMis004",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    },
                    [2] = {
                        key = "SHIELD",
                        args = {
                            amount = "100 + (($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$)",
                            duration = "1",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_DRUID = {
    -- Balance Spells (Levels 1, 2, 4, 8)
    -- Level 1: Wrath (single target nature damage, copy from fireball)
    ["spell-oCSDrBal001"] = {
        id = "spell-oCSDrBal001",
        name = "Wrath",
        description = "Deals $[1].amount$ $[1].school$ damage to a target.",
        icon = 136006,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "balance",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Nature",
                            amount = "(2d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.NATURE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                }     },
                phase = "onResolve"
            }
        }
    },
    -- Level 2: Moonfire (single target arcane damage, apply arcane dot, bonus action)
    ["spell-oCSDrBal002"] = {
        id = "spell-oCSDrBal002",
        name = "Moonfire",
        description = "Deals $[1].amount$ $[1].school$ damage and causes the target to take 10 Arcane damage every turn for 5 turns.",
        icon = 136096,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "balance",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Arcane",
                            amount = "math.floor(((1d2 * 10) + ($stat.INT_MOD$ * 10) + $stat.SPELL_AP$) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrBal002",
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Thorns (apply aura)
    ["spell-oCSDrBal003"] = {
        id = "spell-oCSDrBal003",
        name = "Thorns",
        description = "Surrounds the caster with thorns, causing attackers to take 10 Nature damage. Lasts 5 turns.",
        icon = 136104,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "balance",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrBal003",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Entangling Roots (prevents target from dodging)
    ["spell-oCSDrBal004"] = {
        id = "spell-oCSDrBal004",
        name = "Entangling Roots",
        description = "Roots the target in place for 2 turns, preventing them from dodging attacks.",
        icon = 136100,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "balance",
            [3] = "cc"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrBal004",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Feral Spells (Levels 1, 3, 5, 10)
    -- Level 1: Prowl (copy from Stealth in SPELLS_ROGUE)
    ["spell-oCSDrFer001"] = {
        id = "spell-oCSDrFer001",
        name = "Prowl",
        description = "Enter stealth, becoming invisible to enemies until you attack or are detected.",
        icon = 514640,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "feral",
            [3] = "stealth"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HIDE",
                        args = {
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 1: Claw (sinister strike)
    ["spell-oCSDrFer002"] = {
        id = "spell-oCSDrFer002",
        name = "Claw",
        description = "Deals $[1].amount$ $[1].school$ damage. Awards 1 combo point.",
        icon = 132140,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "feral",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "30",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Physical",
                            amount = "(2d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$ * 1.2))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "1",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Ferocious Bite
    ["spell-oCSDrFer003"] = {
        id = "spell-oCSDrFer003",
        name = "Ferocious Bite",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 132127,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "feral",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "COMBO_POINTS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "6",
                            school = "Physical",
                            amount = "(3d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 5: Pounce (requires stealth, stuns the target for 1 turn, generates 3 combo points)
    ["spell-oCSDrFer004"] = {
        id = "spell-oCSDrFer004",
        name = "Pounce",
        description = "Stuns the target for 1 turn and generates 3 combo points. Can only be used while stealthed.",
        icon = 132142,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
            [1] = "hidden"
        },
        tags = {
            [1] = "druid",
            [2] = "feral",
            [3] = "cc"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ENERGY",
                amount = "40",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrFer004",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "COMBO_POINTS",
                            amount = "3",
                            targets = { targeter = "CASTER" }
                        },
                    },                    
                    [3] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Savage Roar (increases melee attack power by 100% for 3 turns, requires 5 combo points)
    ["spell-oCSDrFer005"] = {
        id = "spell-oCSDrFer005",
        name = "Savage Roar",
        description = "Increases your melee attack power by 100% for 3 turns. Requires 5 combo points.",
        icon = 132121,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "feral",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "COMBO_POINTS",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrFer005",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Restoration Spells (Levels 1, 4, 8, 12)
    -- Level 1: Healing Touch (copy from Holy Light, Healing Wave)
    ["spell-oCSDrRes001"] = {
        id = "spell-oCSDrRes001",
        name = "Healing Touch",
        description = "Heals a target for $[1].amount$ health.",
        icon = 136041,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "restoration",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Nature",
                            amount = "(3d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Mark of the Wild (increases 5 targets stats by 1 and nature resistance by 3)
    ["spell-oCSDrRes002"] = {
        id = "spell-oCSDrRes002",
        name = "Mark of the Wild",
        description = "Increases the primary attributes of up to 5 allies by 1 and their Nature resistance by 3.",
        icon = 136078,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "restoration",
            [3] = "buff"
        },
        costs = {
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrRes002",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Rejuvenation (apply aura, copy from Renewing Mist)
    ["spell-oCSDrRes003"] = {
        id = "spell-oCSDrRes003",
        name = "Rejuvenation",
        description = "Heals the target for 10 health every turn for 5 turns.",
        icon = 136081,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "restoration",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDrRes003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Wild Growth (heals up to 5 allies)
    ["spell-oCSDrRes004"] = {
        id = "spell-oCSDrRes004",
        name = "Wild Growth",
        description = "Heals up to 5 allies for $[1].amount$ health.",
        icon = 236153,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "druid",
            [2] = "restoration",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Nature",
                            amount = "math.floor((2d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.25",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" },
                        },
                        hitThreshold = {
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_DEMON_HUNTER = {
    -- Havoc Spells (Levels 1, 2, 4, 8)
    -- Level 1: Chaos Strike (weapon damage as fel damage, copy from Crusader Strike)
    ["spell-oCSDhHav001"] = {
        id = "spell-oCSDhHav001",
        name = "Chaos Strike",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 1305152,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "demon_hunter",
            [2] = "havoc",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "FURY",
                amount = "30",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fel",
                            amount = "(2d2 * 10) + math.floor(($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$ * 1.2))",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$",
                            [6] = "$stat.FEL_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 2: Blade Dance (cleave attack, copy from Whirlwind, deal fel damage)
    ["spell-oCSDhHav002"] = {
        id = "spell-oCSDhHav002",
        name = "Blade Dance",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and any adjacent targets.",
        icon = 1305149,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "havoc",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "FURY",
                amount = "40",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fel",
                            amount = "math.floor(($wep.mainhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)) * 0.40)",
                            targets = { targeter = "AREA_ENEMY", maxTargets = 3, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$",
                            [6] = "$stat.FEL_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Immolation Aura (copy from Blizzard /Rain of Fire, deal fel damage to 5 targets over 5 turns)
    ["spell-oCSDhHav003"] = {
        id = "spell-oCSDhHav003",
        name = "Immolation Aura",
        description = "Deals 5 Fel damage each turn for 5 turns to the target and any adjacent targets. During this time, you generate 10 Fury each turn.",
        icon = 1344649,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "havoc",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = { -- Apply to enemies
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDhHav003a",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "E" }
                        },
                    },
                    [2] = { -- Apply to self
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDhHav003b",
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Darkness (all allies gain 1 advantage level on Dodge rolls)
    ["spell-oCSDhHav004"] = {
        id = "spell-oCSDhHav004",
        name = "Darkness",
        description = "Up to 5 allies gain 1 advantage level on Dodge rolls for 2 turns.",
        icon = 1305154,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "ALL_ALLIES" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "havoc",
            [3] = "buff",
            [4] = "reaction"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDhHav004",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = { "A" } }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Vengeance Spells (Levels 1, 3, 5, 10)
    -- Level 1: Fracture (generates 2 soul fragments, copy from Heart Strike, high threat)
    ["spell-oCSDhVen001"] = {
        id = "spell-oCSDhVen001",
        name = "Fracture",  
        description = "Deals $[1].amount$ $[1].school$ damage and generates 2 soul fragments.",
        icon = 1388065,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "vengeance",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "($stat.THREAT$ * 1.5)",
                            perRank = "2",
                            school = "$wep.mainhand$",
                            amount = "math.floor(($wep.mainhand$ + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$)) * 0.66)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "SOUL_FRAGMENTS",
                            amount = "2",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Soul Cleave (deals shadow damage and heals self. costs 2 soul fragments.)
    ["spell-oCSDhVen002"] = {
        id = "spell-oCSDhVen002",
        name = "Soul Cleave",
        description = "Deals $[1].amount$ Shadow damage and heals you for $[2].amount$ health. Consumes 2 soul fragments.",
        icon = 1344653,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "vengeance",
            [3] = "melee"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "SOUL_FRAGMENTS",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Shadow",
                            amount = "(2d3 * 10) + ($stat.DEX_MOD$ * 10 + $stat.MELEE_AP$ * 1.2)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$",
                            [6] = "$stat.SHADOW_RESIST$"
                        },
                        critMult = "$stat.MELEE_CRIT_MULT$",
                        critModifier = "$stat.MELEE_CRIT$",
                        hitModifier = "$stat.MELEE_HIT$"
                    },
                    [2] = {
                        key = "HEAL",
                        args = {
                            threat = "0",
                            perRank = "5",
                            school = "Shadow",
                            amount = "(2d3 * 10) + ($stat.DEX_MOD$ * 10)",
                            targets = { ref = "CASTER", maxTargets = 1, flags = "A" },
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    },
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 5: Soul Barrier (self-absorb, copy from Guard)
    ["spell-oCSDhVen003"] = {
        id = "spell-oCSDhVen003",
        name = "Soul Barrier",
        description = "Absorbs up to $[1].amount$ damage for 3 turns.",
        icon = 2065625,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "vengeance",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [3] = {
                resource = "SOUL_FRAGMENTS",
                amount = "2",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SHIELD",
                        args = {
                            amount = "100 + (($stat.DEX_MOD$ * 10) + $stat.MELEE_AP$)",
                            turns = 3,
                            targets = { targeter = "CASTER", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Sigil of Chains (immobilizes RAID_MARKER for 2 turns, copy from Entangling Roots)
    ["spell-oCSDhVen004"] = {
        id = "spell-oCSDhVen004",
        name = "Sigil of Chains",
        description = "Roots the target in place for 2 turns, preventing them from dodging attacks.",
        icon = 1418286,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {},
        tags = {
            [1] = "demon_hunter",
            [2] = "vengeance",
            [3] = "cc"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSDhVen004",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}
 
RPE.Data.DefaultClassic.SPELLS_WARLOCK = {
    -- Demonology Spells (Levels 1, 3, 5, 10)
    -- Level 1: Summon Imp
    ["spell-oCSWaDem001"] = {
        id = "spell-oCSWaDem001",
        name = "Summon Imp",
        description = "Summons an imp to fight for you.",
        icon = 136218,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "demonology",
            [3] = "summon"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "warlock_summon"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SUMMON",
                        args = {
                            npcId = "NPC-summonedpet",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Health Funnel (heals SUMMONED at cost of own health)
    ["spell-oCSWaDem002"] = {
        id = "spell-oCSWaDem002",
        name = "Health Funnel",
        description = "Sacrifices your health to heal your summoned demon for $[1].amount$ health.",
        icon = 136168,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "demonology",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "HEALTH",
                amount = "($stat.INT_MOD$ * 10) + $stat.SPELL_POWER$",
                when = "onStart",
                perRank = "($stat.INT_MOD$ * 10)",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "2",
                            amount = "math.floor(5d2 + ($stat.INT_MOD$ * 10) + $stat.SPELL_POWER$) * 0.75",
                            targets = { targeter = "SUMMONED", maxTargets = 10, flags = "A" },
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Banish (3 turn incapacitate)
    ["spell-oCSWaDem003"] = {
        id = "spell-oCSWaDem003",
        name = "Banish",
        description = "Banishes the target for 3 turns. During this time, they are cannot attack or cast spells and are immune to all effects.",
        icon = 136135,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "demonology",
            [3] = "banish",
            [4] = "cc"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 3,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaDem003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 10: Summon Voidwalker
    ["spell-oCSWaDem004"] = {
        id = "spell-oCSWaDem004",
        name = "Summon Voidwalker",
        description = "Summons a voidwalker to fight for you.",
        icon = 136221,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "demonology",
            [3] = "summon"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 2,
            starts = "onResolve",
            sharedGroup = "warlock_summon"
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SUMMON",
                        args = {
                            npcId = "NPC-summonedpet",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Demonology Spells (Levels 1, 2, 4, 8)
    -- Level 1: Corruption (10 shadow damage every turn for 6 turns, bonus action)
    ["spell-oCSWaAff001"] = {
        id = "spell-oCSWaAff001",
        name = "Corruption",
        description = "Deals $[1].amount$ Shadow damage to the target every turn for 6 turns.",
        icon = 136118,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "affliction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaAff001",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Curse of Weakness (reduces the target's melee AP by 10% for 5 turns)
    ["spell-oCSWaAff002"] = {
        id = "spell-oCSWaAff002",
        name = "Curse of Weakness",
        description = "Reduces the target's melee attack power by 10% for 5 turns.",
        icon = 136138,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "affliction",
            [3] = "curse",
            [4] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaAff002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Fear (2 turn incapacitate, breaks on damage taken)
    ["spell-oCSWaAff003"] = {
        id = "spell-oCSWaAff003",
        name = "Fear",
        description = "Frightens the target for 3 turns, causing them to flee in terror. The effect breaks if the target takes damage.",
        icon = 136183,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "affliction",
            [3] = "cc",
            [4] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaAff003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },                    
                    [2] = {
                        key = "INTERRUPT",
                        args = {
                            targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Life Tap (restores mana at cost of health)
    ["spell-oCSWaAff004"] = {
        id = "spell-oCSWaAff004",
        name = "Life Tap",
        description = "Sacrifices your health to restore $[1].amount$ mana.",
        icon = 136126,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "affliction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "HEALTH",
                amount = "($stat.INT_MOD$ * 10) + $stat.SPELL_POWER$",
                when = "onStart",
                perRank = "5",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "GAIN_RESOURCE",
                        args = {
                            resourceId = "MANA",
                            perRank = "5",
                            amount = "math.floor(5d2 + ($stat.INT_MOD$ * 10) + $stat.SPELL_POWER$)",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Destruction Spells (Levels 1, 4, 8, 12)
    -- Level 1: Shadow Bolt (copy from fireball)
    ["spell-oCSWaDes001"] = {
        id = "spell-oCSWaDes001",
        name = "Shadow Bolt",
        description = "Deals $[1].amount$ Shadow damage.",
        icon = 136197,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "destruction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Shadow",
                            amount = "(2d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.DODGE$",
                            [4] = "$stat.PARRY$",
                            [5] = "$stat.BLOCK$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Immolate (copy from Flame Shock)
    ["spell-oCSWaDes002"] = {
        id = "spell-oCSWaDes002",
        name = "Immolate",
        description = "Deals $[3].amount$ $[3].school$ damage instantly, then an additional 15 Fire damage every turn for 5 turns.",
        icon = 135817,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "destruction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
            requirements = {},
            logic = "ALL",
            actions = {
                [1] = {
                    key = "APPLY_AURA",
                    args = {
                        auraId = "aura-oCSWaDes002",
                        targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    },
                [2] = {
                    key = "DAMAGE",
                    args = {
                        threat = "$stat.THREAT$",
                        perRank = "2",
                        school = "Fire",
                        amount = "math.floor(((1d2 * 10) + ($stat.INT_MOD$ * 10 + $stat.SPELL_AP$)) * 0.6)",
                        targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                        requiresHit = true
                    },
                    hitThreshold = {
                        [1] = "$stat.DEFENCE$",
                        [2] = "$stat.AC$",
                        [3] = "$stat.FIRE_RESIST$"
                    },
                    critMult = "$stat.SPELL_CRIT_MULT$",
                    critModifier = "$stat.SPELL_CRIT$",
                    hitModifier = "$stat.SPELL_HIT$"
                }
            },
            phase = "onResolve"
            }
        }
    },
    
    -- Level 8: Rain of Fire (copy from Blizzard)
    ["spell-oCSWaDes003"] = {
        id = "spell-oCSWaDes003",
        name = "Rain of Fire",
        description = "Deals 5 Fire damage each turn for 5 turns to the target and any adjacent targets.",
        icon = 136186,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "AREA_ENEMY" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "destruction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSWaDes003",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 12: Chaos Bolt (heavy fel damage)
    ["spell-oCSWaDes004"] = {
        id = "spell-oCSWaDes004",
        name = "Chaos Bolt",
        description = "Deals $[1].amount$ Fel damage. This spell cannot miss, has a higher chance to crit, and deals 100% additional critical strike damage. Generates a moderate amount of threat.",
        icon = 236291,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "warlock",
            [2] = "destruction",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$ + 0.5",
                            perRank = "6",
                            school = "Fel",
                            amount = "(4d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FEL_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$ + 1.0",
                        critModifier = "$stat.SPELL_CRIT$ + 5",
                        hitModifier = "$stat.SPELL_HIT$ * 100",
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_PRIEST = {
    -- Holy Spells (Levels 1, 2, 4, 8)
    -- Level 1: Heal (copy from holy light)
    ["spell-oCSPrHol001"] = {
        id = "spell-oCSPrHol001",
        name = "Heal",
        description = "Heals the target for $[1].amount$ health.",
        icon = 135915,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 4,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "holy",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Holy",
                            amount = "(3d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" },
                            requiresHit = false
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 1: Smite (copy from Fireball)
    ["spell-oCSPrHol002"] = {
        id = "spell-oCSPrHol002",
        name = "Smite",
        description = "Deals $[1].amount$ Holy damage.",
        icon = 135924,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "holy",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Holy",
                            amount = "(2d2 * 10) + (($stat.WIS_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.HOLY_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Renew (copy from Rejuvenation)
    ["spell-oCSPrHol003"] = {
        id = "spell-oCSPrHol003",
        name = "Renew",
        description = "Heals the target for 10 health every turn for 5 turns.",
        icon = 135953,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "holy",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrHol003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Prayer of Healing (copy from wild growth)
    ["spell-oCSPrHol004"] = {
        id = "spell-oCSPrHol004",
        name = "Prayer of Healing",
        description = "Heals up to 5 allies within the target area for $[1].amount$ health.",
        icon = 135943,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "AREA_ALLY" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "holy",
            [3] = "heal"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "HEAL",
                        args = {
                            threat = "0.6",
                            perRank = "3",
                            school = "Holy",
                            amount = "math.floor((2d2 * 10) + ($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.25",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" },
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Discipline Spells (Levels 1, 3, 5, 10)
    -- Level 1: Power Word Fortitude (max health increased by 10%)
    ["spell-oCSPrDis001"] = {
        id = "spell-oCSPrDis001",
        name = "Power Word: Fortitude",
        description = "Increases the maximum health of up to 5 allies by 10%.",
        icon = 135941,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "discipline",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrDis001",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 3: Power Word: Shield (absorb shield for 2 turns)
    ["spell-oCSPrDis002"] = {
        id = "spell-oCSPrDis002",
        name = "Power Word: Shield",
        description = "Shields the target, absorbing $[1].amount$ damage for 2 turns.",
        icon = 135940,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 8,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "discipline",
            [3] = "shield"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SHIELD",
                        args = {
                            amount = "30 + math.floor(($stat.WIS_MOD$ * 10) + ($stat.HEAL_POWER$ * 0.5))",
                            turns = 2,
                            perRank = 5,
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 5: Fear Ward (grants the target immunity to fear auras for 5 turns)
    ["spell-oCSPrDis003"] = {
        id = "spell-oCSPrDis003",
        name = "Fear Ward",
        description = "Grants the target immunity to fear effects for 5 turns.",
        icon = 135902,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "discipline",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrDis003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 10: Power Word: Barrier (grants all allies a SHIELD for 1 turn)
    ["spell-oCSPrDis004"] = {
        id = "spell-oCSPrDis004",
        name = "Power Word: Barrier",
        description = "Creates a barrier that shields up to 5 all allies, absorbing $[1].amount$ damage for 1 turn.",
        icon = 253400,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 10,
        rankInterval = 10,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "discipline",
            [3] = "shield"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "5",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "REACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SHIELD",
                        args = {
                            amount = "30 + math.floor((($stat.WIS_MOD$ * 10) + $stat.HEAL_POWER$) * 0.5)",
                            turns = 1,
                            perRank = 10,
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = { "A" } }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Shadow Spells (Levels 1, 4, 8, 12)
    -- Level 1: Shadow Word: Pain
    ["spell-oCSPrSha001"] = {
        id = "spell-oCSPrSha001",
        name = "Shadow Word: Pain",
        description = "Deals 10 Shadow damage to the target every turn for 6 turns.",
        icon = 136207,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "shadow",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrSha001",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 4: Shadow Protection (shadow resist buff)
    ["spell-oCSPrSha002"] = {
        id = "spell-oCSPrSha002",
        name = "Prayer of Shadow Protection",
        description = "Increases the Shadow resistance of up to 5 allies by 3.",
        icon = 135945,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "shadow",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrSha002",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 8: Vampiric Touch (apply aura, 1 turn cast)
    ["spell-oCSPrSha003"] = {
        id = "spell-oCSPrSha003",
        name = "Vampiric Touch",
        description = "Afflicts the target with a vampiric curse, dealing 15 Shadow damage every turn for 5 turns and healing the caster for 15 health.",
        icon = 135978,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "shadow",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrSha003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
    -- Level 12: Vampiric Embrace (apply aura to all allies)
    ["spell-oCSPrSha004"] = {
        id = "spell-oCSPrSha004",
        name = "Vampiric Embrace",
        description = "Empower up to 5 allies with shadow magic, causing them to gain 10 health and 10 mana each time they deal damage. Lasts for 2 turns.",
        icon = 136230,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "priest",
            [2] = "shadow",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSPrSha004",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = { "A" } }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

RPE.Data.DefaultClassic.SPELLS_MAGE = {
    ------ Arcane SPELLS (1, 2, 4, 8) ------
    -- Level 1: Arcane Intellect (int buff)
    ["spell-oCSMaArc001"] = {
        id = "spell-oCSMaArc001",
        name = "Arcane Intellect",
        description = "Increases the Intelligence score of up to 5 allies by 2.",
        icon = 135932,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "arcane",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaInt001",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "A" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 2: Polymorph (2 turn incapacitate, breaks on damage)
    ["spell-oCSMaArc002"] = {
        id = "spell-oCSMaArc002",
        name = "Polymorph",
        description = "Transforms the target into a sheep for 2 turns, incapacitating them. The effect breaks if the target takes damage.",
        icon = 136071,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 2,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "arcane",
            [3] = "cc"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaArc002",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Arcane Blast (1 turn cast, high damage and mana cost)
    ["spell-oCSMaArc003"] = {
        id = "spell-oCSMaArc003",
        name = "Arcane Blast",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 135735,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "arcane",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Arcane",
                            amount = "(2d4 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",  
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaArc003",
                            targets = { targeter = "CASTER" }
                        }
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Arcane Explosion (5 targets, aoe damage)
    ["spell-oCSMaArc004"] = {
        id = "spell-oCSMaArc004",
        name = "Arcane Explosion",
        description = "Deals $[1].amount$ $[1].school$ damage to up to 5 targets.",
        icon = 136116,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 12,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "arcane",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "3",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "1",
                            school = "Arcane",
                            amount = "(1d4 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            targets = { targeter = "PRECAST", maxTargets = 5, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",  
                            [3] = "$stat.ARCANE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    ------ Frost SPELLS (1, 3, 5, 10) ------
    -- Level 1: Frostbolt (Single Target, Ranged Spell, Slow)
    ["spell-oCSMaFro001"] = {
        id = "spell-oCSMaFro001",
        name = "Frostbolt",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 135846,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "frost",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Frost",
                            amount = "(2d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",  
                            [3] = "$stat.FROST_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 3: Blizzard (raid marker DoT)
    ["spell-oCSMaFro002"] = {
        id = "spell-oCSMaFro002",
        name = "Blizzard",
        description = "Deals 5 Frost damage each turn for 5 turns to the target and any adjacent targets.",
        icon = 135857,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 3,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "frost",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "15",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaFro002",
                            targets = { targeter = "RAID_MARKER", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 5: Deep Freeze (1 turn stun)
    ["spell-oCSMaFro003"] = {
        id = "spell-oCSMaFro003",
        name = "Deep Freeze",
        description = "Stuns the target for 1 turn. During this time, they cannot act or defend.",
        icon = 236214,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 5,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "frost",
            [3] = "cc",
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "2",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 6,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaFro003",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" }
                        },
                    }
                },
                phase = "onResolve"
            },                    
            [2] = {
                key = "INTERRUPT",
                args = {
                    targets = { targeter = "TARGET", maxTargets = 1, flags = "E" }
                },
            }
        }
    },

    -- Level 8: Ice Barrier (absorb shield)
    ["spell-oCSMaFro004"] = {
        id = "spell-oCSMaFro004",
        name = "Ice Barrier",
        description = "Shields the caster, absorbing up to $[1].amount$ damage for 5 turns.",
        icon = 135988,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "frost",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "0",
                refundOnInterrupt = false
            },
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 5,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "SHIELD",
                        args = {
                            amount = "100 + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.5)",
                            duration = "5",
                            targets = { targeter = "CASTER" }
                        },
                    },
                    [2] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaFro004",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },

    ------ Fire SPELLS (1, 4, 8, 12) ------
    -- Level 1: Fireball (Single Target, Ranged Spell)
    ["spell-oCSMaFir001"] = {
        id = "spell-oCSMaFir001",
        name = "Fireball",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 135810,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 1,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "fire",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "CAST_TURNS",
            turns = 1,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 0,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "4",
                            school = "Fire",
                            amount = "(2d2 * 10) + (($stat.INT_MOD$ * 10) + $stat.SPELL_AP$)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",  
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 4: Fire Blast (Instant Cast, Single Target, Ranged Spell)
    ["spell-oCSMaFir002"] = {
        id = "spell-oCSMaFir002",
        name = "Fire Blast",
        description = "Deals $[1].amount$ $[1].school$ damage.",
        icon = 135807,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 4,
        rankInterval = 8,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "fire",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "10",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(1d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.5)",
                            targets = { targeter = "PRECAST", maxTargets = 1, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "$stat.SPELL_CRIT_MULT$",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 8: Flamestrike (Raid Marker AoE Spell)
    ["spell-oCSMaFir004"] = {
        id = "spell-oCSMaFir004",
        name = "Flamestrike",
        description = "Deals $[1].amount$ $[1].school$ damage to the target and their adjacent allies.",
        icon = 135826,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 8,
        rankInterval = 6,
        canCrit = true,
        targeter = { default = "PRECAST" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "fire",
            [3] = "spell"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "20",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 1,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "DAMAGE",
                        args = {
                            threat = "$stat.THREAT$",
                            perRank = "2",
                            school = "Fire",
                            amount = "(2d2 * 10) + math.floor(($stat.INT_MOD$ * 10 + $stat.SPELL_AP$) * 0.25)",
                            targets = { targeter = "RAID_MARKER", maxTargets = 10, flags = "E" },
                            requiresHit = true
                        },
                        hitThreshold = {
                            [1] = "$stat.DEFENCE$",
                            [2] = "$stat.AC$",
                            [3] = "$stat.FIRE_RESIST$"
                        },
                        critMult = "2",
                        critModifier = "$stat.SPELL_CRIT$",
                        hitModifier = "$stat.SPELL_HIT$"
                    },
                },
                phase = "onResolve"
            }
        }
    },

    -- Level 12: Combustion (Damage Buff)
    ["spell-oCSMaFir003"] = {
        id = "spell-oCSMaFir003",
        name = "Combustion",
        description = "Reduces the roll required for a spell critical strike by 10 and increases your spell critical damage by 50% for 2 turns.",
        icon = 135824,
        npcOnly = false,
        alwaysKnown = false,
        unlockLevel = 12,
        rankInterval = 0,
        canCrit = false,
        targeter = { default = "CASTER" },
        requirements = {
        },
        tags = {
            [1] = "mage",
            [2] = "fire",
            [3] = "buff"
        },
        costs = {
            [1] = {
                resource = "MANA",
                amount = "5",
                when = "onStart",
                perRank = "1",
                refundOnInterrupt = false
            },
            [2] = {
                resource = "BONUS_ACTION",
                amount = "1",
                when = "onStart",
                perRank = "",
                refundOnInterrupt = false
            }
        },
        cast = {
            type = "INSTANT",
            turns = 0,
            tickIntervalTurns = 1,
            concentration = false,
            moveAllowed = false
        },
        cooldown = {
            turns = 10,
            starts = "onResolve",
            sharedGroup = ""
        },
        groups = {
            [1] = {
                requirements = {},
                logic = "ALL",
                actions = {
                    [1] = {
                        key = "APPLY_AURA",
                        args = {
                            auraId = "aura-oCSMaFir003",
                            targets = { targeter = "CASTER" }
                        },
                    }
                },
                phase = "onResolve"
            }
        }
    },
}

function RPE.Data.DefaultClassic.Spells()
    local items = {}
    local spellTables = {
        RPE.Data.DefaultClassic.SPELLS_COMMON,
        RPE.Data.DefaultClassic.SPELLS_RACIAL,
        RPE.Data.DefaultClassic.SPELLS_PALADIN,
        RPE.Data.DefaultClassic.SPELLS_WARRIOR,
        RPE.Data.DefaultClassic.SPELLS_DEATH_KNIGHT,
        RPE.Data.DefaultClassic.SPELLS_SHAMAN,
        RPE.Data.DefaultClassic.SPELLS_MAGE,
        RPE.Data.DefaultClassic.SPELLS_HUNTER,
        RPE.Data.DefaultClassic.SPELLS_ROGUE,
        RPE.Data.DefaultClassic.SPELLS_DRUID,
        RPE.Data.DefaultClassic.SPELLS_DEMON_HUNTER,
        RPE.Data.DefaultClassic.SPELLS_WARLOCK,
        RPE.Data.DefaultClassic.SPELLS_PRIEST,
        RPE.Data.DefaultClassic.SPELLS_MONK,
        RPE.Data.DefaultClassic.SPELLS_EVOKER
    }
    
    for _, spellTable in ipairs(spellTables) do
        for k, v in pairs(spellTable) do
            items[k] = v
        end
    end
    
    return items
end
