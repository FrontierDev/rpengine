NPC Interactions
===============

If your dataset includes NPC interactions, you can interact with NPCs in-game using the interaction menu.
The interaction menu will automatically appear when you target an NPC that has interactions defined in your active datasets.
It can be dragged wherever you like on the screen, and its position is saved per-character.

Vendors
----------------

NPC vendors display a selection of items that can be purchased for copper/silver/gold.
The prices of items sold by NPC vendors are defined in the dataset and vary from their market value in three ways:

- **Daily fluctation**: Each day, the price of items may increase or decrease by a small random amount. This can be turned off by setting the ``shop_daily`` rule to ``0``.
- (NYI) **Location**: Different NPC vendors in different locations may sell the same item at different prices. This can be used to simulate supply and demand in different areas. This can be turned off by setting the ``shop_location`` rule to ``0``.
- (NYI) **Reputation**: NPC vendors may offer better prices to players with higher reputation with them. This can be turned off by setting the ``shop_reputation`` rule to ``0``.

Shops created using the interaction editor may also have additional restrictions, such as maximum item rarity and stock levels.
If an item is out of stock, it cannot be purchased until the shop is restocked. This occurs at midnight server time.

Trainers
----------------

NPC trainers allow you to learn new profession recipes or spells.
Only spells and recipes from your active dataset(s) will be available to learn from trainers.

If the ``no_recipe_cost`` rule is set to ``1``, profession recipes can be learned for free.
If the ``no_spell_cost`` rule is set to ``1``, spells can be learned for free.

Skinning and Salvaging
----------------

Some in-game NPCs can be skinned or salvaged for materials after they have been defeated, depending on how your datasets have been setup.
To skin or salvage an NPC, kill it, target it, then press the button on the interaction menu.