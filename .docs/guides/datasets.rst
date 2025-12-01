Datasets
===========

The Item Editor allows DMs to author and manage items used by the ruleset and NPCs.

Fields
------

- `id` - unique key
- `name` - display name
- `icon` - texture file ID or path
- `stats` - stat modifications
- `use` - action or effect when used

Editing
-------
Use the in-game Dataset editor (found in the DM tools) to create and test items. Items are persisted under `Data/` in dataset files.

Interactions Editor
-------
**1. Basic**
- `Target` - either the exact ID of an NPC, the tag underneath their name, or their creature type:
    - Exact ID: *e.g.* `541739`. This can be obtained using the command `/rpe npcinfo` while targeting the NPC.
    - Tag: *e.g.* `Blacksmithing Supplies`. This is the tag shown under the NPC's name in the game UI. It will apply the interaction to all NPCs with this tag.
    - Creature type: *e.g* `type:humanoid`. This will apply the interaction to all NPCs of this type.

**2. Options**
Each interaction can have one or more *options*. Each option defines a button or action the player can take when interacting with the target.

- `label`: The text shown on the button (e.g. "Shop", "Salvage").
- `action`: The type of action to perform. Supported actions include:
    - `DIALOGUE`: Opens a dialogue window (customizable by addon authors).
    - `SHOP`: Opens a shop window for the player to buy/sell items.
    - `TRAIN`: Opens a trainer window for skills, spells, or professions.
    - `AUCTION`: Opens an auction house interface.
    - `SKIN`: Attempts to skin the target (usually a beast).
    - `SALVAGE`: Attempts to salvage materials from the target (usually a dead humanoid).
    - `RAISE`: Attempts to raise the target from the dead.
- `requiresDead`: If set (e.g. `1`), the target must be dead for this option to appear.
- `args`: (Advanced) A table of extra arguments for the action. Common keys:
    - `mapID`: Restrict the option to specific map IDs (list or single value).
    - `type`, `flags`, `tags`, `maxLevel`, `maxStock`, `maxRarity`, etc.: Used for filtering, gating, or customizing the action.
    - `output`: For actions like `SALVAGE` or `SKIN`, defines the items and quantities produced. Example:

      ::

        output = {
          { itemId = "iron_ingot", qty = "1d3", chance = 1.0 },
          { itemId = "cloth_scrap", qty = "1d2", chance = 0.25 },
        }

        - `itemId`: The item to give (must match an item in the dataset).
        - `qty`: Quantity, can be a number or dice string (e.g. `"1d3"`).
        - `chance`: Probability (1.0 = always, 0.25 = 25% chance).


