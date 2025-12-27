Spell Editor
=============

The Spell Editor allows you to create and configure spells and abilities in your dataset.

Accessing the Editor
--------------------

1. Open the Dataset Editor (``/rpe data``).
2. Click the **Spells** tab.

Creating a Spell
----------------

Click on an empty slot to add a new spell, or right-click and copy an existing spell from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Name (Required)**: The name of the spell as it appears in the UI.
- **Icon**: The icon texture representing the spell.
- **Description**: The description of the spell as it appears in the tooltip. 
When the tooltip is displayed, it takes any placeholder values and replaces them with the actual values from the spell definition. 
These placeholders use the format ``$[X].[key]$`` where ``[X]`` is the index of the spell action (starting at 1)and ``[key]`` relates to the value that you want to display from that spell action. The following placeholders can be used:
    - ``$[x].amount$`` - the range of the 'amount' field in spell action 'x'.
    - ``$[x].amount.avg`` - the average of the 'amount' field in spell action 'x'.
    - ``$[x].school$`` - the damage school of spell action 'x'.
    - ``$[x].stacks$`` - how many stacks of an aura are applied by spell action 'x'.
- **NPC Only**: Can only NPCs use this spell?
- **Always Known**: Is this spell always given to the player when they select spells for their character in the setup wizard?
- **Can Crit**: Can this spell critically hit?
- **Max Ranks**: Deprecated. Do not change this field. The maximum rank of the spell is now determined automatically based on the rank interval and the maximum level specified by the ``max_player_level`` rule.
- **Unlock Level**: If using the ``use_level_system`` rule, what level does this spell unlock at?
- **Rank Interval**: If using the ``use_spell_ranks`` rule, this defines how many levels are required to gain each new rank of the spell.
- **Spell Requirements**: Any requirements that must be met in order to use this spell. The following spell requirements can be used:
    - ``equip.[slot]`` - Requires an item to be equipped in the specified slot (e.g., ``equip.mainhand``, ``equip.head``, etc.).
    - ``equip.[slot].type]`` - Requires an item of the specified type to be equipped in the specified slot (e.g., ``equip.mainhand.mace``, etc.).
    - ``equip.dual`` - Requires a weapon to be equipped in both main hand and off hand.
    - ``inventory.[item id]`` - Requires the specified item to be in the player's inventory.
    - ``summoned.[type]`` - Requires that the player has a summoned creature of the specified type to be present (e.g., ``summoned.pet``, ``summoned.minion``, etc.).
    - ``nosummoned`` - Requires that the player has no summoned creatures to be present.
    - ``hidden`` - The player must be hidden to use this spell.

**Casting**

- **Cast Type**: Is this spell an instant cast, or does it have a casting time? ``CHANNELED`` spells are not currently supported.
- **Cast Turns**: How many turns does it take to cast this spell? Instant cast spells should be set to 0.
- **Tick Interval**: Not yet implemented.
- **Concentration**: Not yet implemented.
- **Move Allowed**: Not yet implemented.

**Cooldown & Targeting**

- **Cooldown Turns**: How many turns must pass before this spell can be cast again?
- **Cooldown Starts**: Does the cooldown start when spellcasting is started, or when it finishes?
- **Shared Cooldown Group**: The ID of a shared cooldown group. 
Spells which share a cooldown group will all go on cooldown when any one of them is cast, and will go on cooldown for the duration of the spell that was cast.
- **Charges**: Not yet implemented.
- **Recharge Turns**: Not yet implemented.
- **Targeter Default**: The default targeting method for this spell. This can be overridden by specific spell actions.

**Costs**

The resource table allows you to define the resource costs for casting this spell. 
If the player is using one of these resources, they must have enough of each resource to cast the spell.
In this way, a spell could cost both Mana and Rage, but if a player does not use Rage, they will only need to pay the Mana cost.

- **Resources**: The stat keys of the resources used to cast this spell.
- **Amount**: The base amount of each resource required to cast this spell.
- **Per Rank**: The additional amount of each resource required to cast this spell per rank.
- **When**: Does the cost occur at the start or end of casting?

**Groups & Actions**

The spell action groups define how the spell behaves when it is cast. 
Each spell can have multiple action groups, and each action group can have multiple actions. 
Below are the available spell action types and their variables.

``APPLY_AURA`` and ``REMOVE_AURA``
- **Aura ID**: The aura ID to apply or remove. This can be obtained from the Aura editor by right right-clicking an aura and selecting "Copy Aura ID".
- **Per Rank**: This can be left at 0.

