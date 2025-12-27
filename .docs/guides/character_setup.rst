Character Setup
===============

To begin setting up your character, you must have the following:

- a **dataset** that contains a setup wizard configuration.
- a **ruleset** that includes the ``setup_wizard`` rule key, pointing to the dataset containing the setup wizard.

This will be created by whoever runs your RPEngine events, typically your guild leader or one of the guild officers.
They will create the dataset and ruleset, then share them with you. 
If they have been set up correctly, you will not need to manually activate the dataset or ruleset.

Once you have the dataset and ruleset, type ``/rpe setup`` in the chat box to begin the character setup process.
This will open the setup wizard, which will guide you through the character creation process step-by-step.
Follow the prompts in the setup wizard to create your character.
After completing the setup wizard, your character will be created and ready to use in RPEngine events.

If you need to change your character's setup later, you can re-run the setup wizard at any time by typing ``/rpe setup`` again.

**IMPORTANT** - If the setup wizard prompts you to select something such as stats, spells, items or professions, clicking the 'Finish' button WILL reset your profile in that area.
For example, if you select new stats and click 'Finish', your existing stats will be replaced with the new ones you selected.
If you are prompted to select items at any point, then you will also lose any coins you had previously.

Equipment and Binding Spells
-------------------------------

Once you have completed the setup wizard, type ``/rpe sheet`` or left-click the minimap button to open the **main window**. 
Head over to the inventory tab and right click on a piece of equipment, then equip it. Do the same for any spells that you have.

Currently, you cannot view the action bar or unit frames until you enter an event. 
To check everything is set up correctly, make sure you are not in a group, type ``/rpe event``, then hit the **Start Event** button.
This will start an event with just your character in it. Reposition the unit frames and action bar as desired and check that your spells are on the action bar.

If you selected any traits, you should (probably) see the effects of those traits in the top right corner.

By default, only your health bar will be showing next to the player portrait.
You can add **two** additional resource bars to the portrait (although your character can use more resources internally).
To add resource bars, right click on the player portrait and select the resources that you want to **use** and **show**.

Once you are done, you can just ``/reload`` your UI to exit the event and save your profile.


Modifying Your Character After Setup
-------------------------------
After completing your character setup, you may want to modify your character further:

- **Traits** (passive effects) and **Languages** can be added to your character by going to the **Character** tab in the main RPEngine window.
- **Spells** can be learned from spell trainers in-game. If the ``DefaultClassic`` dataset is active, you can find trainers in starting zones. Look for NPCs with class-related titles, e.g., "Warrior Trainer".
- **Professions** can be learned from profession trainers in-game. If the ``DefaultClassic`` dataset is active, look for NPCs with profession-related titles in cities, e.g., "Herbalism Trainer".
- **Items** can be obtained through various means, such as as loot from events, purchasing from shops, or crafting using professions.