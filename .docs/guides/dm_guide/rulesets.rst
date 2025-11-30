Rulesets
========

What is a Ruleset?
------------------

A ruleset defines the **rules and formulas** that govern how stats are calculated. It's the mechanical backbone of your character.

Examples:

- D&D 5e ruleset: ``max_health = 10 + (STA * 5)``
- Warcraft ruleset: ``max_health = 10 * STA``
- Custom ruleset: Your own formulas

Per-Character Rulesets
----------------------

Each character can have an active ruleset:

- Rulesets are identified by name
- Data is saved in ``RPEngineRulesetDB``
- One ruleset is active per character at a time
- Rulesets persist across sessions

Creating a Ruleset
------------------

1. Open the Ruleset window
2. Click "New Ruleset"
3. Enter a ruleset name
4. Add rules (see `Rule Syntax`_)
5. Click "Save"
