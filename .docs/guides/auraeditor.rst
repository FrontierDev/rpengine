Aura Editor
============

The Aura Editor allows you to create and configure auras (buffs, debuffs, and ongoing effects) in your dataset.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **Auras** tab

Click on an empty slot to add a new aura, or right-click and copy an existing aura from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Name (Required)**: The name of the aura as it appears in the UI.
- **Icon**: The icon texture representing the aura.
- **Description**: A description of the aura's effects. The description renders in the same way that a spell's description does.
For more information on how to format spell descriptions, see the Spell Editor guide.

**Type & Flags**

- **Helpful**: Is this a beneficial effect (buff) or a harmful effect (debuff)? Check this box for buffs.
- **Dispel Type**: If this aura is a debuff, what kind of debuff is it? This option determines how the aura can be removed, and also what colour border the debuff has:
    - ``MAGIC`` - Blue border
    - ``DISEASE`` - Brown border
    - ``POISON`` - Green border
    - ``CURSE`` - Purple border
    - ``PHYSICAL`` - Grey border
- **Tags**: Comma-separated tags associated with the aura. These are used throughout the system for filtering and categorization.
Class and racial traits require the tags beginning with ``class:`` or ``race:`` respectively. For example, a Paladin aura would need the tag ``class:paladin``.
- **Trait**: Is this aura a trait (passive effect)? Traits are special auras that are applied when an event starts, and can be assigned in the character sheet.
- **Hidden**: Does this aura icon show when the player has this aura? This can be useful to reduce the number of icons shown on screen for passive effects.
- **Unpurgable**: Can this aura be removed by dispel effects? Check this box to make the aura unpurgeable.
- **Unique per Caster**: This determines whether multiple instances of this aura from different casters can exist on the same target simultaneously. If checked, multiple instances from different casters can exist. If unchecked, only one instance of the aura can exist on a target at any time, regardless of the caster.
- **Remove on Damage Taken**: Should this aura be removed when the target takes damage? This is typically used for protective auras that expire upon taking damage.

**Duration and Ticking**

- **Duration (turns)**: How many turns the aura lasts. Leave blank for permanent auras.
- **Expire at**: When does the aura expire - at the start of the caster's turn, or at the end? You usually want this to be ``ON_OWNER_TURN_END``.
- **Tick Period**: How often does the aura apply its effects? Leave blank for one-time effects. Usually you'll want this to be ``1`` so that the aura ticks every turn.

The rest of this page configures the mechanical effects of the aura. Refer to the Spell Editor guide for details on configuring spell effects, as the same principles apply here.

**Stacks and Conflicts**

- **Max Stacks**: The maximum number of stacks this aura can have. Leave blank for single-stack auras.
- **Stacking Policy**: What happens when the aura is reapplied while it is already active? You will probably want this to be ``REFRESH_DURATION`` for non-stacking auras and ``ADD_MAGNITUDE`` for stacking auras.
    - ``REFRESH_DURATION`` - The duration resets to the maximum duration.
    - ``ADD_MAGNITUDE`` - The stack count increases by one, up to the maximum stacks.
    - ``EXTEND_DURATION`` - The duration increases by the maximum duration, beyond its original maximum.
    - ``REPLACE`` - The existing aura is replaced with the new application.
- **Unique Group**: A group identifier for auras that conflict with each other. If two auras share the same unique group, applying one will remove the other. Leave blank if the aura does not conflict with any others.
- **Conflict Policy**: What happens when this aura conflicts with another aura in the same unique group? You will probably want this to be ``KEEP_HIGHER``.
    - ``NONE`` - No special handling; both auras can coexist.
    - ``KEEP_HIGHER`` - Keep whichever aura has the higher duration.
    - ``KEEP_LATEST`` - Keep the most recently applied aura.
    - ``BLOCK_IF_PRESENT`` - Do not apply this aura if another aura from the same group is already present.

**Stat Modifiers**

Stat modifiers allow the aura to modify character stats while it is active, including both flat bonuses and percentage-based increases, and applying advantage and disadvantage. The stat modifier table has several columns:

