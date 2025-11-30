Combat
======

Overview of combat flow, action resolution, and damage/healing application.

Key files
---------

- `Core/SpellActions.lua`: rolls amounts and builds broadcast entries for damage/heal.
- `Core/Unit.lua`: `ApplyDamage` and `Heal` update unit HP and trigger UI updates.
- `UI/Prefabs/FloatingCombatText.lua`: displays floating combat text entries.

Dealt vs received
-----------------

- Damage/heal *received* is shown by `Unit:ApplyDamage` / `Unit:Heal` for the local player (downwards, red for received damage).
- Damage/heal *dealt* by the controlled player is shown from action handlers (upwards, white for dealt damage).
