Running Events
===============

Read the **Event Setup** guide first to understand how to create and configure events.


Before Starting an Event
-----------------------------

Ensure that all group members have the correct ruleset and datasets active. 
You can verify this by clicking the **Ready Check** button at the top of the event window.
If any group members are missing the required ruleset or datasets, sync them using the **Sync Ruleset** and **Sync Datasets** buttons.

When you are ready to start the event, click the **Start Event** button.
There may be a short delay as unit data is synced to all group members.


Controlling an NPC
-----------------------------

If you have added NPCs to the event, you can take direct control of them and perform actions on their behalf.
To control an NPC, left-click on its portrait in the event widget or the unit frame grid.
Your action bar will turn gold in colour, indicating that you are now controlling an NPC.

While controlling an NPC, you can use the action bar to cast spells.
You can directly edit its health, resurrect or kill the NPC, and change its active, hidden and flying statuses with the toolbar that appears underneath the action bar.
To stop controlling the NPC, click the cancel button to the left of the action bar. It is useful to press the **end turn** button first to remind you that you have finished its turn.

NPCs do not use resources, so you can cast as many spells as you like on their turn. Their spells still respect cooldowns and cast times. 
Additionally, you do not need to select the NPC's defences when they are attacked by another unit (player or otherwise).

NPCs can be spoken for by clicking the "Speak as Unit" button in the temporary actions toolbar.
The language that they speak in can also be chosen here. Players will understand a fraction of what they say based on their language skills.

You can swap between NPCs within the current turn by using the left- and right arrows on the temporary actions toolbar.

Intermissions
-----------------------------

If you need to take a break during an event, you can use the **Intermission** button at the top of the event window.
This is useful if your party needs to move locations, or if there's NPC dialogue between fights.

**BEST PRACTICE**: If your event contains multiple encounters, it is more efficient to use intermissions between them rather than ending and restarting the event.

Tracking Performance
-----------------------------

It is sometimes useful to track the performance of players during an event, such as damage dealt, healing done, and threat generated.
RPEngine includes built-in damage, healing, and threat meters that can be toggled using the **Show/Hide Stats** button at the top of the event window.
These meters are only visible to you and are displayed underneath the event control buttons.


Ending the Event
-----------------------------

Simply press the **End Event** button at the top of the event window to end the event for all group members. 
It is good practice to ``/reload`` your UI after this.