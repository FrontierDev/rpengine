-- RPE/Core/Unit.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@alias UnitType "Aberration"|"Beast"|"Demon"|"Dragonkin"|"Elemental"|"Giant"|"Humanoid"|"Mechanical"|"Undead"
---@alias UnitSize "Tiny"|"Small"|"Medium"|"Large"|"Huge"|"Gargantuan"

---@class EventUnit
---@field id integer
---@field team integer
---@field key string
---@field name string
---@field isNPC boolean
---@field addedBy string|nil
---@field summonType string|nil           -- "None", "Pet", "Minion", "Totem", or "Guardian"
---@field summonedBy integer|nil          -- Unit ID of the summoner (if any)
---@field raidMarker integer|nil
---@field threat table<integer, number>
---@field stats table
---@field attackedLast boolean   -- did the local player attack this unit last turn?
---@field protectedLast boolean  -- did the local player heal/protect this unit last turn?
---@field topThreat boolean      -- is the local player top threat on this unit?
---@field unitType UnitType      # e.g., "Humanoid"
---@field unitSize UnitSize      # e.g., "Medium"
---@field spells string[]
---@field active boolean
---@field hidden boolean
---@field flying boolean
---@field engagement boolean      -- is the unit currently engaged in combat?
---@field absorption table|nil    -- absorption shields: {shieldId = {amount, sourceId, duration, appliedTurn}, ...}
---@field turnsLastCombat integer   -- number of full turns since unit last participated in combat (dealt/taken damage or healing)
local Unit = {}
Unit.__index = Unit
RPE.Core.Unit = Unit

-- Local helpers (Unit.lua scope)
local function realmSlug(s) return s and s:gsub("%s+","") or "" end

local function getLocalPlayerKey()
    local me = UnitName("player")
    local realm = realmSlug(GetRealmName())
    return (me and realm) and (me.."-"..realm):lower() or nil
end

-- Resolve the local player's EventUnit id (reads ActiveEvent, no mutation)
local function getLocalPlayerUnitId()
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return nil end
    local key = ev.localPlayerKey or getLocalPlayerKey()
    local u = key and ev.units[key] or nil
    return u and u.id or nil
end
RPE.Core.GetLocalPlayerUnitId = getLocalPlayerUnitId

-- O(n) resolve any unit by numeric id (small n in practice)
local function resolveUnitById(id)
    id = tonumber(id)
    if not id or id <= 0 then return nil end
    local ev = RPE.Core.ActiveEvent
    if ev and ev.units then
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == id then return u end
        end
    end
    return nil
end

--- Create a new EventUnit
---@param id integer
---@param data table  -- { key=string, name=string|nil, team=integer|nil, isNPC=boolean|nil, addedBy=string|nil, hp?:number, hpMax?:number, initiative?:number }
---@return EventUnit
function Unit.New(id, data)
    assert(tonumber(id), "Unit.New: id required")
    assert(type(data) == "table", "Unit.New: data table required")
    assert(type(data.key) == "string" and data.key ~= "", "Unit.New: data.key required")

    local self = setmetatable({}, Unit)
    self.id      = tonumber(id)
    self.key     = data.key
    self.name    = data.name or data.key
    self.team    = tonumber(data.team) or 1
    self.isNPC   = data.isNPC and true or false
    self.addedBy = data.addedBy
    self.summonType = data.summonType or "None"
    self.summonedBy = tonumber(data.summonedBy)
    local rm = tonumber(data.raidMarker)
    self.raidMarker = (rm and rm > 0) and rm or nil
    self.threat = Unit._CoerceThreatTable(data.threat)
    self._portraits = {}   -- { UnitPortrait, ... }
    self.attackedLast  = data.attackedLast and true or false
    self.protectedLast = data.protectedLast and true or false
    self.topThreat     = data.topThreat and true or false
    self.unitType = (data.unitType or "Humanoid") --[[@as UnitType]]
    self.unitSize = (data.unitSize or "Medium")   --[[@as UnitSize]]
    self.active = data.active and true or false
    self.hidden = data.hidden and true or false
    self.flying = data.flying and true or false
    self.engagement = data.engagement ~= false -- defaults to true (engaged)

    -- NPC stats
    if self.isNPC then
        RPE.Debug:Internal(("Adding NPC: %s"):format(data.key))

        self.stats = type(data.stats) == "table" and data.stats or {} 
    end

    -- NPC spells (list of IDs)
    if type(data.spells) == "table" then
        self.spells = {}
        for _, sid_raw in ipairs(data.spells) do
            local sid = tostring(sid_raw or ""):match("^%s*(.-)%s*$")
            if sid ~= "" then 
                table.insert(self.spells, sid) 
            end
        end
    else
        self.spells = {}
    end

    -- HP (guaranteed fields)
    local hpMax = tonumber(data.hpMax) or tonumber(data.maxHP) or tonumber(data.maxHp) or 100
    local hp    = tonumber(data.hp)    or tonumber(data.currentHP) or tonumber(data.health) or hpMax
    hpMax = math.max(1, math.floor(hpMax))
    hp    = math.floor(math.max(0, math.min(hp, hpMax)))
    self.hpMax = hpMax
    self.hp    = hp

    -- Absorption/shield tracking (shieldId -> {amount, sourceId, duration, appliedTurn})
    self.absorption = {}

    -- Combat tracking: turns since last combat activity (initialized to 0 = just now, so unit starts engaged)
    self.turnsLastCombat = tonumber(data.turnsLastCombat) or 0
    
    -- Engagement state (starts engaged, becomes disengaged after 3 turns of no activity)
    self._isEngaged = true

    -- Initiative (guaranteed field)
    self.initiative = math.floor(tonumber(data.initiative) or 0)

    -- Model data (for NPCs)
    self.displayId  = tonumber(data.displayId)  or tonumber(data.modelDisplayId)
    self.fileDataId = tonumber(data.fileDataId)
    self.cam        = tonumber(data.cam)
    self.rot        = tonumber(data.rot)
    self.z          = tonumber(data.z)

    return self
