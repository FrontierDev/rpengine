-- RPE/Core/SpellCast.lua
-- Runtime casting lifecycle for RPE.Core.Spell data.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local SpellRegistry = assert(RPE.Core.SpellRegistry, "SpellRegistry required")
local Requirements  = assert(RPE.Core.SpellRequirements, "SpellRequirements required")
local Actions       = assert(RPE.Core.SpellActions, "SpellActions required")
local Targeters     = assert(RPE.Core.Targeters, "Targeters required")

---@class SpellCast
---@field def table
---@field caster integer                  -- Unit ID of the caster (numeric ID from ActiveEvent)
---@field targetSets table<string, table>
---@field startedTurn integer|nil
---@field remainingTurns integer|nil
---@field nextTickTurn integer|nil
---@field lastDecrementTurn integer|nil  -- Last turn we decremented remainingTurns (to handle multiple ticks per turn)
---@field wasInterrupted boolean|nil
---@field _costSnapshot table|nil
---@field _rngSeed integer|nil
local SpellCast = {}
SpellCast.__index = SpellCast
RPE.Core.SpellCast = SpellCast



-- ========= Utilities =========

local function randseed() return math.random(1, 2^30) end

-- Serialize action args to JSON-like string for network transmission
local function serializeArgs(args)
    if not args then return "" end
    local parts = {}
    for k, v in pairs(args) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    return table.concat(parts, ",")
end

-- Resolve targets for a given action
local function resolveActionTargets(cast, ctx, action)
    -- Highest priority: directly remembered ref from InitTargeting()
    if action._resolvedRef then
        local resolved = cast.targetSets and cast.targetSets[action._resolvedRef] or {}
        RPE.Debug:Internal(string.format(
            "[SpellCast] resolveActionTargets: Using _resolvedRef='%s' → %d targets",
            action._resolvedRef, #resolved
        ))
        return resolved
    end

    -- Fallback: explicit spec (rare, for auto actions)
    local rawSpec = action.args and action.args.targets
    local spec = {}
    if type(rawSpec) == "table" then
        spec = rawSpec
    elseif type(rawSpec) == "string" then
        spec = { targeter = rawSpec }
    else
        spec = { ref = "precast" }
    end

    if spec.ref then
        local resolved = cast.targetSets and cast.targetSets[spec.ref] or {}
        RPE.Debug:Internal(string.format(
            "[SpellCast] resolveActionTargets: Using ref='%s' → %d targets",
            spec.ref, #resolved
        ))
        return resolved
    end

    if spec.targeter then
        local sel = Targeters:Select(spec.targeter, ctx, cast, spec.args)
        local targets = sel and sel.targets or {}
        RPE.Debug:Internal(string.format(
            "[SpellCast] resolveActionTargets: Using targeter='%s' → %d targets",
            spec.targeter, #targets
        ))
        return targets
    end

    RPE.Debug:Warning("[SpellCast] No valid targeting method found for action: " .. tostring(action.key))
    return {}
end

---@return boolean ok, string? reason, string? code
local function evalGroupRequirements(ctx, cast, group)
    -- Skip requirement checks for NPC units
    local casterUnit = RPE.Common:FindUnitById(cast.caster)
    if casterUnit and casterUnit.isNPC then
        return true  -- NPCs bypass all requirement checks
    end
    
    -- First check spell-level requirements (ALL must pass)
    for _, req in ipairs(cast.def.requirements or {}) do
        local ok, reason, code = Requirements:EvalRequirement(ctx, req)
        if not ok then return false, reason, code end
    end
    
    -- Then check group-level requirements
    local logic = group.logic or "ALL"
    local anyOk, allOk, noneOk = false, true, true
    local firstFailReason, firstFailCode = nil, nil

    for _, req in ipairs(group.requirements or {}) do
        -- Requirements can be strings or {key="..."} objects
        local reqStr = req
        if type(req) == "table" and req.key then
            reqStr = req.key
        end
        
        local ok, reason, code = Requirements:EvalRequirement(ctx, reqStr)
        if not ok and not firstFailReason then firstFailReason, firstFailCode = reason, code end

        if ok then anyOk = true; noneOk = false else allOk = false end
        if logic == "ALL"  and not ok then return false, reason, code end
        if logic == "ANY"  and ok     then return true end
        if logic == "NONE" and ok     then return false, "blocked by NONE requirement", "REQ_BLOCKED" end
    end

    if logic == "ALL"  then return allOk,  firstFailReason, firstFailCode end
    if logic == "ANY"  then return anyOk,  (anyOk and nil or firstFailReason), (anyOk and nil or firstFailCode) end
    if logic == "NONE" then return noneOk, (noneOk and nil or "blocked"), (noneOk and nil or "REQ_BLOCKED") end
    return false, "invalid logic", "REQ_INVALID_LOGIC"
