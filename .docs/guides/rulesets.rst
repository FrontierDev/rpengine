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

    max_health = 10 * $stat.STA$
    ac = 10 + $stat.DEX$ / 2
    damage = 1d6 + $stat.STR$ / 2

**Lists (for stat filtering)**

.. code-block:: lua

    allow_primary = { STR, DEX, CON, INT, WIS, CHA }
    enable_stats = { HEALTH, MANA }
    hit_default_requires = { DAMAGE, APPLY_AURA_HARMFUL }

Special Rules
~~~~~~~~~~~~~

Some rules control addon behavior:

- **dataset_require**: Comma-separated list of required datasets (e.g., ``DefaultWarcraft,Custom5e``)
- **dataset_exclusive**: Set to ``1`` to allow ONLY required datasets

Dataset Requirements
--------------------

Lock specific datasets to your ruleset so they can't be disabled:

**Example: 5e-only ruleset**

.. code-block:: lua

    ruleset_name = "D&D 5e"
    dataset_require = "Default5e"        # Always require this dataset
    dataset_exclusive = 1                # Don't allow other datasets

This ensures:

- ``Default5e`` is automatically activated on login
- Users cannot disable ``Default5e``
- Other datasets cannot be activated (exclusive mode)

**Example: Flexible rulesets**

.. code-block:: lua

    ruleset_name = "Hybrid"
    dataset_require = "DefaultWarcraft"  # Required, but others allowed
    dataset_exclusive = 0                # Users can add more datasets

This allows:

- ``DefaultWarcraft`` is always active
- Users can add ``Custom5e`` if they want
- Flexible configuration

Editing a Ruleset
-----------------

1. Open the Ruleset window
2. Select a ruleset
3. Click "Edit"
4. Modify rules and save
5. Changes take effect immediately

Built-in Rulesets
-----------------

**DefaultWarcraft**

- D&D-inspired mechanics adapted for WoW
- Supports Warcraft classes and combat system
- Includes health, mana, and ability power calculations

**Default5e**

- Dungeons & Dragons 5th Edition rules
- Standard ability scores (STR, DEX, CON, INT, WIS, CHA)
- Classic 5e skill system

**DefaultClassic**

- World of Warcraft Classic mechanics
- Pre-expansion stat formulas
- Legacy support

Rule Examples
-------------

**Health Scaling**

.. code-block:: lua

    max_health = 10 * $stat.CON$

**Armor Class (AC)**

.. code-block:: lua

    ac = 10 + $stat.DEX$ / 2

**Attack Roll**

.. code-block:: lua

    attack_bonus = $stat.STR$ / 2 + $stat.PROFICIENCY$

**Skill Check**

.. code-block:: lua

    acrobatics = $stat.DEX$ / 2
    arcana = $stat.INT$ / 2
    insight = $stat.WIS$ / 2

Best Practices
--------------

1. **Use meaningful names**: ``max_health`` instead of ``mh``
2. **Document complex rules**: Add comments in notes
3. **Test with default stats**: Verify calculations work
4. **Share rulesets**: Export for guild mates
5. **Version your rulesets**: Use names like ``Ruleset v2.1``

Saving & Loading
----------------

Rulesets are automatically saved to ``RPEngineRulesetDB``:

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
                    ...
                }
            }
        }
    }