end

function Unit:SetTeam(team)
    self.team = math.max(1, tonumber(team) or 1)
end

-- ===== Initiative helpers =====
function Unit:SetInitiative(val)
    self.initiative = math.floor(tonumber(val) or 0)
end

function Unit:RollInitiative(minVal, maxVal)
    minVal, maxVal = tonumber(minVal) or 0, tonumber(maxVal) or 20
    self.initiative = math.random(minVal, maxVal)
    return self.initiative
end

-- ===== HP helpers =====
function Unit:SetMaxHP(max)
    max = math.max(1, math.floor(tonumber(max) or (self.hpMax or 1)))
    self.hpMax = max
    if self.hp then self.hp = math.min(self.hp, self.hpMax) end
end

function Unit:SetHP(hp)
    hp = math.floor(tonumber(hp) or 0)
    self.hp = math.max(0, math.min(hp, self.hpMax or 1))
end

function Unit:ApplyDamage(amount, isCrit, absorbedAmount)
    isCrit = isCrit or false
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    absorbedAmount = math.max(0, math.floor(tonumber(absorbedAmount) or 0))
    local wasDead = self:IsDead()
    self:SetHP((self.hp or 0) - amount)
    local isDead = self:IsDead()
    
    -- Reset combat counter and set engaged when damage is taken
    if amount > 0 then
        self.turnsLastCombat = 0
        self:SetEngaged(true)
    end
    RPE.Debug:Internal((string.format("%s lost %s hitpoints (current: %s, dead: %s)", self.name, amount, self.hp, tostring(isDead))))

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
        -- Show damage with absorption notation if any damage was absorbed
        if absorbedAmount > 0 then
            local totalDamage = amount + absorbedAmount
            RPE.Core.CombatText.Screen:AddText(string.format("-%d (Absorbed: %d)", totalDamage, absorbedAmount), 
                { variant = "damage", isCrit = isCrit, direction = "DOWN" })
        else
            RPE.Core.CombatText.Screen:AddNumber(amount, "damage", { isCrit = isCrit, direction = "DOWN" })
        end
    end

    local ev = RPE.Core.ActiveEvent
    if ev and ev.MarkAttacked then ev:MarkAttacked(self.id) end

    -- Broadcast updated health to other players
    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.UpdateUnitHealth then
        Broadcast:UpdateUnitHealth(self.id, self.hp, self.hpMax)
    end

    -- Emit ON_DEATH trigger when unit reaches 0 HP
    if not wasDead and isDead then
        local AuraTriggers = RPE.Core and RPE.Core.AuraTriggers
        if AuraTriggers and AuraTriggers.Emit then
            AuraTriggers:Emit("ON_DEATH", ev or {}, self.id, self.id, { damageAmount = amount })
        end
    end

    return self.hp, isDead
end

