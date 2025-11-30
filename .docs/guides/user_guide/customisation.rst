Customisation
=============

How to customise the RPEngine UI and profiles.

Sections
--------

- Palette & colors
- Floating combat text options
- UI layout and widget visibility

Palette & colors
----------------
RPEngine provides palette files under `UI/Palettes/` and a palette selector in the UI. To add a palette, create a new file in `UI/Palettes` following the existing format.

Floating combat text
--------------------
The floating combat text behaviour is controlled by the `FloatingCombatText` prefab (`UI/Prefabs/FloatingCombatText.lua`) and is initialised in `Profile/ProfileDB.lua`.

You can adjust:

- default direction (`UP` or `DOWN`)
- scroll distance and duration
- base scale

UI layout
--------
Widgets and windows are created from `UI/Windows` and `UI/Prefabs` and can be shown/hidden via the Event Control UI.
