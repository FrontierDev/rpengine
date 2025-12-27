Datasets
===========

Datasets are collections of data that define various aspects of your RPEngine experience, such as NPCs, items, locations, and events.
Datasets can be categorized into three types based on their expected lifespan and usage:
- **Short-term Data**: Datasets that are likely to be synced before every event, such as NPCs and event scripts.
- **Mid-term Data**: Datasets that are expected to be synced occasionally, such as item rewards and crafting recipes.
- **Long-term Data**: Datasets that are expected to be synced once and remain for a long time, such as custom spells, auras, and interactions.

When selecting a dataset for your campaign, it's important to consider the type of data it contains and how frequently it will need to be updated.
While there is no limit to the size of your datasets, syncing large datasets can take quite a long time. 
**Therefore, it is not just good pracitce but highly recommended to separate your datasets based on their expected lifespan and usage.**

Creating a Dataset
--------------------

To create a new dataset, follow these steps:

1. Open the RPEngine dataset manager by typing ``/rpe data`` in the chat or right-clicking the minimap button and selecting **Datasets**.
2. Click the **Create Dataset** button.
3. Enter a name for your dataset. It should be unique!

Consider changing the **metadata** to protect your dataset from modification.
Click on the **Metadata** tab and see the Metadata Editor guide for more information.

Required Datasets
--------------------

You can force your group members to always use the same datasets as you by adding them to the **required datasets** list in your active ruleset.
This ensures that everyone has the same data available during events, preventing potential issues caused by missing or outdated data.

The format of the ``required_rulesets`` key is a Lua table, e.g., ``{ MyDataset1\, MyDataset2 }``.

Additionally, you can make sure that your players ONLY use the required datasets by setting the ``dataset_exclusive`` rule key to ``1``.
This prevents players from loading any datasets that are not on the required list.

Editting Data
--------------------

Please refer to the individual data editor guides for information on how to create and edit specific types of data within your datasets, such as NPCs, items, spells, and interactions.
Always remember to click the **Save** button after making changes to ensure that your edits are stored in the dataset.