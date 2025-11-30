Quick Start Guide
=================

5-Minute Setup
--------------

1. **Log in with your character**
   
   RPEngine automatically creates a profile for each character on login.

2. **Open the Character Sheet**
   
   - Press ``Shift+C`` or use the minimap button
   - View your character's stats and attributes

3. **Create or Load a Ruleset**
   
   - Open the Ruleset window from the UI menu
   - Select a ruleset or create a new one
   - Rulesets define how stats are calculated

4. **Manage Datasets**
   
   - Datasets contain stat definitions and templates
   - Multiple datasets can be active simultaneously
   - Use the Dataset panel to enable/disable them

Basic Workflow
--------------

**For Roleplayers:**

1. Create a character profile with your stats
2. Choose or create a ruleset (D&D 5e, Warcraft, etc.)
3. Equip items to add stat bonuses
4. Use the character sheet to track your abilities

**For Dungeon Masters:**

1. Create custom rulesets for your campaign
2. Define stat formulas and mechanics
3. Lock required datasets to enforce consistency
4. Use the NPC registry to manage NPCs

Common Tasks
------------

Changing Your Character's Stats
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Open the Character Sheet (``Shift+C``)
2. Click "Edit Sheet"
3. Modify stat values and click "Save"

Adding Equipment
~~~~~~~~~~~~~~~~

1. Go to the Equipment tab
2. Click on a slot to search for items
3. Select an item to equip
4. Stats automatically update

Creating a Custom Ruleset
~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Open the Ruleset window
2. Click "New Ruleset"
3. Add rules like: ``max_health = 10 * $stat.STA$``
4. Click "Save"
5. Set as active to use it

Next Steps
----------

- Read the :doc:`profiles` guide for advanced profile management
- Learn about :doc:`rulesets` to create custom game mechanics
- Explore :doc:`datasets` for creating stat templates
