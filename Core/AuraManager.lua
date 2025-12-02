-- RPE/Core/AuraManager.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local AuraRegistry = assert(RPE.Core.AuraRegistry, "AuraRegistry required")
local Aura         = assert(RPE.Core.Aura, "Aura required")
local AuraEvents   = assert(RPE.Core.AuraEvents, "AuraEvents required")
local SpellActions = assert(RPE.Core.SpellActions, "SpellActions required")
local StatMods     = assert(RPE.Core.StatModifiers, "StatModifiers required")
local Broadcast    = assert(RPE.Core.Comms.Broadcast, "Broadcast required")
local AuraTriggers = assert(RPE.Core.AuraTriggers, "AuraTriggers required")

StatMods.aura     = StatMods.aura     or {}  -- totals per-profile per-stat (BUCKETS)
StatMods.auraInst = StatMods.auraInst or {}  -- per-instance per-stat (BUCKETS)

---@class AuraManager
---@field event table|nil
---@field aurasByUnit table<string, table<Aura>>
---@field _netSquelch any
local AuraManager = {}
AuraManager.__index = AuraManager
RPE.Core.AuraManager = AuraManager

-- ===== Utilities =====
local function _tagIndex(t)
    local idx = {}
    for _, v in ipairs(t or {}) do idx[v] = true end
    return idx
end

-- helper: am I the authority for this aura's *source*? (local player or NPC when leader/solo)
local function _isLocalOwnerOfSource(a)
    if not Common or not Common.FindUnitById or not Common.IsAuraStatsEligibleTarget then return false end
    local su = select(1, Common:FindUnitById(a.sourceId or a.source))
    return Common:IsAuraStatsEligibleTarget(su)
end

-- Returns true iff this client owns the aura's source (player owner or NPC + group leader/solo).
local function isSource(a)
    local source = a.sourceId
    local playerId = RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
    return source == playerId
end

-- Does immunity (table) block a target aura def?
local function _immunityBlocks(imm, targetDef)
    if not imm or not targetDef then return false end
    if imm.helpful == true and targetDef.isHelpful then return true end
    if imm.harmful == true and not targetDef.isHelpful then return true end

    if imm.dispelTypes and targetDef.dispelType then
        local want = _tagIndex(imm.dispelTypes)
        if want[string.upper(targetDef.dispelType)] or want[targetDef.dispelType] then return true end
    end

    if imm.tags and targetDef.tags then
        local want = _tagIndex(imm.tags)
        for _, tg in ipairs(targetDef.tags) do
            if want[tg] then return true end
        end
    end

    if imm.ids then
        local want = _tagIndex(imm.ids)
        if want[targetDef.id] then return true end
    end

    return false
end

