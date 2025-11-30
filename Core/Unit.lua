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

function Unit:ApplyDamage(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    self:SetHP((self.hp or 0) - amount)
    RPE.Debug:Internal(("%s lost %s hitpoints (current: %s, dead: %s)"):format(self.name, amount, self.hp, tostring(self:IsDead())))

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
        RPE.Core.CombatText.Screen:AddNumber(amount, "damage", { isCrit = false, direction = "DOWN" })
    end

    local ev = RPE.Core.ActiveEvent
    if ev and ev.MarkAttacked then ev:MarkAttacked(self.id) end

    

    return self.hp, self:IsDead()
end

function Unit:Heal(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    self:SetHP((self.hp or 0) + amount)
    RPE.Debug:Internal(("%s gained %s hitpoints (current: %s, dead: %s)"):format(self.name, amount, self.hp, tostring(self:IsDead())))

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
    end

    local ev = RPE.Core.ActiveEvent
    if ev and ev.MarkProtected then ev:MarkProtected(self.id) end

    if(self.id == RPE.Core.ActiveEvent:GetLocalPlayerUnitId()) then
        RPE.Core.Resources:Set("HEALTH", self.hp)
        RPE.Core.CombatText.Screen:AddNumber(amount, "heal", { isCrit = false, direction = "DOWN" })
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
    local topId = self:GetTopThreat()
    local isTop = (myId ~= nil and topId == myId)

    for i = #self._portraits, 1, -1 do
        local p = self._portraits[i]
        -- Clean dead references (if any got Destroyed)
        if not p or not p.frame or not p.SetThreatTop then
            table.remove(self._portraits, i)
        else
            p:SetThreatTop(isTop)
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
    if not attackerId or attackerId <= 0 or not delta then return end

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

-- ===== Raid marker helpers =====
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
    else
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("The rule 'npc_stats' was expected but is either missing or empty.")
        end
    end
end


-- ===== Unit portrait =====
---@param parent FrameElement
---@param unit EventUnit
---@return FrameElement
function Unit:CreatePortrait(parent, size)
    local UnitPortrait = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait
    assert(UnitPortrait, "UnitPortrait prefab not loaded (check TOC load order).")

    local p = UnitPortrait:New(("RPE_UnitPortrait_%s_%d"):format(self.key, self.id), {
        parent = parent,
        unit   = self,
        size   = size or 36,
    })

    -- Track and immediately sync current "top threat" state for the local player
    self._portraits = self._portraits or {}
    table.insert(self._portraits, p)
    self:_UpdateThreatIconForPortraits()

    return p
end

function Unit:GetTooltip(opts)
    -- Build a tooltip spec the renderer can consume.
    local unitName = self.name
    
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

    if self.team then
        local ev = RPE.Core and RPE.Core.ActiveEvent
        local val = (ev and ev.teamNames and ev.teamNames[self.team])
            or string.format("Team %s", tostring(self.team))
        local colorKey = "team" .. tostring(self.team)
        local r, g, b, a = RPE_UI.Colors.Get(colorKey)
        table.insert(lines, { left = val, right = nil, r = r, g = g, b = b, wrap = false })
    end

    table.insert(lines, { left = string.format("%s · %s", self.unitType or "Humanoid", self.unitSize or "Medium"), right = nil, wrap = false })

    if opts.initiative then
        -- Show initiative...
    end
    
    if opts.health then
        local healthIcon = RPE.Common.InlineIcons.Health
        table.insert(lines,{
            left = string.format(
                "%s |cFFA06060%s / %s|r",
                healthIcon, self.hp, self.hpMax
            ),
            right = nil,
            wrap = false
        })
    end

    return spec
end

-- ===== Net sync (state + delta helpers) =====================================

-- Fields we sync across the wire
Unit.SyncFields = {
    "id","key","name","team","isNPC","hp","hpMax","initiative",
    "raidMarker","unitType","unitSize","active","hidden","flying",
    "displayId","fileDataId","cam","rot","z" 
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
            if k == "isNPC" or k == "active" or k == "hidden" or k == "flying" then
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
            if k == "team" or k == "hp" or k == "hpMax" or k == "initiative" or k == "raidMarker" or k == "id" then
                out[k] = tonumber(v) or 0
            elseif k == "isNPC" or k == "active" or k == "hidden" or k == "flying" then
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
