Item Editor
============

The Item Editor allows you to create and configure items in your dataset.

Accessing the Editor
--------------------

1. Open the Dataset Editor (``/rpe data``).
2. Click the **Items** tab.

Creating an Item
----------------

Click on an empty slot to add a new item, or right-click and copy an existing item from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Name (Required)**: The name of the item as it appears in the UI. 
- **Category**: The category of the item, which defines its general type and behavior (e.g., Weapon, Armor, Consumable, Quest Item).
- **Rarity**: The rarity of the item (e.g., Common, Uncommon, Rare, Epic, Legendary).
- **Icon**: The icon texture representing the item.
- **Description**: A description of the item, also known as "flavor text".
- **Tags**: Comma-separated tags associated with the item. These are used throughout the system for filtering and categorization.

**Stacking**

- **Stackable**: Can the item be stacked?
- **Max Stack**: What is the maximum stack size of the item?
- **Base Price (u)**: The base price of the item in economy units (u). 4 *u* is 1 copper. 
- **Buy @ Vendors**: Can this item be purchased from vendors?
- **Price Override (c)**: Explicitly define the market price of the item in copper (c). If left blank, the price is calculated based on the base price and item rarity.

**Data**

Most of the item's functionality is defined here. The data keys need to be added manually.

**Equipment**-type items have several fields that should be included: 

- ``slot`` - the ID of the slot that the item can be equipped in (e.g., ``head``).
- ``armorType`` - the display name of the slot as it appears in the item tooltip (e.g., ``Head``, ``Helmet``, etc.).
- ``armorMaterial`` - the material type of the armor (e.g., ``Cloth``, ``Leather``, ``Mail``, ``Plate``).
- ``accessoryType`` - the type of accessory (e.g., ``Ring``, ``Trinket``, etc.).
- ``weaponType`` - the type of weapon (e.g., ``Sword``, ``Axe``, ``Bow``, etc.).
- ``hand`` - the hand that the weapon goes in (e.g., ``Main Hand``, ``Off Hand``, ``Two Hand``).
- ``damageSchool`` - the damage school that the weapon deals when it is used to deal damage (e.g., ``Physical``, ``Fire``, ``Frost``, etc.).
- ``damageMin`` - the minimum damage the weapon deals.
- ``damageMax`` - the maximum damage the weapon deals.

Weapons, armour and accessories each require a set of keys to display properly:

- **Weapons** require ``slot``, ``weaponType``, ``hand``, ``damageSchool``, ``damageMin``, and ``damageMax``.
- **Armour** requires ``slot``, ``armorType``, and ``armorMaterial``.
- **Accessories** require ``slot`` and ``accessoryType``.

Both **equipment** and **modification** items can have stat bonuses. 
These are defined using the key format ``stat_[STAT_KEY]``, where ``[STAT_KEY]`` is the Stat Key defined in the Stats Editor. For example, to add a bonus to Strength, you would use the key ``stat_STR`` with a value of the amount to increase Strength by.

**Material**-type items used in crafting recipes should include:
- ``tier`` - the numerical tier of the crafting matierial. For reference, tier 1 includes materials such as copper and linen, while tier 5 includes materials such as arcanite and felcloth.

**Consumable**-type items work by casting a spell when used. To configure this, set the following fields on the 4th page of the editor:

- **Spell ID**: The spell ID to be cast when the item is used. The ID can be found by right-clicking the spell in the spell book and selecting "Copy Spell ID".
- **Spell Rank**: The rank at which to cast the spell.

Harvestable Reagents
---------------
Reagents can be made harvestable by including a tag in the format: ``node:[profession]:[node name]:[min.amount]-[max.amount]``.
For example, ``node:herbalism:peacebloom:1-3`` would make the item "Peacebloom" harvestable from in-game Peacebloom nodes, yielding between 1 and 3 units when harvested.
The tag can have spaces, but must be entirely in lower-case.

Notes and Best Practices
---------------
- Refer to the item economy table to set appropriate base prices for items. The final price of an item is influenced by its rarity and item level.
- Item level is automatically calculated when you save an item in the editor, and is shown if you have the ``show_item_level`` rule set in your active ruleset.



