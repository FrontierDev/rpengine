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

--- Internal: Show the next queued reaction or hide if none pending
local function _showNextReaction()
    if #reactionQueue > 0 then
        currentReaction = table.remove(reactionQueue, 1)
        
        if RPE and RPE.Debug and RPE.Debug.Print then
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
---@param attackDetails table Optional: { attackRoll, predictedDamage, damageSchool, spellName }
function PlayerReaction:Start(hitSystem, spell, action, caster, target, onComplete, attackDetails)
    if not hitSystem or not spell or not action then
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("PlayerReaction:Start called with missing parameters")
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
        predictedDamage = attackDetails and attackDetails.predictedDamage or nil,
        damageSchool = attackDetails and attackDetails.damageSchool or nil,
        damageBySchool = attackDetails and attackDetails.damageBySchool or nil,
        spellName = attackDetails and attackDetails.spellName or (spell and spell.name) or "Unknown Spell",
        turn = attackDetails and attackDetails.turn or nil,
        thresholdStats = attackDetails and attackDetails.thresholdStats or {},  -- Threshold stats for complex defense
    }

    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[PlayerReaction] Queueing reaction: hitSystem=' .. hitSystem .. ', spell=' .. tostring(spell.id or spell.name)))
    end

    -- Queue the reaction
    table.insert(reactionQueue, reaction)
    
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[PlayerReaction] Queue size: %d'):format(#reactionQueue))
    end
    
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

    local onComplete = currentReaction.onComplete
    currentReaction = nil

    if onComplete then
        onComplete(hitResult, roll, lhs, rhs)
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

    -- Show next queued reaction or hide widget
    _showNextReaction()
end

--- Cancel the current reaction
function PlayerReaction:Cancel()
    if not currentReaction then return end

    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal("[PlayerReaction] Reaction cancelled")
    end

    currentReaction = nil

    -- Show next queued reaction or hide widget
    _showNextReaction()
end

return PlayerReaction
