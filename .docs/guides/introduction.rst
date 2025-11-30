Introduction
============

RPEngine (RPE) is a next-generation roleplay event system addon for World of Warcraft. It replaces manual bookkeeping and spreadsheet workflow with an integrated, flexible toolkit for both players and Dungeon Masters. RPEngine builds on experience from earlier addons (such as RPToolkit) and focuses on extensibility, clarity, and campaign-friendly features.

Highlights
----------

- Character profiles and detailed statistics, with configurable spells, passives, buffs, and debuffs
- Turn-based event handling and a full NPC registry for tactical encounters
- Professions, crafting, vendor systems, and a dynamic item economy
- Cross-party DM events and support for large RP-PvP encounters
- An extensible ruleset system to customise mechanics and UI behaviour
- Dataset synchronization for shared spells, items, and NPC data between players
- A "chanter" system to mirror local chat (/s, /y, /e) for party-wide roleplay coordination

Why use RPEngine?
-----------------

RPEngine removes repetitive DM workload by automating common tasks: roll resolution, damage/healing calculations, resource tracking, and stat application. It uses in-game models to present NPCs and provides flexible controls for turn order and grouping. Whether you run small sessions or large campaigns, RPEngine lets you focus on story and roleplay rather than numbers.

Crafting & Economy
------------------

The crafting system is inspired by classic WoW: gather reagents, learn recipes, and craft items. Recipes can accept optional reagents for customization, and item prices may vary by vendor and location to reflect a simple in-game economy.

Rulesets & Data
---------------

Rulesets are Lua tables that expose knobs and expressions the engine reads to determine game behaviour (formulas, limits, dataset requirements). Datasets (under `Data/`) contain items, spells, and NPC templates. Together they let guilds tailor the engine to their preferred mechanics without changing core code.

Getting started (quick)
-----------------------

1. Install and enable the addon, then log in with your character.
2. Complet the character setup wizard.
3. Open the Character Sheet (``/rpe sheet``) to view your profile.

Extending RPEngine
-------------------

RPEngine is built to be extended: the codebase has no external runtime dependencies and is organised so authors can add datasets, rulesets, and integrations. The developer docs describe core APIs (see :doc:`dev/api`).

Where to go next
-----------------

- :doc:`profiles` — character profile management
- :doc:`rulesets` — create and edit rulesets
- :doc:`datasets` — author datasets (items, spells, NPCs)

If you'd like, I can also add a short screenshots/galleries section or example ruleset file to this page.
