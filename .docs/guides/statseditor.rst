Stats Editor
=============

The Stats Editor allows you to create and configure ability scores and statistics for your game system.

Accessing the Editor
--------------------

1. Open the Dataset Editor (``/rpe data``).
2. Click the **Stats** tab.

Creating a Stat
---------------

Click **New Stat** to add a stat. The editor opens with multiple pages of configuration:

**Basics**

- **Stat Key**: (Required) Identifier for the stat that will be used elsewhere in the system, e.g., "STR" for Strength.
- **Name**: The name of the stat in the UI. This is what will show in the character sheet and tooltips.
- **Category**: The category this stat belongs to (e.g., Primary, Secondary, Combat, etc.). This defines where it appears in the statistics sheet.
    - *Resource* - A stat that represents a resource pool (e.g., Health, Mana, Holy Power). The system will automatically detect resource stats and make them available as a resource bar above the action bar. However, in order for them to appear, each resource must have a stat which represents its maximum value (e.g., ``FOCUS`` and ``MAX_FOCUS``).
    - *Primary* - Core ability scores (e.g., Strength, Intelligence). This appear at the top of the statistics sheet, after the visible resources.
    - *Secondary* - Derived stats (e.g., Armor, Critical Strike).
    - *Resistance* - Damage resistances (e.g., Fire Resistance).
    - *Skill* - Proficiencies or skills (e.g., Stealth, Persuasion). These appear at the top of the character sheet.
- **Visible**: Does the stat show up on the character sheet?
- **Rule Key / Expression**: How the stat's value is calculated. This can be a direct number, or a rule expression that computes the value based on other stats or conditions. For example, in the the ``INTIMIDATION`` skill has the expression ``$stat.CHA_MOD``, meaning it uses the character's Charisma modifier. 
- **Default Value**: The default value of the value calculation if it cannot be computed from the rule/expression.
- **Min Value**: The minimum value that the stat can take. Most of the time, you will want this to be 0. It is a good idea to set the minimum value of a maximum resource stat (e.g., ``MAX_MANA``) to 1 to avoid divide-by-zero errors.
- **Max Value**: The maximum value that the stat can take. Typing "inf" will set it to be unbounded.

**Display**

- **Icon**: The icon when the stat appears in the character sheet.
- **Description**: ``Do not use this field.``
- **Tooltip**: The tooltip text that appears when hovering over the stat in the character sheet.
- **Percentage**: Indicates if the stat is displayed as a percentage.

**Recovery**

This section is for stats which recover automatically at the start of each turn (e.g., Health, Mana, Stamina, etc.).

- **Rule Key**: The rule in the active ruleset which contains the formula for recovering this stat at the start of each turn. Generally used for resources like Health (e.g., ``health_regen``) or Mana (e.g., ``mana_regen``).
- **Default Value**: The default value if the recovery formula cannot be computed.

**Mitigation**

This section is for stats which can be used when the player is defending. It does not need to be completed for stats which are not used for defence.

- **Defence Name**: The name of the stat as it appears when the player is defending against an attack. For example, your stat might be called "Fire Resistance" in the character sheet, but when defending it appears as "Resist Fire".
- **Combat Text**: The floating combat text that appears when this stat is used to mitigate damage. e.g., the parry stat might display floating combat text that says "Parried!".
- **Mitigation**: How much damage is mitigated when a defence roll succeeds using this stat as a modifier.
- **Crit. Mitigation**: How much damage is mitigated on a critical defence roll using this stat as a modifier.
- **Fail Mitigation**: How much damage is mitigated on a failed defence roll using this stat as a modifier.

The three mitigation fields all take the parameter ``$value$`` which represents the actual damage taken. For example, ``$value$ - $stat.FEL_RESIST$`` means that the damage taken is reduced by the value of the ``FEL_RESIST`` stat.

**Item Bonuses**

This section configures how stats appear on items and does not need to be completed for stats that are not granted by items.

- **Tooltip Format**: The format of the line on the item tooltip when this stat is granted by an item. Use ``$value$`` as a placeholder for the stat's value. For example, a stat that increases health might have the format "{value} Health". The "+" or "-" sign is added automatically based on whether the stat value is positive or negative.
- **Priority**: The priority of this stat when displayed on an item tooltip. Higher numbers appear first.
- **Color (R, G, B)**: The colour of the stat line on the item tooltip, defined as RGB values from 0 to 1.
- **Level Weight**: How much 1 point in this stat affects the item level of the item. Only useful if your active ruleset contains the ``show_item_level`` rule.

Save the stat when done.

Best Practices
---------------
- Resources (e.g., Health, Mana) should have both a current value stat (e.g., ``MANA``) and a maximum value stat (e.g., ``MAX_MANA``). This allows the system to track both the current and maximum amounts correctly.
- If a stat's max value relies on another stat (e.g., the max value of ``CHI`` depends on the value of ``MAX_CHI``), the max value should read ``$stat.MAX_CHI``. The tailing "$" ensures that the system treats it as a reference to another stat rather than a literal value.
- Resources that can be spent (e.g., Mana, Energy) should have their minimum value set to 0 to prevent negative values.
