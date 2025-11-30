Rulesets
========

Overview
--------

RPEngine rulesets are Lua modules (files that return a table) which define knobs and small expressions used by the engine for formulas, NPC stat seeding, XP scaling, and dataset control. Place custom ruleset files in `Data/` and manage them from the DM UI.

Common keys
-----------

- `id` (string)
- `name` (string)
- `description` (string)
- `version` (string|number)
- `npc_stats` (table)
- `xp_scale` (number)
- `rules` (table)

Example
-------

.. code-block:: lua

   return {
       id = "default_5e",
       name = "Default 5e",
       description = "5e-style rules",
       npc_stats = { "strength", "dexterity", "constitution" },
       xp_scale = 1.0,
       rules = { max_level = 20, crit_multiplier = 1.5 }
   }

References
----------

- `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua`
- Developer docs: `dev/api`
