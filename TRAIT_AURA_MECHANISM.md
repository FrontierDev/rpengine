# Trait Aura Application Mechanism - RPEngine

## Overview
Trait auras (permanent auras marked with `isTrait = true`) are applied to units through a multi-stage initialization and runtime system. This document maps all locations where trait auras get applied.

---

## 1. Trait Aura Definitions

### Location: [Data/Classic/Auras.lua](Data/Classic/Auras.lua)

**Unholy Presence (aura-oCADkPre02)** - Example trait aura
- **File**: [Data/Classic/Auras.lua](Data/Classic/Auras.lua#L5740)
- **Lines**: 5740-5780
- **Key Property**: `isTrait = true`
- **Tags**: `"class:deathknight"` (at line 5752)
- **Definition includes**:
  - `id = "aura-oCADkPre02"`
  - `isTrait = true`
  - `tags = { "class:deathknight" }`
  - Triggers for ON_CRIT events
  - Tick actions to heal summoned units

### All Trait Auras
All auras marked with `isTrait = true` are defined in [Data/Classic/Auras.lua](Data/Classic/Auras.lua). Search results show 20+ matches for `isTrait = true` at various lines.

---

## 2. Profile Storage of Traits

### Location: [Profile/CharacterProfile.lua](Profile/CharacterProfile.lua)

#### Trait Storage
- **Lines**: 124
- **Field**: `traits = opts.traits or {}` - list of trait aura IDs stored per character profile

#### Trait API Methods

**GetTraits()** - [Profile/CharacterProfile.lua](Profile/CharacterProfile.lua#L1022)
- **Lines**: 1022-1025
- **Returns**: `self.traits or {}` - the list of all trait aura IDs for the profile
- **Purpose**: Retrieve all traits stored in a character profile

**AddTrait(auraId)** - [Profile/CharacterProfile.lua](Profile/CharacterProfile.lua#L897)
- **Lines**: 897-993
- **Purpose**: Add a trait aura to the profile's traits list
- **Checks**:
  - Prevents duplicates
  - Validates aura exists in AuraRegistry
  - Checks tags for `"class:"` and `"race:"` prefixes
  - Enforces trait limits:
    - `max_traits` (overall limit)
    - `max_traits_racial` (racial trait limit)
    - `max_traits_class` (class trait limit)
    - `max_generic_traits` (generic trait limit)

**HasTrait(auraId)** - [Profile/CharacterProfile.lua](Profile/CharacterProfile.lua#L1010)
- **Lines**: 1010-1016
- **Returns**: boolean - true if trait is in profile's traits list

---

## 3. Trait Aura Application to Player Unit

### Location: [Core/AuraManager.lua](Core/AuraManager.lua)

#### AuraManager Initialization
- **File**: [Core/AuraManager.lua](Core/AuraManager.lua#L454)
- **Function**: `AuraManager.New(event)`
- **Lines**: 443-475

**Critical Code Block** (lines 454-475):
```lua
-- Apply player's traits as auras when manager is created
local Common = RPE.Common
local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
if profile and profile.GetTraits and Common and Common.LocalPlayerId then
    local traits = profile:GetTraits()
    if traits and #traits > 0 then
        local playerId = Common:LocalPlayerId()
        if playerId then
            for _, traitId in ipairs(traits) do
                local ok, inst = manager:Apply(playerId, playerId, traitId)
                if ok then
                    RPE.Debug:Internal(("[AuraManager.New] Applied trait '%s' to player"):format(tostring(traitId)))
                else
                    RPE.Debug:Warning(("[AuraManager.New] Failed to apply trait '%s': %s"):format(tostring(traitId), tostring(inst)))
                end
            end
        end
    end
end
```

**Mechanism**:
1. When AuraManager is created (typically per Event)
2. Retrieves active character profile via `RPE.Profile.DB.GetOrCreateActive()`
3. Gets all traits from profile via `profile:GetTraits()`
4. Iterates through trait aura IDs
5. Calls `manager:Apply(playerId, playerId, traitId)` to apply each trait to the player
6. Logs success or failure for each trait application

---

## 4. Core Aura Application Function

### Location: [Core/AuraManager.lua](Core/AuraManager.lua#L774)

**Function**: `AuraManager:Apply(source, target, auraId, opts)`
- **Lines**: 774-950+
- **Parameters**:
  - `source`: Caster unit ID
  - `target`: Target unit ID
  - `auraId`: Aura definition ID (e.g., "aura-oCADkPre02")
  - `opts`: Options table with stacking policy, uniqueness, etc.

**Application Flow**:
1. Validates aura exists in AuraRegistry
2. Checks aura requirements via SpellRequirements:EvalRequirements()
3. Gets all existing auras on target via `forUnit(self, tId, true)`
4. Applies immunity gates (existing auras may block new one)
5. Checks for uniqueGroup conflicts
6. Handles stacking policies:
   - `ADD_MAGNITUDE`: Add stacks
   - `REFRESH_DURATION`: Refresh existing duration
   - `EXTEND_DURATION`: Extend duration
   - `REPLACE`: Remove existing, apply new
7. Creates new Aura instance via `Aura.New(def, sId, tId, now, opts)`
8. Inserts into auras list
9. Calls `_onApplied(newAura)` to process effects
10. Returns success/failure with Aura instance or error code

---

## 5. Aura Application Through Spells

### Location: [Core/SpellActions.lua](Core/SpellActions.lua#L797)

**Action**: `APPLY_AURA`
- **Lines**: 797-862
- **Registration**: `Actions:Register("APPLY_AURA", function(ctx, cast, targets, args) ... end)`

**Purpose**: Spell action that applies auras as spell effects

**Key Parameters**:
- `args.auraId` or `args.id`: The aura ID to apply
- `args.stacks`: Number of stacks (default 1)
- `args.snapshot`: Snapshot data (amount, school, profile stats)
- `args.stackingPolicy`: How to handle existing auras
- `args.uniqueByCaster`: If true, per-caster instance

**Process**:
1. Validates `auraId` is provided
2. Gets AuraManager from event
3. For each target:
   - Builds snapshot of aura effects (amount, caster stats)
   - Calls `mgr:Apply(caster, target, auraId, options)`
   - Logs errors if apply fails

---

## 6. Aura Data Definition Structure

### Location: [Core/Aura.lua](Core/Aura.lua)

**Aura Class Field**: `isTrait`
- **Line**: 28
- **Type**: `boolean|nil`
- **Description**: Whether this aura is a permanent trait
- **Used in**: Aura:ToTable() serialization (line 147)

---

## 7. Tag-Based Aura System

### How Class/Race Tags Work

1. **Aura Definition** (Data/Classic/Auras.lua):
   - Auras can have tags like `"class:deathknight"`, `"race:human"`, etc.
   - Tags stored in `tags` table of aura definition
   - Example: Unholy Presence at [Data/Classic/Auras.lua](Data/Classic/Auras.lua#L5752)

2. **Profile Validation** (Profile/CharacterProfile.lua):
   - `AddTrait()` checks aura tags for `"class:"` prefix
   - Only adds trait if it matches character's class
   - Example: [Profile/CharacterProfile.lua](Profile/CharacterProfile.lua#L910-L943)

3. **Tag Indexing**:
   - Tags used for immunity checking in [Core/AuraManager.lua](Core/AuraManager.lua#L59-L67)
   - Immunity can block auras with specific tags

---

## Summary: Where Trait Auras Get Applied

| Stage | File | Lines | Mechanism |
|-------|------|-------|-----------|
| **Definition** | Data/Classic/Auras.lua | Varies | `isTrait = true` flag marks auras as traits |
| **Profile Storage** | Profile/CharacterProfile.lua | 124, 897-1025 | Traits stored as list of aura IDs; GetTraits() retrieves them |
| **Initialization** | Core/AuraManager.lua | 454-475 | AuraManager.New() applies all traits from profile to player on creation |
| **Core Application** | Core/AuraManager.lua | 774-950+ | Apply() function validates, checks immunities, creates Aura instances |
| **Spell-Based** | Core/SpellActions.lua | 797-862 | APPLY_AURA action applies auras as spell effects |
| **Class Validation** | Profile/CharacterProfile.lua | 910-943 | Tags check ensures class:deathknight auras only apply to DK classes |

---

## Unholy Presence Specific Path

**Unholy Presence (aura-oCADkPre02)** Application Flow:

1. **Definition**: [Data/Classic/Auras.lua](Data/Classic/Auras.lua#L5740)
   - `isTrait = true`
   - `tags = { "class:deathknight" }`

2. **Added to Profile**: 
   - Via UI or code: `profile:AddTrait("aura-oCADkPre02")`
   - Validates tag matches Death Knight class
   - Stored in profile.traits list

3. **Applied on Manager Creation**:
   - When AuraManager is created via `AuraManager.New(event)`
   - Retrieves profile's trait list including "aura-oCADkPre02"
   - Calls `manager:Apply(playerId, playerId, "aura-oCADkPre02")`
   - Aura is created and attached to player unit
   - ON_CRIT trigger and tick healing actions become active

4. **Runtime Effects**:
   - Every turn: Heals summoned minions for 30 health
   - On crit: Reduces cooldown of DK unholy spells by 1