function Unit:Heal(amount, isCrit)
    isCrit = isCrit or false
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    
    -- Reset combat counter and set engaged when healing is received
    if amount > 0 then
        self.turnsLastCombat = 0
        self:SetEngaged(true)
    end
    
    -- Apply healing_received modifier from active rules
    -- The rule should be a stat name (e.g., "$stat.HEALING_TAKEN$") that resolves to a multiplier (default 1)
    if RPE.ActiveRules then
        local healingReceivedRule = RPE.ActiveRules:Get("healing_received")
        if healingReceivedRule then
            local multiplier = 1
            if type(healingReceivedRule) == "string" then
                -- Try to extract stat name from token format like "$stat.HEALING_TAKEN$"
                local statId = healingReceivedRule:match("^%$stat%.([%w_]+)%$$")
                if statId then
                    -- Resolve the stat value as the multiplier
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        multiplier = tonumber(Stats:GetValue(statId)) or 1
                    end
                else
                    -- If not a token, try to treat it as a direct stat name
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        multiplier = tonumber(Stats:GetValue(healingReceivedRule)) or 1
                    end
                end
            else
                -- If not a string, assume it's a numeric multiplier
                multiplier = tonumber(healingReceivedRule) or 1
            end
            amount = math.floor(amount * multiplier)
        end
    end
    
    self:SetHP((self.hp or 0) + amount)
    RPE.Debug:Internal(("%s gained %s hitpoints (current: %s, dead: %s)"):format(self.name, amount, self.hp, tostring(self:IsDead())))

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
    end

    local ev = RPE.Core.ActiveEvent
    if ev and ev.MarkProtected then ev:MarkProtected(self.id) end

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
        RPE.Core.CombatText.Screen:AddNumber(amount, "heal", { isCrit = isCrit, direction = "DOWN" })
    end

    -- Broadcast updated health to other players
    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.UpdateUnitHealth then
        Broadcast:UpdateUnitHealth(self.id, self.hp, self.hpMax)
    end

    return self.hp
end

function Unit:IsDead()
    return (self.hp or 0) <= 0
end

function Unit:SetAttackedLast(flag)
    self.attackedLast = not not flag
    for _, p in ipairs(self._portraits or {}) do
        if p.SetAttackedLast then
            p:SetAttackedLast(self.attackedLast)
        end
    end
end

function Unit:SetProtectedLast(flag)
    self.protectedLast = not not flag
    for _, p in ipairs(self._portraits or {}) do
        if p.SetHealedLast then
            p:SetHealedLast(self.protectedLast)
        end
    end
end

function Unit:SetTopThreat(flag)
    self.topThreat = not not flag
    for _, p in ipairs(self._portraits or {}) do
        if p.SetThreatTop then
            p:SetThreatTop(self.topThreat)
        end
    end
end


-- ===== Threat helpers =====

-- Internal: coerce arbitrary table into { [attackerId:number] = threat:number >= 0 }
function Unit._CoerceThreatTable(src)
    local t = {}
    if type(src) ~= "table" then return t end
    for k, v in pairs(src) do
        local id = tonumber(k)
        local val = tonumber(v)
        if id and id > 0 and val and val > 0 then
            t[id] = val
        end
    end
    return t
end

-- Re-evaluate "is local player top threat" and toggle the portrait icon(s)
function Unit:_UpdateThreatIconForPortraits()
    if not self._portraits then return end
    local myId  = getLocalPlayerUnitId()
    local topId, topVal = self:GetTopThreat()
    local isTop = (myId ~= nil and topId == myId)
    local myThreat = (myId and self.threat and self.threat[myId]) or 0

    for i = #self._portraits, 1, -1 do
        local p = self._portraits[i]
        -- Clean dead references (if any got Destroyed)
        if not p or not p.frame or not p.SetThreatTop then
            table.remove(self._portraits, i)
        else
            p:SetThreatTop(isTop)
            if p.SetThreatAmount then
                p:SetThreatAmount(myThreat)
            end
        end
    end
end

--- Get current threat value from an attacker unit id (defaults to 0).
function Unit:GetThreat(attackerId)
    attackerId = tonumber(attackerId)
    if not attackerId or attackerId <= 0 then return 0 end
    return tonumber(self.threat and self.threat[attackerId]) or 0
end

--- Set threat to an exact value (<=0 clears). Enforces non-ally rule.
function Unit:SetThreat(attackerId, value)
    attackerId = tonumber(attackerId); value = tonumber(value)
    if not attackerId or attackerId <= 0 then return end

    -- Enforce: only non-team members can add/hold threat
    local attacker = resolveUnitById(attackerId)
    if attacker and tonumber(attacker.team) == tonumber(self.team) then
        return
    end

    self.threat = self.threat or {}
    if not value or value <= 0 then
        self.threat[attackerId] = nil
    else
        self.threat[attackerId] = value
    end
    self:_UpdateThreatIconForPortraits()
