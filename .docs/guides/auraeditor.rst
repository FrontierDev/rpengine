Aura Editor
============

The Aura Editor allows you to create and configure auras (buffs, debuffs, and ongoing effects) in your dataset.

Overview
--------

Auras represent temporary or permanent effects that modify character stats and abilities.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **Auras** tab
3. Search or browse existing auras
4. Click **New Aura** to create

Creating an Aura
----------------

1. Click **New Aura** button
2. Fill in basic information:

   - **Name**: Aura name
   - **Type**: Buff, Debuff, Condition, Effect
   - **Description**: What the aura does

3. Configure duration:

   - **Duration Type**: Instantaneous, Timed, Permanent, Concentration
   - **Duration Length**: If timed (in rounds/minutes/hours)
   - **Stackable**: Can multiple instances apply?

4. Set triggers:

   - **Apply Trigger**: When does it start?
   - **Remove Trigger**: When does it end?
   - **Refresh Trigger**: How to extend duration

5. Configure effects:

   - **Stat Modifiers**: Bonuses/penalties to stats
   - **Immunity**: Resistances or immunities granted
   - **Restrictions**: Movement, action limitations
   - **Custom Effects**: Special behavior

6. Save the aura

Aura Types
----------

**Buffs**
- Beneficial effects
- Increase effectiveness
- Examples: Haste, Shield of Faith

**Debuffs**
- Harmful effects
- Decrease effectiveness
- Examples: Paralyzed, Poisoned

**Conditions**
- Status effects
- Multiple effects combined
- Examples: Charmed, Frightened, Restrained

**Environmental**
- Effects from surroundings
- Ongoing damage
- Examples: Difficult Terrain, Darkness

Tips
----

- Clear naming helps identify effects
- Document all mechanical changes
- Test aura interactions with other effects
- Consider stacking and duration carefully
