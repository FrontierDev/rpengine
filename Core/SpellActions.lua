-- RPE/Core/SpellActions.lua
-- Registry for atomic spell actions (runtime execution).
-- Parsing/rolling of amounts is delegated to RPE.Core.Formula.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Formula  = assert(RPE.Core.Formula, "Formula required")
local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
local Actions  = { _acts = {} }

Actions.__index = Actions
RPE.Core.SpellActions = Actions

-- Local helpers
local GetMyUnitId = function()
    local ev = RPE.Core.ActiveEvent
    return ev and ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId() or nil
end

-- Resolve unit id or object from number | table{id} | string (numeric id or key)
local function coerceUnitId(x)
    if type(x) == "number" then return x end
    if type(x) == "table" and tonumber(x.id) then return tonumber(x.id) end
    if type(x) == "string" then
        local n = tonumber(x)
        if n then return n end
        local ev = RPE.Core.ActiveEvent
        if ev and ev.units then
            local u = ev.units[x:lower()]
            if u and tonumber(u.id) then return tonumber(u.id) end
        end
    end
    return 0
end

local function findUnitById(id)
    id = tonumber(id) or 0
    if id <= 0 then return nil end
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return nil end
    for _, u in pairs(ev.units) do
        if tonumber(u.id) == id then return u end
    end
    return nil
end

-- ===== Registry ==============================================================

--- Register an action handler.
---@param key string
---@param fn fun(ctx:table, cast:table, targets:table, args:table)
function Actions:Register(key, fn)
    assert(type(key) == "string" and key ~= "", "SpellActions:Register: key must be string")
    assert(type(fn)  == "function", "SpellActions:Register: fn must be function")
    self._acts[key] = fn
end

--- Run an action handler.
---@param key string
---@param ctx table|nil
---@param cast table|nil
---@param targets table|nil
---@param args table|nil
function Actions:Run(key, ctx, cast, targets, args)
    local fn = self._acts[key]
    if not fn then
        if RPE.Debug and RPE.Debug.Warn then
            RPE.Debug:Warn("Unknown action: " .. tostring(key))
        end
        return
    end
    return fn(ctx or {}, cast or {}, targets or {}, args or {})
end

-- ===== Default Actions =======================================================