end

--- Add (or subtract) threat delta (<=0 after addition clears). Enforces non-ally rule.
function Unit:AddThreat(attackerId, delta)
    attackerId = tonumber(attackerId); delta = tonumber(delta)
    if not attackerId or attackerId <= 0 or delta == nil then return end

    local attacker = resolveUnitById(attackerId)
    if attacker and tonumber(attacker.team) == tonumber(self.team) then
        return
    end

    self.threat = self.threat or {}
    local newVal = (tonumber(self.threat[attackerId]) or 0) + delta
    if newVal <= 0 then
        self.threat[attackerId] = nil
    else
        self.threat[attackerId] = newVal
    end
    self:_UpdateThreatIconForPortraits()
end

--- Convenience: add threat using an attacker EventUnit reference (team-safe).
function Unit:AddThreatFromUnit(attackerUnit, delta)
    if not attackerUnit or attackerUnit == self then return end
    if tonumber(attackerUnit.team) == tonumber(self.team) then return end
    self:AddThreat(attackerUnit.id, delta)
end

--- Remove a single attacker from the table.
function Unit:ClearThreat(attackerId)
    attackerId = tonumber(attackerId)
    if not attackerId or attackerId <= 0 then return end
    if not self.threat then return end
    self.threat[attackerId] = nil
    self:_UpdateThreatIconForPortraits()
end

--- Wipe all threat on this unit.
function Unit:ResetThreat()
    self.threat = {}
    self:_UpdateThreatIconForPortraits()
end

--- Return topAttackerId (or nil if none). Second value is optional topThreat if you need it.
function Unit:GetTopThreat()
    local topId, topVal = nil, 0
    if not self.threat then return nil, 0 end
    for id, val in pairs(self.threat) do
        val = tonumber(val) or 0
        if val > topVal then
            topId, topVal = id, val
        end
    end
    return topId, topVal
end

--- Return a descending list of { id, value }. Optional limit.
function Unit:GetSortedThreat(limit)
    local list = {}
    if self.threat then
        for id, val in pairs(self.threat) do
            local v = tonumber(val)
            if v and v > 0 then
                list[#list+1] = { id = id, value = v }
            end
        end
    end
    table.sort(list, function(a,b) return a.value > b.value end)
    if limit and tonumber(limit) and #list > limit then
        local n = tonumber(limit)
        while #list > n do table.remove(list) end
    end
    return list
end

--- Multiplicative decay for all entries (e.g., factor=0.9). Values below epsilon are dropped.
function Unit:DecayThreat(factor, epsilon)
    factor  = tonumber(factor)  or 1
    epsilon = tonumber(epsilon) or 1e-3
    if factor >= 1 or not self.threat then return end
    for id, val in pairs(self.threat) do
        local v = (tonumber(val) or 0) * factor
        if v <= epsilon then
            self.threat[id] = nil
        else
            self.threat[id] = v
        end
    end
    self:_UpdateThreatIconForPortraits()
end

-- ===== Crowd Control helpers =====
--- Check if unit has any crowd control aura blocking actions
function Unit:IsBlockedFromActions()
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.id)
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.crowdControl then
            local cc = aura.def.crowdControl
            -- Check block all actions
            if cc.blockAllActions then
                return true
            end
        end
    end
    return false
end

--- Check if unit has crowd control blocking a specific action by tag
function Unit:IsActionBlockedByTag(actionTag)
    if not actionTag then return false end
    
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.id)
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.crowdControl then
            local cc = aura.def.crowdControl
            if cc.blockActionsByTag then
                -- Check if actionTag matches any blocked tag
                for _, blockedTag in ipairs(cc.blockActionsByTag) do
                    if blockedTag == actionTag then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--- Check if unit has crowd control failing all defences
function Unit:IsFailingAllDefences()
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.id)
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.crowdControl then
            local cc = aura.def.crowdControl
            if cc.failAllDefences then
                return true
            end
        end
    end
    return false
end

--- Check if unit has crowd control failing a specific defence stat
function Unit:IsDefenceStatFailing(defenceStat)
    if not defenceStat then return false end
    
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.id)
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.crowdControl then
            local cc = aura.def.crowdControl
            if cc.failDefencesByStats then
                -- Check if defenceStat matches any failed stat
                for _, failedStat in ipairs(cc.failDefencesByStats) do
                    if failedStat == defenceStat then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--- Get movement speed modifier from crowd control auras (0-1, where 1=100% speed)
