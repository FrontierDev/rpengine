-- RPE/Core/Comms/Broadcast.lua
RPE         = RPE or {}
RPE.Core    = RPE.Core or {}
RPE.Core.Comms = RPE.Core.Comms or {}

local Comms = RPE.Core.Comms
local Broadcast = RPE.Core.Comms.Broadcast or {}
RPE.Core.Comms.Broadcast = Broadcast

-- local helpers (mirror Supergroup’s GetFullName logic lightly)
local function toKey(fullName)  -- canonical lowercased key
    return type(fullName) == "string" and fullName:lower() or nil
end


-- Fix concat + full name
local function GetFullName(unit)
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then
        return name .. "-" .. realm:gsub("%s+", "")
    else
        return name .. "-" .. GetRealmName():gsub("%s+", "")
    end
end

local function IsInMyBlizzardGroup(fullNameKey)
    if not fullNameKey then return false end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local fn = GetFullName("raid" .. i)
            if fn and toKey(fn) == fullNameKey then return true end
        end
        return false
    end
    if IsInGroup() then
        local me = GetFullName("player")
        if me and toKey(me) == fullNameKey then return true end
        for i = 1, GetNumSubgroupMembers() do
            local fn = GetFullName("party" .. i)
            if fn and toKey(fn) == fullNameKey then return true end
        end
        return false
    end
    local me = GetFullName("player")
    return me and toKey(me) == fullNameKey
end


-- local helpers
-- Percent-escape to keep ";" safe in descriptions
local function _esc(s)
    if s == nil then return "" end
    s = tostring(s)
    s = s:gsub("%%", "%%25"):gsub(";", "%%3B"):gsub("\n", "%%0A")
    return s
end

local function _toUnitId(x)
    -- number
    if type(x) == "number" then
        x = math.floor(x)
        return (x > 0) and x or nil
    end

    -- unit table (EventUnit or similar)
    if type(x) == "table" then
        if tonumber(x.id) then return tonumber(x.id) end
        if type(x.key) == "string" then
            local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
            local u  = ev and ev.units and ev.units[x.key:lower()]
            if u and tonumber(u.id) then return tonumber(u.id) end
        end
        return nil
    end

    -- string: numeric id OR event key ("npc:...:<id>" or "Name-Realm")
    if type(x) == "string" then
        local n = tonumber(x)
        if n then n = math.floor(n); return (n > 0) and n or nil end

        local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
        if ev and ev.units then
            local key = x:gsub("%s+", ""):lower()
            local u = ev.units[key]
            if u and tonumber(u.id) then return tonumber(u.id) end
        end
    end

    return nil
end

local function _sendAll(prefix, flat)
    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    if IsInRaid() then
        Comms:Send(prefix, flat, "RAID")
    elseif IsInGroup() then
        Comms:Send(prefix, flat, "PARTY")
    else
        Comms:Send(prefix, flat, "WHISPER", UnitName("player"))
    end

    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                Comms:Send(prefix, flat, "WHISPER", memberKey)
            end
        end
    end
end


