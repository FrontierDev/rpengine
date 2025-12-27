Rulesets
========

A ruleset is a collection of configuration settings that dictate how RPEngine operates. 
It provides a way to customize various aspects of the addon, such as combat mechanics, character progression, and event rules.
Essentially, it can be thought of as the "settings" file.
It should be considered as **long-term data**, meaning that once a ruleset is chosen for a campaign, it should not be changed frequently.

**IMPORTANT** - RPEngine events require a **ruleset** and a **dataset** to function correctly.
All members of your group must have the same ruleset active.

When you reload your UI, RPEngine will tell you which ruleset is currently active.
To change your active ruleset, open the **ruleset window** with ``/rpe ruleset`` or by clicking the minimap button and selecting **Rulesets**.

Each ruleset is made up of a set of **rule keys** that define specific settings.
Please refer to the rule keys reference section below for a list of all available rule keys and their descriptions.
Note that the format of the rule's value is very specific. 
For instance, typing ``mainhand, offhand, ranged`` into the value box for ``equipment_slots_bottom`` will not work; 
you must use the Lua table format: ``{ mainhand\, offhand\, ranged }``.


Rule Keys Reference
--------------------

All available rule keys that can be used in the ``rules`` table:

.. csv-table::
   :header: "Key", "Description"
   :escape: \

   ``max_tick_units``, How many units can act per turn in combat.
   ``setup_wizard``, The name of the dataset to use for the setup wizard.
   ``use_level_system``, Enable level-based progression.
   ``exp_per_level``, Formula for experience required per level: ``83+pow((5*$level$)\, 1.5)``
   ``no_spell_cost``, Set to 1 to disable spell learning costs
   ``no_recipe_cost``, Set to 1 to disable recipe learning costs.
   ``use_spell_ranks``, Enable spells with multiple ranks.
   ``use_spell_ranks_lvl``, Set to 0 to make all spell ranks learnable at level 1.
   ``shop_daily``, Enable daily fluctation on shop prices.
   ``shop_location``, Enables location-based shop pricing. (NYI)
   ``shop_reputation``, Enables reputation-based shop pricing. (NYI)
   ``max_racial_traits``, Maximum racial traits allowed (default: 3).
   ``max_traits``, Total number of traits allowed (default: 10).
   ``max_class_traits``, Maximum class traits allowed (default: 1).
   ``max_skill``, Maximum modifier in a 'skill' stat (default: 50).
   ``max_professions``, Maximum professions allowed per character (default: 2).
   ``max_player_level``, Maximum player level if ``use_level_system`` is enabled (default: 20).
   ``portrait_size``, Unit portrait size in non-combat events (default: 32).
   ``action_bar_slots``, Number of action bar slots available (default: 5).
   ``equipment_slots_left``, List of left-side equipment slots (default: ``{ head\, neck }``).
   ``equipment_slots_right``, List of right-side equipment slots (default: ``{ legs\, feet }``).
   ``equipment_slots_bottom``, List of bottom-side equipment slots (default: ``{ mainhand\, offhand\, ranged }``).
   ``fudge``, Fudge factor for damage/healing rolls (default: 0).
   ``dot_crits``, Enable critical hits on damage-over-time effects (default: 0).
   ``healing_received``, Multiplier for healing received (default: ``$stat.HEALING_TAKEN$``).
   ``hit_system``, Hit resolution system: ``"complex"``\, ``"simple"``\, or ``"ac"`` (default: ``"complex"``).
   ``hit_roll``, Roll range for all dice rolls (default: ``"1d20"``).
   ``hit_base_threshold``, Base DC for hit checks (default: 0).
   ``hit_aoe_roll_mode``, Change to ``single_roll`` to roll once for all targets in an AoE spell (default: ``per_target``).
   ``always_hit``, Set to 1 to auto-succeed hit checks (default: 0).
   ``show_item_level``, Display item levels (default: 1).
   ``show_reagent_tiers``, Display reagent tiers (default: 1).
   ``dataset_require``, List of datasets that are required/locked.
   ``dataset_exclusive``, Only allow required datasets to be loaded; 1 = yes (default: 0).