function Unit:GetMovementSpeedModifier()
    local speedMod = 1.0
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return speedMod end
    
    local auras = ev._auraManager:All(self.id)
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.crowdControl then
            local cc = aura.def.crowdControl
            if cc.slowMovement and cc.slowMovement > 0 then
                -- Apply slowMovement as a percentage reduction (0-100)
                local slow = tonumber(cc.slowMovement) or 0
                speedMod = speedMod * (1 - (slow / 100))
            end
        end
    end
    return math.max(0, speedMod)  -- Ensure never goes below 0
end


function Unit:SetRaidMarker(marker)
    if marker and tonumber(marker) and marker >= 1 and marker <= 8 then
        self.raidMarker = tonumber(marker)
    else
        self.raidMarker = nil
    end
end

function Unit:GetRaidMarker()
    return self.raidMarker
end

-- ===== Damage Tracking =====
function Unit:GetTurnsLastCombat()
    return tonumber(self.turnsLastCombat) or 999
end

function Unit:ResetCombat()
    RPE.Debug:Internal(("ResetCombat called on %s"):format(self.name or self.key))
    self.turnsLastCombat = 0
    self:SetEngaged(true)
end

--- Check if unit is disengaged (not currently engaged in combat)
function Unit:IsDisengaged()
    return not self.engagement
end

--- Set engagement state and broadcast state change
function Unit:SetEngaged(isEngaged)
    isEngaged = not not isEngaged
    
    -- When engaging (setting to true), reset the disengagement timer
    if isEngaged and not self.engagement then
        self.turnsLastCombat = 0
    end
    
    -- If state actually changed, broadcast the update
    if self.engagement ~= isEngaged then
        self.engagement = isEngaged
        
        -- Broadcast state change to sync with group
        local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if Broadcast and Broadcast.UpdateState then
            Broadcast:UpdateState(self)
        end
        
        -- Only display messages for local player
        local ev = RPE.Core and RPE.Core.ActiveEvent
        if ev and ev.localPlayerKey then
            if tostring(self.key):lower() == ev.localPlayerKey then
                if isEngaged then
                    self:_DisplayCombatStatusMessage("Entering Combat", {1.0, 0.2, 0.2})  -- red
                else
                    self:_DisplayCombatStatusMessage("Leaving Combat", {0.7, 0.7, 0.7})  -- grey
                end
            end
        end
    end
end

--- Check if unit should be disengaged based on turnsLastCombat and update accordingly
function Unit:CheckAndDisplayCombatStatusChange()
    -- Only disengage if they've been inactive for 3+ turns (turnsLastCombat starts at 0)
    if self.turnsLastCombat >= 3 and self.engagement then
        self:SetEngaged(false)
    end
end

--- Display a floating combat status message
function Unit:_DisplayCombatStatusMessage(text, color)
    local fct = RPE.Core and RPE.Core.CombatText and RPE.Core.CombatText.Screen
    if not fct then return end
    
    -- Display the message
    fct:AddText(text, {
        color = { 1.0, 0.2, 0.2, 1.0 },  -- red for both messages
        duration = 1.5,
        distance = 60,
        direction = "DOWN"  -- text goes downwards
    })
end

-- ===== Stats =====-- 
function Unit:GetStat(id)
    if not id then return 0 end
    local stats = self.stats
    if type(stats) ~= "table" then return 0 end
    local v = stats[id]
    return tonumber(v) or 0
end

--- Seed NPC stats table from the ruleset's "npc_stats" list.
function Unit:SeedNPCStats()
    self.stats = self.stats or {}

    local npcStatList = RPE.ActiveRules:Get("npc_stats")
    if type(npcStatList) == "table" and next(npcStatList) ~= nil then
        for i, stat in ipairs(npcStatList) do
            if type(stat) == "string" and stat ~= "" then
                -- Initialise all listed stats with a random default (0–5)
                local val = math.random(0, 5)
                self.stats[stat] = val
                if RPE and RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(("NPC %s stat seeded: %s = %d"):format(tostring(self.id), stat, val))
                end
            end
        end
    end
end


