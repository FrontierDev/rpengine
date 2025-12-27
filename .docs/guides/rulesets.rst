Rulesets
========

Overview
--------


Rule Keys Reference
--------------------

All available rule keys that can be used in the ``rules`` table:

.. list-table::
   :header-rows: 1
   :widths: 25 15 50

   * - Key
     - Default
     - Description
   * - ``max_tick_units``
     - ``4``
     - How many units can act per turn in combat.
    * - ``setup_wizard``
     - e.g. ``Custom Dataset``
     - The name of the dataset to use for the setup wizard.
   * - ``use_level_system``
     - ``1``
     - Enable level-based progression.
   * - ``exp_per_level``
     - ``83+pow((5*$level$), 1.5)``
     - Formula for experience required per level. 
   * - ``no_spell_cost``
     - ``0``
     - Set to 1 to disable spell learning costs
   * - ``no_recipe_cost``
     - ``0``
     - Set to 1 to disable recipe learning costs.
   * - ``use_spell_ranks``
     - ``1``
     - Enable spells with multiple ranks.
   * - ``use_spell_ranks_lvl``
     - ``1``
     - Set to 0 to make all spell ranks learnable at level 1.
   * - ``shop_daily``
     - ``1``
     - Enable daily fluctation on shop prices.
   * - ``shop_location``
     - ``0``
     - Enables location-based shop pricing. (NYI)
   * - ``shop_reputation``
     - ``0``
     - Enables reputation-based shop pricing. (NYI)
   * - ``max_racial_traits``
     - ``3``
     - Maximum racial traits allowed.
   * - ``max_traits``
     - ``10``
     - Total number of traits allowed.
   * - ``max_class_traits``
     - ``1``
     - Maximum class traits allowed.
   * - ``max_skill``
     - ``50``
     - Maximum modifier in a 'skill' stat.
   * - ``max_professions``
     - ``2``
     - Maximum professions allowed per character.
   * - ``max_player_level``
     - ``20``
     - Maximum player level if ``use_level_system`` is enabled.
   * - ``portrait_size``
     - 32
     - Unit portrait size in non-combat events.
   * - ``action_bar_slots``
     - ``5``
     - Number of action bar slots available.
   * - ``equipment_slots_left``
     - ``{ head, neck }``
     - List of left-side equipment slots.
   * - ``equipment_slots_right``
     - ``{ legs, feet }``
     - List of right-side equipment slots
   * - ``equipment_slots_bottom``
     - ``{ mainhand, offhand, ranged }``
     - List of bottom-side equipment slots
   * - ``fudge``
     - ``0``
     - Fudge factor for damage/healing rolls
   * - ``dot_crits``
     - ``0``
     - Enable critical hits on damage-over-time effects
   * - ``healing_received``
     - ``$stat.HEALING_TAKEN$``
     - Multiplier for healing received.
   * - ``hit_system``
     - ``"complex"``
     - Hit resolution system: "complex", "simple", or "ac"
   * - ``hit_roll``
     - ``"1d20"``
     - Roll range for all dice rolls.
   * - ``hit_base_threshold``
     - ``0``
     - Base DC for hit checks.
   * - ``hit_aoe_roll_mode``
     - ``per_target``
     - Change to ``single_roll`` to roll once for all targets in an AoE spell.
   * - ``always_hit``
     - ``0``
     - Always succeed hit checks (1 = yes)
   * - ``show_item_level``
     - (none)
     - Display item levels (1 = yes)
   * - ``show_reagent_tiers``
     - (none)
     - Display reagent tiers (1 = yes)
   * - ``dataset_require``
     - e.g. ``{ DefaultClassic, CustomDataset }``
     - List of datasets that are required/locked
   * - ``dataset_exclusive``
     - ``0``
     - Only allow required datasets to be loaded (1 = yes)