-- DAMAGE: roll amount and apply to all targets.
Actions:Register("DAMAGE", function(ctx, cast, targets, args)
    local ev = ctx and ctx.event
    if not (ev and targets and #targets > 0) then return end

    local profile = cast and cast.profile
    local school  = tostring(args.school or "Physical")

    if not cast or not cast.def then
        RPE.Debug:Internal("[SpellActions:DAMAGE] Running without a spell definition (likely aura tick).")
    end

    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0
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
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
            base = base + (perAmount * (rank - 1))
        end

        return math.max(0, math.floor(base))
    end

    -- Per-target build (no local apply)
    local entries = {}
    for _, tgt in ipairs(targets) do
        local amt = rollAmount()
        if amt > 0 then
            local isCrit = false
            if args.critChance then
                local mult = math.max(1, tonumber(args.critMult or 2))
                if math.random() < tonumber(args.critChance) then
                    isCrit = true
                    amt = math.floor(amt * mult)
                end
            end

            entries[#entries+1] = {
                target = coerceUnitId(tgt),
                amount = amt,
                school = school,
                crit   = isCrit,
                threat = args.threat,
            }
        end
    end

    if Broadcast and Broadcast.Damage and #entries > 0 then
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("DAMAGE entries to send: %d"):format(#entries))
            for i, e in ipairs(entries) do
                -- Debug print
                RPE.Debug:Internal(("  [%d] target=%s amount=%d crit=%s threat=%s"):
                    format(i, tostring(e.target), e.amount, tostring(e.crit), tostring(e.threat)))

                -- Optional floating combat text
                if RPE.Core.CombatText and RPE.Core.CombatText.Screen then
                    RPE.Core.CombatText.Screen:AddText(e.amount, {
                        variant = "damageDealt",
                        isCrit = e.crit,
                        direction = "UP"
                    })
                end

                -- Correct event emission
                RPE.Core.AuraTriggers:Emit("ON_HIT", {}, cast.caster, e.target, {
                    spell  = cast.def,
                    amount = e.amount,
                    isCrit = e.crit,
                    school = e.school,
                })
            end
        end
        
        Broadcast:Damage(cast and cast.caster, entries)
    end
end)



-- HEAL: roll amount and heal all targets.
Actions:Register("HEAL", function(ctx, cast, targets, args)
    local ev      = ctx and ctx.event
    if not (ev and targets and #targets > 0) then return end

    local profile = cast and cast.profile

    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0
        else
            base = tonumber(args.amount) or 0
        end

        local rank = tonumber(cast and cast.rank) or 1
        local perExpr = args.perRank
        if rank > 1 and perExpr and perExpr ~= "" then
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
            base = base + (perAmount * (rank - 1))
        end

        return math.max(0, math.floor(base))
    end

    -- Per-target build
    local entries = {}
    for _, tgt in ipairs(targets) do
        local amt = rollAmount()
        if amt > 0 then
            local isCrit = false
            if args.critChance then
                local mult = math.max(1, tonumber(args.critMult or 2))
                if math.random() < tonumber(args.critChance) then
                    isCrit = true
                    amt = math.floor(amt * mult)
                end
            end

            entries[#entries+1] = {
                target = coerceUnitId(tgt),   -- coerced by Broadcast:Heal
                amount = amt,
                crit   = isCrit,
            }
        end
    end

    if Broadcast and Broadcast.Heal and #entries > 0 then
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("HEAL entries to send: %d"):format(#entries))
            for i,e in ipairs(entries) do
                RPE.Debug:Internal(("  [%d] target=%s amount=%d crit=%s"):format(i, tostring(e.target), e.amount, tostring(e.crit)))
                RPE.Core.CombatText.Screen:AddText("+"..e.amount, { variant = "heal", isCrit = e.crit })
            end
        end
        Broadcast:Heal(cast and cast.caster, entries)
    end
end)


-- Add near APPLY_AURA:
local function _hasRandom(expr)
    return type(expr) == "string"
        and (expr:find("%d+%s*[dD]%s*%d+") or expr:find("rand%(") or expr:find("%$rand"))
end

-- Replace APPLY_AURA with:
Actions:Register("APPLY_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then
        RPE.Debug:Error("APPLY_AURA: missing auraId")
        return
    end

    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then
        RPE.Debug:Error("APPLY_AURA: no AuraManager attached to event")
        return
    end

    local profile = cast and cast.profile

    for _, tgt in ipairs(targets or {}) do
        -- Build per-instance snapshot
        local snap = {}
        if type(args.snapshot) == "table" then
            for k, v in pairs(args.snapshot) do snap[k] = v end
        end
        if args.amount ~= nil then
            if _hasRandom(args.amount) then
                -- keep string so it re-rolls each tick
                snap.amount = args.amount
            else
                -- snapshot flat/stat-only formulas once
                snap.amount = Formula:Roll(args.amount, profile)
            end
        end
        if args.school ~= nil then snap.school = args.school end
        -- keep caster profile for $stat.*$ resolution on ticks
        if profile ~= nil then snap.profile = profile end

        local ok, res = mgr:Apply(
            cast and cast.caster or ctx.caster,
            tgt,
            auraId,
            {
                stacks          = tonumber(args.stacks) or 1,
                charges         = args.charges,
                rngSeed         = args.rngSeed,
                snapshot        = snap,               -- 👈 includes amount (string or number)
                stackingPolicy  = args.stackingPolicy,
                uniqueByCaster  = args.uniqueByCaster,
            }
        )

        if not ok then
            RPE.Debug:Error(("APPLY_AURA failed: aura=%s tgt=%s reason=%s"):
                format(auraId, tostring(tgt), tostring(res)))
        end
    end
end)



-- REMOVE_AURA: remove a specific aura.
Actions:Register("REMOVE_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then return end

    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        mgr:Remove(tgt, auraId, cast and cast.caster)
    end
end)

-- EXTEND_AURA: extend duration by N turns.
Actions:Register("EXTEND_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then return end

    local turns = tonumber(args.turns or args.amount) or 1
    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        local _, inst = mgr:Has(tgt, auraId, cast and cast.caster)
        if inst then
            inst:ExtendDuration(turns)
            mgr:_onRefreshed(inst, true)
        end
    end
end)

-- DISPEL: remove N harmful/helpful auras of certain types.
Actions:Register("DISPEL", function(ctx, cast, targets, args)
    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        mgr:Dispel(tgt, {
            types   = args.types,
            max     = args.max or 1,
            helpful = args.helpful or false,
        })
    end
end)


-- REDUCE_COOLDOWN: reduce remaining cooldown on a specific spell or shared group.
-- args:
--   spellId      = "HEALING_WORD"   -- target spell id   (preferred)
--   sharedGroup  = "POTION"         -- or a cooldown group key
--   amount       = 1                -- turns to reduce (default 1)
Actions:Register("REDUCE_COOLDOWN", function(ctx, cast, targets, args)
    local CD  = RPE.Core.Cooldowns
    if not (CD and cast and cast.caster) then return end

    local turn   = (ctx.event and ctx.event.turn) or 0
    local amount = tonumber(args.amount or args.turns) or 1

    local def
    if args.sharedGroup then
        -- build a minimal def keyed to the shared group
        def = { id = "SG:" .. tostring(args.sharedGroup), cooldown = { sharedGroup = tostring(args.sharedGroup) } }
    elseif args.spellId then
        local reg = RPE.Core.SpellRegistry
        def = reg and reg:Get(args.spellId)
    end
    if not def then return end

    CD:Reduce(cast.caster, def, amount, turn)
end)

return Actions