--- Build a flat payload for the ruleset (name ; count ; k1 ; v1 ; k2 ; v2 ; ...)
local function BuildRulesetPayload(rs)
    local payload = {}
    payload[#payload+1] = rs.name or "UnnamedRuleset"

    -- count and k/v pairs (values serialized as strings; arrays become "{a,b,c}")
    local kv = {}
    local count = 0
    for k, v in pairs(rs.rules or {}) do
        count = count + 1
        kv[#kv+1] = tostring(k)
        if type(v) == "table" then
            -- treat as array of scalars; join with commas and wrap in braces
            local parts = {}
            for i, vv in ipairs(v) do parts[i] = tostring(vv) end
            kv[#kv+1] = "{" .. table.concat(parts, ",") .. "}"
        elseif type(v) == "boolean" then
            kv[#kv+1] = v and "true" or "false"
        else
            kv[#kv+1] = tostring(v)
        end
    end

    payload[#payload+1] = tostring(count)
    for i = 1, #kv do payload[#payload+1] = kv[i] end
    return payload
end

--- Broadcast my active ruleset to all members of the Supergroup.
function Broadcast:SendActiveRulesetToSupergroup()
    local RulesetDB      = RPE.Profile and RPE.Profile.RulesetDB
    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    if not RulesetDB then
        RPE.Debug:Error("[Broadcast] RulesetDB missing; cannot send ruleset.")
        return
    end

    local rs = RulesetDB.LoadActiveForCurrentCharacter()
    if not rs then
        RPE.Debug:Internal("[Broadcast] No active ruleset for this character.")
        return
    end

    local payload = BuildRulesetPayload(rs)

    -- 1) Send once to my party/raid if applicable.
    if IsInRaid() then
        Comms:Send("RULESET_PUSH", payload, "RAID")
    elseif IsInGroup() then
        Comms:Send("RULESET_PUSH", payload, "PARTY")
    else
        -- solo: nothing to send on group channel
    end

    -- 2) Whisper to any Supergroup members not covered by party/raid.
    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                -- WHISPER targets are case-insensitive on modern clients; we have lowercased keys here.
                Comms:Send("RULESET_PUSH", payload, "WHISPER", memberKey)
            end
        end
    end

    RPE.Debug:Print(string.format("[Broadcast] Sent active ruleset '%s' to Supergroup.", rs.name))
end

function Broadcast:StartEvent(ev)
    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    local flat = { ev.id or "", ev.name or "" }
    flat[#flat+1] = (ev.subtext or "")
    flat[#flat+1] = (ev.difficulty or "NORMAL")

    -- serialize teamNames
    local tnParts = {}
    for i = 1, #ev.teamNames do
        tnParts[#tnParts+1] = tostring(ev.teamNames[i] or "")
    end
    flat[#flat+1] = table.concat(tnParts, ",")

    for _, u in pairs(ev.units or {}) do
        flat[#flat+1] = tostring(u.id or 0)
        flat[#flat+1] = tostring(u.key or "")
        flat[#flat+1] = tostring(u.name or "")
        flat[#flat+1] = tostring(u.team or 1)
        flat[#flat+1] = u.isNPC and "1" or "0"
        flat[#flat+1] = tostring(u.hp or 0)
        flat[#flat+1] = tostring(u.hpMax or 0)
        flat[#flat+1] = tostring(u.initiative or 0)
        flat[#flat+1] = tostring(u.raidMarker or 0)
        flat[#flat+1] = tostring(u.unitType or "")
        flat[#flat+1] = tostring(u.unitSize or "")
        flat[#flat+1] = u.active and "1" or "0"
        flat[#flat+1] = u.hidden and "1" or "0"
        flat[#flat+1] = u.flying and "1" or "0"

        -- New: serialize stats table
        local statParts = {}
        if type(u.stats) == "table" then
            for statId, val in pairs(u.stats) do
                statParts[#statParts+1] = statId .. "=" .. tostring(val or 0)
            end
        end
        flat[#flat+1] = table.concat(statParts, ",")
        flat[#flat+1] = tostring(u.fileDataId or "")
        flat[#flat+1] = tostring(u.displayId or "")
        flat[#flat+1] = tostring(u.cam or "")
        flat[#flat+1] = tostring(u.rot or "")
        flat[#flat+1] = tostring(u.z or "")
        
        -- Serialize spells (comma-separated string)
        local spellParts = {}
        if type(u.spells) == "table" then
            for _, sid in ipairs(u.spells) do
                table.insert(spellParts, tostring(sid or ""))
            end
        end
        flat[#flat+1] = table.concat(spellParts, ",")
    end

    if IsInRaid() then
        Comms:Send("START_EVENT", flat, "RAID")
    elseif IsInGroup() then
        Comms:Send("START_EVENT", flat, "PARTY")
    else
        RPE.Core.ActiveEvent:OnStart(ev) -- local start
    end

    -- 2) Whisper to any Supergroup members not covered by party/raid.
    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                Comms:Send("START_EVENT", flat, "WHISPER", memberKey)
            end
        end
    end
end

--- Tell the other members of the group to execute OnTurn().
function Broadcast:Advance(payload)
    local UnitClass = RPE.Core.Unit
    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    local flat = {}
    if payload then
        flat[#flat+1] = payload.id or ""
        flat[#flat+1] = payload.name or ""
        flat[#flat+1] = payload.subtext or ""
        flat[#flat+1] = payload.mode or ""

        if type(payload.deltas) == "table" then
            -- New compact delta wire format:
            -- id ; name ; mode ; DELTAS ; n ; (id ; op ; kv ; stats) × n
            flat[#flat+1] = "DELTAS"
            flat[#flat+1] = tostring(#payload.deltas)
            for _, d in ipairs(payload.deltas) do
                flat[#flat+1] = tostring(d.id or 0)
                flat[#flat+1] = tostring(d.op or "U")
                -- IMPORTANT: KVEncode/StatsEncode already percent-escape commas/equals/;/%/LF
                local kvCSV    = UnitClass.KVEncode(d.fields or {})
                local statsCSV = UnitClass.StatsEncode(d.stats or {})
                flat[#flat+1] = kvCSV
                flat[#flat+1] = statsCSV
            end
        else
            -- Legacy: full-units payload (unchanged)
            for _, u in pairs(payload.units or {}) do
                flat[#flat+1] = tostring(u.id or 0)
                flat[#flat+1] = tostring(u.key or "")
                flat[#flat+1] = tostring(u.name or "")
                flat[#flat+1] = tostring(u.team or 1)
                flat[#flat+1] = u.isNPC and "1" or "0"
                flat[#flat+1] = tostring(u.hp or 0)
                flat[#flat+1] = tostring(u.hpMax or 0)
                flat[#flat+1] = tostring(u.initiative or 0)
                flat[#flat+1] = tostring(u.raidMarker or 0)
                flat[#flat+1] = tostring(u.unitType or "")
                flat[#flat+1] = tostring(u.unitSize or "")
                flat[#flat+1] = u.active and "1" or "0"
                flat[#flat+1] = u.hidden and "1" or "0"
                flat[#flat+1] = u.flying and "1" or "0"
                -- stats as key=value CSV
                local statsCSV = UnitClass.StatsEncode(u.stats or {})
                flat[#flat+1] = statsCSV
            end
        end
    end

    -- To Blizzard group (RAID/INSTANCE_CHAT) and whisper to off-group supergroup members
    _sendAll("ADVANCE", flat)
end

function Broadcast:EndEvent()
    _sendAll("END_EVENT", { "ok" })
end

--- Apply aura (minimal: auraId + description text).
--- opts: { stacks?:number, instanceId?:string }
function Broadcast:AuraApply(source, target, auraId, description, opts)
    opts = opts or {}
    if not auraId or auraId == "" then return end
    local sId = _toUnitId(source) or 0
    local tId = _toUnitId(target) or 0
    if tId == 0 then return end

    local inst = opts.instanceId
    if not inst and RPE and RPE.Common and RPE.Common.GenerateGUID then
        inst = RPE.Common:GenerateGUID("AUR")
    end

    local flat = {
        tostring(sId),
        tostring(tId),
        tostring(auraId),
        tostring(inst or ""),
        tostring(tonumber(opts.stacks or 0) or 0),
        _esc(description or ""),
    }

    _sendAll("AURA_APPLY", flat)
end

--- Remove aura; prefer instanceId if known, otherwise remove by auraId (optionally by source).
--- opts: { instanceId?:string, fromSource?:number|table }
--- Remove aura by id (optionally by source).
function Broadcast:AuraRemove(target, auraId, fromSource)
    local tId = _toUnitId(target) or 0
    if tId == 0 or not auraId or auraId == "" then return end
    local sId = _toUnitId(fromSource) or 0

    local flat = {
        tostring(tId),
        tostring(auraId),
        tostring(sId),   -- 0 => no source filter
    }
    _sendAll("AURA_REMOVE", flat)
end

--- Dispel (types CSV, max count, choose helpful vs harmful).
function Broadcast:AuraDispel(target, types, maxCount, helpful)
    local tId = _toUnitId(target) or 0
    if tId == 0 then return end
    local csv = table.concat(types or {}, ",")
    local flat = {
        tostring(tId),
        csv,
        tostring(maxCount or 1),
        helpful and "1" or "0",
    }
    _sendAll("AURA_DISPEL", flat)
end

-- === Scaffold: remote stat modifications (disabled) =========================
function Broadcast:_AuraStatModify(target, payload)
    -- placeholder; intentionally not broadcasting until policy decided
end

--- Broadcast damage to one or many targets in a single message (no text field).
--- Back-compat single-target:
---   Broadcast:Damage(source, target, amount, opts)   -- opts: { school?, crit?, threat? }
--- New multi-target:
---   Broadcast:Damage(source, {
---       { target=t1, amount=12, school="FIRE",  crit=true,  threat=20 },
---       { t2, 7, "ICE", false, 7 }, -- tuple-style also allowed
---   })
function Broadcast:Damage(source, targets, amount, opts)
    local sId = _toUnitId(source) or 0
    local flat = { tostring(sId) }

    local function push_one(tgt, amt, o)
        local tId = _toUnitId(tgt) or 0
        local a   = math.max(0, math.floor(tonumber(amt) or 0))
        if tId == 0 or a <= 0 then return end
        local school = tostring((o and o.school) or "")
        local crit   = ((o and o.crit) and "1") or "0"
        local tDelta = (o and o.threat ~= nil) and tostring(math.floor(tonumber(o.threat) or 0)) or ""
        flat[#flat+1] = tostring(tId)
        flat[#flat+1] = tostring(a)
        flat[#flat+1] = school
        flat[#flat+1] = crit
        flat[#flat+1] = tDelta
    end

    local is_tbl = type(targets) == "table"
    local looks_like_entry_list = is_tbl and ((type(targets[1]) == "table") or (targets.target ~= nil and targets.amount ~= nil))

    if looks_like_entry_list then
        local list = targets
        if (list.target ~= nil and list.amount ~= nil) then list = { list } end
        for _, e in ipairs(list) do
            local tgt = (e.target ~= nil) and e.target or e[1]
            local amt = (e.amount ~= nil) and e.amount or e[2]
            local o = {
                school = (e.school ~= nil) and e.school or e[3],
                crit   = (e.crit   ~= nil) and e.crit   or e[4],
                threat = (e.threat ~= nil) and e.threat or e[5],
            }
            push_one(tgt, amt, o)
        end
    else
        -- Back-compat single-target path
        push_one(targets, amount, opts or {})
    end

    if #flat > 1 then
        _sendAll("DAMAGE", flat)
    end
end

--- Broadcast healing to one or many targets in a single message (no text field).
--- Back-compat single-target:
---   Broadcast:Heal(source, target, amount, opts)   -- opts: { crit?, threat? }
--- New multi-target:
---   Broadcast:Heal(source, {
---       { target=t1, amount=12, crit=true,  threat=20 },
---       { t2, 7, false, 7 }, -- tuple-style also allowed
---   })
function Broadcast:Heal(source, targets, amount, opts)
    local sId = _toUnitId(source) or 0
    local flat = { tostring(sId) }

    local function push_one(tgt, amt, o)
        local tId = _toUnitId(tgt) or 0
        local a   = math.max(0, math.floor(tonumber(amt) or 0))
        if tId == 0 or a <= 0 then return end
        local crit   = ((o and o.crit) and "1") or "0"
        local tDelta = (o and o.threat ~= nil) and tostring(math.floor(tonumber(o.threat) or 0)) or ""
        flat[#flat+1] = tostring(tId)
        flat[#flat+1] = tostring(a)
        flat[#flat+1] = crit
        flat[#flat+1] = tDelta
    end

    local is_tbl = type(targets) == "table"
    local looks_like_entry_list = is_tbl and ((type(targets[1]) == "table") or (targets.target ~= nil and targets.amount ~= nil))

    if looks_like_entry_list then
        local list = targets
        if (list.target ~= nil and list.amount ~= nil) then list = { list } end
        for _, e in ipairs(list) do
            local tgt = (e.target ~= nil) and e.target or e[1]
            local amt = (e.amount ~= nil) and e.amount or e[2]
            local o = {
                crit   = (e.crit   ~= nil) and e.crit   or e[3],
                threat = (e.threat ~= nil) and e.threat or e[4],
            }
            push_one(tgt, amt, o)
        end
    else
        -- Back-compat single-target path
        push_one(targets, amount, opts or {})
    end

    if #flat > 1 then
        _sendAll("HEAL", flat)
    end
end

--- Broadcast health update for any unit (player or NPC)
---@param unitId integer|nil Unit ID to update health for (nil = local player)
---@param hp number|nil Current health (nil for player = Resources:Get("HEALTH"))
---@param hpMax number|nil Maximum health (nil for player = Resources:Get("HEALTH"))
function Broadcast:UpdateUnitHealth(unitId, hp, hpMax)
    local tId
    
    if not unitId then
        -- Player case: resolve ID and defaults
        local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
        if not ev or not ev.units then return end
        tId = RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
        
        -- Resolve HP values with fallback to Resources
        local curHP = tonumber(hp)
        local maxHP = tonumber(hpMax)
        if not (curHP and maxHP) and RPE and RPE.Core and RPE.Core.Resources and RPE.Core.Resources.Get then
            local c, m = RPE.Core.Resources:Get("HEALTH")
            curHP = curHP or tonumber(c)
            maxHP = maxHP or tonumber(m)
        end
        hp = curHP
        hpMax = maxHP
    else
        -- Any unit case: convert ID
        tId = _toUnitId(unitId) or 0
        if tId == 0 then return end
        hp = tonumber(hp) or 0
        hpMax = tonumber(hpMax) or 0
    end
    
    local flat = {
        tostring(tId),
        tostring(hp),
        tostring(hpMax),
    }
    
    _sendAll("UNIT_HEALTH", flat)
end


--- Broadcast an NPC attack/spell cast at a player target.
--- Includes spell info, hit parameters, and predicted damage so player can respond.
---@param source integer NPC unit ID
---@param target integer Player unit ID  
---@param spellId string Spell ID being cast
---@param spellName string Display name of spell
---@param hitSystem string "complex"|"simple"|"ac" - how to resolve the hit
---@param attackRoll number Total attack roll (1d20 + modifier) already rolled by attacker
---@param thresholdStats table Array of defense stat IDs (for complex) or single (for simple)
---@param damageBySchool table|number Damage by school {[school]=amount} or single number for backwards compatibility
---@param auraEffects table Array of aura effects to apply on hit
function Broadcast:AttackSpell(source, target, spellId, spellName, hitSystem, attackRoll, thresholdStats, damageBySchool, auraEffects)
    local sId = _toUnitId(source) or 0
    local tId = _toUnitId(target) or 0
    if sId == 0 or tId == 0 or not spellId or not spellName then return end

    -- Serialize threshold stats (array of stat IDs)
    local statCSV = ""
    if type(thresholdStats) == "table" then
        local parts = {}
        for _, stat in ipairs(thresholdStats) do
            table.insert(parts, tostring(stat or ""))
        end
        statCSV = table.concat(parts, ",")
    elseif type(thresholdStats) == "string" then
        statCSV = thresholdStats
    end

    -- Serialize damage by school (table of {[school] = amount})
    -- Format: school1:amount1,school2:amount2,...
    local damageCSV = ""
    if type(damageBySchool) == "table" then
        local parts = {}
        for school, amount in pairs(damageBySchool) do
            if tonumber(amount) and tonumber(amount) > 0 then
                table.insert(parts, school .. ":" .. math.floor(tonumber(amount)))
            end
        end
        damageCSV = table.concat(parts, ",")
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(('[Broadcast] ATTACK_SPELL damageCSV: %s'):format(damageCSV))
        end
    elseif type(damageBySchool) == "number" and damageBySchool > 0 then
        -- Fallback for old code passing just a number
        damageCSV = "Physical:" .. math.floor(damageBySchool)
    end

    -- Serialize aura effects (table of {auraId, actionKey, args} from triggered aura effects)
    local auraEffectsJSON = ""
    if type(auraEffects) == "table" and #auraEffects > 0 then
        local auraStrings = {}
        for _, effect in ipairs(auraEffects) do
            -- Format: auraId|actionKey|argsJSON
            if effect.auraId and effect.actionKey then
                local argsStr = effect.argsJSON or ""
                table.insert(auraStrings, effect.auraId .. "|" .. effect.actionKey .. "|" .. argsStr)
            end
        end
        auraEffectsJSON = table.concat(auraStrings, "||")
    end

    local flat = {
        tostring(sId),
        tostring(tId),
        tostring(spellId),
        tostring(spellName),
        tostring(hitSystem or "complex"),
        tostring(math.floor(tonumber(attackRoll) or 0)),
        statCSV,
        damageCSV,
        auraEffectsJSON,
    }

    _sendAll("ATTACK_SPELL", flat)
end

--- Broadcast an NPC/controlled unit message to the group
---@param unitId integer NPC unit ID
---@param unitName string Display name of the NPC
---@param message string The message to broadcast
function Broadcast:SendNPCMessage(unitId, unitName, message)
    if not unitId or not unitName or not message then return end
    
    local flat = {
        tostring(tonumber(unitId) or 0),
        tostring(unitName),
        tostring(message),
    }
    
    _sendAll("NPC_MESSAGE", flat)
end