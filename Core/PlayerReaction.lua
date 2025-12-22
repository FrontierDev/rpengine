-- RPE/Core/PlayerReaction.lua
-- Handles player reaction logic for defending against attacks/effects

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class PlayerReaction
local PlayerReaction = {}
PlayerReaction.__index = PlayerReaction
RPE.Core.PlayerReaction = PlayerReaction

-- ===== State =====
local currentReaction = nil  -- { hitSystem, spell, action, caster, target }
local reactionQueue = {}  -- Queue of pending reactions waiting to be displayed

-- ===== API =====

--- Calculate final damage after applying mitigation
---@param baseDamage number The incoming damage amount
---@param mitigationExpr string|number The mitigation expression (string like "$value$*0.5", number for flat reduction, or 0/nil for no mitigation)
---@param targetUnit table The target unit for stat lookups
---@return number finalDamage The damage after mitigation (minimum 0)
local function _calculateMitigatedDamage(baseDamage, mitigationExpr, targetUnit)
    if not baseDamage or baseDamage <= 0 then 
        return baseDamage 
    end
    if not mitigationExpr or mitigationExpr == 0 then 
        return baseDamage 
    end
    
    -- If mitigation is a simple number, subtract it from damage
    if type(mitigationExpr) == "number" then
        local result = math.max(0, baseDamage - mitigationExpr)
        return result
    end
    
    -- If mitigation is a string expression, evaluate it with $value$ as the damage
    if type(mitigationExpr) == "string" then
        local Formula = RPE and RPE.Core and RPE.Core.Formula
        if Formula and Formula.Roll then
            local profile = targetUnit and targetUnit._profile or (RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive())
            -- Replace $value$ with the actual damage amount (as a string for substitution)
            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(baseDamage))
            -- Use Roll() to get a single numeric result from the expression
            -- This is more appropriate for actual damage calculations than Parse() which returns ranges
            local result = Formula:Roll(exprWithValue, profile)
            if result and type(result) == "number" then
                return math.max(0, result)
            end
        end
    end
    return baseDamage
end

--- Internal: Display defense success floating text
local function _displayDefenseFloatingText(defenseStat)
    if not defenseStat then return end
    
    local text = "Defend"  -- Default fallback
    
    -- Try to get combatText from stat's mitigation table first
    local StatRegistry = RPE.Core and RPE.Core.StatRegistry
    if StatRegistry then
        local stat = StatRegistry:Get(defenseStat)
        if stat and stat.mitigation and stat.mitigation.combatText then
            text = stat.mitigation.combatText
        else
            -- Fallback to hardcoded mapping if no combatText property
            if defenseStat == "DODGE" then
                text = "Dodge"
            elseif defenseStat == "BLOCK" then
                text = "Block"
            elseif defenseStat == "DEFENCE" then
                text = "Defend"
            elseif defenseStat == "PARRY" then
                text = "Parry"
            elseif defenseStat == "AC" then
                text = "Defend"
            end
        end
    else
        -- Fallback if stat registry not available
        if defenseStat == "DODGE" then
            text = "Dodge"
        elseif defenseStat == "BLOCK" then
            text = "Block"
        elseif defenseStat == "DEFENCE" then
            text = "Defend"
        elseif defenseStat == "PARRY" then
            text = "Parry"
        elseif defenseStat == "AC" then
            text = "Defend"
        end
    end
    
    local fct = RPE.Core and RPE.Core.CombatText and RPE.Core.CombatText.Screen
    if fct then
        fct:AddText(text, {
            color = { 1.0, 1.0, 1.0, 1.0 },  -- white
            duration = 1.5,
            distance = 60,
            direction = "DOWN"  -- floating downwards
        })
    end
end

