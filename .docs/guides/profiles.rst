Character Profiles
==================

What is a Profile?
------------------

A character profile stores all data specific to one character:

- **Basic Info**: Character name, realm, guild
- **Stats**: All tracked attributes and abilities
- **Equipment**: Equipped items and their bonuses
- **Inventory**: Items the character possesses
- **Professions**: Crafting specializations and recipes

Per-Character Storage
---------------------

Each character gets their own profile automatically:

- Profiles are identified by character name + realm
- Data is saved in ``RPEngineProfilesDB``
- Switching characters loads the appropriate profile
- Multiple characters can use different rulesets

Creating a Profile
------------------

Profiles are created automatically on first login. You can also manually create new profiles:

1. Open the Profile Manager
2. Click "New Profile"
3. Enter a profile name
4. Configure stats and equipment

Profile Management
------------------

**Loading a Profile**

- Profiles for your character load automatically on login
- Use the Profile Manager to switch between profiles
- Only one profile is active at a time

**Editing a Profile**

1. Open the Character Sheet (``Shift+C``)
2. Click "Edit Sheet"
3. Modify stats, equipment, or notes
4. Click "Save"

**Deleting a Profile**

1. Open the Profile Manager
2. Select a profile
3. Click "Delete" (cannot be undone)

**Resetting a Profile**

1. Open the Character Sheet
2. Click "Reset Profile"
3. Confirm - this restores default stats

Stat Details
------------

Each stat has:

- **Base Value**: Starting value (from a rule or literal number)
- **Equipment Modifiers**: Bonuses from equipped items
- **Aura Effects**: Buffs/debuffs from active auras
- **Effective Value**: Final calculated value

The Character Sheet displays effective values and breakdowns of modifiers.

Profile Data Files
------------------

Profiles are persisted in ``RPEngineProfilesDB`` SavedVariable:

.. code-block:: lua

    RPEngineProfilesDB = {
        _schema = 1,
        currentByChar = {
            ["PlayerName-RealmName"] = "ActiveProfileName"
        },
        profiles = {
            ["ActiveProfileName"] = {
                name = "ActiveProfileName",
                stats = { ... },
                equipment = { ... },
                items = { ... },
                notes = "Optional notes"
            }
        }
    }

Tips & Best Practices
---------------------

- **Back up important profiles**: Export data or save a screenshot
- **Use descriptive names**: "Warrior Build v2" is better than "Profile1"
- **Test stat changes**: Use a secondary profile to experiment
- **Document rules**: Add notes explaining custom rulesets