function AuraManager:_applyImmunitySweepFor(a)
    local def = AuraRegistry:Get(a.id)
    if not def then return end
    
    -- Check if immunity has actual content
    if not def.immunity then return end
    if not (def.immunity.helpful == true or def.immunity.harmful == true or 
            (def.immunity.dispelTypes and #def.immunity.dispelTypes > 0) or
            (def.immunity.tags and #def.immunity.tags > 0) or
            (def.immunity.ids and #def.immunity.ids > 0)) then
        return
    end
    
    local list = self:All(a.targetId)
    if #list == 0 then return end

    for i = #list, 1, -1 do
        local other = list[i]
        if other.instanceId ~= a.instanceId then
            local odef = AuraRegistry:Get(other.id)
            if _immunityBlocks(def.immunity, odef) then
                self:_onRemoved(other, "IMMUNE_PURGE")
                table.remove(list, i)
            end
        end
    end
    -- Stats will be recomputed by the caller that invoked this (we call it from _onApplied)
end

-- helpers (top of AuraManager.lua)
local function NewBucket()
    return { ADD = 0, PCT_ADD = 0, MULT = 1, FINAL_ADD = 0 }
end

local function AccumBucket(dst, src)
    dst.ADD       = (dst.ADD or 0)       + (src.ADD or 0)
    dst.PCT_ADD   = (dst.PCT_ADD or 0)   + (src.PCT_ADD or 0)
    dst.MULT      = (dst.MULT or 1)      * (src.MULT or 1)
    dst.FINAL_ADD = (dst.FINAL_ADD or 0) + (src.FINAL_ADD or 0)
end

local function SubtractBucket(dst, src)
    dst.ADD       = (dst.ADD or 0)       - (src.ADD or 0)
    dst.PCT_ADD   = (dst.PCT_ADD or 0)   - (src.PCT_ADD or 0)
    dst.MULT      = (dst.MULT or 1)      / ((src.MULT or 1) ~= 0 and (src.MULT or 1) or 1)
    dst.FINAL_ADD = (dst.FINAL_ADD or 0) - (src.FINAL_ADD or 0)
end

local function MakeBucketFromModifier(m, stacks)
    local b = NewBucket()
    local amt  = (tonumber(m.value) or 0) * (m.scaleWithStacks and (stacks or 1) or 1)
    local mode = string.upper(m.mode or "ADD")
    if     mode == "ADD" or mode == "FLAT" then b.ADD       = amt
    elseif mode == "PCT_ADD"               then b.PCT_ADD   = amt
    elseif mode == "MULT" or mode == "PCT_MULT" then b.MULT = 1 + (amt / 100)
    elseif mode == "FINAL_ADD"             then b.FINAL_ADD = amt
    else b.ADD = amt end
    return b
end

-- Build per-instance modifiers table: { [statId] = amount }
local function _computeInstanceMods(self, inst, targetProfile)
    local def = AuraRegistry:Get(inst.id)
    if not def or not def.modifiers or #def.modifiers == 0 then return nil end

    -- Only use caster profile if the caster is the local player
    local casterProfile = nil
    if inst.sourceId or inst.source then
        local cu = select(1, Common:FindUnitById(inst.sourceId or inst.source))
        if Common:IsAuraStatsEligibleTarget(cu) then
            casterProfile = RPE.Profile.DB.GetOrCreateActive()
        end
    end

    local sums = {}  -- [statId] = BUCKET
    for _, m in ipairs(def.modifiers) do
        local statId = m.stat or m.id
        if statId then
            -- amount (supports string formulas + $stat$)
            local amt = m.value or m.amount or 0
            if type(amt) == "string" and RPE.Core.Formula then
                local ctx = (m.source == "CASTER") and (casterProfile or targetProfile) or targetProfile
                amt = RPE.Core.Formula:Roll(amt, ctx)
            end
            amt = tonumber(amt) or 0
            if m.scaleWithStacks ~= false then
                amt = amt * (inst.stacks or 1)
            end

            -- Ruleset gate (if any)
            local ok = true
            if targetProfile and targetProfile.stats and RPE.ActiveRules then
                local statObj = targetProfile.stats[statId]
                if statObj and not RPE.ActiveRules:IsStatEnabled(statId, statObj.category) then
                    ok = false
                end
            end

            if ok then
                local b = NewBucket()
                local mode = string.upper(m.mode or "ADD")
                if     mode == "ADD" or mode == "FLAT" then b.ADD       = amt
                elseif mode == "PCT_ADD"               then b.PCT_ADD   = amt
                elseif mode == "MULT" or mode == "PCT_MULT" then b.MULT = 1 + (amt / 100)
                elseif mode == "FINAL_ADD"             then b.FINAL_ADD = amt
                else b.ADD = amt end

                local acc = sums[statId] or NewBucket()
                AccumBucket(acc, b)
                sums[statId] = acc
            end
        end
    end
    return sums
end



local function _notifyStatChanged(statId)
    if _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.StatisticSheet then
        _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(statId)
    end
end

-- Add a new instance's mods into totals
local function _addInstanceMods(pid, instId, mods)
    if not mods or not next(mods) then return end
    StatMods.aura[pid]     = StatMods.aura[pid]     or {}
    StatMods.auraInst[pid] = StatMods.auraInst[pid] or {}
    StatMods.auraInst[pid][instId] = mods

    for statId, b in pairs(mods) do
        local total = StatMods.aura[pid][statId] or NewBucket()
        AccumBucket(total, b)
        StatMods.aura[pid][statId] = total
        _notifyStatChanged(statId)
    end
end


-- Recompute one instance and adjust totals by delta
local function _updateInstanceMods(self, inst, pid, targetProfile)
    StatMods.aura[pid]     = StatMods.aura[pid]     or {}
    StatMods.auraInst[pid] = StatMods.auraInst[pid] or {}

    local old = StatMods.auraInst[pid][inst.instanceId] or {}
    local new = _computeInstanceMods(self, inst, targetProfile) or {}

    -- union of statIds
    local seen = {}
    for k in pairs(old) do seen[k] = true end
    for k in pairs(new) do seen[k] = true end

    for statId in pairs(seen) do
        local total = StatMods.aura[pid][statId] or NewBucket()
        local oldB  = old[statId] or NewBucket()
        local newB  = new[statId] or NewBucket()
        SubtractBucket(total, oldB)
        AccumBucket(total, newB)
        StatMods.aura[pid][statId] = total
        _notifyStatChanged(statId)
    end

    StatMods.auraInst[pid][inst.instanceId] = new
end


-- Remove an instance's contribution from totals
local function _removeInstanceMods(pid, instId)
    local instMods = StatMods.auraInst[pid] and StatMods.auraInst[pid][instId]
    if not instMods then return end

    StatMods.aura[pid] = StatMods.aura[pid] or {}
    for statId, b in pairs(instMods) do
        local total = StatMods.aura[pid][statId] or NewBucket()
        SubtractBucket(total, b)
        StatMods.aura[pid][statId] = total
        _notifyStatChanged(statId)
    end

    StatMods.auraInst[pid][instId] = nil
end


local function toUnitId(x)
    -- If already number
    if type(x) == "number" then return x end

    -- If EventUnit table
    if type(x) == "table" and x.id then
        return tonumber(x.id)
    end

    -- If key string, resolve via ActiveEvent
    if type(x) == "string" then
        local ev = RPE.Core.ActiveEvent
        if ev and ev.units then
            local u = ev.units[x:lower()]
            if u and u.id then return tonumber(u.id) end
        end
    end

    return nil
end


local function forUnit(self, unitId, create)
    if not self.aurasByUnit then
        RPE.Debug:Error("aurasByUnit not found.")
    end

    local map = self.aurasByUnit[unitId]
    if not map and create then
        map = {}
        self.aurasByUnit[unitId] = map
    end
    return map
end

local function forSource(self, sourceId, create)
    local map = self.aurasBySource[sourceId]
    if not map and create then
        map = {}
        self.aurasBySource[sourceId] = map
    end
    return map
end

---Create a manager (usually per-Event).
---@param event table|nil
function AuraManager.New(event)
    RPE.Debug:Internal(">> Created the Aura Manager.")
    local o = {
        event = event,
        aurasByUnit = {},
        aurasBySource = {}, 
        listeners = {},        -- <function(ev, aura, payload, mgr)>
    }
    return setmetatable(o, AuraManager)
end

function AuraManager:All(unit)
    local uId = toUnitId(unit)
    if not uId then return {} end
    return forUnit(self, uId, false) or {}
end

function AuraManager:AllBySource(source)
    local sId = toUnitId(source)
    if not sId then return {} end
    return forSource(self, sId, false) or {}
end

function AuraManager:Find(unit, predicate)
    local list = self:All(unit)
    local out = {}
    for _, a in ipairs(list) do
        if not predicate or predicate(a) then
            table.insert(out, a)
        end
    end
    return out
end

function AuraManager:Has(unit, auraId, fromSource)
    local list = self:All(unit)
    for _, a in ipairs(list) do
        if a.id == auraId and (not fromSource or a.sourceId == toUnitId(fromSource)) then
            return true, a
        end
    end
    return false, nil
end

-- ===== Conflict helpers =====
local function chooseByPolicy(policy, existing, newMagnitude, newestInstance)
    if policy == AuraRegistry.CONFLICT.KEEP_LATEST then
        return newestInstance
    elseif policy == AuraRegistry.CONFLICT.KEEP_HIGHER then
        -- For simplicity: compare stacks as proxy magnitude (custom games can override)
        local best = newestInstance
        for _, inst in ipairs(existing) do
            if (inst.stacks or 1) > (best.stacks or 1) then
                best = inst
            end
        end
        return best
    elseif policy == AuraRegistry.CONFLICT.BLOCK_IF_PRESENT then
        return existing[1]   -- "keep some existing" -> means ignore new (caller will see this)
    end
    return newestInstance
end

-- Sum all aura modifiers currently affecting a specific target and write them into StatModifiers.aura.
-- Only applies if the target is the local player. Never touches other players/NPCs.
function AuraManager:_recomputeStatModsForTarget(targetId)
    local ev = self.event or RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end

    -- Find unit object by numeric id
    local unit
    for _, u in pairs(ev.units) do
        if tonumber(u.id) == tonumber(targetId) then unit = u; break end
    end
    if not unit then return end

    -- Only proceed if the target is the local player
    local tu = select(1, Common:FindUnitById(targetId))
    if not (tu and Common:IsAuraStatsEligibleTarget(tu)) then return end

    local targetProfile = RPE.Profile.DB.GetOrCreateActive()
    if not targetProfile then return end
    local pid = targetProfile.name

    local Formula      = RPE.Core.Formula
    local AuraRegistry = RPE.Core.AuraRegistry

    -- Collect buckets from all live auras on the target
    local sums = {} -- [statId] = BUCKET
    for _, inst in ipairs(self:All(targetId)) do
        local def = AuraRegistry and AuraRegistry:Get(inst.id)
        if def and def.modifiers and #def.modifiers > 0 then
            -- caster profile context only if caster is local
            local casterProfile = nil
            if inst.sourceId or inst.source then
                local cu = select(1, Common:FindUnitById(inst.sourceId or inst.source))
                if Common:IsAuraStatsEligibleTarget(cu) then
                    casterProfile = RPE.Profile.DB.GetOrCreateActive()
                end
            end

            for _, m in ipairs(def.modifiers) do
                local statId = m.stat or m.id
                if statId then
                    local amt = m.value or m.amount or 0
                    if type(amt) == "string" and Formula then
                        local ctxProfile = (m.source == "CASTER") and (casterProfile or targetProfile) or targetProfile
                        amt = Formula:Roll(amt, ctxProfile)
                    end
                    amt = tonumber(amt) or 0
                    if m.scaleWithStacks ~= false then
                        amt = amt * (inst.stacks or 1)
                    end

                    local ok = true
                    if targetProfile and targetProfile.stats and RPE.ActiveRules then
                        local statObj = targetProfile.stats[statId]
                        if statObj and not RPE.ActiveRules:IsStatEnabled(statId, statObj.category) then
                            ok = false
                        end
                    end
                    if ok then
                        local b = NewBucket()
                        local mode = string.upper(m.mode or "ADD")
                        if     mode == "ADD" or mode == "FLAT" then b.ADD       = amt
                        elseif mode == "PCT_ADD"               then b.PCT_ADD   = amt
                        elseif mode == "MULT" or mode == "PCT_MULT" then b.MULT = 1 + (amt / 100)
                        elseif mode == "FINAL_ADD"             then b.FINAL_ADD = amt
                        else b.ADD = amt end

                        local acc = sums[statId] or NewBucket()
                        AccumBucket(acc, b)
                        sums[statId] = acc
                    end
                end
            end
        end
    end

    -- Write back totals for the local player's profile only
    local all = RPE.Core.StatModifiers
    all.aura[pid] = all.aura[pid] or {}

    -- zero/clear any stats that vanished
    for oldStatId, _ in pairs(all.aura[pid]) do
        if sums[oldStatId] == nil then
            all.aura[pid][oldStatId] = NewBucket()
            if _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.StatisticSheet then
                _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(oldStatId)
            end
        end
    end

    for statId, bucket in pairs(sums) do
        all.aura[pid][statId] = bucket
        if _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.StatisticSheet then
            _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(statId)
        end
    end
end




-- ===== Apply / Refresh / Extend / Remove =====
---@param source any  @unit key or unit table
---@param target any  @unit key or unit table
---@param auraId string
---@param opts table|nil  -- stacks, charges, snapshot, rngSeed, stackingPolicy override, uniqueByCaster override, extendTurns, refresh
function AuraManager:Apply(source, target, auraId, opts)
    opts = opts or {}
    local sId = toUnitId(source) or source
    local tId = toUnitId(target)
    assert(tId, "AuraManager.Apply: invalid target unit")

    local def = AuraRegistry:Get(auraId)
    assert(def, ("Unknown aura '%s'"):format(tostring(auraId)))

    local now  = (self.event and self.event.turn) or 0
    local list = forUnit(self, tId, true)

    -- ---------- Immunity gate (existing auras may block this new one) ----------
    local function tagIndex(t) local x = {}; for _,v in ipairs(t or {}) do x[v] = true end; return x end
    local function hasActualImmunity(imm)
        if not imm then return false end
        if imm.helpful == true or imm.harmful == true then return true end
        if imm.dispelTypes and #imm.dispelTypes > 0 then return true end
        if imm.tags and #imm.tags > 0 then return true end
        if imm.ids and #imm.ids > 0 then return true end
        return false
    end
    local function immunityBlocks(imm, targetDef)
        if not imm or not targetDef then return false end
        if imm.helpful == true and (targetDef.isHelpful) then return true end
        if imm.harmful == true and (not targetDef.isHelpful) then return true end
        if imm.dispelTypes and targetDef.dispelType then
            local want = tagIndex(imm.dispelTypes)
            local ty   = tostring(targetDef.dispelType)
            if want[ty] or want[ty:upper()] then return true end
        end
        if imm.tags and targetDef.tags then
            local want = tagIndex(imm.tags)
            for _, tg in ipairs(targetDef.tags or {}) do
                if want[tg] then return true end
            end
        end
        if imm.ids then
            local want = tagIndex(imm.ids)
            if want[targetDef.id] then return true end
        end
        return false
    end

    do
        for _, existing in ipairs(list) do
            local exDef = AuraRegistry:Get(existing.id)
            if exDef and immunityBlocks(exDef.immunity, def) then
                return false, "IMMUNE"
            end
        end
    end
    -- -------------------------------------------------------------------------

    -- Unique-by-caster filter (be robust to sourceId vs source in instances).
    local function matchesExisting(inst)
        if inst.id ~= def.id then return false end
        if def.uniqueByCaster or opts.uniqueByCaster then
            local instSource = inst.sourceId or inst.source
            return instSource == sId
        end
        return true
    end

    -- Handle uniqueGroup conflicts (KEEP_LATEST / KEEP_HIGHER / BLOCK_IF_PRESENT)
    if def.uniqueGroup then
        local groupExisting = {}
        for _, inst in ipairs(list) do
            local d = AuraRegistry:Get(inst.id)
            if d and d.uniqueGroup == def.uniqueGroup then
                table.insert(groupExisting, inst)
            end
        end
        if #groupExisting > 0 then
            if def.conflictPolicy == AuraRegistry.CONFLICT.BLOCK_IF_PRESENT then
                return false, "BLOCKED_BY_GROUP"
            elseif def.conflictPolicy == AuraRegistry.CONFLICT.KEEP_LATEST
                or def.conflictPolicy == AuraRegistry.CONFLICT.KEEP_HIGHER then
                local newInst = Aura.New(def, sId, tId, now, opts)
                local chosen  = chooseByPolicy(def.conflictPolicy, groupExisting, newInst.stacks, newInst)
                -- Remove all others in the group:
                for i = #list, 1, -1 do
                    local inst = list[i]
                    local d = AuraRegistry:Get(inst.id)
                    if d and d.uniqueGroup == def.uniqueGroup and inst ~= chosen then
                        self:_onRemoved(inst, "GROUP_CONFLICT")
                        table.remove(list, i)
                    end
                end
                if chosen == newInst then
                    table.insert(list, newInst)
                    self:_onApplied(newInst)
                    -- If the chosen one itself grants immunity, purge anything it blocks:
                    if def.immunity then
                        for i = #list, 1, -1 do
                            local other = list[i]
                            if other ~= newInst then
                                local odef = AuraRegistry:Get(other.id)
                                if immunityBlocks(def.immunity, odef) then
                                    self:_onRemoved(other, "IMMUNE_PURGE")
                                    table.remove(list, i)
                                end
                            end
                        end
                    end
                    return true, newInst
                else
                    -- Winner was an existing one; optionally refresh it according to policy if you prefer.
                    self:_onRefreshed(chosen)
                    return true, chosen
                end
            end
        end
    end

    -- Same-aura on target? (respect uniqueByCaster)
    local existing = nil
    for _, inst in ipairs(list) do
        if matchesExisting(inst) then existing = inst; break end
    end

    local policy = opts.stackingPolicy or def.stackingPolicy
    if existing then
        if policy == AuraRegistry.STACKING.ADD_MAGNITUDE then
            local changedStacks = existing:AddStacks(opts.stacks or 1)
            local touched = false
            if def.duration and def.duration.turns > 0 then
                touched = existing:RefreshDuration(now) or touched
            end
            self:_onRefreshed(existing, changedStacks or touched)
            return true, existing

        elseif policy == AuraRegistry.STACKING.REFRESH_DURATION then
            local touched = existing:RefreshDuration(now)
            self:_onRefreshed(existing, touched)
            return true, existing

        elseif policy == AuraRegistry.STACKING.EXTEND_DURATION then
            local extended = existing:ExtendDuration(opts.extendTurns or def.duration.turns or 0)
            self:_onRefreshed(existing, extended)
            return true, existing

        elseif policy == AuraRegistry.STACKING.REPLACE then
            for i = #list, 1, -1 do
                if matchesExisting(list[i]) then
                    self:_onRemoved(list[i], "REPLACED")
                    table.remove(list, i)
                end
            end
            local inst = Aura.New(def, sId, tId, now, opts)
            table.insert(list, inst)
            self:_onApplied(inst)
            if hasActualImmunity(def.immunity) then
                for i = #list, 1, -1 do
                    local other = list[i]
                    if other ~= inst then
                        local odef = AuraRegistry:Get(other.id)
                        if immunityBlocks(def.immunity, odef) then
                            self:_onRemoved(other, "IMMUNE_PURGE")
                            table.remove(list, i)
                        end
                    end
                end
            end
            return true, inst
        end
    end

    -- Fresh instance
    local inst = Aura.New(def, sId, tId, now, opts)
    table.insert(list, inst)
    self:_onApplied(inst)

    -- If this aura grants immunity, purge any conflicting auras already present.
    if hasActualImmunity(def.immunity) then
        for i = #list, 1, -1 do
            local other = list[i]
            if other ~= inst then
                local odef = AuraRegistry:Get(other.id)
                if odef and immunityBlocks(def.immunity, odef) then
                    self:_onRemoved(other, "IMMUNE_PURGE")
                    table.remove(list, i)
                end
            end
        end
    end

    return true, inst
end


---Remove by auraId (optionally by source).
function AuraManager:Remove(unit, auraId, fromSource)
    local tId = toUnitId(unit) or unit
    local sId = fromSource and (toUnitId(fromSource) or fromSource) or nil
    local list = self:All(tId)
    if #list == 0 then return 0 end
    local removed = 0

    for i = #list, 1, -1 do
        local a = list[i]
        if a.id == auraId and (not sId or a.sourceId == sId) then
            self:_onRemoved(a, "REMOVED")
            table.remove(list, i); removed = removed + 1
            -- also remove from source map if present
            local srcKey = tonumber(a.sourceId or a.source)
            local sList  = srcKey and forSource(self, srcKey, false)
            if sList then
                for j = #sList, 1, -1 do
                    if sList[j] == a then table.remove(sList, j); break end
                end
            end
        end
    end

    -- 🔔 Broadcast (only if *this* call caused removals, and not from network)
    if removed > 0 and Broadcast then
        Broadcast:AuraRemove(tId, auraId, sId) -- sId may be nil
    end

    return removed
end



---Dispel N auras of certain types (e.g., MAGIC/POISON), priority rule is simple oldest-first.
---@param unit any
---@param opts table  -- { types={"MAGIC","CURSE"}, max=1, helpful=false }
function AuraManager:Dispel(unit, opts)
    opts = opts or {}
    local tId = toUnitId(unit) or unit

    -- 🔔 Broadcast the intent first (once), others will run the same selection logic.
    if Broadcast and not self._netSquelch then
        Broadcast:AuraDispel(tId, opts.types or {}, opts.max or 1, opts.helpful == true)
    end


    local list = self:All(tId)
    if #list == 0 then return 0 end

    local types = {}
    for _, ty in ipairs(opts.types or {}) do types[ty] = true end

    local candidates = {}
    for _, a in ipairs(list) do
        local def = AuraRegistry:Get(a.id)
        if def and not def.unpurgable then
            if (opts.helpful == true and def.isHelpful)
            or (opts.helpful == false and not def.isHelpful) then
                if not types or not def.dispelType or types[def.dispelType] then
                    table.insert(candidates, a)
                end
            end
        end
    end

    table.sort(candidates, function(x, y) return (x.startTurn or 0) < (y.startTurn or 0) end)
    local count = 0
    local max = opts.max or 1
    for i = 1, math.min(#candidates, max) do
        self:_onRemoved(candidates[i], "DISPELLED")
        -- remove from unit list
        for j = #list, 1, -1 do
            if list[j] == candidates[i] then
                table.remove(list, j)
                break
            end
        end
        count = count + 1
    end

    return count
end

-- ===== Turn advancement =====

---Call at the start of the caster's turn.
function AuraManager:OnOwnerTurnStart(unit, turn)
    local casterId = toUnitId(unit) or unit
    if not casterId then return end

    -- 1) Ticks due at start (for auras cast by this unit)
    for _, list in pairs(self.aurasByUnit) do
        for _, a in ipairs(list) do
            if a.sourceId == casterId and a:CanTickAt(turn) then
                if isSource(a) then
                    self:_onTick(a, turn)   -- only the caster's owner executes effects
                end
                a:AdvanceTick(turn)         -- everyone advances schedule for UI sync
            end
        end
    end

    -- 2) Expire-at-start policy for auras cast by this unit
    local emptyTargets = {}
    for targetId, list in pairs(self.aurasByUnit) do
        for i = #list, 1, -1 do
            local a = list[i]
            local def = AuraRegistry:Get(a.id)
            if a.sourceId == casterId
               and def and def.duration
               and def.duration.expires == AuraRegistry.EXPIRE.ON_OWNER_TURN_START
               and a:IsExpiredAt(turn) then
                self:_onExpired(a)
                table.remove(list, i)
            end
        end
        if #list == 0 then
            table.insert(emptyTargets, targetId)
        end
    end
    for _, targetId in ipairs(emptyTargets) do
        self.aurasByUnit[targetId] = nil
    end

    -- 3) Hook (per-instance)
    for _, list in pairs(self.aurasByUnit) do
        for _, a in ipairs(list) do
            if a.sourceId == casterId then
                self:_onOwnerTurnStart(a, turn)
            end
        end
    end
end

---Call at the end of the caster's turn.
function AuraManager:OnOwnerTurnEnd(unit, turn)
    local casterId = toUnitId(unit) or unit
    if not casterId then return end

    -- Expire-at-end policy for auras cast by this unit
    local emptyTargets = {}
    for targetId, list in pairs(self.aurasByUnit) do
        for i = #list, 1, -1 do
            local a = list[i]
            local def = AuraRegistry:Get(a.id)
            if a.sourceId == casterId
               and def and def.duration
               and def.duration.expires == AuraRegistry.EXPIRE.ON_OWNER_TURN_END
               and a:IsExpiredAt(turn) then
                RPE.Debug:Internal(("[AuraManager:OnOwnerTurnEnd] Expiring '%s' (src=%s tgt=%s): nowTurn=%s expiresOn=%s")
                    :format(tostring(a.id), tostring(a.sourceId), tostring(a.targetId),
                            tostring(turn), tostring(a.expiresOn)))
                self:_onExpired(a)
                table.remove(list, i)
            end
        end
        -- Clean up empty target entries
        if #list == 0 then
            table.insert(emptyTargets, targetId)
        end
    end
    
    -- Remove empty entries
    for _, targetId in ipairs(emptyTargets) do
        self.aurasByUnit[targetId] = nil
    end

    -- Hook (per-instance)
    for _, list in pairs(self.aurasByUnit) do
        for _, a in ipairs(list) do
            if a.sourceId == casterId then
                self:_onOwnerTurnEnd(a, turn)
            end
        end
    end
end


---Execute tick actions for all auras that should tick this turn.
function AuraManager:OnTick(turn)
    local Common = RPE.Common
    local SpellActions = RPE.Core.SpellActions
    if not SpellActions then 
        RPE.Debug:Internal("[AuraManager:OnTick] SpellActions is nil!")
        return 
    end
    
    RPE.Debug:Internal(("[AuraManager:OnTick] Starting tick for turn %d"):format(turn))
    
    local totalAuras = 0
    local tickedAuras = 0
    
    for targetId, list in pairs(self.aurasByUnit) do
        totalAuras = totalAuras + #list
        RPE.Debug:Internal(("[AuraManager:OnTick] Target %s has %d auras"):format(tostring(targetId), #list))
        
        for _, aura in ipairs(list) do
            local canTick = aura:CanTickAt(turn)
            if RPE.Debug then
                RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s': CanTickAt(%d)=%s, nextTick=%s"):format(
                    tostring(aura.id), turn, tostring(canTick), tostring(aura.nextTick)))
            end
            
            if canTick then
                tickedAuras = tickedAuras + 1
                local def = AuraRegistry:Get(aura.id)
                RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s' should tick. Def=%s, has tick=%s"):format(
                    tostring(aura.id), tostring(def ~= nil), tostring(def and def.tick ~= nil)))
                
                if not def or not def.tick then
                    if RPE.Debug and RPE.Debug.Internal then
                        RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s' missing tick table."):format(tostring(aura.id)))
                    end
                    aura:AdvanceTick(turn)
                else
                    local tick = def.tick
                    local actionsRoot = tick.actions
                    RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s': actionsRoot=%s, count=%d"):format(
                        tostring(aura.id), tostring(actionsRoot ~= nil), actionsRoot and #actionsRoot or 0))
                    
                    if not (actionsRoot and #actionsRoot > 0) then
                        if RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s' has no tick actions."):format(tostring(aura.id)))
                        end
                        aura:AdvanceTick(turn)
                    else
                        local ctx = { event = self.event, combat = self.event and self.event.combat }

                        -- Use snapshot profile if available (captured when aura was applied)
                        -- Otherwise nil - tick damage will use default rolls without stat bonuses
                        local casterProfile = aura.snapshot and aura.snapshot.profile
                        
                        local cast = { caster = aura.sourceId or aura.source, profile = casterProfile, def = def }
                        local targets = { targetId }
                        
                        RPE.Debug:Internal(("[AuraManager:OnTick] Executing tick for aura '%s', caster=%s, target=%s"):format(
                            tostring(aura.id), tostring(cast.caster), tostring(targetId)))

                        -------------------------------------------------------------------------
                        -- Flatten nested actions / groups into a single list
                        -------------------------------------------------------------------------
                        local acts = {}

                        local function flattenActionBlock(block)
                            if block.key then
                                table.insert(acts, block)
                            elseif block.actions and type(block.actions) == "table" then
                                for _, sub in ipairs(block.actions) do
                                    flattenActionBlock(sub)
                                end
                            elseif block.group and SpellActions and SpellActions.groups then
                                local g = SpellActions.groups[block.group]
                                if g and type(g) == "table" then
                                    if RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(("[AuraManager:OnTick] Expanded action group '%s' with %d sub-actions."):format(
                                            tostring(block.group), #g))
                                    end
                                    for _, sub in ipairs(g) do flattenActionBlock(sub) end
                                else
                                    if RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(("[AuraManager:OnTick] Unknown action group '%s' in aura '%s'."):format(
                                            tostring(block.group), tostring(aura.id)))
                                    end
                                end
                            else
                                if RPE.Debug and RPE.Debug.Internal then
                                    RPE.Debug:Internal(("[AuraManager:OnTick] Skipped invalid tick action entry (no key/actions/group)."))
                                end
                            end
                        end

                        for _, block in ipairs(actionsRoot) do
                            flattenActionBlock(block)
                        end

                        RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s' has %d flattened actions"):format(
                            tostring(aura.id), #acts))

                        if #acts == 0 then
                            if RPE.Debug and RPE.Debug.Internal then
                                RPE.Debug:Internal(("[AuraManager:OnTick] Aura '%s' tick had no resolved actions."):format(tostring(aura.id)))
                            end
                            aura:AdvanceTick(turn)
                        else
                            -------------------------------------------------------------------------
                            -- Execute all flattened actions
                            -------------------------------------------------------------------------
                            for i, act in ipairs(acts) do
                                if RPE.Debug and RPE.Debug.Internal then
                                    RPE.Debug:Internal(("[AuraManager:OnTick] Running tick action #%d (%s) for aura '%s'"):format(
                                        i, tostring(act.key or "nil"), tostring(aura.id)))
                                end

                                local runtimeArgs = {}
                                if act.args then for k, v in pairs(act.args) do runtimeArgs[k] = v end end
                                if type(aura.snapshot) == "table" then
                                    for k, v in pairs(aura.snapshot) do runtimeArgs[k] = v end
                                end

                                if def.stackingPolicy == AuraRegistry.STACKING.ADD_MAGNITUDE then
                                    if type(runtimeArgs.amount) == "number" and type(aura.stacks) == "number" then
                                        local before = runtimeArgs.amount
                                        runtimeArgs.amount = runtimeArgs.amount * math.max(1, aura.stacks)
                                        if RPE.Debug and RPE.Debug.Internal then
                                            RPE.Debug:Internal(("[AuraManager:OnTick] Scaled by stacks (%d): %.2f → %.2f"):format(
                                                aura.stacks, before, runtimeArgs.amount))
                                        end
                                    end
                                end

                                local ok, err = pcall(function()
                                    RPE.Debug:Internal(("[AuraManager:OnTick] About to call Actions:Run('%s', ctx, cast, targets, args)"):format(
                                        tostring(act.key)))
                                    SpellActions:Run(act.key, ctx, cast, targets, runtimeArgs)
                                    RPE.Debug:Internal(("[AuraManager:OnTick] Actions:Run completed successfully"):format())
                                end)

                                if not ok then
                                    if RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(("[AuraManager:OnTick] SpellActions:Run failed for '%s': %s"):format(
                                            tostring(aura.id), tostring(err)))
                                    end
                                else
                                    if RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(("[AuraManager:OnTick] Finished tick action '%s' for '%s'."):format(
                                            tostring(act.key), tostring(aura.id)))
                                    end
                                end
                            end

                            -- Advance the tick schedule
                            aura:AdvanceTick(turn)

                            -- Emit TICK event
                            if AuraEvents then
                                AuraEvents:Emit("TICK", aura, turn)
                            end
                        end
                    end
                end
            end
        end
    end
    
    RPE.Debug:Internal(("[AuraManager:OnTick] Finished: %d/%d auras ticked"):format(tickedAuras, totalAuras))
end


-- ===== Internal notifications / integration points =====
function AuraManager:Subscribe(fn)
    if type(fn) ~= "function" then return nil end
    table.insert(self.listeners, fn)
    return fn
end

function AuraManager:Unsubscribe(fn)
    if not fn then return end
    for i = #self.listeners, 1, -1 do
        if self.listeners[i] == fn then table.remove(self.listeners, i) break end
    end
end

function AuraManager:_emit(ev, a, payload)
    for _, fn in ipairs(self.listeners) do
        local ok, err = pcall(fn, ev, a, payload, self)
        if not ok and RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal("|cffff5555AuraManager listener error:|r " .. tostring(err))
        end
    end
end

-- Call _emit inside your internal callbacks:
function AuraManager:_onApplied(a)
    if AuraEvents then AuraEvents:Emit("APPLY", a) end
        -- Broadcast apply (only from the local owner of the *caster*; never echo network)
    if Broadcast and _isLocalOwnerOfSource(a) and not self._netSquelch  then
        local def = AuraRegistry:Get(a.id)
        local desc = ""
        if def and def.description and Common and Common.FindUnitById and Common.ProfileForUnit and Common.ParseText then
            local tu = select(1, Common:FindUnitById(a.targetId))
            local tp = Common:ProfileForUnit(tu)
            desc = Common:ParseText(def.description or "", tp)
        end
        Broadcast:AuraApply(a.sourceId, a.targetId, a.id, desc, { stacks = a.stacks })
    end

    -- per-instance add
    do
    local tu = select(1, Common:FindUnitById(a.targetId))
        if Common:IsAuraStatsEligibleTarget(tu) then
            local tp = RPE.Profile.DB.GetOrCreateActive()
            if tp then _addInstanceMods(tp.name, a.instanceId, _computeInstanceMods(self, a, tp)) end
        end
    end

    -- Register aura triggers (ON_HIT, etc.)
    do
        local handles = AuraTriggers:RegisterFromAura(a)
        if handles then
            a._triggerHandles = handles
        end
    end

    -- purge conflicts if this aura grants immunity
    self:_applyImmunitySweepFor(a)
end

function AuraManager:_onRefreshed(a)
    if AuraEvents then AuraEvents:Emit("REFRESH", a) end

    -- per-instance update (handles stacks/duration refresh that affects magnitude)
    do
        local tu = select(1, Common:FindUnitById(a.targetId))
        if Common:IsAuraStatsEligibleTarget(tu) then
            local tp = RPE.Profile.DB.GetOrCreateActive()
            if tp then _updateInstanceMods(self, a, tp.name, tp) end
        end
    end
end

function AuraManager:_onRemoved(a, reason)
    if AuraEvents then AuraEvents:Emit("REMOVE", a, reason) end

    if Broadcast and _isLocalOwnerOfSource(a) and not self._netSquelch then
        Broadcast:AuraRemove(a.targetId or a.target, a.id, a.sourceId or a.source)
    end

    -- per-instance subtract
    do
        local tu = select(1, Common:FindUnitById(a.targetId))
        if Common:IsAuraStatsEligibleTarget(tu) then
            local tp = RPE.Profile.DB.GetOrCreateActive()
            if tp then _removeInstanceMods(tp.name, a.instanceId) end
        end
    end

    -- Unregister triggers if present
    if a._triggerHandles then
        AuraTriggers:Unregister(a._triggerHandles)
        a._triggerHandles = nil
    end
end

function AuraManager:_onExpired(a)
    -- 🔍 Debug: log every expiration event clearly
    RPE.Debug:Internal(("[AuraManager:_onExpired] Aura '%s' expired on target=%s (source=%s, instance=%s)")
        :format(
            tostring(a.id),
            tostring(a.targetId or a.target),
            tostring(a.sourceId or a.source),
            tostring(a.instanceId)
        ))

    -- Emit EXPIRE event
    if AuraEvents then
        AuraEvents:Emit("EXPIRE", a)
    end

    -- Network broadcast (only from the local owner of the source)
    if Broadcast and _isLocalOwnerOfSource(a) and not self._netSquelch then
        Broadcast:AuraRemove(a.targetId or a.target, a.id, a.sourceId or a.source)
    end

    -- Remove stat contributions
    do
        local tu = select(1, Common:FindUnitById(a.targetId))
        if Common:IsAuraStatsEligibleTarget(tu) then
            local tp = RPE.Profile.DB.GetOrCreateActive()
            if tp then
                RPE.Debug:Internal(("[AuraManager:_onExpired] Removing stat mods for aura '%s' (profile=%s)")
                    :format(tostring(a.id), tostring(tp.name)))
                _removeInstanceMods(tp.name, a.instanceId)
            end
        end
    end

    -- Unregister triggers if present
    if a._triggerHandles then
        AuraTriggers:Unregister(a._triggerHandles)
        a._triggerHandles = nil
    end
end


function AuraManager:_onTick(a, turn)
    if not a then
        RPE.Debug:Internal("[AuraManager:_onTick] No aura instance provided.")
        return
    end

    if not isSource(a) then
        RPE.Debug:Internal(("[AuraManager:_onTick] Skipped '%s' — not local source."):format(tostring(a.id)))
        return
    end

    RPE.Debug:Internal(("-- Aura '%s' ticking on turn %d (source=%s, target=%s)")
        :format(tostring(a.id), tonumber(turn or -1), tostring(a.sourceId), tostring(a.targetId)))

    if AuraEvents then AuraEvents:Emit("TICK", a, turn) end

    local def = AuraRegistry and AuraRegistry:Get(a.id)
    if not def or not def.tick then
        RPE.Debug:Internal(("[AuraManager:_onTick] Aura '%s' missing tick table."):format(tostring(a.id)))
        return
    end

    local tick = def.tick
    local actionsRoot = tick.actions
    if not (actionsRoot and #actionsRoot > 0) then
        RPE.Debug:Internal(("[AuraManager:_onTick] Aura '%s' has no tick actions."):format(tostring(a.id)))
        return
    end

    local ctx = { event = self.event, combat = self.event and self.event.combat }

    local casterUnit    = select(1, Common:FindUnitById(a.sourceId or a.source))
    local casterProfile = (casterUnit and Common:ProfileForUnit(casterUnit)) or (a.snapshot and a.snapshot.profile)
    local cast = { caster = a.sourceId or a.source, profile = casterProfile }
    local targets = { a.targetId or a.target }

    -------------------------------------------------------------------------
    -- Flatten nested actions / groups into a single list
    -------------------------------------------------------------------------
    local acts = {}

    local function flattenActionBlock(block)
        if block.key then
            table.insert(acts, block)
        elseif block.actions and type(block.actions) == "table" then
            for _, sub in ipairs(block.actions) do
                flattenActionBlock(sub)
            end
        elseif block.group and RPE.Core.SpellActions and RPE.Core.SpellActions.groups then
            local g = RPE.Core.SpellActions.groups[block.group]
            if g and type(g) == "table" then
                RPE.Debug:Internal(("[AuraManager:_onTick] Expanded action group '%s' with %d sub-actions.")
                    :format(tostring(block.group), #g))
                for _, sub in ipairs(g) do flattenActionBlock(sub) end
            else
                RPE.Debug:Internal(("[AuraManager:_onTick] Unknown action group '%s' in aura '%s'.")
                    :format(tostring(block.group), tostring(a.id)))
            end
        else
            RPE.Debug:Internal(("[AuraManager:_onTick] Skipped invalid tick action entry (no key/actions/group)."))
        end
    end

    for _, block in ipairs(actionsRoot) do
        flattenActionBlock(block)
    end

    if #acts == 0 then
        RPE.Debug:Internal(("[AuraManager:_onTick] Aura '%s' tick had no resolved actions."):format(tostring(a.id)))
        return
    end

    -------------------------------------------------------------------------
    -- Execute all flattened actions
    -------------------------------------------------------------------------
    for i, act in ipairs(acts) do
        RPE.Debug:Internal(("[AuraManager:_onTick] Running tick action #%d (%s) for aura '%s'")
            :format(i, tostring(act.key or "nil"), tostring(a.id)))

        local runtimeArgs = {}
        if act.args then for k, v in pairs(act.args) do runtimeArgs[k] = v end end
        if type(a.snapshot) == "table" then
            for k, v in pairs(a.snapshot) do runtimeArgs[k] = v end
        end

        if def.stackingPolicy == AuraRegistry.STACKING.ADD_MAGNITUDE then
            if type(runtimeArgs.amount) == "number" and type(a.stacks) == "number" then
                local before = runtimeArgs.amount
                runtimeArgs.amount = runtimeArgs.amount * math.max(1, a.stacks)
                RPE.Debug:Internal(("[AuraManager:_onTick] Scaled by stacks (%d): %.2f → %.2f")
                    :format(a.stacks, before, runtimeArgs.amount))
            end
        end

        local ok, err = pcall(function()
            SpellActions:Run(act.key, ctx, cast, targets, runtimeArgs)
        end)

        if not ok then
            RPE.Debug:Internal(("[AuraManager:_onTick] SpellActions:Run failed for '%s': %s")
                :format(tostring(a.id), tostring(err)))
        else
            RPE.Debug:Internal(("[AuraManager:_onTick] Finished tick action '%s' for '%s'.")
                :format(tostring(act.key), tostring(a.id)))
        end
    end
end

function AuraManager:TriggerEvent(eventName, ctx, sourceId, targetId, extra)
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[AuraManager:TriggerEvent] Triggering event '%s' (source=%s, target=%s)")
            :format(tostring(eventName), tostring(sourceId), tostring(targetId)))
    end

    local eventTargetId = targetId -- prevent shadowing

    for ownerId, auraList in pairs(self.aurasByUnit) do
        for _, aura in ipairs(auraList) do
            local def = AuraRegistry:Get(aura.id)
            if def and def.triggers then
                for _, trig in ipairs(def.triggers) do
                    if trig.event == eventName then
                        local act = trig.action
                        local ref = (act.targets and act.targets.ref or "target"):lower()

                        local recipients = {}
                        if ref == "source" then
                            table.insert(recipients, sourceId)
                        elseif ref == "target" then
                            table.insert(recipients, eventTargetId)
                        elseif ref == "both" then
                            table.insert(recipients, sourceId)
                            table.insert(recipients, eventTargetId)
                        end

                        if RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(("[AuraManager:TriggerEvent] Aura '%s' responding to '%s' with '%s' (ref=%s, targets=%s)")
                                :format(tostring(aura.id), tostring(eventName), tostring(act.key), ref, table.concat(recipients, ", ")))
                        end

                        local snapshot = aura.snapshot or {}
                        local profile  = snapshot.profile
                        local args     = act.args or {}

                        for _, unitId in ipairs(recipients) do
                            if act.key == "DAMAGE" then
                                local amount = 0
                                if type(args.amount) == "string" and RPE.Core.Formula then
                                    amount = tonumber(RPE.Core.Formula:Roll(args.amount, profile)) or 0
                                else
                                    amount = tonumber(args.amount or 0)
                                end

                                if amount > 0 and Broadcast and Broadcast.Damage then
                                    Broadcast:Damage(sourceId, {
                                        { target = unitId, amount = amount, school = args.school or "Physical" }
                                    })
                                end

                            elseif act.key == "HEAL" then
                                local amount = 0
                                if type(args.amount) == "string" and RPE.Core.Formula then
                                    amount = tonumber(RPE.Core.Formula:Roll(args.amount, profile)) or 0
                                else
                                    amount = tonumber(args.amount or 0)
                                end

                                if amount > 0 and Broadcast and Broadcast.Heal then
                                    Broadcast:Heal(sourceId, {
                                        { target = unitId, amount = amount }
                                    })
                                end

                            elseif act.key == "APPLY_AURA" and args.auraId then
                                RPE.Core.AuraManager:Apply(sourceId, unitId, args.auraId)
                            
                            elseif act.key == "GAIN_RESOURCE" then
                                local Resources = RPE.Core and RPE.Core.Resources
                                if Resources then
                                    local resourceId = args.resourceId
                                    local amount = 0
                                    if type(args.amount) == "string" and RPE.Core.Formula then
                                        amount = tonumber(RPE.Core.Formula:Roll(args.amount, profile)) or 0
                                    else
                                        amount = tonumber(args.amount or 0)
                                    end
                                    if resourceId and amount > 0 then
                                        Resources:Add(resourceId, amount)
                                        if RPE.Debug and RPE.Debug.Internal then
                                            RPE.Debug:Internal(("[AuraManager:TriggerEvent] GAIN_RESOURCE: Added %d %s to unit %s"):format(amount, resourceId, unitId))
                                        end
                                    end
                                end
                            end
                        end

                        if RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal("[AuraManager:TriggerEvent] Trigger action executed.")
                        end
                    end
                end
            end
        end
    end
end

function AuraManager:_onOwnerTurnStart(a, turn)
    -- hook point
end

function AuraManager:_onOwnerTurnEnd(a, turn)
    -- hook point
end

function AuraManager:AdvanceTurn(turn)
    for _, list in pairs(self.aurasByUnit or {}) do
        for i = #list, 1, -1 do
            local a = list[i]
            if a.expiresOn and turn >= a.expiresOn then
                self:_onExpired(a)
                table.remove(list, i)
            end
        end
    end
end

