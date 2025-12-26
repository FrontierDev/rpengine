Setup Wizard Editor
====================

The Setup Wizard Editor is a powerful tool for dungeon masters and dataset admins to create custom character creation sequences for players. Each page represents a step in character creation, where players make choices and receive automatic rewards.

Accessing the Editor
--------------------

1. Open the Dataset Editor (``/rpe data``).
2. Click the **Setup Wizard** tab.

Common Page Options
-------------------

Every page has these base settings:

- **Type**: Page type (SELECT_RACE, SELECT_CLASS, etc.)
- **Enabled**: Checkbox to enable/disable this page. Useful if you decide that you don't want to use a page, but want to keep its settings for another time.
- **Title**: Heading shown to players
- **Actions**: Spell action groups executed when page is completed

If the setup wizard contains a page, it WILL reset that portion of the character's data. For example, if there is a SELECT_SPELLS page, any existing spells on the character will be removed when they complete the wizard. The same applies for stats, items, languages and professions.

Page Types and Configuration
============================

SELECT_RACE
-----------

Allows players to select their character race. By default, they can select from all of the WoW playable races; these do not need to be added manually.
On this page of the setup wizard, racial traits will be made available for selection. These are Auras which have been tagged as "race:[key]" in the Aura Editor.

- **Custom Races**: Allows you to defined custom races for players to choose from. The 'Race ID' field is used to tag racial auras, whilst the Race Name is what appears in the Setup Wizard itself. The numerical race icon ID can be obtained from Wowhead.

SELECT_CLASS
------------

Allows players to select their character class. By default, they can select from all of the WoW playable classes; these do not need to be added manually.
On this page of the setup wizard, class traits will be made available for selection. These are Auras which have been tagged as "class:[key]" in the Aura Editor.

- **Custom Classes**: Allows you to define custom classes for players to choose from. The 'Class ID' field is used to tag class auras, whilst the Class Name is what appears in the Setup Wizard itself. The numerical class icon ID can be obtained from Wowhead.

SELECT_STATS
------------

Players allocate ability scores.

- **Stat Type**: Defines how stats are allocated:
    - **Point Buy**: Players have a pool of points to spend. Each time they increase a stat, it costs more points to increase the stat further.
    - **Standard Array**: Players assign predefined values to up to six stats, which are defined in the 'Stats' field below.
    - **Simple Assign**: Players have a pool of points to spend, with each increment costing the same.
- **Stats (CSV)**: A comma-separated list of stat names to include on this page, e.g., "STR, DEX, CON" etc. These are the Stat Key values defined in the Stats Editor.
- **Max Per Stat**: The maximum value a player can assign to any single stat.
- **Max Points**: The maximum number of points a player can spend on stats.
- **Increment By**: How much each stat increases by per point.

SELECT_LANGUAGE
---------------

Allows the player to assign their character's known languages. There are no additional options for this page type.


SELECT_SPELLS
-------------

Allows players to select starting spells and abilities from a list of all spells in your active datasets. 

- **Allow Racial**: Do not filter racial spells out of the selection list.
- **Restrict to Class**: Only allow players to select spell options that match their chosen class. A SELECT_CLASS page must be present earlier in the wizard for this to work.
- **Restrict to Race**: Only allow players to select spell options that match their chosen race. A SELECT_RACE page must be present earlier in the wizard for this to work.
- **First Rank Only**: Only allow players to select the first rank of multi-rank spells.
- **Max Spell Points**: The maximum number of points that players can spend on spells.
- **Max Spells Total**: The maximum number of spells that players can select.

SELECT_ITEMS
------------

Allows players to select starting equipment.

- **Max Allowance**: The maximum total value of the items that the player can select. If left blank, there is no limit.
- **Include Tags**: If specified, only items with these tags will be shown for selection.
- **Exclude Tags**: If specified, items with these tags will be excluded from selection.
- **Max Rarity**: The maximum item rarity that players can select.
- **Allowed Categories**: If specified, only items from these categories will be shown for selection.
- **Apply Spare Change**: If enabled, any unspent allowance will be granted to the player as currency.

SELECT_PROFESSIONS
------------------

Allows players to allocate profession/crafting points. They can choose from any of the primary WoW professions (e.g., Alchemy, Blacksmithing, etc.). 

- **Max Profession Level**: The maximum level a player can assign to any single profession. By default, the max profession level is 1.
- **Prof Points Allowed**: The total number of profession points a player can allocate.