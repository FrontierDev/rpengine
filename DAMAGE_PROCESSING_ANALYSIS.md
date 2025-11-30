# DAMAGE Action Processing Analysis

## Executive Summary
Found the root cause of why damage formulas work for NPC targets but not for player reactions. The issue is in `SpellCast.lua` where player target attack previews are calculated - **formulas are NOT being evaluated**, only flat numeric values are used.

---

## 1. Where DAMAGE Actions Are Processed

### File: `Core/SpellActions.lua`
**Function:** `Actions:Register("DAMAGE", ...)`  
**Lines:** 87-171

This is where DAMAGE actions are **executed locally** against NPC targets.

#### How it works:
```lua
Actions:Register("DAMAGE", function(ctx, cast, targets, args)
    -- ...
    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0  -- ✅ FORMULA EVALUATED
        else
            base = tonumber(args.amount) or 0
        end
        
        local rank = 1
        if cast and cast.def and cast.def.rank then
            rank = tonumber(cast.def.rank) or 1
        elseif args and args.rank then
            rank = tonumber(args.rank) or 1
        end
        
        local perExpr = args.perRank
        if rank > 1 and perExpr and perExpr ~= "" then
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0  -- ✅ FORMULA EVALUATED
            base = base + (perAmount * (rank - 1))
        end
        
        return math.max(0, math.floor(base))
    end
    -- ...
    Broadcast:Damage(cast and cast.caster, entries)
end)
```

**Key Point:** The formula is evaluated using `Formula:Roll(args.amount, profile)` before broadcasting.

---

## 2. Amount Field Handling

### Type Checking
The code checks if `args.amount` is:
- **String:** Treated as formula, evaluated via `Formula:Roll()`
- **Number:** Used directly as flat damage value

### Formula Evaluation
**Class:** `RPE.Core.Formula`  
**Method:** `Formula:Roll(expression, profile)`

The formula module handles:
- Dice notation (e.g., "2d6")
- Random functions (e.g., "rand(10)")
- Stat references (e.g., "$stat.STRENGTH$")
- Math operations

---

## 3. Difference: NPC vs Player Targets

### For NPC Targets (WORKS ✅)
**Process:**
1. NPC is detected as `isNPC = true` in `SpellCast.lua:784`
2. Hit check performed via `_checkHitVsNPC()`
3. **DAMAGE action executed immediately via `SpellActions:Run("DAMAGE", ...)`**
4. Inside `SpellActions:DAMAGE`, formula evaluated with `Formula:Roll()`
5. Broadcast sent with already-calculated numeric damage

**Code location:** `Core/SpellCast.lua:156-188`

```lua
if act.key == "DAMAGE" or (act.key == "APPLY_AURA" and act.requiresHit) then
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    
    for _, tgt in ipairs(targets) do
        local tgtUnit = RPE.Common:FindUnitByKey(tgt)
        if tgtUnit and tgtUnit.isNPC then
            local hitResult, roll, lhs, rhs = _checkHitVsNPC(...)
            if hitResult then
                -- ✅ ACTION EXECUTED FOR NPCs
                SpellActions:Run(act.key, ev, cast, { tgt }, act.args or {})
            end
        end
    end
end
```

### For Player Targets (BROKEN ❌)
**Process:**
1. Player is detected as `isNPC = false` in `SpellCast.lua:791`
2. Hit check NOT performed locally
3. Attack broadcast to player for them to defend
4. **Damage preview calculated BEFORE broadcasting** without formula evaluation
5. Player receives preview with incorrect damage values
6. When player is hit, damage is applied from the preview (already wrong)

**Code location:** `Core/SpellCast.lua:860-875`

```lua
-- ❌ PROBLEM: Damage calculated WITHOUT formula evaluation
if act.key == "DAMAGE" and act.args then
    local amt = tonumber(act.args.amount) or 0  -- No Formula:Roll() call!
    local school = (act.args.school) or "Physical"
    amt = math.max(0, math.floor(amt))
    if amt > 0 then
        damageBySchool[school] = (damageBySchool[school] or 0) + amt
    end
end
```

This directly uses `act.args.amount` which is still a **string formula** that hasn't been evaluated.

---

## 4. Broadcasting Pipeline

