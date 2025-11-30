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
        if RPE.Debug and RPE.Debug.Warn then RPE.Debug:Warn("Unknown targeter: "..tostring(key)) end
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
    return { name = "caster", targets = { cast.caster } }
end)

-- Whatever was chosen in precast.
Targeters:Register("PRECAST", function(ctx, cast, args)
    local out = {}
    for i, t in ipairs(cast.targetSets and cast.targetSets.precast or {}) do out[i] = t end
    return { name = "precast", targets = out }
end)

-- Ally single if provided in PRECAST; otherwise self.
Targeters:Register("ALLY_SINGLE_OR_SELF", function(ctx, cast, args)
    local prec = cast.targetSets and cast.targetSets.precast or {}
    if #prec > 0 then return { name = "ally", targets = { prec[1] } } end
    return { name = "self", targets = { cast.caster } }
end)

return Targeters
