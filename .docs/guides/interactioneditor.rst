Interaction Editor
===================

The Interaction Editor allows you to create and configure NPC interactions and dialogue trees.

Overview
--------

Interactions define how players communicate with NPCs, including dialogue options, quest progression, and branching conversations.

Accessing the Editor
--------------------

1. Open the Dataset Editor
2. Go to the **Interactions** tab
3. Select an NPC to edit interactions
4. Click **New Interaction** to create

Creating an Interaction
-----------------------

1. Click **New Interaction** button
2. Set interaction type:

   - **Dialogue**: Conversation tree
   - **Trade**: Buy/sell interface
   - **Quest**: Quest interaction
   - **Special**: Custom interaction

3. For dialogue interactions:

   - **Initial Text**: What NPC says first
   - **Options**: Player dialogue choices
   - **Responses**: NPC replies to each option
   - **Next Node**: Where conversation goes next

4. Configure dialogue branches:

   - Create multiple conversation paths
   - Set conditions for visibility
   - Link nodes together
   - Handle different outcomes

5. For trade interactions:

   - **Inventory**: What NPC buys/sells
   - **Prices**: Currency values
   - **Stock**: Limited quantities if applicable

6. For quest interactions:

   - **Quest Giver**: Offers quest
   - **Quest Taker**: Completes quest
   - **Rewards**: Experience, items, currency
   - **Requirements**: Level/quest prerequisites

7. Save the interaction

Best Practices
--------------

- Keep dialogue trees reasonable length
- Use clear, readable options for players
- Provide multiple dialogue paths
- Include flavor text for immersion
- Test conversations thoroughly
- Avoid dead-end dialogue

Tips
----

- Branch conversations based on player stats/background
- Use conditional text for different outcomes
- Reward exploration with unique dialogue
- Make quest instructions clear
- Document complex dialogue trees