### For NPC Damage (Correct)
1. `SpellActions:DAMAGE` evaluates formula → numeric amount
2. Calls `Broadcast:Damage(caster, entries)` with numeric values
3. `Broadcast:Damage()` serializes to format: `sId;tId1;amount1;school1;crit1;threat1;tId2;amount2;...`
4. Comms handler receives numeric amounts

**File:** `Core/Comms/Broadcast.lua:742-782`

### For Player Attack Preview (Incorrect)
1. `SpellCast` calculates damage preview with formula strings unevaluated
2. Calls `Broadcast:AttackSpell(caster, target, spellId, spellName, hitSystem, attackRoll, thresholdStats, **damageBySchool**, auraEffects)`
3. `Broadcast:AttackSpell()` serializes `damageBySchool` to CSV format

**File:** `Core/Comms/Broadcast.lua:915-925`

```lua
-- Serialize damage by school (table of {[school] = amount})
-- Format: school1:amount1,school2:amount2,...
local damageCSV = ""
if type(damageBySchool) == "table" then
    local parts = {}
    for school, amount in pairs(damageBySchool) do
        if tonumber(amount) and tonumber(amount) > 0 then  -- ❌ tonumber(formula_string) returns nil!
            table.insert(parts, school .. ":" .. math.floor(tonumber(amount)))
        end
    end
    damageCSV = table.concat(parts, ",")
end
```

### Receiving End
`Core/Comms/Handle.lua:1150-1181` parses the CSV and treats values as already-numeric.

The `predictedDamage` sent to player reaction is based on these unparsed formula strings, resulting in `0` damage shown in the preview.

---

## 5. Root Cause Summary

| Step | NPC Targets | Player Targets |
|------|-------------|----------------|
| **Hit Check** | Performed locally | Deferred to player |
| **Formula Evaluation** | In `SpellActions:DAMAGE` | NOT EVALUATED |
| **Amount Type** | Numeric (post-evaluation) | String (formula unevaluated) |
| **Serialization** | Numeric values → CSV | Formula strings → tonumber() returns nil |
| **Result** | Correct damage | 0 damage in preview |

---

## 6. How It's Fixed

The damage formula must be evaluated **before** being sent in the `Broadcast:AttackSpell()` call.

### Required Changes
In `Core/SpellCast.lua` around line 870:

**CURRENT (Wrong):**
```lua
if act.key == "DAMAGE" and act.args then
    local amt = tonumber(act.args.amount) or 0  -- ❌ Formula not evaluated
    local school = (act.args.school) or "Physical"
    amt = math.max(0, math.floor(amt))
    if amt > 0 then
        damageBySchool[school] = (damageBySchool[school] or 0) + amt
    end
end
```

**CORRECT:**
```lua
if act.key == "DAMAGE" and act.args then
    local profile = cast and cast.profile
    local amt = 0
    
    if type(act.args.amount) == "string" then
        amt = tonumber(Formula:Roll(act.args.amount, profile)) or 0  -- ✅ EVALUATE FORMULA
    else
        amt = tonumber(act.args.amount) or 0
    end
    
    -- Apply rank bonuses (same logic as in SpellActions:DAMAGE)
    local rank = tonumber(cast.def and cast.def.rank) or 1
    local perExpr = act.args.perRank
    if rank > 1 and perExpr and perExpr ~= "" then
        local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
        amt = amt + (perAmount * (rank - 1))
    end
    
    local school = (act.args.school) or "Physical"
    amt = math.max(0, math.floor(amt))
    if amt > 0 then
        damageBySchool[school] = (damageBySchool[school] or 0) + amt
    end
end
```

### Additional Consideration
The same issue likely exists for **on-hit aura damage effects** (lines 895-930) - they should also evaluate formulas before preview.

---

## Files Summary

| File | Function | Role |
|------|----------|------|
| `Core/SpellActions.lua` | `Actions:Register("DAMAGE")` | Executes damage for NPCs (correct) |
| `Core/SpellCast.lua` | `_runActionOnHit()` | Calculates damage preview for players (broken) |
| `Core/Comms/Broadcast.lua` | `Broadcast:AttackSpell()` | Serializes and broadcasts player attacks |
| `Core/Comms/Handle.lua` | `ATTACK_SPELL` handler | Receives and displays player attack previews |
| `Core/PlayerReaction.lua` | `PlayerReaction:Start()` | Shows reaction UI with damage preview |

