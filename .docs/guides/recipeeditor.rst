Recipe Editor
===========

The Recipe Editor allows you to create and configure crafting recipes in your dataset.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **Recipes** tab

Click the **Add Recipe** button to create a new recipe, or click the *...* button and copy an existing recipe from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Name (Required)**: The name of the recipe as it appears in the UI.
- **Profession**: The profession that the recipe belongs to (e.g., Blacksmithing, Alchemy, etc.).
- **Category**: The category of the recipe within the profession (e.g., Weapons, Potions, etc.). This ditcates the folder structure in the profession trainer UI.
- **Skill Req**: The minimum profession skill level required to learn the recipe.
- **Quality**: The quality of the recipe (e.g., Common, Uncommon, Rare, Epic, Legendary).

**Output**

- **Output Item Id** - The item ID of the item that is created when the recipe is crafted. This can be found by right-clicking an item in the Item Editor and selecting 'Copy Item ID'.
- **Output Quantity** - The number of items created when the recipe is crafted.

**Reagents**

This section defines the reagents required to craft the recipe. Each reagent has two fields: an item ID and a quantity. 
The item ID can be found by right-clicking an item in the Item Editor and selecting 'Copy Item ID'.

**Optional Reagents** - *This will be removed in a future update.*

**Tools** - Not yet implemented.

**Costs**

This section defines any additional costs required to LEARN the recipe, such as gold or special currencies.
It takes either a built-in currency ID (``copper``, ``justice``, ``honor``, ``conquest`` or ``valor``) or the item ID of an item that is of the ``CURRENCY`` type.
Recipe costs can be bypassed using the ``no_recipe_cost`` rule in the active ruleset.