end

local function runActions(ctx, cast, actions)
    -- Pre-compute hit checks for all targets across all actions in this group
    -- We'll cache hit results by (action, target) pair, AND cache the resolved targets
    local hitCache = {}  -- { [action] = { [targetRef] = {hit=bool, roll=num, ...} } }
    local targetCache = {}  -- { [action] = {targets} } - cache resolved targets to avoid double resolution
    
    for _, act in ipairs(actions or {}) do
        local targets = resolveActionTargets(cast, ctx, act)
        targetCache[act.key] = targets  -- Cache for later use
        
        -- Perform hit check (or use cached results from first action)
        local hitTargets, missTargets = SpellCast:CheckHit(ctx, cast, act, targets)
        
        -- Cache these results for actions that share targets
        if not hitCache[act.key] then
            hitCache[act.key] = {}
        end
        for _, tgt in ipairs(hitTargets or {}) do
            hitCache[act.key][tgt] = true
        end
        for _, tgt in ipairs(missTargets or {}) do
            hitCache[act.key][tgt] = false
        end
    end
    
    -- Now run actions, using cached hit results and cached targets
    for i, act in ipairs(actions or {}) do
        local targets = targetCache[act.key] or {}  -- Use cached targets instead of re-resolving
        
        -- Filter out player targets for DAMAGE and APPLY_AURA actions
        -- (they're handled via broadcast/reaction system)
        local applyTargets = targets
        if act.key == "DAMAGE" or (act.key == "APPLY_AURA" and act.requiresHit) then
            applyTargets = {}
            
            for _, tgt in ipairs(targets) do
                local tgtUnit = RPE.Common:FindUnitByKey(tgt)
                local isNPC = tgtUnit and tgtUnit.isNPC
                
                if isNPC then
                    -- NPC: include if it hit
                    if hitCache[act.key] and hitCache[act.key][tgt] == true then
                        table.insert(applyTargets, tgt)
                    end
                end
                -- Player targets: skip entirely (handled via broadcast/reaction)
            end
            
            if act.key == "APPLY_AURA" and act.requiresHit then
                -- Also need to use DAMAGE hit results
                local damageAct = nil
                for j = 1, i - 1 do
                    if actions[j].key == "DAMAGE" then
                        damageAct = actions[j]
                        break
                    end
                end
                
                if damageAct and hitCache[damageAct.key] then
                    -- Filter to only targets that hit on the DAMAGE action
                    applyTargets = {}
                    for _, tgt in ipairs(targets) do
                        local tgtUnit = RPE.Common:FindUnitByKey(tgt)
                        local isNPC = tgtUnit and tgtUnit.isNPC
                        
                        if isNPC and hitCache[damageAct.key][tgt] == true then
                            table.insert(applyTargets, tgt)
                        end
                    end
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(('[SpellCast] APPLY_AURA \'%s\' uses DAMAGE hit results: %d NPC targets'):format(
                            act.args and act.args.auraId or "?",
                            #applyTargets
                        ))
                    end
                end
            end
        end

        if applyTargets and #applyTargets > 0 then
            RPE.Debug:Internal(("Running action '%s' on %d target(s)"):format(act.key, #applyTargets))
            Actions:Run(act.key, ctx, cast, applyTargets, act.args)
        end
    end
end

-- ========= API =========

---Create a new SpellCast instance.
---@param defId string           -- Spell definition ID from registry
---@param caster integer|nil     -- Unit ID of the caster (optional; defaults to local player)
---@param rank integer|nil       -- Spell rank (defaults to 1)
---@return SpellCast
function SpellCast.New(defId, caster, rank)
    local def = assert(SpellRegistry:Get(defId), "Unknown spell id: "..tostring(defId))
    local castRank = tonumber(rank) or 1

    -- Inject rank into the def, so formula/tooltip functions can access it
    def.rank = castRank

    -- If caster not provided, use the local player's unit ID
    local casterId = caster
    if casterId == nil then
        casterId = RPE.Common:LocalPlayerId()
    end
    
    -- Convert string keys to numeric unit IDs for registry consistency
    if type(casterId) == "string" then
        -- Look up the unit by key to get its numeric ID
        local event = RPE.Core.ActiveEvent
        if event and event.units then
            local unit = event.units[casterId]
            if unit and unit.id then
                casterId = unit.id
            end
        end
    end
    
    casterId = tonumber(casterId)

    local self = setmetatable({
        def = def,
        caster = casterId,
        targetSets = { precast = {} },
        wasInterrupted = false,
        _rngSeed = randseed(),
    }, SpellCast)
    return self
end

function SpellCast:InitTargeting()
    self.pendingTargets = {}
    self.chosenTargets  = {}

    local seenRefs = {}

    RPE.Debug:Internal(">>> InitTargeting(): Start")
    for gi, g in ipairs(self.def.groups or {}) do
        for ai, act in ipairs(g.actions or {}) do
            local t = (act.args and act.args.targets) or {}
            local targeter = t.targeter or nil
            
            -- Normalize targeting to a canonical ref
            local ref
            if t.ref then
                ref = t.ref
            elseif targeter == "PRECAST" or targeter == "precast" then
                ref = "precast"
            elseif targeter == "TARGET" or targeter == "target" then
                ref = "precast"  -- TARGET uses spell-level precast targets
            else
                -- For other targeters, create per-action refs to prompt separately
                ref = "action_" .. gi .. "_" .. ai
            end

            RPE.Debug:Internal(string.format(
                "  Action [%d.%d] key=%s, targeter=%s → ref=%s, maxTargets=%s, flags=%s",
                gi, ai,
                tostring(act.key),
                tostring(targeter),
                tostring(ref),
                tostring(t.maxTargets or "nil"),
                tostring(t.flags or "nil")
            ))

            if not seenRefs[ref] then
                seenRefs[ref] = true
                act._resolvedRef = ref
                table.insert(self.pendingTargets, {
                    group = g,
                    action = act,
                    ref = ref,
                    maxTargets = tonumber(t.maxTargets) or 1,
                    flags = t.flags,
                })
                RPE.Debug:Internal("    >> Added to pendingTargets")
            else
                RPE.Debug:Internal("    -- Skipped (already seen ref=" .. ref .. ")")
                act._resolvedRef = ref  -- Still set the ref even though we skip the prompt
            end
        end
    end
    RPE.Debug:Internal(">>> InitTargeting(): End, total = " .. tostring(#self.pendingTargets))
end


function SpellCast:RequestNextTargetSet(ctx)
    local spec = table.remove(self.pendingTargets, 1)
    if not spec then
        RPE.Debug:Internal(">>> All target sets resolved.")
        return self:FinishTargeting(ctx)
    end

    RPE.Debug:Internal(">>> RequestNextTargetSet: Prompting for ref = " .. tostring(spec.ref))

    -- Close any previously opened target window
    local existing = RPE.Core.Windows and RPE.Core.Windows.TargetWindow
    if existing and existing.Hide then
        existing:Hide()
        RPE.Core.Windows.TargetWindow = nil
    end

    -- Always create a fresh instance
    local TW = nil
    if RPE_UI.Windows and RPE_UI.Windows.TargetWindow and RPE_UI.Windows.TargetWindow.New then
        TW = RPE_UI.Windows.TargetWindow.New()
        RPE.Core.Windows.TargetWindow = TW
    end

    if not TW then
        UIErrorsFrame:AddMessage("Target UI unavailable.", 1, 0.2, 0.2)
        return
    end

    TW:Open({
        spellIcon    = self.def.icon,
        spellName    = self.def.name,
        maxTargets   = spec.maxTargets,
        flags        = spec.flags,
        casterUnitId = self.caster,
        onConfirm  = function(keys)
            self.targetSets[spec.ref] = keys
            if TW and TW.Hide then
                TW:Hide()
            end
            RPE.Core.Windows.TargetWindow = nil
            RPE.Debug:Internal(">>> Confirmed targets for ref = " .. tostring(spec.ref))
            self:RequestNextTargetSet(ctx)
        end,
        onCancel = function()
            UIErrorsFrame:AddMessage("Cast cancelled.", 1, 0.2, 0.2)
            self.pendingTargets = {}
            if TW and TW.Hide then
                TW:Hide()
            end
            RPE.Core.Windows.TargetWindow = nil
        end,
    })
end


function SpellCast:FinishTargeting(ctx)
    -- Validate
    local ok, reason = self:Validate(ctx)
    if not ok then
        UIErrorsFrame:AddMessage("Cannot cast: "..(reason or ""), 1,0.3,0.3)
        return
    end

    -- Precast
    ok, reason = self:PreCast(ctx, nil)
    if not ok then
        UIErrorsFrame:AddMessage("Invalid targets: "..(reason or ""), 1,0.3,0.3)
        return
    end

    -- Start
    ok, reason = self:Start(ctx, ctx.event and ctx.event.turn)
    if not ok then
        UIErrorsFrame:AddMessage("Cast failed: "..(reason or ""), 1,0.3,0.3)
        return
    end

    -- Resolve immediately if instant
    if (self.def.cast and self.def.cast.type) == "INSTANT" then
        self:Resolve(ctx, ctx.event and ctx.event.turn)
    end
end


-- Stage 0: Validate
function SpellCast:Validate(ctx)
    self._costSnapshot = (self.def.costs or {})

    -- Skip all requirement checks for NPC units
    local casterUnit = RPE.Common:FindUnitById(self.caster)
    if casterUnit and casterUnit.isNPC then
        return true  -- NPCs bypass all validation
    end

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "validate" then
            local ok, reason, code = evalGroupRequirements(ctx, self, g)
            if not ok then return false, reason, code end
            runActions(ctx, self, g.actions)
        end
    end

    local ok, reason = Requirements:Eval("HasResources", ctx, self, {})
    if not ok then return false, reason end

    ok, reason = Requirements:Eval("CooldownReady", ctx, self, {})
    if not ok then return false, reason end

    return true
end

-- Stage 1: PreCast
function SpellCast:PreCast(ctx, selectedTargets)
    if selectedTargets then self.targetSets.precast = selectedTargets end

    -- Requirement validation is now handled per-group via requirement strings
    -- No longer a global hardcoded check

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "precast" then
            local gok, greason = evalGroupRequirements(ctx, self, g)
            if gok then runActions(ctx, self, g.actions) else return false, greason end
        end
    end
    return true
end

-- Stage 2: Start
function SpellCast:Start(ctx, currentTurn)
    self.startedTurn = currentTurn or (ctx.event and ctx.event.turn) or 0
    -- Initialize lastDecrementTurn to prevent decrementing on the same turn the cast starts
    self.lastDecrementTurn = self.startedTurn

    -- Only spend resources if this cast has a resources context (player casts)
    -- NPCs don't spend resources, so ctx.resources will be nil for them
    if ctx.resources then 
        ctx.resources:Spend(self._costSnapshot, "onStart")
    end

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "onStart" then
            local ok, reason = evalGroupRequirements(ctx, self, g)
            if ok then runActions(ctx, self, g.actions) else return false, reason end
        end
    end

    local ct = self.def.cast or { type = "INSTANT" }
    if ct.type == "CAST_TURNS" then
        self.remainingTurns = tonumber(ct.turns) or 1
    elseif ct.type == "CHANNEL" then
        self.remainingTurns = tonumber(ct.turns) or 1
        self.nextTickTurn   = self.startedTurn + (tonumber(ct.tickIntervalTurns) or 1)
    else
        self.remainingTurns = 0
    end
    
    if RPE.Debug and RPE.Debug.Print and ct.type ~= "INSTANT" then
        RPE.Debug:Internal(('[SpellCast:Start] castType=%s, turns=%s, remainingTurns=%d, startedTurn=%d'):format(
            ct.type or "nil",
            tostring(ct.turns),
            self.remainingTurns,
            self.startedTurn
        ))
    end

    local cd = self.def.cooldown
    if cd and ctx.cooldowns and cd.starts == "onStart" then
        ctx.cooldowns:Start(self.caster, self.def, self.startedTurn)
    end

    -- Register cast with event for multi-unit tracking
    if ctx.event and ctx.event.RegisterCast then
        ctx.event:RegisterCast(self.caster, self)
    end

    -- Ensure cast bar exists and begin
    if not (self.remainingTurns == 0) then
        local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
        if not CB and RPE_UI and RPE_UI.Windows and RPE_UI.Windows.CastBarWidget and RPE_UI.Windows.CastBarWidget.New then
            CB = RPE_UI.Windows.CastBarWidget.New()
            RPE.Core.Windows.CastBarWidget = CB
        end
        CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
        if CB and CB.Begin then CB:Begin(self, ctx) end
    end

    return true
end

-- Stage 3: Tick
function SpellCast:Tick(ctx, currentTurn)
    if not self.remainingTurns or self.remainingTurns <= 0 then return false end
    local ct = self.def.cast or { type = "INSTANT" }

    if ctx.resources then ctx.resources:Spend(self._costSnapshot, "perTick") end

    if ct.type == "CHANNEL" and self.nextTickTurn and currentTurn >= self.nextTickTurn then
        for _, g in ipairs(self.def.groups or {}) do
            if g.phase == "onTick" then
                local ok = (select(1, evalGroupRequirements(ctx, self, g)))
                if ok then runActions(ctx, self, g.actions) end
            end
        end
        self.nextTickTurn = currentTurn + (tonumber(ct.tickIntervalTurns) or 1)
    end

    -- Decrement remainingTurns only once per turn (not once per tick when there are multiple ticks per turn)
    local shouldDecrement = not self.lastDecrementTurn or self.lastDecrementTurn < currentTurn
    if RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[SpellCast:Tick] Turn=%d, lastDecrementTurn=%s, shouldDecrement=%s, remainingTurns=%d'):format(
            currentTurn, 
            tostring(self.lastDecrementTurn or "nil"), 
            tostring(shouldDecrement),
            self.remainingTurns or 0
        ))
    end
    if shouldDecrement then
        self.remainingTurns = math.max(0, (self.remainingTurns or 0) - 1)
        self.lastDecrementTurn = currentTurn
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(('[SpellCast:Tick] Decremented remainingTurns to %d'):format(self.remainingTurns))
        end
    end

    -- Update cast bar if it exists (for UI display)
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if CB and CB.Update then 
        CB:Update(self, ctx, currentTurn) 
        -- Note: CB:Update() will call Finish() which calls Resolve() if this cast is complete
    end

    if self.remainingTurns == 0 then
        -- Cast is complete - Resolve() may have already been called by CB:Update() -> Finish()
        -- If there's no cast bar, Resolve() won't have been called, so we must ensure it gets called
        -- To avoid double-calling Resolve(), we'll mark that we're handling it
        if not (CB and CB.Update) then
            self:Resolve(ctx, currentTurn)
        end
        return true
    end
    return false
end

-- Stage 4: Resolve
function SpellCast:Resolve(ctx, currentTurn)
    if ctx.resources then ctx.resources:Spend(self._costSnapshot, "onResolve") end

    for i, g in ipairs(self.def.groups or {}) do
        if g.phase == "onResolve" then
            local ok, reason, code = evalGroupRequirements(ctx, self, g)
            if ok then
                RPE.Debug:Internal(("→ Running group %d (onResolve)"):format(i))
                runActions(ctx, self, g.actions)
            else
                RPE.Debug:Warning(("→ Skipped group %d (onResolve): %s [%s]"):format(
                    i, tostring(reason or "unknown"), tostring(code or "???")
                ))
            end
        end
    end

    local cd = self.def.cooldown
    local t  = currentTurn or (ctx.event and ctx.event.turn) or 0
    if cd and ctx.cooldowns and (cd.starts == "onResolve" or cd.starts == nil) then
        ctx.cooldowns:Start(self.caster, self.def, t)
    end

    -- Clear cast from registry
    if ctx.event and ctx.event.ClearCast then
        ctx.event:ClearCast(self.caster)
    end

    RPE.Debug:Internal(("Resolving %s at Rank %d"):format(self.def.name or "?", self.def.rank or 1))
end


-- Stage 5: Interrupt
function SpellCast:Interrupt(ctx, reason)
    self.wasInterrupted = true

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "onInterrupt" then
            local ok = (select(1, evalGroupRequirements(ctx, self, g)))
            if ok then runActions(ctx, self, g.actions) end
        end
    end

    if ctx and ctx.resources then ctx.resources:Refund(self._costSnapshot) end

    -- Clear cast from registry
    if ctx.event and ctx.event.ClearCast then
        ctx.event:ClearCast(self.caster)
    end

    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if CB and CB.Interrupt then CB:Interrupt(self, reason) end
end

-- ===== Hit Checking ===== --
-- Per-action overrides fall back to ruleset
local function _hitParams(act, ctx)
    -- roll
    local roll = act.rollOverride
    if roll == nil then roll = RPE.ActiveRules:Get("hit_roll") end
    if type(roll) == "table" then roll = roll[1] end
    roll = tostring(roll or "1d20")

    -- base threshold
    local base = act.thresholdBaseOverride
    if base == nil then base = RPE.ActiveRules:Get("hit_base_threshold") end
    if type(base) == "table" then base = base[1] end
    base = tonumber(base) or 10

    -- mode
    local mode = act.rollMode
    if mode == nil then mode = RPE.ActiveRules:Get("hit_aoe_roll_mode") end
    if type(mode) == "table" then mode = mode[1] end
    mode = (mode == "single_roll") and "single_roll" or "per_target"

    return roll, base, mode
end

-- Get the hit system from active rules
local function _getHitSystem()
    local raw = RPE.ActiveRules:Get("hit_system", "complex")
    local systemStr = "complex"
    if type(raw) == "table" and raw[1] then
        systemStr = tostring(raw[1]):lower()
    elseif type(raw) == "string" then
        systemStr = raw:lower()
    end
    if systemStr == "simple" or systemStr == "ac" then
        return systemStr
    end
    return "complex"  -- default
end

-- Check hit for NPC target (complex/simple/ac systems)
local function _checkHitVsNPC(tgtUnit, casterUnit, hitSystem, rollSpec, baseThreshold, attMod, thresholdIds)
    local roll = RPE.Common:Roll(rollSpec)
    local lhs = roll + attMod
    local defThr = 0
    
    if hitSystem == "simple" then
        -- Simple: always use DEFENCE stat
        if tgtUnit and tgtUnit.stats then
            defThr = tonumber(tgtUnit.stats.DEFENCE) or 0
        end
        local rhs = baseThreshold + defThr
        return lhs >= rhs, roll, lhs, defThr  -- Return defThr for display, not rhs
    elseif hitSystem == "ac" then
        -- AC: roll against AC value directly (no base threshold added)
        if tgtUnit and tgtUnit.stats then
            local ac = tonumber(tgtUnit.stats.AC) or 0
            return lhs >= ac, roll, lhs, ac
        end
        return lhs >= baseThreshold, roll, lhs, baseThreshold
    else
        -- Complex (default): use specified thresholds
        if #thresholdIds > 0 and tgtUnit and tgtUnit.stats then
            -- NPC: choose the highest stat
            for _, id in ipairs(thresholdIds) do
                local val = tonumber(tgtUnit.stats[id]) or 0
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(("[SpellCast] Threshold stat " .. tostring(id) .. " = " .. tostring(val)))
                end
                if val > defThr then defThr = val end
            end
        end
        local rhs = baseThreshold + defThr
        return lhs >= rhs, roll, lhs, defThr  -- Return defThr for display, not rhs
    end
end

-- Check hit for player target (complex/simple systems need player choice, ac is automatic)
local function _checkHitVsPlayer(tgtUnit, casterUnit, hitSystem, rollSpec, baseThreshold, attMod, thresholdIds)
    if hitSystem == "ac" then
        -- AC: automatic, no player choice needed
        local roll = RPE.Common:Roll(rollSpec)
        local ac = (tgtUnit and tgtUnit.stats and tonumber(tgtUnit.stats.AC)) or 0
        local lhs = roll + attMod
        local rhs = ac
        return lhs >= rhs, roll, lhs, rhs
    else
        -- Complex/Simple: need player defence choice (NYI)
        RPE.Debug:NYI("Player defence choice for complex/simple hit systems")
        
        -- For now, still roll but note that this needs player input
        local roll = RPE.Common:Roll(rollSpec)
        local defThr = 0
        
        if hitSystem == "simple" then
            if tgtUnit and tgtUnit.stats then
                defThr = tonumber(tgtUnit.stats.DEFENCE) or 0
            end
        else
            -- Complex: use first threshold for now (TODO: player choice)
            if #thresholdIds > 0 and tgtUnit and tgtUnit.stats then
                local firstId = thresholdIds[1]
                defThr = tonumber(tgtUnit.stats[firstId]) or 0
            end
        end
        
        local lhs = roll + attMod
        local rhs = baseThreshold + defThr
        return lhs >= rhs, roll, lhs, rhs
    end
end

function SpellCast:CheckHit(ctx, cast, act, targets)
    -- Performs to-hit calculations using the caster's unit ID from the cast object.
    -- Supports three hit systems: complex, simple, and ac
    -- For player targets: broadcasts attack and lets player respond via reaction system
    
    targets = targets or {}
    if #targets == 0 then return targets, {} end

    -- always_hit
    local alwaysVal = RPE.ActiveRules:Get("always_hit", 0)
    if type(alwaysVal) == "table" then alwaysVal = alwaysVal[1] end
    local always = tonumber(alwaysVal) or 0

    -- requiresHit (explicit flag beats ruleset list)
    local requiresHit
    if act.requiresHit ~= nil then
        requiresHit = not not act.requiresHit
    else
        local list = RPE.ActiveRules:Get("hit_default_requires", {})
        if type(list) == "table" then
            for i = 1, #list do
                if list[i] == act.key then requiresHit = true; break end
            end
        elseif type(list) == "string" then
            requiresHit = (list == act.key)
        else
            requiresHit = false
        end
    end

    if always == 1 or not requiresHit then
        return targets, {}
    end

    local hitSystem = _getHitSystem()
    local rollSpec, baseThreshold, mode = _hitParams(act, ctx)
    baseThreshold = tonumber(baseThreshold) or 10

    -- attacker / caster
    local casterUnit = RPE.Common:FindUnitById(cast.caster)

    -- parse attacker modifier ID
    local attId = act.hitModifier and act.hitModifier:match("^%$stat%.([%w_]+)%$$")
    local attMod = 0
    if attId then
        attMod = RPE.Stats:GetValue(attId) or 0
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("[SpellCast] Hit modifier stat: " .. tostring(attId) .. " = " .. tostring(attMod)))
        end
    end

    -- parse threshold IDs (can be string or table of strings)
    local thresholdIds = {}
    local hitThreshold = act.hitThreshold
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(("[SpellCast] Raw hitThreshold: " .. tostring(hitThreshold) .. " (type: " .. type(hitThreshold) .. ")"))
    end
    
    if type(hitThreshold) == "string" then
        local id = hitThreshold:match("^%$stat%.([%w_]+)%$$")
        if id then thresholdIds = { id } end
    elseif type(hitThreshold) == "table" then
        for _, v in ipairs(hitThreshold) do
            if type(v) == "string" then
                local id = v:match("^%$stat%.([%w_]+)%$$")
                if id then table.insert(thresholdIds, id) end
            end
        end
    end
    
    -- Debug: show threshold stat IDs
    if RPE and RPE.Debug and RPE.Debug.Print then
        if #thresholdIds > 0 then
            RPE.Debug:Internal(("[SpellCast] Hit threshold stats: " .. table.concat(thresholdIds, ", ")))
        else
            RPE.Debug:Internal(("[SpellCast] No hit threshold stats found (thresholdIds is empty)"))
        end
    end

    local singleRoll = (mode == "single_roll") and RPE.Common:Roll(rollSpec) or nil

    local hits, misses = {}, {}
    local playerTargets = {}  -- Track player targets for broadcasting attacks
    
    for i = 1, #targets do
        local ref = targets[i]
        local tgtUnit = RPE.Common:FindUnitByKey(ref) or nil

        -- Determine if target is NPC or player
        local isNPC = tgtUnit and tgtUnit.isNPC
        
        local hitResult, roll, lhs, rhs
        if isNPC then
            hitResult, roll, lhs, rhs = _checkHitVsNPC(tgtUnit, casterUnit, hitSystem, 
                                                        singleRoll or rollSpec, baseThreshold, attMod, thresholdIds)
        else
            -- For player targets, we need to broadcast the attack and let them defend
            roll = singleRoll or RPE.Common:Roll(rollSpec)
            lhs = roll + attMod
            
            -- Store player target info for broadcasting after the loop
            playerTargets[#playerTargets+1] = {
                ref = ref,
                unit = tgtUnit,
                thresholdIds = thresholdIds,
                roll = roll,
                attackRoll = lhs,  -- Total roll + modifier
            }
            -- Don't include player targets in hits/misses - they're handled via broadcast/reaction
            hitResult = false
            rhs = 0  -- Will be determined by player's choice
        end

        if hitResult then
            if RPE and RPE.Debug and RPE.Debug.Print then
                if hitSystem == "ac" then
                    RPE.Debug:Internal((' > Hit: %s (%d + %d vs %d) [%s]')
                        :format(tostring(ref), roll or 0, attMod, rhs or 0, hitSystem))
                else
                    RPE.Debug:Internal((' > Hit: %s (%d + %d vs %d + %d) [%s]')
                        :format(tostring(ref), roll or 0, attMod, baseThreshold, rhs or 0, hitSystem))
                end
            end
            hits[#hits+1] = ref
        else
            if RPE and RPE.Debug and RPE.Debug.Print then
                if hitSystem == "ac" then
                    RPE.Debug:Internal((' > Miss: %s (%d + %d vs %d) [%s]')
                        :format(tostring(ref), roll or 0, attMod, rhs or 0, hitSystem))
                else
                    RPE.Debug:Internal((' > Miss: %s (%d + %d vs %d + %d) [%s]')
                        :format(tostring(ref), roll or 0, attMod, baseThreshold, rhs or 0, hitSystem))
                end
            end
            misses[#misses+1] = ref
        end
    end

    -- Broadcast attacks on player targets
    if #playerTargets > 0 then
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        
        -- Calculate total predicted damage including base spell damage + on-hit aura effects
        -- Damage is tracked per school: { [school] = amount, ... }
        local damageBySchool = {}
        
        -- Base spell damage
        if act.key == "DAMAGE" and act.args then
            local amt = 0
            if type(act.args.amount) == "string" then
                -- Evaluate formula using the caster's profile
                local Formula = RPE.Core and RPE.Core.Formula
                if Formula and Formula.Roll then
                    amt = tonumber(Formula:Roll(act.args.amount, cast.profile)) or 0
                else
                    amt = tonumber(act.args.amount) or 0
                end
            else
                amt = tonumber(act.args.amount) or 0
            end
            
            -- Add per-rank scaling if applicable
            if type(act.args.perRank) == "string" and act.args.perRank ~= "" then
                local rank = (cast and cast.def and tonumber(cast.def.rank)) or 1
                if rank > 1 then
                    local Formula = RPE.Core and RPE.Core.Formula
                    if Formula and Formula.Roll then
                        local perRankAmt = tonumber(Formula:Roll(act.args.perRank, cast.profile)) or 0
                        amt = amt + (perRankAmt * (rank - 1))
                    end
                end
            end
            
            local school = (act.args.school) or "Physical"
            amt = math.max(0, math.floor(amt))
            if amt > 0 then
                damageBySchool[school] = (damageBySchool[school] or 0) + amt
            end
        end
        
        -- Collect aura effects triggered by this hit and their damage
        local auraEffects = {}
        local AuraManager = RPE.Core.ActiveEvent and RPE.Core.ActiveEvent._auraManager
        if AuraManager then
            -- Get auras for this caster from the AuraManager (keyed by numeric unit ID)
            local auraList = AuraManager.aurasByUnit and AuraManager.aurasByUnit[cast.caster]
            
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(('[SpellCast] Checking auras for caster %d: found=%s'):format(
                    cast.caster, auraList and "yes" or "no"))
            end
            
            if auraList then
                for _, aura in pairs(auraList) do
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(('[SpellCast]   Aura: id=%s, hasTriggers=%s'):format(
                            aura.def and aura.def.id or "?", 
                            aura.def and aura.def.triggers and "yes" or "no"))
                    end
                    if aura.def and aura.def.triggers then
                        for _, trigger in ipairs(aura.def.triggers) do
                            if RPE and RPE.Debug and RPE.Debug.Print then
                                RPE.Debug:Internal(('[SpellCast]     Trigger: event=%s, hasAction=%s'):format(
                                    trigger.event or "?",
                                    trigger.action and "yes" or "no"))
                            end
                            if (trigger.event == "ON_HIT" or trigger.event == "ON_DAMAGE") and trigger.action then
                                if RPE and RPE.Debug and RPE.Debug.Print then
                                    RPE.Debug:Internal(('[SpellCast] Found ON_HIT trigger: auraId=%s, action=%s'):format(
                                        aura.def.id, trigger.action.key))
                                end
                                
                                local effectData = {
                                    auraId = aura.def.id or "unknown",
                                    actionKey = trigger.action.key,
                                    argsJSON = trigger.action.args and serializeArgs(trigger.action.args) or "",
                                }
                                table.insert(auraEffects, effectData)
                                
                                -- Add damage from this on-hit effect
                                if trigger.action.key == "DAMAGE" and trigger.action.args then
                                    local amt = 0
                                    if type(trigger.action.args.amount) == "string" then
                                        -- Evaluate formula using the caster's profile
                                        local Formula = RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            amt = tonumber(Formula:Roll(trigger.action.args.amount, cast.profile)) or 0
                                        else
                                            amt = tonumber(trigger.action.args.amount) or 0
                                        end
                                    else
                                        amt = tonumber(trigger.action.args.amount) or 0
                                    end
                                    
                                    local school = (trigger.action.args.school) or "Physical"
                                    amt = math.max(0, math.floor(amt))
                                    if amt > 0 then
                                        damageBySchool[school] = (damageBySchool[school] or 0) + amt
                                        if RPE and RPE.Debug and RPE.Debug.Print then
                                            RPE.Debug:Internal(('[SpellCast]   Added on-hit damage: +%d %s'):format(
                                                amt, school))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for _, ptgt in ipairs(playerTargets) do
            if Broadcast and Broadcast.AttackSpell and ptgt.unit then
                
                Broadcast:AttackSpell(
                    cast.caster,
                    ptgt.unit.id,
                    cast.def.id or "UNKNOWN",
                    cast.def.name or "Unknown Spell",
                    hitSystem,
                    ptgt.attackRoll,  -- Send total attack roll, not just modifier
                    ptgt.thresholdIds,
                    damageBySchool,
                    auraEffects
                )
            end
        end
    end

    return hits, misses
end

return SpellCast

