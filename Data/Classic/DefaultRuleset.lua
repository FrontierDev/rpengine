-- RPEngine/Data/Classic/DefaultRuleset.lua
-- Default ruleset for Classic D&D campaign system
-- Based on Ruleset 013052

RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.Classic = RPE.Data.Classic or {}

RPE.Data.Classic.DefaultRuleset = {
    name = "DefaultClassic",
    rules = {
        exp_per_level = "83+pow((5*$level$), 1.5)",
        show_reagent_tiers = "1",
        equipment_slots_left = "{ head, chest }",
        hit_system = "complex",
        hit_aoe_roll_mode = "per_target",
        max_professions = "2",
        allow_resource = "{ HEALTH, MAX_HEALTH, MANA, MAX_MANA, ACTION, BONUS_ACTION, REACTION, HOLY_POWER, MAX_HOLY_POWER, RAGE, FAVOUR, MAX_FAVOUR }",
        hit_default_requires = "{ DAMAGE, APPLY_AURA_HARMFUL }",
        max_tick_units = "4",
        hit_base_threshold = "0",
        equipment_slots_bottom = "{ mainhand, offhand, ranged }",
        setup_wizard = "DefaultClassic",
        max_racial_traits = "3",
        show_item_level = "1",
        use_spell_ranks = "1",
        equipment_slots_right = "{ hands, feet, trinket }",
        max_generic_traits = "2",
        shop_reputation = "0",
        use_spell_ranks_lvl = "1",
        mana_regen = "0.2*$stat.WIS_MOD$",
        healing_received = "$stat.HEALING_TAKEN$",
        hit_roll = "1d20",
        always_hit = "0",
        dot_crits = "0",
        max_traits = "10",
        use_level_system = "1",
        fudge = "1d10-5",
        max_skill = "50",
        dataset_exclusive = "0",
        npc_stats = "{ DODGE, PARRY, BLOCK, FIRE_RESIST, DEFENCE, AC }",
        health_regen = "0.2*$stat.WIS_MOD$",
        max_player_level = "20",
        max_class_traits = "1",
    },
}

return RPE.Data.Classic.DefaultRuleset
