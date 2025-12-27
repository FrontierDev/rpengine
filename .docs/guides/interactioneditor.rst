Interaction Editor
===========

The Interaction Editor allows you to create and configure interactions with in-game NPCs.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **Interactions** tab

Click the **Add Interaction** button to create a new interaction, or click the *...* button and copy an existing interaction from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Target**: Despite what the label says, this field takes one of three values:
    - **NPC ID**: The exact ``npcId`` of an NPC. You can find this information by targetting an NPC in-game and running the ``/rpe npcinfo`` command.
    - **NPC Title**: The 'title' of an NPC. When you hover over an NPC, this is the text that appears under their name in white. This allows you to create interactions that can be used by multiple NPCs with the same title, e.g., ``Alchemy Supplies``.
    - **NPC Type**: The unit type of an NPC (e.g., Humanoid, Beast, Undead, etc.). This allows you to create interactions that can be used by all NPCs of a certain type. This should be lowercase, e.g., ``type:beast``.

**Options**

Multiple interactions can be added to a target. Each interaction has a **label**, which is the text that appears in the interaction menu that appears when an NPC is targeted in-game. The following **actions** are supported, with the corresponding arguments in the table below:

- ``SHOP``: Opens a shop interface.
    - ``maxRarity`` - The maximum item rarity that the shop will sell (e.g., ``rare``, ``epic``, etc.). Items above this rarity will not be sold.
    - ``maxStock`` - The maximum stock level for each item in the shop. Once an item is sold out, the player cannot buy any more again until the shop is restocked.
    - ``matchAll``- Dictates whether an item needs to match all tags specified in the **tags** field, or just one of them. If set to true, an item must have all of the specified tags to appear in the shop. If set to false, an item only needs to have one of the specified tags to appear in the shop.
    - ``tags`` - A comma-separated list of item tags that the shop sells. Only items with these tags will appear in the shop.
- ``TRAIN``: Opens a profession trainer interface.
    - ``type`` - Dictates whether the trainer teaches ``SPELL``s or ``PROFESSION`` recipes.
    - ``flags`` - In ``PROFESSION`` mode, this should be a comma-separated list of profession flags that the trainer offers (e.g., ``blacksmithing``, ``alchemy``, etc.). In ``SPELL`` mode, this is a comma-separated list of spell tags that the trainer offers (e.g., ``warrior``, ``mage``, etc.).
    - ``maxLevel`` - The maximum profession level that the trainer will teach recipes for. Recipes above this level will not be taught. In ``SPELL`` mode, this is the maximum character level that the trainer will teach spells for.
- ``SKIN`` and ``SALVAGE``: Allows the player to skin or salvage the NPC for materials.
    - ``requiresDead`` - If true, the NPC must be dead in order to skin or salvage it.
    - ``mapIDs`` - A comma-separated list of map IDs where the skinning or salvaging can take place. If left blank, skinning and salvaging can take place anywhere.
    - ``output`` - A comma-separated list of item IDs that can be obtained from skinning or salvaging the NPC. 
    The format is ``[item id]:[dice roll]:[chance]``, where ``[item id]`` is the ID of the item that can be obtained, ``[dice roll]`` is the number of items that can be obtained, and ``[chance]`` is the chance (between 0 and 1) to receive any of that item. 
    For example, ``17012:1d3:100,17013:1d2:50`` means that skinning or salvaging the NPC will always yield 1-3 items with ID 17012, and has a 50% chance to yield 1-2 items with ID 17013.

Tips and Best Practices
-------------
- Interaction data is usually long-lived data and can be kept in your long-term dataset (typically alongside your custom spells and auras).
- Interactions merge together from all of your active datasets, so you can have different interactions in different datasets if needed.