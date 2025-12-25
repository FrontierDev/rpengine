-- RPE/Core/Targeters.lua
-- Declarative target selection strategies.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Targeters
---@field _tgts table<string, fun(ctx:table, cast:table, args:table): table> -- returns { name=string, targets=table }
local Targeters = { _tgts = {} }
Targeters.__index = Targeters
RPE.Core.Targeters = Targeters

function Targeters:Register(key, fn)
    assert(type(key)=="string" and type(fn)=="function", "Register needs key,function")
    self._tgts[key] = fn
end

function Targeters:Select(key, ctx, cast, args)
    local fn = self._tgts[key]
    if not fn then
        if RPE.Debug and RPE.Debug.Warn then RPE.Debug:Warning("Unknown targeter: "..tostring(key)) end
        return { name = key, targets = {} }
    end
    local ok, sel = pcall(fn, ctx or {}, cast, args or {})
    if not ok then
        if RPE.Debug and RPE.Debug.Error then RPE.Debug:Error("Targeter "..key.." failed: "..tostring(sel)) end
        return { name = key, targets = {} }
    end
    return sel or { name = key, targets = {} }
end

-- ===== Minimal built-ins =====

-- The caster themselves.
Targeters:Register("CASTER", function(ctx, cast, args)
    if not cast.caster then
        if RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("[Targeters:CASTER] No valid caster found for spell: " .. tostring(cast.def and cast.def.id))
        end
        return { name = "caster", targets = {} }
    end

    return { name = "caster", targets = { cast.caster } }
end)

-- Whatever was chosen in precast.
Targeters:Register("PRECAST", function(ctx, cast, args)
    local out = {}
    for i, t in ipairs(cast.targetSets and cast.targetSets.precast or {}) do out[i] = t end
    return { name = "precast", targets = out }
end)

-- The target(s) of the aura itself (for aura tick actions)
Targeters:Register("TARGET", function(ctx, cast, args)
    local targets = {}
    if cast.targets and #cast.targets > 0 then
        for _, t in ipairs(cast.targets) do
            table.insert(targets, t)
        end
    end
    return { name = "target", targets = targets }
end)

-- All allies (including self)
Targeters:Register("ALL_ALLIES", function(ctx, cast, args)
    local Common = RPE.Common
    if not Common or not Common.Event then
        return { name = "all_allies", targets = {} }
    end
    
    local event = Common:Event()
    if not (event and event.units) then
        return { name = "all_allies", targets = {} }
    end
    
    local casterTeam = cast.casterTeam
    if not casterTeam then
        -- Try to find caster's team from event
        local casterUnit = Common:FindUnitById(cast.caster)
        if casterUnit then
            casterTeam = casterUnit.team
        end
    end
    
    local targets = {}
    for key, unit in pairs(event.units) do
        if unit.team == casterTeam then
            if unit.isNPC then
                table.insert(targets, unit.id)
            else
                table.insert(targets, key)
            end
        end
    end

    -- Apply maxTargets filtering if specified and > 0
    local maxTargets = args and args.maxTargets or 0
    if maxTargets > 0 and #targets > maxTargets then
        -- Fisher-Yates shuffle
        for i = #targets, 2, -1 do
            local j = math.random(1, i)
            targets[i], targets[j] = targets[j], targets[i]
        end
        -- Keep only first maxTargets
        for i = #targets, maxTargets + 1, -1 do
            table.remove(targets, i)
        end
    end

    return { name = "all_allies", targets = targets }
end)

-- All enemies
Targeters:Register("ALL_ENEMIES", function(ctx, cast, args)
    local Common = RPE.Common
    if not Common or not Common.Event then
        return { name = "all_enemies", targets = {} }
    end
    
    local event = Common:Event()
    if not (event and event.units) then
        return { name = "all_enemies", targets = {} }
    end
    
    local casterTeam = cast.casterTeam
    if not casterTeam then
        -- Try to find caster's team from event
        local casterUnit = Common:FindUnitById(cast.caster)
        if casterUnit then
            casterTeam = casterUnit.team
        end
    end
    
    local targets = {}
    for _, unit in pairs(event.units) do
        if unit.team and unit.team ~= casterTeam then
            table.insert(targets, unit.id)
        end
    end
    
    -- Apply maxTargets filtering if specified and > 0
    local maxTargets = args and args.maxTargets or 0
    if maxTargets > 0 and #targets > maxTargets then
        -- Fisher-Yates shuffle
        for i = #targets, 2, -1 do
            local j = math.random(1, i)
            targets[i], targets[j] = targets[j], targets[i]
        end
        -- Keep only first maxTargets
        for i = #targets, maxTargets + 1, -1 do
            table.remove(targets, i)
        end
    end
    
    return { name = "all_enemies", targets = targets }
end)

-- All units
Targeters:Register("ALL_UNITS", function(ctx, cast, args)
    local Common = RPE.Common
    if not Common or not Common.Event then
        return { name = "all_units", targets = {} }
    end
    
    local event = Common:Event()
    if not (event and event.units) then
        return { name = "all_units", targets = {} }
    end
    
    local targets = {}
    for _, unit in pairs(event.units) do
        table.insert(targets, unit.id)
    end
    
    return { name = "all_units", targets = targets }
end)

-- Units summoned by the caster (or caster's master if caster is summoned)
Targeters:Register("SUMMONED", function(ctx, cast, args)
    local Common = RPE.Common
    if not Common or not Common.Event then
        return { name = "summoned", targets = {} }
    end
    
    local event = Common:Event()
    if not (event and event.units) then
        return { name = "summoned", targets = {} }
    end
    
    local casterId = cast.caster
    if not casterId then
        return { name = "summoned", targets = {} }
    end
    
    -- Resolve caster to a unit object to get numeric ID
    local casterUnit = Common:FindUnitById(casterId)
    if not casterUnit then
        return { name = "summoned", targets = {} }
    end
    
    local casterNumericId = tonumber(casterUnit.id)
    local ownerToCheck = casterNumericId
    
    -- If the caster itself is summoned, look for units summoned by caster's master instead
    if casterUnit.summonedBy then
        ownerToCheck = tonumber(casterUnit.summonedBy)
    end
    
    local targets = {}
    for _, unit in pairs(event.units) do
        -- Only include units that are:
        -- 1. Not the caster themselves
        -- 2. Summoned by the ownerToCheck
        if tonumber(unit.id) ~= casterNumericId and unit.summonedBy and tonumber(unit.summonedBy) == ownerToCheck then
            table.insert(targets, unit.id)
        end
    end
    
    return { name = "summoned", targets = targets }
end)

return Targeters
