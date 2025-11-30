Rulesets
========

Overview
--------

This single canonical rulesets page describes RPEngine rulesets: Lua modules that return a table of knobs and values used by core modules (formulas, NPC seeding, XP scaling, dataset controls).

Quick example
-------------

.. code-block:: lua

   return {
       id = "default_5e",
       name = "Default 5e",
       description = "5e-style rules",
       npc_stats = { "strength", "dexterity", "constitution" },
       xp_scale = 1.0,
       rules = { max_level = 20, crit_multiplier = 1.5 }
   }

See `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua` for built-in examples.