-- ===== Unit portrait =====
---@param parent FrameElement
---@param unit EventUnit
---@return FrameElement
function Unit:CreatePortrait(parent, size, noHealthBar)
    local UnitPortrait = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait
    assert(UnitPortrait, "UnitPortrait prefab not loaded (check TOC load order).")

    local p = UnitPortrait:New(("RPE_UnitPortrait_%s_%d"):format(self.key, self.id), {
        parent = parent,
        unit   = self,
        size   = size or 36,
        noHealthBar = noHealthBar or false,
    })

    -- Track and immediately sync current "top threat" state for the local player
    self._portraits = self._portraits or {}
    table.insert(self._portraits, p)
    self:_UpdateThreatIconForPortraits()

    return p
end

function Unit:GetTooltip(opts)
    -- Build a tooltip spec the renderer can consume.
    local Common = RPE and RPE.Common
    local unitName = Common and Common.FormatUnitName and Common:FormatUnitName(self) or self.name
    local summonerLine = nil
    
    -- For summoned pets/totems, prepare summoner info on separate line
    if self.isNPC and self.summonedBy then
        if Common and Common.FindUnitById then
            local summoner = Common:FindUnitById(self.summonedBy)
            if summoner and summoner.name then
                local summonerType = self.summonType or "Pet"
                if summonerType == "None" then summonerType = "Pet" end
                local formattedSummonerName = Common.FormatUnitName and Common:FormatUnitName(summoner) or summoner.name
                summonerLine = formattedSummonerName .. "'s " .. summonerType
            elseif RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[Unit:GetTooltip] Summoner %d not found"):format(self.summonedBy))
            end
        elseif RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Unit:GetTooltip] Common or FindUnitById not available"))
        end
    end
    
    -- Prepend raid marker icon to name if unit has one
    if self.raidMarker and self.raidMarker >= 1 and self.raidMarker <= 8 then
        unitName = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. self.raidMarker .. ":16:16:0:0:64:64:4:60:4:60|t " .. unitName
    end
    
    local spec = {
        lines = {}
    }
    local lines = spec.lines

    -- First line: Unit name (gold left) | Unit ID (grey right)
    table.insert(lines, {
        left = unitName,
        r = 1, g = 0.82, b = 0,  -- gold
        right = "|cFF808080" .. tostring(self.id) .. "|r",  -- grey ID on right
        r2 = 0.7, g2 = 0.7, b2 = 0.7,
        wrap = false
    })
    
    -- Add summoner info on second line if applicable
    if summonerLine then
        local r, g, b, a = RPE_UI.Colors.Get("textMuted")
        table.insert(lines, {
            left = summonerLine,
            r = r, g = g, b = b,
            wrap = false
        })
    end

    if self.team then
        local ev = RPE.Core and RPE.Core.ActiveEvent
        local val = (ev and ev.teamNames and ev.teamNames[self.team])
            or string.format("Team %s", tostring(self.team))
        local colorKey = "team" .. tostring(self.team)
        local r, g, b, a = RPE_UI.Colors.Get(colorKey)
        table.insert(lines, { left = val, right = nil, r = r, g = g, b = b, wrap = false })
    end

    table.insert(lines, { left = string.format("%s · %s%s", self.unitType or "Humanoid", self.unitSize or "Medium", self.flying and " . Flying" or ""), right = nil, wrap = false })

    if opts.health then
        local healthIcon = RPE.Common.InlineIcons.Health
        local healthText = string.format(
            "%s |cFFA06060%s / %s|r",
            healthIcon, self.hp, self.hpMax
        )
        if self:IsDisengaged() then
            healthText = healthText .. " |cFFC0C0C0(Disengaged)|r"
        end
        table.insert(lines, {
            left = healthText,
            right = nil,
            wrap = false
        })
    end

    -- Add casting information if unit is currently casting
    if self._castTimeRemaining ~= nil and self._castTimeTotal ~= nil and self._castTimeTotal > 0 then
        table.insert(lines, {
            left = " ",  -- Empty line for spacing
            wrap = false
        })
        
        local castingText = "Casting"
        if self._castIcon then
            castingText = "|T" .. self._castIcon .. ":16:16:0:0|t " .. castingText
        end
        castingText = castingText .. " " .. (self._castName or "Unknown")
        
        local castTarget = self._castTarget and Common and Common:FindUnitById(self._castTarget)
        local castTargetName = castTarget and (Common.FormatUnitName and Common:FormatUnitName(castTarget) or castTarget.name) or "Self"
        
        table.insert(lines, {
            left = castingText,
            right = nil,
            r = 0.8, g = 0.8, b = 0.8,  -- yellow
            wrap = false
        })
        table.insert(lines, {
            left = RPE.Common.InlineIcons.Target .. " ".. castTargetName,
            right = nil,
            r = 0.8, g = 0.8, b = 0.8,  -- light grey
            wrap = false
        })
    end

    return spec