--- Internal: Show the next queued reaction or hide if none pending
local function _showNextReaction()
    if #reactionQueue > 0 then
        currentReaction = table.remove(reactionQueue, 1)
        if RPE and RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(('[PlayerReaction] Showing next queued reaction, %d remaining'):format(#reactionQueue))
        end
        -- Show the reaction widget
        local Widget = RPE_UI and RPE_UI.Widgets and RPE_UI.Widgets.PlayerReactionWidget
        if Widget and Widget.Open then
            Widget:Open(currentReaction)
        end
    else
        -- No more reactions, hide widget
        local Widget = RPE_UI and RPE_UI.Widgets and RPE_UI.Widgets.PlayerReactionWidget
        if Widget and Widget.Close then
            Widget:Close()
        end
        currentReaction = nil
    end
end

-- ===== Public API =====

--- Start a new reaction dialog (e.g., player defending against an attack)
---@param hitSystem string "complex"|"simple"|"ac"
---@param spell table The spell being cast
---@param action table The action containing hit parameters
---@param caster integer Unit ID of the attacker
---@param target integer Unit ID of the defender (usually player)
---@param onComplete function Callback: function(hitResult, roll, lhs, rhs)
---@param attackDetails table Optional: { attackRoll, predictedDamage, damageSchool, spellName, isCritical }
function PlayerReaction:Start(hitSystem, spell, action, caster, target, onComplete, attackDetails)
    if not hitSystem or not spell or not action then
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("PlayerReaction:Start called with missing parameters")
        end
        return
    end

    -- Validate that required stats exist in the active dataset
    local Stats = RPE and RPE.Stats
    if hitSystem == "simple" and Stats and Stats.Get then
        -- Simple system requires DEFENCE stat
        if not Stats:Get("DEFENCE") then
            if RPE and RPE.Debug and RPE.Debug.Warning then
                RPE.Debug:Warning("PlayerReaction:Start - DEFENCE stat not found in active dataset")
            end
            return
        end
    elseif hitSystem == "complex" and Stats and Stats.Get then
        -- Complex system requires at least ONE valid threshold stat
        local thresholdStats = attackDetails and attackDetails.thresholdStats or {}
        local hasValidStat = false
        for _, statId in ipairs(thresholdStats) do
            if Stats:Get(statId) then
                hasValidStat = true
                break
            end
        end
        if not hasValidStat then
            if RPE and RPE.Debug and RPE.Debug.Warning then
                RPE.Debug:Warning("PlayerReaction:Start - No valid threshold stats found in active dataset")
            end
            return
        end
    elseif hitSystem == "ac" and Stats and Stats.Get then
        -- AC system requires AC stat
        if not Stats:Get("AC") then
            if RPE and RPE.Debug and RPE.Debug.Warning then
                RPE.Debug:Warning("PlayerReaction:Start - AC stat not found in active dataset")
            end
            return
        end
    end

    -- Get the target unit for damage calculations
    local targetUnit = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent.units and RPE.Core.ActiveEvent.units[target]
    
    -- Calculate final damage based on mitigation
    local predictedDamage = attackDetails and attackDetails.predictedDamage or 0
    local isCritical = attackDetails and attackDetails.isCritical or false
    local finalDamage = predictedDamage
    local thresholdStats = attackDetails and attackDetails.thresholdStats or {}
    
    -- Calculate total absorption from shields (reduces damage taken)
    local totalAbsorption = 0
    if targetUnit and targetUnit.absorption then
        for shieldId, shield in pairs(targetUnit.absorption) do
            if shield.amount then
                totalAbsorption = totalAbsorption + shield.amount
            end
        end
    end
    
    if RPE and RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[PlayerReaction.Start] predictedDamage=%d, isCritical=%s, absorption=%d"):format(
            predictedDamage, tostring(isCritical), totalAbsorption))
    end
    
    -- NOTE: finalDamage will be calculated in the defense handler based on which specific defense is chosen.
    -- We do NOT calculate it here to avoid incorrectly applying the first threshold stat's mitigation
    -- when the player might choose a different defense stat.

    -- Check if all available defence stats are failing due to crowd control
    local failingDefenceStats = attackDetails and attackDetails.failingDefenceStats or {}
    local allDefencesFailing = #failingDefenceStats > 0 and #failingDefenceStats == #thresholdStats
    
    -- If all defences are failing (crowd control), auto-fail the defence immediately
    if allDefencesFailing then
        -- Immediately call the completion callback with failure (hitResult = false means defence failed)
        if onComplete then
            onComplete(false, 0, 0, predictedDamage)  -- Roll is 0, lhs is 0, rhs is full predicted damage
        end
        return
    end

    local reaction = {
        hitSystem = hitSystem,
        spell = spell,
        action = action,
        caster = caster,
        target = target,
        onComplete = onComplete,
        -- Attack details for display
        attackRoll = attackDetails and attackDetails.attackRoll or nil,
        predictedDamage = predictedDamage,
        finalDamage = finalDamage,
        damageSchool = attackDetails and attackDetails.damageSchool or nil,
        damageBySchool = attackDetails and attackDetails.damageBySchool or nil,
        spellName = attackDetails and attackDetails.spellName or (spell and spell.name) or "Unknown Spell",
        turn = attackDetails and attackDetails.turn or nil,
        thresholdStats = attackDetails and attackDetails.thresholdStats or {},  -- Threshold stats for complex defense
        isCritical = isCritical,
        totalAbsorption = totalAbsorption,  -- Total shield absorption that will reduce damage
        failingDefenceStats = failingDefenceStats,  -- Track which defence stats are failing due to CC
    }

    -- Queue the reaction
    table.insert(reactionQueue, reaction)
    
    -- If no reaction is currently displayed, show the first one
    if not currentReaction then
        _showNextReaction()
    end
end

--- Get the current reaction state
function PlayerReaction:GetCurrent()
    return currentReaction
end

--- Get the pending reaction queue
function PlayerReaction:GetQueue()
    return reactionQueue
end

--- Complete the reaction and clean up
function PlayerReaction:Complete(hitResult, roll, lhs, rhs)
    if not currentReaction then return end

    -- Store the defense stat before clearing currentReaction
    local defenseStat = currentReaction.chosenDefenseStat
    
    local onComplete = currentReaction.onComplete
    currentReaction = nil

    if onComplete then
        onComplete(hitResult, roll, lhs, rhs)
    end
    
    -- Display defense success floating text only if defense succeeded (hitResult == true)
    if hitResult and defenseStat then
        _displayDefenseFloatingText(defenseStat)
    end

    -- Re-sync the event widget to show the correct current tick (in case multiple ticks per turn)
    local ev = RPE.Core.ActiveEvent
    local widget = RPE.Core.Windows and RPE.Core.Windows.EventWidget
    if ev and widget and widget.ShowTick then
        local tickUnits = ev.ticks[ev.tickIndex]
        if tickUnits then
            widget:ShowTick(ev.turn, ev.tickIndex, #ev.ticks, tickUnits)
        end
    end

    RPE.Core._isDefendingThisTurn = false

    -- Show next queued reaction or hide widget
    _showNextReaction()
end

--- Cancel the current reaction
function PlayerReaction:Cancel()
    if not currentReaction then return end

    if RPE and RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal("[PlayerReaction] Reaction cancelled")
    end

    currentReaction = nil

    -- Show next queued reaction or hide widget
    _showNextReaction()
end

return PlayerReaction
