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
Rulesets
========

Rulesets
--------

RPEngine rulesets are single Lua modules (files that return a table) which define numeric knobs and simple expressions the engine uses for formulas, NPC stat seeding, XP scaling, and dataset control. Place custom ruleset files in `Data/` and use the DM UI to select or manage them.

Minimal keys:

- `id` (string)
- `name` (string)
- `description` (string)
- `version` (string|number)
- `npc_stats` (table)
- `xp_scale` (number)
- `rules` (table)

See `Data/Default5e.lua`, `Data/DefaultClassic.lua`, and `Data/DefaultWarcraft.lua` for examples.
Rulesets
========

Overview
--------

Rulesets configure the mechanical rules RPEngine uses: stat formulas, NPC seeding, XP scaling, dataset requirements, and related knobs. Each ruleset is a Lua module that returns a table; the engine loads available rulesets and the DM may select one per character/event.

Location
--------

Built-in rulesets live under `Data/` (for example `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua`). Custom rulesets may be placed in `Data/` or a DM-managed folder and referenced by `id`.

Minimal format
--------------

A ruleset is a Lua table with common fields. The engine ignores unknown fields, but useful keys include:

- `id` (string): unique identifier (e.g. `default_5e`).
- `name` (string): human-readable display name.
- `description` (string): short description.
- `version` (string|number): optional version for migrations.
- `npc_stats` (table): list of stat keys used when seeding NPCs.
- `xp_scale` (number): XP multiplier.
- `rules` (table): map of named knobs (e.g. `max_level`, `crit_multiplier`).

Example
-------

.. code-block:: lua

   return {
       id = "default_5e",
       name = "Default 5e",
       description = "5e-style rules",
       npc_stats = { "strength", "dexterity", "constitution" },
    Rulesets
    ========

    This page describes RPEngine rulesets — Lua modules that return a table of knobs and values the engine uses for formulas, NPC seeding, XP scaling, and dataset control. See `Data/` for built-in examples.

--------------

1. Use meaningful rule names (e.g., ``max_health`` instead of ``mh``).
2. Document complex rules in the ruleset notes so other DMs understand intent.
3. Keep the `rules` table focused on small, well-documented knobs; implement complex logic in modules.
4. Version rulesets if you change semantics.

Saving & Loading
----------------

Rulesets are persisted to the saved variables table ``RPEngineRulesetDB``. A simplified example:

.. code-block:: lua

    RPEngineRulesetDB = {
        _schema = 1,
        currentByChar = {
            ["PlayerName-RealmName"] = "ActiveRulesetName"
        },
        rulesets = {
            ["ActiveRulesetName"] = {
                name = "ActiveRulesetName",
                rules = {
                    max_health = "10 * $stat.CON$",
                    ac = "10 + $stat.DEX$ / 2",
                }
            }
        }
    }

References
----------

- Example files: `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua`.
- Developer APIs: see `dev/api` for modules that consume ruleset values (for example `RPE.Core.Formula`).
Rulesets
========

Overview
--------

Rulesets define the core game rules that RPEngine uses to interpret, roll, and resolve gameplay systems such as NPC stat seeding, XP scaling, damage formulas, and rule-driven behaviour. A ruleset is a Lua table file (returned from a module) that the engine loads at startup or when selected by the DM.

Location
--------

Default rulesets are provided in the `Data/` folder (for example `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua`). Custom rulesets may be added by the DM as separate Lua files and referenced by ID from the profile or UI.

Format
------

A ruleset is a plain Lua table with well-known fields. The engine is permissive — unknown fields are ignored — but a good ruleset usually contains at least these keys:

- `id` (string): a unique identifier for the ruleset (e.g. `default_5e`).
- `name` (string): human-readable name shown in the UI.
- `description` (string): short description for DMs/players.
- `version` (string|number): optional version/key for migrations.
- `npc_stats` (table): list of stat names to seed NPCs with (e.g. `{"str","dex","con"}`).
- `xp_scale` (number): global XP multiplier.
- `rules` (table): a mapping of named rule knobs (e.g. `max_level`, `death_mode`, `crit_multiplier`).

Example
-------

An example ruleset file (minimal):

.. code-block:: lua

   return {
       id = "default_5e",
       name = "Default 5e",
       description = "Baseline 5e-like rules for NPCs and XP",
       version = "1.0",
       npc_stats = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" },
       xp_scale = 1.0,
       rules = {
           max_level = 20,
           crit_multiplier = 1.5,
           allow_friendly_fire = false,
       }
   }

How rulesets are used
---------------------

- On startup the engine loads available rulesets and exposes them in the DM profile UI.
- The currently active ruleset is applied to event creation and formula evaluation. Modules such as `RPE.Core.Formula`, `RPE.Core.AuraManager`, and NPC seeding use values from the active ruleset.
- Rulesets are intentionally lightweight: most behaviour is controlled by the `rules` table and by rule-aware modules.

Extending and custom rules
--------------------------

- Add a new Lua file to `Data/` or a DM-managed folder and return the ruleset table as in the example above.
- Keep `id` unique and preferably lowercase with underscores.
- If you need to override a small set of default values, create a ruleset that sets only the changed keys and reference it from the profile.

Best practices
--------------

- Provide `name`, `id`, and `description` so DMs can easily identify the ruleset in the UI.
- Include a `version` string when you change semantics that may require migration.
- Keep the `rules` table focused on small, well-documented knobs rather than embedding logic; modules should read those knobs and implement behaviour.

Troubleshooting
---------------

- Syntax errors in a ruleset file prevent it from loading; check the Lua error logs and run `/reload` after fixing.
- If a value appears ignored, confirm the consuming module supports that key (consult the developer docs in `dev/api`).

References
----------

- Example files: `Data/Default5e.lua`, `Data/DefaultClassic.lua`, `Data/DefaultWarcraft.lua`.
- Developer APIs: see `dev/api` for modules that consume ruleset values (for example `RPE.Core.Formula`).
Rulesets
========

What is a Ruleset?
------------------

A ruleset defines the **rules and formulas** that govern how stats are calculated. It's the mechanical backbone of your character.

Examples:

- D&D 5e ruleset: ``max_health = 10 + (STA * 5)``
- Warcraft ruleset: ``max_health = 10 * STA``
- Custom ruleset: Your own formulas

Per-Character Rulesets
----------------------

Each character can have an active ruleset:

- Rulesets are identified by name
- Data is saved in ``RPEngineRulesetDB``
- One ruleset is active per character at a time
- Rulesets persist across sessions

Creating a Ruleset
------------------

1. Open the Ruleset window
2. Click "New Ruleset"
3. Enter a ruleset name
4. Add rules (see `Rule Syntax`_)
5. Click "Save"

Rule Syntax
-----------

Rules are key-value pairs. Keys are rule identifiers, values are expressions or simple values.

**Simple Values**

.. code-block:: lua

    max_skill = 50
    base_ac = 10
    crit_chance = 5

**Expressions**

Use ``$stat.STAT_NAME$`` to reference other stats:

.. code-block:: lua
