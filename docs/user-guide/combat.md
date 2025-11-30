# Combat

Overview of combat flow, damage/healing resolution, and how floating combat text is produced.

- Spells and actions are resolved in `Core/SpellActions.lua`.
- Damage and healing are applied to `EventUnit` objects in `Core/Unit.lua`.
- Floating combat text calls are invoked from the Unit methods for received effects, and from action handlers for dealt effects.