end

-- ===== Net sync (state + delta helpers) =====================================

-- Fields we sync across the wire
Unit.SyncFields = {
    "id","key","name","team","isNPC","hp","hpMax","initiative",
    "raidMarker","unitType","unitSize","active","hidden","flying","engagement",
    "displayId","fileDataId","cam","rot","z","summonType","summonedBy",
    "turnsLastCombat"
}
-- Percent-escape for CSV key=value lists (safe against ; , = % \n)
local function _escCSV(s)
    if s == nil then return "" end
    s = tostring(s)
    s = s:gsub("%%","%%25"):gsub(";", "%%3B"):gsub(",", "%%2C"):gsub("=","%%3D"):gsub("\n","%%0A")
    return s
end
local function _unescCSV(s)
    if not s or s == "" then return "" end
    s = s:gsub("%%0A","\n"):gsub("%%3D","="):gsub("%%2C",","):gsub("%%3B",";"):gsub("%%25","%%")
    return s
end

--- Return a shallow "wire" state for this unit (stable order/types).
function Unit:ToSyncState()
    local statsCopy
    if type(self.stats) == "table" then
        statsCopy = {}; for k,v in pairs(self.stats) do statsCopy[k] = v end
    end
    return {
        id         = tonumber(self.id),
        key        = tostring(self.key or ""),
        name       = tostring(self.name or self.key or ""),
        team       = tonumber(self.team) or 1,
        isNPC      = not not self.isNPC,
        hp         = tonumber(self.hp) or 0,
        hpMax      = tonumber(self.hpMax) or 1,
        initiative = tonumber(self.initiative) or 0,
        raidMarker = (self.raidMarker and self.raidMarker > 0) and self.raidMarker or nil,
        unitType   = self.unitType or "Humanoid",
        unitSize   = self.unitSize or "Medium",
        stats      = statsCopy,
        active = not not self.active,
        hidden = not not self.hidden,
        flying = not not self.flying,
        displayId  = tonumber(self.displayId),
        fileDataId = tonumber(self.fileDataId),
        cam        = tonumber(self.cam),
        rot        = tonumber(self.rot),
        z          = tonumber(self.z),
        summonType = self.summonType or nil,
        summonedBy = tonumber(self.summonedBy) or nil,
    }
end

--- Diff two sync states; return table of changed scalars + statsChanged flag.
function Unit.DiffStates(oldS, newS)
    local changed = {}
    for _, k in ipairs(Unit.SyncFields) do
        if k ~= "id" then
            local ov = oldS and oldS[k] or nil
            local nv = newS[k]
            if ov ~= nv then
                -- key rarely changes; include if it did (for safety)
                changed[k] = nv
            end
        end
    end

    local statsChanged = false
    local A, B = oldS and oldS.stats or nil, newS.stats or nil
    if (A and not B) or (B and not A) then
        statsChanged = true
    elseif A and B then
        -- shallow compare
        for k, v in pairs(A) do
            if tonumber(B[k]) ~= tonumber(v) then statsChanged = true break end
        end
        if not statsChanged then
            for k, v in pairs(B) do
                if tonumber(A[k]) ~= tonumber(v) then statsChanged = true break end
            end
        end
    end
    return changed, statsChanged
end

