-- RPE/Profile/TestStats.lua
-- Bootstrap harness: creates three official stat datasets on PLAYER_LOGIN if they don't exist.
-- Stats are dataset-driven, not hardcoded per-profile.

RPE = RPE
RPE.Profile = RPE.Profile

local DB = RPE.Profile.DB
local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB

-- ==== Stat definitions (same as before, but now in table format) ====
local STAT_DEFS_5E = {
    -- --- Resources ---
    ACTION = {
        name    = "Actions",
        base    = 1,
        min     = 0,
        max     = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\action.png",
        visible = 0,
        recovery = { ruleKey = "action_regen", default = 1 },
    },
    BONUS_ACTION = {
        name    = "Bonus Actions",
        base    = 1,
        min     = 0,
        max     = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\bonus_action.png",
        visible = 0,
        recovery = { ruleKey = "bonusaction_regen", default = 1 },
    },
    REACTION = {
        name    = "Reactions",
        base    = 1,
        min     = 0,
        max     = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\reaction.png",
        visible = 0,
        recovery = { ruleKey = "reaction_regen", default = 1 },
    },
    MAX_HEALTH = {
        name    = "Max Health",
        base    = { ruleKey = "max_health", default = 0 },
        visible = 0,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\health.png",
    },
    HEALTH = {
        name    = "Hitpoints",
        min     = 0,
        max     = { ref = "MAX_HEALTH" },
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\health.png",
        tooltip = "Your current hitpoints. If this reaches 0, you are knocked out.\\n\\nYour maximum health is $stat.MAX_HEALTH$.",
        recovery = { ruleKey = "health_regen", default = 0 },
    },
    MAX_HOLY_POWER = {
        name    = "Max Holy Power",
        base    = 3,
        visible = 0,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\mana.png",
    },
    HOLY_POWER = {
        name    = "Holy Power",
        base    = 0,
        min     = 0,
        max     = { ref = "MAX_HOLY_POWER" },
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\mana.png",
        tooltip = "Divine power used to perform powerful Paladin-specific spells.",
    },
    MAX_MANA = {
        name    = "Max Mana",
        base    = { ruleKey = "max_mana", default = 0 },
        visible = 0,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\mana.png",
    },
    MANA = {
        name    = "Mana",
        base    = 75,
        min     = 0,
        max     = { ref = "MAX_MANA" },
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\mana.png",
        tooltip = "Your current mana. Used to power spells and abilities.\\n\\nYour maximum mana is $stat.MAX_MANA$.",
        recovery = { ruleKey = "mana_regen", default = 0 },
    },
    -- --- Primary stats ---
    STR = {
        name    = "Strength",
        category = "PRIMARY",
        base    = 12,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\str.png",
        itemTooltipFormat = "$value$ Strength",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    INT = {
        name    = "Intellect",
        category = "PRIMARY",
        base    = 15,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\int.png",
        itemTooltipFormat = "$value$ Intellect",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    AGI = {
        name    = "Agility",
        category = "PRIMARY",
        base    = 10,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\agi.png",
        itemTooltipFormat = "$value$ Agility",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    STA = {
        name    = "Stamina",
        category = "PRIMARY",
        base    = 14,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\sta.png",
        itemTooltipFormat = "$value$ Stamina",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    SPI = {
        name    = "Spirit",
        category = "PRIMARY",
        base    = 13,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\spi.png",
        itemTooltipFormat = "$value$ Spirit",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    CHA = {
        name    = "Charisma",
        category = "PRIMARY",
        base    = 11,
        min     = -math.huge,
        max     = math.huge,
        visible = 1,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\cha.png",
        itemTooltipFormat = "$value$ Charisma",
        itemTooltipColor = {1, 1, 1},
        itemTooltipPriority = 100,
        itemLevelWeight = 230,
    },
    -- --- Melee ---
    MELEE_AP = {
        name = "Attack Power",
        category = "SECONDARY",
        base = { ruleKey = "melee_ap", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_melee_ap" },
        itemTooltipFormat = "$value$ Melee Attack Power",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\melee.png",
    },
    MELEE_HIT = {
        name = "Hit Chance",
        category = "SECONDARY",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\melee.png",
        itemTooltipFormat = "$value$% Melee Hit Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    MELEE_CRIT = {
        name = "Crit. Chance",
        category = "SECONDARY",
        base = { ruleKey = "melee_crit", default = 0 },
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\melee.png",
        itemTooltipFormat = "$value$% Melee Crit. Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    -- --- Ranged ---
    RANGED_AP = {
        name = "Ranged Power",
        category = "SECONDARY",
        base = { ruleKey = "ranged_ap", default = 0 },
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\ranged.png",
    },
    RANGED_HIT = {
        name = "Hit Chance",
        category = "SECONDARY",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\ranged.png",
        pct  = 1,
    },
    RANGED_CRIT = {
        name = "Crit. Chance",
        category = "SECONDARY",
        base = { ruleKey = "ranged_crit", default = 0 },
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\ranged.png",
        pct  = 1,
    },
    -- --- Spell ---
    SPELL_AP = {
        name = "Spell Power",
        category = "SECONDARY",
        base = { ruleKey = "spell_power", default = 0 },
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
    },
    SPELL_HIT = {
        name = "Hit Chance",
        category = "SECONDARY",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        itemTooltipFormat = "$value$% Spell Hit Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    SPELL_CRIT = {
        name = "Crit. Chance",
        category = "SECONDARY",
        base = { ruleKey = "spell_crit", default = 0 },
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    -- --- Defense ---
    PARRY = {
        name = "Parry Chance",
        category = "DEFENSE",
        base = 5,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\parry.png",
        itemTooltipFormat = "$value$% Parry Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    BLOCK = {
        name = "Block Chance",
        category = "DEFENSE",
        base = 5,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\block.png",
        itemTooltipFormat = "$value$% Block Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    DODGE = {
        name = "Dodge Chance",
        category = "DEFENSE",
        base = 5,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\dodge.png",
        itemTooltipFormat = "$value$% Dodge Chance",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
        pct  = 1,
    },
    DEFENCE = {
        name = "Defence",
        category = "DEFENSE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\healed_last.png",
        itemTooltipFormat = "$value$ Defence",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
    },
    AC = {
        name = "Armor Class",
        category = "DEFENSE",
        base = 10,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\healed_last.png",
        itemTooltipFormat = "$value$ AC",
        itemTooltipColor = {0, 1, 0},
        itemTooltipPriority = 99,
    },
    -- --- Resistances ---
    FIRE_RESIST = {
        name = "Fire",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    FROST_RESIST = {
        name = "Frost",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    NATURE_RESIST = {
        name = "Nature",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    ARCANE_RESIST = {
        name = "Arcane",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    SHADOW_RESIST = {
        name = "Shadow",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    HOLY_RESIST = {
        name = "Holy",
        category = "RESISTANCE",
        base = 0,
        min  = 0,
        max  = math.huge,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    -- --- Skills ---
    ACROBATICS = {
        name = "Acrobatics",
        category = "SKILL",
        base = { ruleKey = "acrobatics", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    ANIMAL_HANDLING = {
        name = "Animal Handling",
        category = "SKILL",
        base = { ruleKey = "animal_handling", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    ARCANA = {
        name = "Arcana",
        category = "SKILL",
        base = { ruleKey = "arcana", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    ATHLETICS = {
        name = "Athletics",
        category = "SKILL",
        base = { ruleKey = "athletics", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    DECEPTION = {
        name = "Deception",
        category = "SKILL",
        base = { ruleKey = "deception", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    HISTORY = {
        name = "History",
        category = "SKILL",
        base = { ruleKey = "history", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    INSIGHT = {
        name = "Insight",
        category = "SKILL",
        base = { ruleKey = "insight", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    INTIMIDATION = {
        name = "Intimidation",
        category = "SKILL",
        base = { ruleKey = "intimidation", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    INVESTIGATION = {
        name = "Investigation",
        category = "SKILL",
        base = { ruleKey = "investigation", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    MEDICINE = {
        name = "Medicine",
        category = "SKILL",
        base = { ruleKey = "medicine", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    NATURE = {
        name = "Nature",
        category = "SKILL",
        base = { ruleKey = "nature", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    PERCEPTION = {
        name = "Perception",
        category = "SKILL",
        base = { ruleKey = "perception", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    PERFORMANCE = {
        name = "Performance",
        category = "SKILL",
        base = { ruleKey = "performance", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    PERSUASION = {
        name = "Persuasion",
        category = "SKILL",
        base = { ruleKey = "persuasion", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    RELIGION = {
        name = "Religion",
        category = "SKILL",
        base = { ruleKey = "religion", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    SLEIGHT_OF_HAND = {
        name = "Sleight of Hand",
        category = "SKILL",
        base = { ruleKey = "sleight_of_hand", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    STEALTH = {
        name = "Stealth",
        category = "SKILL",
        base = { ruleKey = "stealth", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
    SURVIVAL = {
        name = "Survival",
        category = "SKILL",
        base = { ruleKey = "survival", default = 0 },
        min  = 0,
        max  = { ruleKey = "max_skill", default = 20 },
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\spell.png",
        pct  = 1,
    },
}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if not DatasetDB then return end

    -- Create three official datasets if they don't exist
    local datasets = {
        { name = "RPE-Official-5e", stats = STAT_DEFS_5E },
        { name = "RPE-Official-Warcraft", stats = STAT_DEFS_5E },
        { name = "RPE-Official-Classic", stats = STAT_DEFS_5E },
    }

    for _, dsInfo in ipairs(datasets) do
        if not DatasetDB.GetByName or not DatasetDB.GetByName(dsInfo.name) then
            local ds = {
                name = dsInfo.name,
                items = {},
                spells = {},
                auras = {},
                npcs = {},
                extra = {
                    stats = dsInfo.stats,
                },
            }
            if DatasetDB.Save then
                pcall(DatasetDB.Save, ds)
            end
        end
    end

    -- Set default active dataset if none is set
    if DatasetDB.GetActiveNaForCurrentCharacter then
        local active = DatasetDB.GetActiveNameForCurrentCharacter()
        if not active or active == "" then
            if DatasetDB.SetActiveNameForCurrentCharacter then
                DatasetDB.SetActiveNameForCurrentCharacter("RPE-Official-5e")
            end
        end
    end

    -- Seed profile stats from active dataset on first login (optional fallback)
    local profile = DB.GetOrCreateActive()
    if profile and not next(profile.stats) then
        local activeName = DatasetDB.GetActiveNameForCurrentCharacter and DatasetDB.GetActiveNameForCurrentCharacter()
        local ds = activeName and DatasetDB.GetByName and DatasetDB.GetByName(activeName)
        if ds and ds.extra and ds.extra.stats then
            for statId, statDef in pairs(ds.extra.stats) do
                profile:GetStat(statId, statDef.category or "PRIMARY"):SetData(statDef)
            end
            DB.SaveProfile(profile)
        end
    end
end)