``DAMAGE`` and ``HEAL``
- **Amount**: The base damage amount. This can be a fixed number, an expression or a dice roll (e.g., "2d6+3").
The special placeholder ``$wep.[slot]$`` can be used to reference the weapon damage of the specified slot (e.g., ``$wep.mainhand$``).
- **Per Rank**: The additional damage amount per rank. This can be a fixed number, an expression or a dice roll.
- **School**: The damage school (e.g., Physical, Fire, Frost, etc.). The special placeholder ``$wep.[slot]$`` can be used to reference the damage school of the weapon equipped in the specified slot.
- **Requires Hit**: Does this damage only occur on a successful hit? Heals should not require a hit.
- **Hit Modifier**: The expression to modify the hit roll by (e.g., to add accuracy bonuses). Use the placeholder ``$stat.[STAT_KEY]$`` to reference stats.
- **Hit Thresholds**: The stats that the hit roll is checked against. Multiple stats can be selected. NPCs will use the highest value of the selected stats, whilst players will be able to choose between them.
- **Crit Modifier**: The expression to modify the crit roll by (e.g., to add critical strike bonuses). Use the placeholder ``$stat.[STAT_KEY]$`` to reference stats.
- **Crit Multip;ier**: How much the damage is multiplied by on a critical hit. For example, a value of 2 means that critical hits deal double damage. The placeholder ``$stat.CRIT_DMG_BONUS$`` can be used to include any critical damage bonus stats, e.g., ``$stat.CRIT_DMG_BONUS$``.
- **Threat**: How much the damage is multiplied by to calculate threat generation. For example, a value of 1 means that threat is equal to damage dealt, whilst a value of 0.5 means that threat is half the damage dealt. It can also refer to a stat using the same placeholder.

``GAIN_RESOURCE``
- **Resource ID**: The stat key of the resource to gain.
- **Amount**: The base amount of the resource to gain.

``HIDE``
- No special variables. This action will hide the caster.

``INTERRUPT``
- No special variables. This action will interrupt the target's casting.

``REDUCE_COOLDOWN``
- **Spell ID**: The spell ID of the spell to reduce the cooldown of. 
This can also be a shared cooldown group identifier. Typing "all" here will reduce the cooldown of all spells.
- **Amount**: The number of turns to reduce the cooldown by.

``SHIELD``
- **Amount**: The base amount of damage the shield can absorb.
- **Per Rank**: The additional amount of damage the shield can absorb per rank.
- **Duration**: How long the shield lasts (in turns).

``SUMMON``
- **NPC ID**: The NPC ID of the creature to summon. This can be obtained from the NPC editor by right right-clicking an NPC and selecting "Copy NPC ID".

All spell action groups have a **targeter** field. This defines how the spell action selects its target(s). The available targeter types are:
- **PRECAST**: This prompts the caster to select a target when the spell is first cast.
- **CASTER**: The caster themselves is the target.
- **TARGET**: This should be used in conjunction with a PRECAST targeter. 
The target(s) selected by the prompt are used as the target for this action. 
If there are no spell actions with the PRECAST targeter, the spell will default back to the default targeter specified on page 3.
- **ALL_ALLIES**: All allies of the caster are targeted.
- **ALL_ENEMIES**: All enemies of the caster are targeted.
- **ALL_UNITS**: All units (allies and enemies) are targeted.

The targeter fields has the following additional options:
- **Max Targets**: The maximum number of targets that can be selected. Only applies to PRECAST, ALL_ALLIES, ALL_ENEMIES and ALL_UNITS targeters.
A non-zero value here will randomly select targets up to the specified maximum when the targeter is ALL_ALLIES, ALL_ENEMIES or ALL_UNITS.
- **Flags**: If left blank, all units can be targeted by the spell. Only enemies will be targetted if the flag field is ``E``. Only allies will be targetted if the flag field is ``A``.

In general, only one action group is needed for most spells. However, multiple action groups can be used to create more complicated spells with conditional effects. This feature is being expanded.
The 'phase' and 'logic' fields should usually be left at their default values.

**Tags**

Spell tags are used throughout the system for filtering and categorization.
For instance, warrior trainers will only offer spells that have the tag ``warrior``.

Best Practices
---------------
- If in doubt, copy a spell from the sample dataset to see how it is configured.
- 

