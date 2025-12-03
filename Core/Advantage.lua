-- RPE/Core/Advantage.lua
-- Tracks advantage/disadvantage levels for player stats.
-- Lifecycle is managed by the aura system; advantages are removed when auras expire.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Advantage
local Advantage = {}
Advantage.__index = Advantage
RPE.Core.Advantage = Advantage

-- ===== State =====
local advantages = {}  -- { [statId] = { level = number, sources = { [auraId] = true } }, ... }

-- ===== API =====

--- Set advantage level for a stat from a specific aura source
---@param statId string The stat ID (e.g., "BLOCK")
---@param level number The advantage level (+1 to +10 for advantage, -1 to -10 for disadvantage)
---@param auraId string The aura ID granting this advantage (for source tracking)
function Advantage:Set(statId, level, auraId)
    if not statId or statId == "" then return end
    
    statId = statId:upper()
    level = tonumber(level) or 0
    auraId = tostring(auraId or "unknown")
    
    -- Get or create advantage entry for this stat
    local adv = advantages[statId]
    if not adv then
        adv = { level = 0, sources = {} }
        advantages[statId] = adv
    end
    
    if level == 0 then
        -- Removing this source
        adv.sources[auraId] = nil
        if next(adv.sources) == nil then
            -- No more sources, remove the advantage entirely
            advantages[statId] = nil
        end
    else
        -- Adding/updating this source with the new level
        adv.sources[auraId] = true
        adv.level = level  -- Use the level from this source (last one wins if multiple)
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print(("[Advantage] Set %s to level %d (source: %s)"):format(statId, level, auraId))
        end
    end
end

--- Get the current advantage level for a stat
---@param statId string The stat ID
---@return number level The advantage level (0 if not set)
function Advantage:Get(statId)
    if not statId or statId == "" then return 0 end
    
    local adv = advantages[statId:upper()]
    return (adv and adv.level) or 0
end

--- Check if a stat has any advantage
---@param statId string The stat ID
---@return boolean hasAdvantage True if level > 0
function Advantage:HasAdvantage(statId)
    return self:Get(statId) > 0
end

--- Check if a stat has any disadvantage
---@param statId string The stat ID
---@return boolean hasDisadvantage True if level < 0
function Advantage:HasDisadvantage(statId)
    return self:Get(statId) < 0
end

--- Remove advantage from a specific source (aura)
---@param statId string The stat ID
---@param auraId string The aura ID that granted this advantage
function Advantage:Remove(statId, auraId)
    if not statId or statId == "" then return end
    
    statId = statId:upper()
    auraId = tostring(auraId or "unknown")
    
    local adv = advantages[statId]
    if not adv then return end
    
    -- Remove this source
    adv.sources[auraId] = nil
    
    -- If no more sources, remove the advantage entirely
    if next(adv.sources) == nil then
        advantages[statId] = nil
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print(("[Advantage] Removed advantage from %s (no remaining sources)"):format(statId))
        end
    else
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print(("[Advantage] Removed source %s from %s (level still %d from other sources)"):format(
                auraId, statId, adv.level))
        end
    end
end

--- Clear all advantages
function Advantage:Clear()
    if RPE and RPE.Debug and RPE.Debug.Print then
        local count = 0
        for _ in pairs(advantages) do count = count + 1 end
        if count > 0 then
            RPE.Debug:Print(("[Advantage] Cleared all %d advantages"):format(count))
        end
    end
    table.wipe(advantages)
end

--- Get all current advantages
---@return table List of {statId, level, sources}
function Advantage:GetAll()
    local result = {}
    for statId, adv in pairs(advantages) do
        local sourceList = {}
        for auraId in pairs(adv.sources) do
            table.insert(sourceList, auraId)
        end
        table.insert(result, {
            statId = statId,
            level = adv.level,
            sources = sourceList,
        })
    end
    return result
end

--- Roll a formula with advantage/disadvantage applied
---@param formula string The formula string (e.g., "1d4+5")
---@param profile table The player profile for stat resolution
---@param statId string The stat ID to look up advantage level
---@return number result The rolled value with advantage/disadvantage applied
function Advantage:Roll(formula, profile, statId)
    local Formula = RPE and RPE.Core and RPE.Core.Formula
    if not (Formula and Formula.Roll) then
        -- Fallback: just roll once without advantage
        return 0
    end
    
    statId = statId and statId:upper() or nil
    local advLevel = statId and self:Get(statId) or 0
    local numRolls = 1 + math.abs(advLevel)
    
    -- Roll multiple times
    local rolls = {}
    for i = 1, numRolls do
        local val = tonumber(Formula:Roll(formula, profile)) or 0
        table.insert(rolls, val)
    end
    
    -- Select based on advantage/disadvantage
    local selectedRoll
    if advLevel > 0 then
        -- Advantage: take highest
        table.sort(rolls, function(a, b) return a > b end)
        selectedRoll = rolls[1]
    elseif advLevel < 0 then
        -- Disadvantage: take lowest
        table.sort(rolls)
        selectedRoll = rolls[1]
    else
        -- No advantage/disadvantage: just return the single roll
        selectedRoll = rolls[1]
    end
    
    return selectedRoll
end

return Advantage