--- Encode key=value CSV from a table (only known Unit.SyncFields are used).
function Unit.KVEncode(tbl)
    local parts = {}
    for _, k in ipairs(Unit.SyncFields) do
        local v = tbl[k]
        if v ~= nil then
            local sv
            if k == "isNPC" or k == "active" or k == "hidden" or k == "flying" or k == "engagement" then
                sv = (v and "1" or "0")
            else
                sv = tostring(v)
            end
            parts[#parts+1] = _escCSV(k) .. "=" .. _escCSV(sv)
        end
    end
    return table.concat(parts, ",")
end

--- Decode key=value CSV into a table with proper types.
function Unit.KVDecode(str)
    local out = {}
    if not str or str == "" then return out end
    for pair in string.gmatch(str, "([^,]+)") do
        local rk, rv = pair:match("([^=]+)=([^=]*)")
        if rk then
            local k = _unescCSV(rk)
            local v = _unescCSV(rv)
            if k == "team" or k == "hp" or k == "hpMax" or k == "initiative" or k == "raidMarker" or k == "id" or k == "displayId" or k == "fileDataId" then
                out[k] = tonumber(v) or 0
            elseif k == "cam" or k == "rot" or k == "z" then
                out[k] = tonumber(v) or nil
            elseif k == "isNPC" or k == "active" or k == "hidden" or k == "flying" or k == "engagement" then
                out[k] = (v == "1" or v == "true")
            else
                out[k] = v
            end
        end
    end
    return out
end


--- Encode stats table as key=value CSV.
function Unit.StatsEncode(stats)
    local parts = {}
    if type(stats) == "table" then
        for k, v in pairs(stats) do
            parts[#parts+1] = _escCSV(k) .. "=" .. tostring(tonumber(v) or 0)
        end
    end
    return table.concat(parts, ",")
end

--- Decode stats key=value CSV back to table<number>.
function Unit.StatsDecode(str)
    local out = {}
    if not str or str == "" then return out end
    for pair in string.gmatch(str, "([^,]+)") do
        local rk, rv = pair:match("([^=]+)=([^=]*)")
        if rk then out[_unescCSV(rk)] = tonumber(_unescCSV(rv)) or 0 end
    end
    return out
end

--- Apply a small set of scalar field changes to an existing unit.
function Unit.ApplyKV(u, kv)
    if not u or type(kv) ~= "table" then return end

    if kv.key        ~= nil then u.key        = kv.key end
    if kv.name       ~= nil then u.name       = kv.name end
    if kv.team       ~= nil then u.team       = tonumber(kv.team) or u.team end
    if kv.isNPC      ~= nil then u.isNPC      = not not kv.isNPC end
    if kv.hp         ~= nil then u.hp         = tonumber(kv.hp) or u.hp end
    if kv.hpMax      ~= nil then u.hpMax      = tonumber(kv.hpMax) or u.hpMax end
    if kv.initiative ~= nil then u.initiative = tonumber(kv.initiative) or u.initiative end

    if kv.unitType ~= nil then u.unitType = kv.unitType --[[@as UnitType]] end
    if kv.unitSize ~= nil then u.unitSize = kv.unitSize --[[@as UnitSize]] end
    if kv.active   ~= nil then u.active   = not not kv.active end
    if kv.hidden   ~= nil then u.hidden   = not not kv.hidden end
    if kv.flying   ~= nil then u.flying   = not not kv.flying end
    if kv.engagement ~= nil then u.engagement = not not kv.engagement end

    if kv.raidMarker ~= nil then
        local v = tonumber(kv.raidMarker)
        u.raidMarker = (v and v > 0) and v or nil
    end

    -- Model data
    if kv.displayId  ~= nil then u.displayId  = tonumber(kv.displayId) end
    if kv.fileDataId ~= nil then u.fileDataId = tonumber(kv.fileDataId) end
    if kv.cam        ~= nil then u.cam        = tonumber(kv.cam) end
    if kv.rot        ~= nil then u.rot        = tonumber(kv.rot) end
    if kv.z          ~= nil then u.z          = tonumber(kv.z) end

    -- Summon data
    if kv.summonType  ~= nil then u.summonType  = kv.summonType end
    if kv.summonedBy  ~= nil then u.summonedBy  = tonumber(kv.summonedBy) end

    -- Combat tracking
    if kv.turnsLastCombat ~= nil then u.turnsLastCombat = tonumber(kv.turnsLastCombat) or 0 end

    -- Stats
    if type(kv.stats) == "table" then
        u.stats = kv.stats
    end

    -- Spells (NPC only)
    if kv.isNPC and type(kv.spells) == "table" then
        u.spells = {}
        for _, sid in ipairs(kv.spells) do
            local sid_trim = tostring(sid or ""):match("^%s*(.-)%s*$")
            if sid_trim ~= "" then table.insert(u.spells, sid_trim) end
        end
    end
end


--- Adds a spell ID to this unit's spell list (no data payload, just ID).
function Unit:AddSpell(spellId)
    if not spellId or spellId == "" then return end
    self.spells = self.spells or {}
    -- prevent duplicates
    for _, sid in ipairs(self.spells) do
        if sid == spellId then return end
    end
    table.insert(self.spells, spellId)
end

function Unit:RemoveSpell(spellId)
    if not self.spells then return end
    for i, sid in ipairs(self.spells) do
        if sid == spellId then
            table.remove(self.spells, i)
            break
        end
    end
end

function Unit:HasSpell(spellId)
    if not self.spells then return false end
    for _, sid in ipairs(self.spells) do
        if sid == spellId then return true end
    end
    return false
end

function Unit:ListSpells()
    return self.spells or {}
end

return Unit
