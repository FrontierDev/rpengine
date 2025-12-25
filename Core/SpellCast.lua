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

local function runActions(ctx, cast, actions, groupId)
    -- Pre-compute hit checks for all targets across all actions in this group
    -- We'll cache hit results by (action, target) pair, AND cache the resolved targets
    local hitCache = {}  -- { [action] = { [targetRef] = {hit=bool, roll=num, ...} } }
    local targetCache = {}  -- { [action] = {targets} } - cache resolved targets to avoid double resolution
    
    local aggregatedPlayerTargets = {}  -- { [playerUnitId] = { unit, hitSystem, thresholdIds, attackRoll, isCrit, damageBySchool={}, auraEffects={} } }
    local aggregatedNPCTargets = {}  -- { [npcUnitId] = { unit, damageBySchool={}, auraEffects={} } } - for NPC-to-NPC attacks
    
    -- Store groupId in cast for DAMAGE action to use
    if groupId then
        cast._currentGroupPhase = groupId
        cast._groupId = groupId  -- Pass the exact groupId to use for pending damage
    end
    
    for _, act in ipairs(actions or {}) do
        local targets = resolveActionTargets(cast, ctx, act)
        targetCache[act.key] = targets  -- Cache for later use
        
        -- Perform hit check (or use cached results from first action)
        -- Returns hits, misses, AND playerTargetData array
        local hitTargets, missTargets, playerTargetData = SpellCast:CheckHit(ctx, cast, act, targets)
        
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
        
        -- Aggregate player target damage across actions
        if act.key == "DAMAGE" and playerTargetData then
            for _, ptgtData in ipairs(playerTargetData) do
                local unitId = ptgtData.unit.id
                if not aggregatedPlayerTargets[unitId] then
                    aggregatedPlayerTargets[unitId] = {
                        unit = ptgtData.unit,
                        hitSystem = ptgtData.hitSystem,
                        thresholdIds = ptgtData.thresholdIds,
                        attackRoll = ptgtData.attackRoll,
                        isCrit = ptgtData.isCrit,
                        damageBySchool = {},
                        auraEffects = {},
                    }
                end
                
                -- Merge damage schools
                for school, amount in pairs(ptgtData.damageBySchool or {}) do
                    aggregatedPlayerTargets[unitId].damageBySchool[school] = (aggregatedPlayerTargets[unitId].damageBySchool[school] or 0) + amount
                end
                
                -- Merge aura effects
                for _, effect in ipairs(ptgtData.auraEffects or {}) do
                    table.insert(aggregatedPlayerTargets[unitId].auraEffects, effect)
                end
                
                -- Mark as critical if any DAMAGE action was crit
                if ptgtData.isCrit then
                    aggregatedPlayerTargets[unitId].isCrit = true
                end
            end
        end
        
        -- Aggregate NPC target damage and aura effects across actions
        if (act.key == "DAMAGE" or act.key == "APPLY_AURA") and act.key ~= "APPLY_AURA" then
            -- Track DAMAGE actions for NPC targets
            if hitTargets then
                for _, tgt in ipairs(hitTargets) do
                    local tgtUnit = RPE.Common:FindUnitByKey(tgt)
                    if tgtUnit and tgtUnit.isNPC then
                        local unitId = tgtUnit.id
                        if not aggregatedNPCTargets[unitId] then
                            aggregatedNPCTargets[unitId] = {
                                unit = tgtUnit,
                                damageBySchool = {},
                                auraEffects = {},
                            }
                        end
                        
                        -- For DAMAGE, merge the damage
                        if act.key == "DAMAGE" and playerTargetData then
                            -- Find damage for this NPC target in playerTargetData
                            for _, ptgtData in ipairs(playerTargetData) do
                                if ptgtData.unit.id == unitId then
                                    for school, amount in pairs(ptgtData.damageBySchool or {}) do
                                        aggregatedNPCTargets[unitId].damageBySchool[school] = (aggregatedNPCTargets[unitId].damageBySchool[school] or 0) + amount
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Now run actions, using cached hit results and cached targets
    for i, act in ipairs(actions or {}) do
        local targets = targetCache[act.key] or {}  -- Use cached targets instead of re-resolving
        
        -- Filter out player targets for DAMAGE and APPLY_AURA actions
        -- (they're handled via broadcast/reaction system)
        -- Also defer APPLY_AURA for NPC targets to apply after damage
        local applyTargets = targets
        if act.key == "DAMAGE" or act.key == "APPLY_AURA" then
            applyTargets = {}
            
            for _, tgt in ipairs(targets) do
                local tgtUnit = RPE.Common:FindUnitByKey(tgt)
                local isNPC = tgtUnit and tgtUnit.isNPC
                
                if isNPC then
                    -- NPC: include if it hit (for actions that requiresHit)
                    if not act.requiresHit then
                        -- No hit check required, apply to all targets
                        table.insert(applyTargets, tgt)
                    elseif act.key == "DAMAGE" then
                        -- DAMAGE always includes hits
                        if hitCache[act.key] and hitCache[act.key][tgt] == true then
                            table.insert(applyTargets, tgt)
                        end
                    elseif act.key == "APPLY_AURA" then
                        -- For APPLY_AURA, check DAMAGE hit results
                        local damageAct = nil
                        for j = 1, i - 1 do
                            if actions[j].key == "DAMAGE" then
                                damageAct = actions[j]
                                break
                            end
                        end
                        
                        if damageAct and hitCache[damageAct.key] and hitCache[damageAct.key][tgt] == true then
                            table.insert(applyTargets, tgt)
                        end
                    end
                end
                -- Player targets: skip entirely (handled via broadcast/reaction system)
            end
            
            if act.key == "APPLY_AURA" then
                -- Defer BOTH player and NPC aura applications
                -- Collect them instead of running immediately
                for _, tgt in ipairs(targets) do
                    local tgtUnit = RPE.Common:FindUnitByKey(tgt)
                    
                    -- If FindUnitByKey fails, try finding by numeric ID directly
                    if not tgtUnit and type(tgt) == "number" then
                        tgtUnit = RPE.Common:FindUnitById(tgt)
                    end
                    
                    if tgtUnit and tgtUnit.isNPC then
                        -- Collect NPC aura effect for deferred application after damage
                        local unitId = tgtUnit.id
                        if not aggregatedNPCTargets[unitId] then
                            aggregatedNPCTargets[unitId] = {
                                unit = tgtUnit,
                                damageBySchool = {},
                                auraEffects = {},
                            }
                        end
                        
                        -- Check if this aura should be applied (hit requirement)
                        local shouldApply = false
                        if not act.requiresHit then
                            shouldApply = true
                        else
                            -- Check DAMAGE hit results
                            local damageAct = nil
                            for j = 1, i - 1 do
                                if actions[j].key == "DAMAGE" then
                                    damageAct = actions[j]
                                    break
                                end
                            end
                            if damageAct and hitCache[damageAct.key] and hitCache[damageAct.key][tgt] then
                                shouldApply = hitCache[damageAct.key][tgt] == true
                            end
                        end
                        
                        if shouldApply then
                            local effectData = {
                                auraId = (act.args and act.args.auraId) or "unknown",
                                actionKey = "APPLY_AURA",
                                argsJSON = act.args and serializeArgs(act.args) or "",
                            }
                            table.insert(aggregatedNPCTargets[unitId].auraEffects, effectData)
                            
                            if RPE and RPE.Debug and RPE.Debug.Print then
                                RPE.Debug:Internal(('[SpellCast] Deferring APPLY_AURA \'%s\' for NPC %d'):format(
                                    act.args and act.args.auraId or "?",
                                    unitId
                                ))
                            end
                        end
                    elseif tgtUnit and not tgtUnit.isNPC then
                        -- For players, defer aura application via broadcast
                        -- Collect aura effect for inclusion in AttackSpell broadcast
                        local unitId = tgtUnit.id
                        if not aggregatedPlayerTargets[unitId] then
                            aggregatedPlayerTargets[unitId] = {
                                unit = tgtUnit,
                                hitSystem = "complex",  -- Default, will be overwritten by DAMAGE
                                thresholdIds = {},
                                attackRoll = 0,
                                isCrit = false,
                                damageBySchool = {},
                                auraEffects = {},
                            }
                        end
                        
                        local effectData = {
                            auraId = (act.args and act.args.auraId) or "unknown",
                            actionKey = "APPLY_AURA",
                            argsJSON = act.args and serializeArgs(act.args) or "",
                        }
                        table.insert(aggregatedPlayerTargets[unitId].auraEffects, effectData)
                        
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[SpellCast] Deferring APPLY_AURA \'%s\' for player %d (via broadcast)'):format(
                                act.args and act.args.auraId or "?",
                                unitId
                            ))
                        end
                    end
                end
                
                -- Still execute APPLY_AURA immediately locally (don't defer execution, only defer broadcast)
                -- This allows triggers like ON_KILL to fire on the same turn
                local applyAuraTargets = {}
                for unitId in pairs(aggregatedPlayerTargets) do
                    if aggregatedPlayerTargets[unitId].unit then
                        table.insert(applyAuraTargets, aggregatedPlayerTargets[unitId].unit)
                    end
                end
                for unitId in pairs(aggregatedNPCTargets) do
                    if aggregatedNPCTargets[unitId] then
                        -- Create minimal unit table for NPC
                        table.insert(applyAuraTargets, {id = unitId, isNPC = true})
                    end
                end
                
                if applyAuraTargets and #applyAuraTargets > 0 then
                    RPE.Debug:Internal(("Running action '%s' on %d target(s) [immediately for local triggers]"):format(act.key, #applyAuraTargets))
                    if act._critThreshold ~= nil then
                        act.args._critThreshold = act._critThreshold
                    end
                    if act._critMult ~= nil then
                        act.args._critMult = act._critMult
                    end
                    if act._rolls ~= nil then
                        act.args._rolls = act._rolls
                    end
                    local Actions = RPE.Core and RPE.Core.SpellActions
                    if Actions and Actions.Run then
                        Actions:Run(act.key, ctx, cast, applyAuraTargets, act.args)
                    end
                end
                
                -- Skip running APPLY_AURA from the normal applyTargets list (already executed above)
                applyTargets = {}
            end
        end

        if applyTargets and #applyTargets > 0 then
            RPE.Debug:Internal(("Running action '%s' on %d target(s)"):format(act.key, #applyTargets))
            -- Copy cached crit values into args so handler can access them
            if act._critThreshold ~= nil then
                act.args._critThreshold = act._critThreshold
            end
            if act._critMult ~= nil then
                act.args._critMult = act._critMult
            end
            if act._rolls ~= nil then
                act.args._rolls = act._rolls
            end
            Actions:Run(act.key, ctx, cast, applyTargets, act.args)
        end
    end
    
    -- Flush pending damage for this group (aggregate all DAMAGE actions and broadcast once)
    if groupId then
        local SpellActions = RPE.Core and RPE.Core.SpellActions
        if SpellActions and SpellActions.FlushDamageForGroup then
            SpellActions:FlushDamageForGroup(groupId)
        end
    end
    
    -- Broadcast aggregated player target attacks (after all DAMAGE actions processed)
    -- Only broadcast if there's actual damage (don't broadcast pure APPLY_AURA with no damage)
    if next(aggregatedPlayerTargets) then
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if Broadcast and Broadcast.AttackSpell then
            for unitId, ptgtData in pairs(aggregatedPlayerTargets) do
                if ptgtData.unit then
                    -- Check if there's actual damage to report
                    local hasDamage = false
                    if ptgtData.damageBySchool and type(ptgtData.damageBySchool) == "table" then
                        for school, amount in pairs(ptgtData.damageBySchool) do
                            if tonumber(amount) and tonumber(amount) > 0 then
                                hasDamage = true
                                break
                            end
                        end
                    end
                    
                    if hasDamage then
                        -- Has damage: broadcast as attack spell (with aura effects if any)
                        Broadcast:AttackSpell(
                            cast.caster,
                            ptgtData.unit.id,
                            cast.def.id or "UNKNOWN",
                            cast.def.name or "Unknown Spell",
                            ptgtData.hitSystem,
                            ptgtData.attackRoll,
                            ptgtData.thresholdIds,
                            ptgtData.damageBySchool,
                            ptgtData.auraEffects or {}
                        )
                    else
                        -- No damage: apply auras directly without triggering player reaction
                        if ptgtData.auraEffects and #ptgtData.auraEffects > 0 then
                            local SpellActions = RPE.Core and RPE.Core.SpellActions
                            for _, effect in ipairs(ptgtData.auraEffects) do
                                if SpellActions and effect.auraId then
                                    -- Parse args back from JSON if needed
                                    local args = {}
                                    if effect.argsJSON and effect.argsJSON ~= "" then
                                        for pair in effect.argsJSON:gmatch("[^,]+") do
                                            local k, v = pair:match("([^=]+)=(.+)")
                                            if k then args[k] = v end
                                        end
                                    end
                                    args.auraId = effect.auraId
                                    
                                    if RPE and RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(("[SpellCast] Applying aura \'%s\' to player %d (no damage)"):format(
                                            effect.auraId, ptgtData.unit.id))
                                    end
                                    
                                    -- Apply the aura via broadcast
                                    if Broadcast and Broadcast.AuraApply then
                                        local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
                                        local auraDef = AuraRegistry and AuraRegistry:Get(effect.auraId)
                                        local desc = auraDef and auraDef.description or "Applied aura"
                                        Broadcast:AuraApply(cast.caster, ptgtData.unit.id, effect.auraId, desc)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Apply NPC-to-NPC attack aura effects (which were deferred)
    if next(aggregatedNPCTargets) then
        local SpellActions = RPE.Core and RPE.Core.SpellActions
        if SpellActions then
            for unitId, npcData in pairs(aggregatedNPCTargets) do
                if npcData.unit and #npcData.auraEffects > 0 then
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(('[SpellCast] Applying %d deferred auras to NPC %d'):format(
                            #npcData.auraEffects, unitId))
                    end
                    
                    for _, effect in ipairs(npcData.auraEffects) do
                        -- Parse args from JSON if present
                        local effectArgs = {}
                        if effect.argsJSON and effect.argsJSON ~= "" then
                            -- Simple JSON parsing for args
                            for key, val in string.gmatch(effect.argsJSON, '([%w_]+)=([^,}]+)') do
                                effectArgs[key] = val
                            end
                        end
                        
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[SpellCast] Applying aura: auraId=%s, action=%s'):format(
                                effect.auraId, effect.actionKey))
                        end
                        
                        -- Execute the action on target
                        local ok, err = pcall(function()
                            SpellActions:Run(effect.actionKey, ctx or {}, { caster = cast.caster }, { unitId }, effectArgs)
                        end)
                        
                        if not ok and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal("|cffff5555[SpellCast] Aura application error:|r " .. tostring(err))
                        end
                    end
                end
            end
        end
    end
    
    -- Flush pending combat messages after all actions processed
    local castKey = tostring(cast and cast.def and cast.def.id or cast and cast.caster or "unknown")
    if RPE.Core.SpellActions and RPE.Core.SpellActions.FlushCombatMessages then
        RPE.Core.SpellActions:FlushCombatMessages(castKey)
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
    local spellDefaultTargeter = self.def.targeter and self.def.targeter.default

    RPE.Debug:Internal(">>> InitTargeting(): Start")
    for gi, g in ipairs(self.def.groups or {}) do
        -- First pass: check if this group has a RAID_MARKER action
        local groupHasRaidMarker = false
        for _, act in ipairs(g.actions or {}) do
            local t = (act.args and act.args.targets) or {}
            local targeter = t.targeter or nil
            if targeter == "RAID_MARKER" or targeter == "raid_marker" then
                groupHasRaidMarker = true
                break
            end
        end

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
                -- TARGET uses RAID_MARKER ref if this group has RAID_MARKER action, otherwise spell-level targeter
                if groupHasRaidMarker then
                    ref = "raid_marker"
                elseif spellDefaultTargeter == "RAID_MARKER" or spellDefaultTargeter == "raid_marker" then
                    ref = "raid_marker"
                else
                    ref = "precast"
                end
            elseif targeter == "RAID_MARKER" or targeter == "raid_marker" then
                ref = "raid_marker"
            elseif targeter == "CASTER" or targeter == "caster" then
                ref = "caster"
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

            -- Detect instant-resolve targeters
            local instantTargeters = {
                ALL_ALLIES = true,
                ALL_ENEMIES = true,
                ALL_UNITS = true,
                CASTER = true,
                SUMMONED = true,
            }
            if targeter and instantTargeters[targeter] then
                -- Auto-resolve: fill targetSets immediately, skip prompt
                if not self.targetSets[ref] then
                    local sel = Targeters:Select(targeter, {}, self, t.args)
                    self.targetSets[ref] = sel and sel.targets or {}
                    RPE.Debug:Internal("    >> Auto-resolved targets for instant targeter: " .. targeter)
                end
                act._resolvedRef = ref
                seenRefs[ref] = true
                -- Do NOT add to pendingTargets (no prompt)
            elseif not seenRefs[ref] then
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

    -- Extract targeter name for the TargetWindow to know which auto-selection behavior to use
    local targeterName = nil
    if spec.action and spec.action.args and spec.action.args.targets then
        targeterName = spec.action.args.targets.targeter
    end
    -- Fall back to spell-level targeter if action doesn't have explicit targets
    if not targeterName and self.def and self.def.targeter then
        targeterName = self.def.targeter.default
    end

    TW:Open({
        spellIcon    = self.def.icon,
        spellName    = self.def.name,
        maxTargets   = spec.maxTargets,
        flags        = spec.flags,
        casterUnitId = self.caster,
        targeter     = targeterName,
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

    local casterUnit = RPE.Common:FindUnitById(self.caster)
    
    -- Check crowd control blocking for ALL units (including NPCs)
    local ev = RPE.Core.ActiveEvent
    if ev and ev._auraManager then
        -- Check if caster is blocked from all actions
        if ev._auraManager:IsBlockedFromActions(self.caster) then
            return false, "Blocked from casting actions", "CC_BLOCKED"
        end
        
        -- Check if this specific spell is blocked by tag
        if self.def.tags then
            for _, tag in ipairs(self.def.tags) do
                if ev._auraManager:IsActionBlockedByTag(self.caster, tag) then
                    return false, "Action blocked by tag: " .. tag, "CC_TAG_BLOCKED"
                end
            end
        end
    end

    -- Skip all other requirement checks for NPC units
    if casterUnit and casterUnit.isNPC then
        return true  -- NPCs bypass non-CC validation
    end

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "validate" then
            local ok, reason, code = evalGroupRequirements(ctx, self, g)
            if not ok then return false, reason, code end
            runActions(ctx, self, g.actions, "validate")
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
            if gok then runActions(ctx, self, g.actions, "precast") else return false, greason end
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
        ctx.resources:Spend(self._costSnapshot, "onStart", self.def)
    end

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "onStart" then
            local ok, reason = evalGroupRequirements(ctx, self, g)
            if ok then runActions(ctx, self, g.actions, "onStart") else return false, reason end
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

        -- Broadcast casting information to group
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if Broadcast then
            -- Get primary target (first from precast or self)
            local targetId = nil
            if self.targetSets and self.targetSets.precast and #self.targetSets.precast > 0 then
                local firstTargetKey = self.targetSets.precast[1]
                if firstTargetKey then
                    local ev = RPE.Core.ActiveEvent
                    if ev and ev.units and ev.units[firstTargetKey] then
                        targetId = ev.units[firstTargetKey].id
                    end
                end
            end
            
            Broadcast:SendCasting(self.caster, self.def.id, self.def.name, self.def.icon, self.remainingTurns, tonumber(self.def.cast.turns) or 1, targetId)
        end
    end

    return true
end

-- Stage 3: Tick
function SpellCast:Tick(ctx, currentTurn)
    if not self.remainingTurns or self.remainingTurns <= 0 then return false end
    local ct = self.def.cast or { type = "INSTANT" }

    if ctx.resources then ctx.resources:Spend(self._costSnapshot, "perTick", self.def) end

    if ct.type == "CHANNEL" and self.nextTickTurn and currentTurn >= self.nextTickTurn then
        for _, g in ipairs(self.def.groups or {}) do
            if g.phase == "onTick" then
                local ok = (select(1, evalGroupRequirements(ctx, self, g)))
                if ok then runActions(ctx, self, g.actions, "onTick") end
            end
        end
        self.nextTickTurn = currentTurn + (tonumber(ct.tickIntervalTurns) or 1)
    end

    -- Decrement remainingTurns only once per turn (not once per tick when there are multiple ticks per turn)
    local shouldDecrement = not self.lastDecrementTurn or self.lastDecrementTurn < currentTurn
    if shouldDecrement then
        self.remainingTurns = math.max(0, (self.remainingTurns or 0) - 1)
        self.lastDecrementTurn = currentTurn

        -- Broadcast updated cast progress to group
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if Broadcast then
            -- Get primary target (first from precast or self)
            local targetId = nil
            if self.targetSets and self.targetSets.precast and #self.targetSets.precast > 0 then
                local firstTargetKey = self.targetSets.precast[1]
                if firstTargetKey then
                    local ev = RPE.Core.ActiveEvent
                    if ev and ev.units and ev.units[firstTargetKey] then
                        targetId = ev.units[firstTargetKey].id
                    end
                end
            end
            
            Broadcast:SendCasting(self.caster, self.def.id, self.def.name, self.def.icon, self.remainingTurns, tonumber(self.def.cast.turns) or 1, targetId)
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
    -- Check if this cast was interrupted (via unit flag or spell flag)
    local casterUnit = RPE.Common:FindUnitById(self.caster)
    local isInterrupted = self.wasInterrupted or (casterUnit and casterUnit._wasInterrupted)
    
    if isInterrupted then
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("Resolve skipped: Cast was interrupted"):format())
        end
        -- Clear the interrupt flag so it doesn't affect future casts
        if casterUnit then
            casterUnit._wasInterrupted = nil
        end
    else
        if ctx.resources then ctx.resources:Spend(self._costSnapshot, "onResolve", self.def) end

        for i, g in ipairs(self.def.groups or {}) do
            local ok, reason, code = evalGroupRequirements(ctx, self, g)
            if ok then
                RPE.Debug:Internal(("→ Running group %d (onResolve)"):format(i))
                runActions(ctx, self, g.actions, "onResolve")
            else
                RPE.Debug:Warning(("→ Skipped group %d (onResolve): %s [%s]"):format(
                    i, tostring(reason or "unknown"), tostring(code or "???")
                ))
            end
        end
    end

    -- Unhide the caster if they are currently hidden
    if casterUnit and casterUnit.hidden then
        casterUnit.hidden = false
        
        -- Broadcast unhide to all players
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if Broadcast and Broadcast.Unhide then
            Broadcast:Unhide(self.caster)
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

    -- Broadcast clear casting to group
    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast then
        Broadcast:SendClearCasting(self.caster)
    end

    RPE.Debug:Internal(("Resolving %s at Rank %d"):format(self.def.name or "?", self.def.rank or 1))
end


-- Stage 5: Interrupt
function SpellCast:Interrupt(ctx, reason)
    self.wasInterrupted = true

    for _, g in ipairs(self.def.groups or {}) do
        if g.phase == "onInterrupt" then
            local ok = (select(1, evalGroupRequirements(ctx, self, g)))
            if ok then runActions(ctx, self, g.actions, "onInterrupt") end
        end
    end

    if ctx and ctx.resources then ctx.resources:Refund(self._costSnapshot) end

    -- Clear cast from registry
    if ctx.event and ctx.event.ClearCast then
        ctx.event:ClearCast(self.caster)
    end

    -- Broadcast clear casting to group
    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast then
        Broadcast:SendClearCasting(self.caster)
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

-- Get crit chance from action override or ruleset
-- Parse dice specification (e.g., "1d20", "2d6", "1d100") and return max value
local function _parseDiceMax(rollSpec)
    if type(rollSpec) ~= "string" then return 1 end
    -- Match pattern like "1d20" or "2d8" (count and sides)
    local count, sides = rollSpec:match("(%d+)[dD](%d+)")
    if count and sides then
        return tonumber(count) * tonumber(sides)
    end
    return 1  -- Default fallback
end

local function _getCritParams(act, ctx, cast, casterUnit, rollSpec)
    -- Crit threshold based on dice maximum value minus crit modifier from spell action
    -- E.g., 1d20 (max 20) with 5% crit modifier = threshold is 19 (or 95% of the roll must be made)
    
    local diceMax = _parseDiceMax(rollSpec) or 1
    
    -- Helper to get stat from either unit (for NPCs) or RPE.Stats (for players)
    local function getStat(statId)
        -- For NPCs, use unit stats
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            return tonumber(casterUnit.stats[statId] or 0) or 0
        end
        -- For players, use RPE.Stats
        return tonumber(RPE.Stats:GetValue(statId) or 0) or 0
    end
    
    -- Get crit modifier from spell action args, with fallback to SPELL_CRIT stat
    local spellCrit = 0
    
    -- First, check action args for crit modifier
    if act and act.args and act.args.critModifier then
        if type(act.args.critModifier) == "string" then
            local id = act.args.critModifier:match("^%$stat%.([%w_]+)%$$")
            if id then
                spellCrit = getStat(id)
            else
                spellCrit = tonumber(act.args.critModifier) or 0
            end
        else
            spellCrit = tonumber(act.args.critModifier) or 0
        end
    end
    
    -- If no action override, fall back to SPELL_CRIT stat
    if spellCrit == 0 then
        spellCrit = getStat("SPELL_CRIT")
    end
    
    -- Calculate crit threshold: max - (spellCrit as percentage of max)
    -- E.g., max=20, spellCrit=5 → threshold = 20 - 1 = 19 (top 5%)
    local critThreshold = diceMax - (diceMax * spellCrit / 100)
    
    if RPE and RPE.Debug and RPE.Debug.Print then
        local source = "stat:SPELL_CRIT"
        if act and act.args and act.args.critModifier then
            source = "action:critModifier"
        end
        RPE.Debug:Internal(("[SpellCast] Crit threshold: diceMax=%d, spellCrit=%.1f%% (from %s), threshold=%.1f"):format(diceMax, spellCrit, source, critThreshold))
    end
    
    -- crit multiplier from stat (defaults to 2x)
    local critMult = 2
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(("[SpellCast] _getCritParams: act.key=%s, act.critMult=%s (action-level), caster.isNPC=%s"):format(
            tostring(act and act.key), tostring(act and act.critMult), tostring(casterUnit and casterUnit.isNPC)))
        if act and act.args then
            RPE.Debug:Internal(("[SpellCast] act.args.critMult=%s (args-level)"):format(
                tostring(act.args.critMult)))
        end
    end
    
    -- Helper function to resolve crit multiplier value
    local function resolveCritMultValue(val)
        if type(val) == "string" then
            local id = val:match("^%$stat%.([%w_]+)%$$")
            if id then
                local statVal = getStat(id)
                return (statVal and statVal > 0) and statVal or 2
            else
                local n = tonumber(val)
                return (n and n > 0) and n or 2
            end
        else
            local n = tonumber(val)
            return (n and n > 0) and n or 2
        end
    end
    
    -- Check action-scoped critMult FIRST (this is where the schema puts it with scope="action")
    if act and act.critMult then
        critMult = resolveCritMultValue(act.critMult)
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("[SpellCast] Using action-level critMult: %s → %.1f"):format(tostring(act.critMult), critMult))
        end
    -- Then check args-scoped critMult for backwards compatibility
    elseif act and act.args and act.args.critMult then
        critMult = resolveCritMultValue(act.args.critMult)
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("[SpellCast] Using args-level critMult: %s → %.1f"):format(tostring(act.args.critMult), critMult))
        end
    else
        -- Default: look for CRIT_MULTIPLIER stat, fallback to 2x
        local statVal = getStat("CRIT_MULTIPLIER")
        if statVal and statVal > 0 then
            critMult = statVal
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(("[SpellCast] Using CRIT_MULTIPLIER stat: %.1f"):format(critMult))
            end
        else
            critMult = 2
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(("[SpellCast] No crit multiplier found, using default: 2.0"):format())
            end
        end
    end
    
    return critThreshold, critMult
end

---Determine if a roll is a critical strike
---@param roll number
---@param critThreshold number
---@return boolean isCrit
local function _checkCrit(roll, critThreshold)
    return roll >= critThreshold
end

-- Check hit for NPC target (complex/simple/ac systems)
local function _checkHitVsNPC(tgtUnit, casterUnit, hitSystem, rollSpec, baseThreshold, attMod, thresholdIds, critThreshold)
    local roll = RPE.Common:Roll(rollSpec)
    local lhs = roll + attMod
    local defThr = 0
    
    -- Check for crit: roll >= critThreshold
    local isCrit = _checkCrit(roll, critThreshold)
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(("  Crit check (NPC): roll=%d >= threshold=%.1f → %s"):format(roll, critThreshold, isCrit and "CRIT" or "normal"))
    end
    
    -- Check if target is failing all defences due to crowd control
    local ev = RPE.Core.ActiveEvent
    if ev and ev._auraManager and ev._auraManager:IsFailingAllDefences(tgtUnit.id) then
        return true, roll, lhs, 0, isCrit  -- Always hits when target fails all defences
    end
    
    if hitSystem == "simple" then
        -- Simple: always use DEFENCE stat
        if tgtUnit and tgtUnit.stats then
            defThr = tonumber(tgtUnit.stats.DEFENCE) or 0
        end
        local rhs = baseThreshold + defThr
        return lhs >= rhs, roll, lhs, defThr, isCrit  -- Return isCrit
    elseif hitSystem == "ac" then
        -- AC: roll against AC value directly (no base threshold added)
        if tgtUnit and tgtUnit.stats then
            local ac = tonumber(tgtUnit.stats.AC) or 0
            return lhs >= ac, roll, lhs, ac, isCrit
        end
        return lhs >= baseThreshold, roll, lhs, baseThreshold, isCrit
    else
        -- Complex (default): use specified thresholds
        if #thresholdIds > 0 and tgtUnit and tgtUnit.stats then
            -- NPC: choose the highest stat
            for _, id in ipairs(thresholdIds) do
                local val = tonumber(tgtUnit.stats[id]) or 0
                -- Check if this specific defence stat is failing due to crowd control
                if ev and ev._auraManager and ev._auraManager:IsDefenceStatFailing(tgtUnit.id, id) then
                    val = 0  -- Defence stat is disabled by crowd control
                end
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(("[SpellCast] Threshold stat " .. tostring(id) .. " = " .. tostring(val)))
                end
                if val > defThr then defThr = val end
            end
        end
        local rhs = baseThreshold + defThr
        return lhs >= rhs, roll, lhs, defThr, isCrit  -- Return isCrit
    end
end

-- Check hit for player target (complex/simple systems need player choice, ac is automatic)
local function _checkHitVsPlayer(tgtUnit, casterUnit, hitSystem, rollSpec, baseThreshold, attMod, thresholdIds, critThreshold)
    if hitSystem == "ac" then
        -- AC: automatic, no player choice needed
        local roll = RPE.Common:Roll(rollSpec)
        local ac = (tgtUnit and tgtUnit.stats and tonumber(tgtUnit.stats.AC)) or 0
        local lhs = roll + attMod
        local rhs = ac
        local isCrit = _checkCrit(roll, critThreshold)
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("  Crit check (Player AC): roll=%d >= threshold=%.1f → %s"):format(roll, critThreshold, isCrit and "CRIT" or "normal"))
        end
        return lhs >= rhs, roll, lhs, rhs, isCrit
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
        local isCrit = roll >= critThreshold
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("  Crit check (Player %s): roll=%d >= threshold=%.1f → %s"):format(hitSystem:upper(), roll, critThreshold, isCrit and "CRIT" or "normal"))
        end
        return lhs >= rhs, roll, lhs, rhs, isCrit
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
        -- No hit check needed, but we still need rolls for crit purposes
        -- Always generate rolls and store them
        local rollSpec, baseThreshold, mode = _hitParams(act, ctx)
        local casterUnit = RPE.Common:FindUnitById(cast.caster)
        local critThreshold, critMult = _getCritParams(act, ctx, cast, casterUnit, rollSpec)
        
        act._critThreshold = critThreshold
        act._critMult = critMult
        act._rolls = {}
        
        for _, ref in ipairs(targets) do
            local roll = RPE.Common:Roll(rollSpec)
            act._rolls[ref] = roll
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(("  Generated roll for target %s: %d"):format(tostring(ref), roll))
            end
        end
        
        -- All hits (no hit check), crit check is handled separately
        return targets, {}
    end

    local hitSystem = _getHitSystem()
    local rollSpec, baseThreshold, mode = _hitParams(act, ctx)
    baseThreshold = tonumber(baseThreshold) or 10

    -- attacker / caster
    local casterUnit = RPE.Common:FindUnitById(cast.caster)

    -- Get crit parameters from action or ruleset
    local critThreshold, critMult = _getCritParams(act, ctx, cast, casterUnit, rollSpec)
    -- Store for use in action handlers if needed
    act._critThreshold = critThreshold
    act._critMult = critMult

    -- parse attacker modifier ID
    local attId = act.hitModifier and act.hitModifier:match("^%$stat%.([%w_]+)%$$")
    local attMod = 0
    if attId then
        -- For NPCs, use unit stats; for players, use RPE.Stats
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            attMod = tonumber(casterUnit.stats[attId] or 0) or 0
        else
            attMod = RPE.Stats:GetValue(attId) or 0
        end
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
    
    -- Initialize roll storage for this action
    act._rolls = {}

    local hits, misses = {}, {}
    local playerTargets = {}  -- Track player targets for broadcasting attacks
    
    for i = 1, #targets do
        local ref = targets[i]
        local tgtUnit = RPE.Common:FindUnitByKey(ref) or nil

        -- Determine if target is NPC or player
        local isNPC = tgtUnit and tgtUnit.isNPC
        
        local hitResult, roll, lhs, rhs, isCrit
        if isNPC then
            hitResult, roll, lhs, rhs, isCrit = _checkHitVsNPC(tgtUnit, casterUnit, hitSystem, 
                                                        singleRoll or rollSpec, baseThreshold, attMod, thresholdIds, critThreshold)
        else
            -- For player targets, we need to broadcast the attack and let them defend
            roll = singleRoll or RPE.Common:Roll(rollSpec)
            lhs = roll + attMod
            isCrit = _checkCrit(roll, critThreshold)
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(("  Crit check (Player target): roll=%d >= threshold=%.1f → %s"):format(roll, critThreshold, isCrit and "CRIT" or "normal"))
            end
            
            -- Store player target info for broadcasting after the loop
            playerTargets[#playerTargets+1] = {
                ref = ref,
                unit = tgtUnit,
                thresholdIds = thresholdIds,
                roll = roll,
                attackRoll = lhs,  -- Total roll + modifier
                isCrit = isCrit,
            }
            -- Don't include player targets in hits/misses - they're handled via broadcast/reaction
            hitResult = false
            rhs = 0  -- Will be determined by player's choice
        end
        
        -- Store the roll for this target so handlers can access it
        act._rolls[ref] = roll

        if hitResult then
            if RPE and RPE.Debug and RPE.Debug.Print then
                if hitSystem == "ac" then
                    RPE.Debug:Internal((' > Hit: %s (%d + %d vs %d) [%s]%s')
                        :format(tostring(ref), roll or 0, attMod, rhs or 0, hitSystem, isCrit and " CRIT" or ""))
                else
                    RPE.Debug:Internal((' > Hit: %s (%d + %d vs %d + %d) [%s]%s')
                        :format(tostring(ref), roll or 0, attMod, baseThreshold, rhs or 0, hitSystem, isCrit and " CRIT" or ""))
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
            
            -- Display "Miss" floating text for NPC targets only (player targets handled via reaction system)
            if isNPC and tgtUnit then
                local fct = RPE.Core and RPE.Core.CombatText and RPE.Core.CombatText.Screen
                if fct then
                    fct:AddText("Miss", {
                        color = { 1.0, 1.0, 1.0, 1.0 },  -- white
                        duration = 1.5,
                        distance = 60,
                        direction = "UP"  -- floating upwards
                    })
                end
            end
        end
    end

    -- Prepare player target data for aggregation (broadcast happens in runActions after all DAMAGE actions)
    local playerTargetDataArray = {}
    
    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    -- This needs to happen BEFORE damage calculation, regardless of target type
    local profile = cast and cast.profile
    if not profile and cast and cast.caster then
        -- Find the caster unit to check if it's an NPC
        local casterUnit = RPE.Common:FindUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            -- For NPCs, create a wrapper that acts like a profile with their stats
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end
    
    if #playerTargets > 0 then
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
                    amt = tonumber(Formula:Roll(act.args.amount, profile)) or 0
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
                        local perRankAmt = tonumber(Formula:Roll(act.args.perRank, profile)) or 0
                        amt = amt + (perRankAmt * (rank - 1))
                    end
                end
            end
            
            local school = (act.args.school) or "Physical"
            -- If school is a weapon token like "$wep.ranged$", resolve to the caster's
            -- equipped weapon's damageSchool property (if present).
            if type(school) == "string" then
                local slot = school:match("^%$wep%.([%w_]+)%$")
                if slot then
                    local norm = string.lower(slot)
                    if norm == "mh" then norm = "mainhand"
                    elseif norm == "oh" then norm = "offhand"
                    elseif norm == "rng" or norm == "wand" then norm = "ranged" end

                    -- Try to resolve equipped item from profile (GetEquipped API) or equipment table
                    local item = nil
                    if profile and type(profile.GetEquipped) == "function" then
                        local ok, id = pcall(profile.GetEquipped, profile, norm)
                        if ok and id then
                            if type(id) == "table" then item = id end
                            if type(id) == "string" then
                                local reg = RPE.Core and RPE.Core.ItemRegistry
                                if reg and type(reg.Get) == "function" then
                                    local ok2, def = pcall(reg.Get, reg, id)
                                    if ok2 and def then item = def end
                                end
                            end
                        end
                    end
                    if not item and profile and type(profile.equipment) == "table" then
                        local ent = profile.equipment[norm]
                        if ent then
                            if type(ent) == "table" then item = ent end
                            if type(ent) == "string" then
                                local reg = RPE.Core and RPE.Core.ItemRegistry
                                if reg and type(reg.Get) == "function" then
                                    local ok2, def = pcall(reg.Get, reg, ent)
                                    if ok2 and def then item = def end
                                end
                            end
                        end
                    end

                    if item then
                        local d = (type(item) == "table") and (item.data or item) or {}
                        local ds = d.damageSchool or d.school or d.damage_school
                        if ds and type(ds) == "string" and ds ~= "" then
                            school = ds
                        else
                            school = "Physical"  -- default if item has no damage school
                        end
                    else
                        school = "Physical"  -- default if weapon not found
                    end
                end
            end
            
            -- Apply fudge factor from ruleset (default: 0)
            local fudge = 0
            if RPE.ActiveRules then
                local fudgeVal = RPE.ActiveRules:Get("fudge", 0)
                if type(fudgeVal) == "string" then
                    local Formula = RPE.Core and RPE.Core.Formula
                    fudge = (Formula and Formula.Roll and tonumber(Formula:Roll(fudgeVal, profile))) or 0
                else
                    fudge = tonumber(fudgeVal) or 0
                end
            end
            amt = amt + fudge
            
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
                                            amt = tonumber(Formula:Roll(trigger.action.args.amount, profile)) or 0
                                        else
                                            amt = tonumber(trigger.action.args.amount) or 0
                                        end
                                    else
                                        amt = tonumber(trigger.action.args.amount) or 0
                                    end
                                    
                                    -- Apply fudge factor from ruleset (default: 0)
                                    local fudge = 0
                                    if RPE.ActiveRules then
                                        local fudgeVal = RPE.ActiveRules:Get("fudge", 0)
                                        if type(fudgeVal) == "string" then
                                            local Formula = RPE.Core and RPE.Core.Formula
                                            fudge = (Formula and Formula.Roll and tonumber(Formula:Roll(fudgeVal, profile))) or 0
                                        else
                                            fudge = tonumber(fudgeVal) or 0
                                        end
                                    end
                                    amt = amt + fudge
                                    
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
        
        -- Build playerTargetDataArray for aggregation in runActions
        for _, ptgt in ipairs(playerTargets) do
            if ptgt.unit then
                -- Apply crit multiplier to damage if this was a critical hit
                local finalDamageBySchool = {}
                for school, amount in pairs(damageBySchool) do
                    if ptgt.isCrit then
                        -- Apply the crit multiplier that was calculated in _getCritParams
                        amount = math.floor(amount * critMult)
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[SpellCast] Applying crit multiplier to player attack: damage×%.1f'):format(critMult))
                        end
                    end
                    finalDamageBySchool[school] = amount
                end
                
                -- Prepare aura effects with crit flag
                local allEffects = {}
                for _, effect in ipairs(auraEffects or {}) do
                    table.insert(allEffects, effect)
                end
                
                -- Add crit flag as metadata if this hit was critical
                if ptgt.isCrit then
                    table.insert(allEffects, {
                        auraId = "CRIT_FLAG",
                        actionKey = "METADATA",
                        argsJSON = "isCrit=true",
                    })
                end
                
                -- Store for aggregation in runActions
                table.insert(playerTargetDataArray, {
                    unit = ptgt.unit,
                    hitSystem = hitSystem,
                    thresholdIds = thresholdIds,
                    attackRoll = ptgt.attackRoll,
                    isCrit = ptgt.isCrit,
                    damageBySchool = finalDamageBySchool,
                    auraEffects = allEffects,
                })
            end
        end
    end

    return hits, misses, playerTargetDataArray
end

return SpellCast