- **Stat**: The Stat Key of the stat to modify (e.g., ``STR``, ``ARMOR``, etc.). Note, this does not use the same format as spell effects (e.g., ``$stat.STR``), just the raw Stat Key (e.g., ``STR``)!
- **Mode**: The type of modification to apply:
    - ``ADD``, ``SUB``: Add or subtract a flat value to the stat.
    - ``PCT_ADD``, ``PCT_SUB``: Adds a percentage of the base stat value. This is additive, so multiple percentage modifiers will stack together. e.g., two ``PCT_ADD`` modifiers of 10% each will result in a total of +20% to the base stat, not +10% then +11%.
    - ``MULT``: Multiplies the stat by a factor. e.g., a multiplier of 1.5 will increase the stat by 50%, while a multiplier of 0.8 will decrease the stat by 20%.
    - ``FINAL_ADD``: Adds a flat value to the stat after all other calculations have been applied. This is useful for effects that should bypass percentage increases or multipliers.
    - ``ADVANTAGE``: Increases the advantage level of the given stat. Advantage levels are cumulative, so multiple applications of advantage will increase the level further. For each advantage level, rolls using this modifier are rolled again and the highest result is taken. The opposite is true for disadvantage, in which the lowest roll is taken
- **Value**: The value to apply to the stat, based on the selected mode.
- **Per Rank**: The value to apply per rank of the aura.
- **Scale**: For stackable auras, this should read ``"STACKS"``. For other auras, just leave it blank.
- **Source**: Does the aura apply to the ``TARGET`` of the aura (i.e., the unit with the aura on it), or the ``CASTER`` of the aura (i.e., the unit that applied the aura)?
- **Snapshot**: Just leave this as dynamic. It is unlikely you will need to change this. It determines when the stat modifier value is calculated - either when the aura is applied (snapshot) or each time the stat is queried (dynamic).

**Immunity**

This page defines immunities and crowd control effects granted by the aura.

- **Damage Schools**: When this aura is applied, the target becomes immune to damage from the selected damage schools.
- **Aura Types**: When this aura is applied, the target becomes immune to the selected aura types (e.g., ``MAGIC, POISON`` will make the target immune to ``MAGIC`` and ``POISON`` auras).
- **Aura Tags**: When this aura is applied, the target becomes immune to auras with any of the specified tags. For example, if you enter the tag ``protection``, the target will be immune to any auras that have the ``protection`` tag.
- **Aura IDs**: When this aura is applied, the target becomes immune to auras with any of the specified Aura IDs.
- **Block Helpful**: Prevents helpful auras from being applied to the target while this aura is active.
- **Block Harmful**: Prevents harmful auras from being applied to the target while this aura is active.
- **Block All Actions**: Prevents the target from casting ANY spells while they have this aura.
- **Block by Tag**: Prevents the target from casting spells with any of the specified tags while they have this aura.
- **Fail All Defences**: Causes the target to fail all their defensive rolls while they have this aura. Players will not be prompted to defend against attacks.
- **Fail by Stat**: Prevents the target from making defence rolls using the specified stat while they have this aura.
- **Slow Movement**: Not yet implemented.

**Aura Triggers**

Aura triggers enable a limited number of effects to occur when certain events happen while the aura is active. 
This is how the system handles effects such as 'deal fire damage on hit'.
The aura trigger talbes has the following columns:

- **Event**: This is the event that is triggered at certain points in RPE's combat flow. The available events are:
    - ``ON_HIT``, ``ON_DAMAGE`` - when the unit with the aura hits another unit with a damaging spell or attack.
    - ``ON_HIT_TAKEN`` - when the unit with the aura is hit by a damaging spell or attack.
    - ``ON_CRIT`` - when the unit with the aura lands a critical hit with a damaging spell or attack.
    - ``ON_CRIT_TAKEN`` - when the unit with the aura is critically hit by a damaging spell or attack.
    - ``ON_HEAL`` - when the unit with the aura heals another unit.
    - ``ON_HEAL_TAKEN`` - when the unit with the aura is healed by another unit.
    - ``ON_KILL`` - when the unit with the aura kills another unit.
    - ``ON_DEATH`` - when the unit with the aura reaches 0 HP.
- **Action**: The action to perform when the event is triggered. The available actions are:
    - ``DEAL_DAMAGE`` - deal damage to the target.
    - ``HEAL`` - heal the target.
    - ``APPLY_AURA`` - apply another aura to the target.
    - ``GAIN_RESOURCE`` - remove an aura from the target.
- **Amount**: The magnitude of the effect. This can include expressions (e.g., ``$stat.INT_MOD$``, ``2d2``).
- **Stat**: The school of damage to apply.
- **Duration**: Not used. Ignore this field for now.
- **Aura ID**: The Aura ID to apply or remove when using the ``APPLY_AURA`` action.
- **Target**: Who is the target of the effect? Options are:
    - ``TARGET`` - the target of the spell or attack that triggered the event.
    - ``SOURCE`` - the source of the spell or attacker that triggered the event.

Tips
-----------------------------
- Copy an existing aura from the sample dataset to see how it is configured.
- Applying too many stat mods at once can cause a brief freeze (~1 second) as the system recalculates all affected stats. Try to keep the number of simultaneous stat mods to a minimum for best performance.