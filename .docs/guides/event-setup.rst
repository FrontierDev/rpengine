Event Setup
===============

To open the event setup window, type ``/rpe event`` in the chat box or click the minimap button and select **Event**.
Only the group leader can view this window. Each tab in the event window has a specific purpose:

Control
-------

This is where events are started, stopped and paused. There are seven buttons here:

- **Sync Ruleset**: This button syncs the ruleset and dataset from the group leader to all other group members. 
- **Sync Datasets**: Syncs ALL of your custom datasets to the group members. This may take a long time if you have large datasets.
- **Ready Check**: Performs a 'dry run' of starting the event, without actually starting it. 
This checks that all group members have the correct ruleset and datasets active.
- **Start Event**: Starts the event. All group members must be online and have the correct ruleset and datasets active.
- **End Event**: Ends the event for all group members.
- **Intermission**: Used to temporarily hide the **event widget** for all players. Useful when taking breaks. Click again to clear.
-- **Show/Hide Stats**: Toggles the damage/healing/threat meters, visible only to you and displayed underneath the buttons.

Units
-------

All **units** (players and NPCs) that are part of the event are listed here. 
Each unit has a set of important variables that are displayed here:

- **Raid Marker**: The raid marker assigned to the unit. Multiple units can share the same raid marker.
- **ID**: The unique identifier for the unit. This is used in event scripts to refer to the unit and is shown in the unit's tooltip.
- **Name**: The name of the unit. For players, this will be their TRP name if they have one set.
- **Init**: The unit's initiative score, used to determine turn order in combat.
- **HP**: The unit's current and maximum health points.
- **Active**: Whether the unit is active in the event. Inactive units do not appear in the turn order and cannot be targetted.
- **Hidden**: Whether the unit is hidden from players. Hidden units appear in the turn order, but the information that palyers see about them is restricted.
- **Flying**: Whether the unit is marked as flying. This doesn't have any effect yet, but may be used in future features.

The unit's initiative, ID and name cannot be changed, but its other properties can be modified by right-clicking on the unit in the table.

**Tip:** Using shift, ctrl and alt while left-clicking on a unit allows you to quickly change its active, hidden and flying statuses.

Settings
-------

This tab contains various settings that affect how the event is run:
- **Event Name**: The name of the event, displayed at the top of the event widget. Keep it short and descriptive, e.g., ``Battle for Hillsbrad Foothills``.
- **Event Subtext**: A subtitle for the event, displayed below the event name in the event widget.
Use this to provide additional context or information about the event, e.g., ``Defeat all enemy forces.``
- **Difficulty**: The perceived difficult of this event, either ``Normal``, ``Heroic`` or ``Mythic``.
This changes the icon next to the event title and has no effect on the event itself currently.
- **Turn Order Mode**: Determines how turn order is calculated:
    - ``INITIATIVE`` - Highest initiative goes first. Units are grouped according to the ``max_tick_units`` rule key.
    - ``PHASE`` - All units in the same team take their turn together. Turn order is determined by team order.
    - ``BALANCED`` - Attempts to place an equal number of units from each team in each tick, while respecting initiative order.
    - ``NON_COMBAT`` - Causes all UI elements except for the unit portraits to be hidden.
    The size of the portraits can be controlled in the ruleset with the ``portrait_size`` rule key.
    Use this for when you want to run non-combat events with talking NPCs.
- **Team Names (1-4)**: The names of each team in the event. These are displayed in the unit frame grid and unit portraits.

Adding Units to the Event
---------------------------------

Click the **Add Unit** button at the top of the **Units** tab to add a new unit to the event.
This will display a popup where you can select:

- **Unit**: The unit from your active datasets.
- **Raid Marker**: The raid marker to assign to the unit.
- **Team**: The team to assign the unit to (1-4).
- **Active, Hidden, Flying**: The initial statuses for the unit.

When you update these settings, the name of the unit will change to reflect the selected team and raid marker options.

By default, NPCs that you add before an event will not be active. 
However, if an event is already running, the popup will automatically select the **Active** option for NPCs, so that they can participate in the ongoing event.

To add the unit, click the **Add Unit** button in the popup.

**Note:** Holding the shift key while pressing the add unit button will keep the window open, allowing you to add multiple units before closing the popup.
