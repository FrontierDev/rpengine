NPC Editor
===========

The NPC Editor allows you to create and configure non-player characters in your dataset.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **NPCs** tab

Click the **Add NPC** button to create a new NPC, or click the *...* button and copy an existing NPC from any dataset. The editor opens with multiple pages of configuration:

**Basics**

- **Name (Required)**: The name of the NPC as it appears in the UI.
- **Default Team**: Not used currently, I think.
- **Unit Type**: The type of NPC (e.g., Humanoid, Beast, Undead, etc.). This is displayed in the unit's tooltip during an event.
- **Unit Size**: The size of the unit. This is displayed in the unit's tooltip during an event.
- **Summon Type**: The type of summon (e.g., Guardian, Minion, etc.). This is displayed in the unit's tooltip during an event.
- **Base HP**: The base health points of the NPC.
- **HP per Player**: The amount of health points added per player in the event.

**Model**

The unit's model is displayed in its unit portrait during events. Click on 'Choose Model' to select a model from the game's files. The position of the model can be adjusted using the three sliders underneath the preview frames.

**Stats**

The stats that the NPC can use. The **stat** column takes a stay key, e.g., ``MELEE_AP``, as defined in the Stats Editor. The **value** column takes a fixed number. If a spell attempts to access a stat that the NPC does not have, it will default to 1.

**NPC Spellbook*

The spells that the NPC can use. Left click on a slot to change the spell.

**NPC Behaviours** and **Bestiary Entries** are not yet implemented.


Tips and Best Practices
-------------
NPC data is relatively short-lived compared to stats, spells and (to a lesser extent) items. Therefore, it is often best to keep all of your NPCs in a separate dataset from your main items, spells and stats.
This way, if you need to make changes to your NPCs, you can do so without having to resync all of your items and spells as well.
You will have to sync your dataset before most events that you run, unless you are reusing NPCs a lot!


