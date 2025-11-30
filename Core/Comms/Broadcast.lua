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
-- Rulesets are sent as semicolon-delimited arrays and are chunked/reassembled by CommsManager
-- No escaping needed - the system handles raw data correctly
local function _esc(s)
    return tostring(s or "")
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
--- Stream ruleset to supergroup members (metadata first, then individual rules)
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

    self:_StreamRuleset(rs)
end

-- Stream a single ruleset to supergroup (sends metadata, then rules)
function Broadcast:_StreamRuleset(rs)
    if not rs or not rs.name then
        RPE.Debug:Error("[Broadcast] Invalid ruleset to stream")
        return
    end

    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    local channels = {}
    
    -- Determine channels to send on
    if IsInRaid() then
        channels[#channels+1] = { type = "RAID" }
    elseif IsInGroup() then
        channels[#channels+1] = { type = "PARTY" }
    end
    
    -- Add supergroup members via whisper
    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                channels[#channels+1] = { type = "WHISPER", target = memberKey }
            end
        end
    end

    if #channels == 0 then return end

    -- Send metadata first
    local metaPayload = {
        rs.name,
    }
    
    for _, ch in ipairs(channels) do
        if ch.type == "WHISPER" then
            Comms:Send("RULESET_META", metaPayload, ch.type, ch.target)
        else
            Comms:Send("RULESET_META", metaPayload, ch.type)
        end
    end

    -- Stream each rule as individual key-value pair
    for ruleKey, ruleValue in pairs(rs.rules or {}) do
        -- Serialize the value (might be string, number, boolean, or table)
        local valueStr
        if type(ruleValue) == "string" then
            valueStr = string.format("%q", ruleValue)  -- properly quoted string
        elseif type(ruleValue) == "number" or type(ruleValue) == "boolean" then
            valueStr = tostring(ruleValue)
        elseif type(ruleValue) == "table" then
            -- For table values, use _ser to serialize them
            valueStr = self:_ser(ruleValue)
        else
            valueStr = "nil"
        end
        
        -- Escape the serialized value for safe transmission
        valueStr = _esc(valueStr)
        
        local rulePayload = { rs.name, ruleKey, valueStr }
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("RULESET_RULE", rulePayload, ch.type, ch.target)
            else
                Comms:Send("RULESET_RULE", rulePayload, ch.type)
            end
        end
    end

    -- Send completion signal
    local completePayload = { rs.name }
    for _, ch in ipairs(channels) do
        if ch.type == "WHISPER" then
            Comms:Send("RULESET_COMPLETE", completePayload, ch.type, ch.target)
        else
            Comms:Send("RULESET_COMPLETE", completePayload, ch.type)
        end
    end

    -- Count rules (use pairs iteration to handle sparse tables)
    local ruleCount = 0
    for _ in pairs(rs.rules or {}) do ruleCount = ruleCount + 1 end
    RPE.Debug:Print(string.format("[Broadcast] Streamed ruleset '%s' (%d rules)", rs.name, ruleCount))
end

--- Stream dataset objects to supergroup members (one object at a time)
function Broadcast:SendActiveDatasetToSupergroup()
    local DatasetDB      = RPE.Profile and RPE.Profile.DatasetDB
    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    if not DatasetDB then
        RPE.Debug:Error("[Broadcast] DatasetDB missing; cannot send datasets.")
        return
    end

    local names = DatasetDB.GetActiveNamesForCurrentCharacter()
    if not names or #names == 0 then
        RPE.Debug:Internal("[Broadcast] No active datasets for this character.")
        return
    end

    -- Default datasets that don't need to be sent (built-in)
    local DEFAULT_DATASETS = { "DefaultClassic", "Default5e", "DefaultWarcraft" }
    local function isDefault(name)
        for _, dname in ipairs(DEFAULT_DATASETS) do
            if name == dname then return true end
        end
        return false
    end

    local sentNames = {}
    
    -- Stream each active dataset
    for _, name in ipairs(names) do
        if not isDefault(name) then
            local ds = DatasetDB.GetByName(name)
            if ds then
                self:_StreamDataset(ds)
                sentNames[#sentNames+1] = name
            end
        end
    end

    if #sentNames == 0 then
        RPE.Debug:Internal("[Broadcast] Only default/inactive datasets active; nothing to send.")
        return
    end

    RPE.Debug:Print(string.format("[Broadcast] Streaming %d custom datasets to Supergroup: %s", #sentNames, table.concat(sentNames, ", ")))
end

-- Stream a single dataset to supergroup (sends metadata, then objects)
function Broadcast:_StreamDataset(ds)
    if not ds or not ds.name then
        RPE.Debug:Error("[Broadcast] Invalid dataset to stream")
        return
    end

    -- Debug: log what's in the dataset before streaming
    RPE.Debug:Internal(string.format("[Broadcast] Dataset '%s' before stream: items=%d, spells=%d, auras=%d, npcs=%d", 
        ds.name, 
        (ds.items and #(ds.items or {})) or 0,
        (ds.spells and #(ds.spells or {})) or 0,
        (ds.auras and #(ds.auras or {})) or 0,
        (ds.npcs and #(ds.npcs or {})) or 0
    ))
    
    -- Debug: also show actual keys
    if ds.items then
        local itemKeys = {}
        for k in pairs(ds.items) do itemKeys[#itemKeys+1] = k end
        RPE.Debug:Internal(string.format("[Broadcast] Dataset items: %s", table.concat(itemKeys, ", ")))
    end

    local ActiveSupergrp = RPE.Core and RPE.Core.ActiveSupergroup
    local channels = {}
    
    -- Determine channels to send on
    if IsInRaid() then
        channels[#channels+1] = { type = "RAID" }
    elseif IsInGroup() then
        channels[#channels+1] = { type = "PARTY" }
    end
    
    -- Add supergroup members via whisper
    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                channels[#channels+1] = { type = "WHISPER", target = memberKey }
            end
        end
    end

    if #channels == 0 then return end

    -- Send metadata first (including autoActivate flag)
    local metaPayload = {
        ds.name,
        tostring(ds.guid or ""),
        tostring(ds.version or 1),
        ds.author or "",
        ds.notes or "",
        "1",  -- autoActivate: 1=true (activate when received), 0=false (just save, don't activate)
    }
    
    for _, ch in ipairs(channels) do
        if ch.type == "WHISPER" then
            Comms:Send("DATASET_META", metaPayload, ch.type, ch.target)
        else
            Comms:Send("DATASET_META", metaPayload, ch.type)
        end
    end

    -- Stream items
    for itemId, itemDef in pairs(ds.items or {}) do
        RPE.Debug:Internal(string.format("[Broadcast] Item %s: type=%s, has_icon=%s", itemId, type(itemDef), 
            (type(itemDef) == "table" and (itemDef.icon or itemDef.iconId)) or "N/A"))
        
        -- Ensure item has an icon field (check both 'icon' and 'iconId', normalize to 'icon')
        local itemToSend = itemDef or {}
        if type(itemToSend) == "table" then
            itemToSend = {}
            for k, v in pairs(itemDef) do itemToSend[k] = v end
            -- Normalize icon field: use 'icon' if present, otherwise try 'iconId', otherwise default
            if not itemToSend.icon then
                itemToSend.icon = itemToSend.iconId or 134400
            end
            -- Remove iconId if it exists to avoid duplication
            itemToSend.iconId = nil
        end
        
        local serialized = self:_ser(itemToSend)
        RPE.Debug:Internal(string.format("[Broadcast] Item %s serialized (%d bytes): %s", itemId, #serialized, serialized:sub(1, 150)))
        -- Format: datasetName|itemId|rawSerializedObject (no escaping needed - object is last field)
        local msg = ds.name .. "|" .. itemId .. "|" .. serialized
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("DATASET_ITEM", msg, ch.type, ch.target)
            else
                Comms:Send("DATASET_ITEM", msg, ch.type)
            end
        end
    end

    -- Stream spells
    for spellId, spellDef in pairs(ds.spells or {}) do
        -- Ensure spell has an icon field (default to 132222 if missing)
        local spellToSend = spellDef or {}
        if type(spellToSend) == "table" then
            spellToSend = {}
            for k, v in pairs(spellDef) do spellToSend[k] = v end
            if not spellToSend.icon then
                spellToSend.icon = 132222  -- Default spell icon
            end
        end
        -- Format: datasetName|spellId|rawSerializedObject (no escaping needed - object is last field)
        local msg = ds.name .. "|" .. spellId .. "|" .. self:_ser(spellToSend)
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("DATASET_SPELL", msg, ch.type, ch.target)
            else
                Comms:Send("DATASET_SPELL", msg, ch.type)
            end
        end
    end

    -- Stream auras
    for auraId, auraDef in pairs(ds.auras or {}) do
        -- Ensure aura has an icon field (default to 132223 if missing)
        local auraToSend = auraDef or {}
        if type(auraToSend) == "table" then
            auraToSend = {}
            for k, v in pairs(auraDef) do auraToSend[k] = v end
            if not auraToSend.icon then
                auraToSend.icon = 132223  -- Default aura icon
            end
        end
        -- Format: datasetName|auraId|rawSerializedObject (no escaping needed - object is last field)
        local msg = ds.name .. "|" .. auraId .. "|" .. self:_ser(auraToSend)
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("DATASET_AURA", msg, ch.type, ch.target)
            else
                Comms:Send("DATASET_AURA", msg, ch.type)
            end
        end
    end

    -- Stream NPCs
    for npcId, npcDef in pairs(ds.npcs or {}) do
        local npcToSend = npcDef or {}
        if type(npcToSend) == "table" then
            npcToSend = {}
            for k, v in pairs(npcDef) do npcToSend[k] = v end
        end
        -- Format: datasetName|npcId|rawSerializedObject (no escaping needed - object is last field)
        local msg = ds.name .. "|" .. npcId .. "|" .. self:_ser(npcToSend)
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("DATASET_NPC", msg, ch.type, ch.target)
            else
                Comms:Send("DATASET_NPC", msg, ch.type)
            end
        end
    end

    -- Stream extra categories (stats, interactions, recipes, achievements, etc.)
    for categoryName, categoryItems in pairs(ds.extra or {}) do
        if type(categoryItems) == "table" then
            local messageType = "DATASET_" .. categoryName:upper()
            for itemId, itemDef in pairs(categoryItems) do
                local itemToSend = itemDef or {}
                if type(itemToSend) == "table" then
                    itemToSend = {}
                    for k, v in pairs(itemDef) do itemToSend[k] = v end
                end
                -- Format: datasetName|itemId|rawSerializedObject (no escaping needed - object is last field)
                local msg = ds.name .. "|" .. itemId .. "|" .. self:_ser(itemToSend)
                for _, ch in ipairs(channels) do
                    if ch.type == "WHISPER" then
                        Comms:Send(messageType, msg, ch.type, ch.target)
                    else
                        Comms:Send(messageType, msg, ch.type)
                    end
                end
            end
        end
    end

    -- Send completion signal
    local completePayload = { ds.name }
    for _, ch in ipairs(channels) do
        if ch.type == "WHISPER" then
            Comms:Send("DATASET_COMPLETE", completePayload, ch.type, ch.target)
        else
            Comms:Send("DATASET_COMPLETE", completePayload, ch.type)
        end
    end

    local counts = ds:Counts()
    local extraCounts = {}
    for categoryName, categoryItems in pairs(ds.extra or {}) do
        if type(categoryItems) == "table" then
            local count = 0
            for _ in pairs(categoryItems) do count = count + 1 end
            if count > 0 then
                table.insert(extraCounts, string.format("%s=%d", categoryName, count))
            end
        end
    end
    local extraStr = (#extraCounts > 0) and (", " .. table.concat(extraCounts, ", ")) or ""
    RPE.Debug:Print(string.format("[Broadcast] Streamed dataset '%s' (%d items, %d spells, %d auras, %d npcs%s)",
        ds.name, counts.items, counts.spells, counts.auras, counts.npcs, extraStr))
end

-- Simple table serializer for small objects (with escaping for safe transmission)
-- Simple table serializer for small objects (NO internal escaping - escaping happens at transmission)
function Broadcast:_ser(tbl)
    if type(tbl) ~= "table" then return tostring(tbl) end
    local parts = {}
    
    -- First, check if this looks like an array (has numeric indices)
    local maxIndex = 0
    local hasNumericKeys = false
    for k in pairs(tbl) do
        if type(k) == "number" then
            hasNumericKeys = true
            if k > maxIndex then maxIndex = k end
        end
    end
    
    -- If it looks like an array, serialize it as an array
    if hasNumericKeys and maxIndex > 0 then
        for i = 1, maxIndex do
            local v = tbl[i]
            local valueStr
            if type(v) == "string" then
                valueStr = string.format("%q", v)
            elseif type(v) == "number" or type(v) == "boolean" then
                valueStr = tostring(v)
            elseif type(v) == "table" then
                valueStr = self:_ser(v)
            else
                valueStr = "nil"
            end
            parts[#parts+1] = valueStr
        end
        -- Array: {val1,val2,...}
        return "{" .. table.concat(parts, ",") .. "}"
    end
    
    -- Otherwise serialize as a table with key=value pairs
    -- Collect all keys and sort them for consistent ordering
    local keys = {}
    for k in pairs(tbl) do
        if type(k) ~= "number" then  -- Skip numeric keys in dict mode
            table.insert(keys, k)
        end
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    
    -- Serialize in sorted order
    for _, k in ipairs(keys) do
        local v = tbl[k]
        -- Determine if key needs quoting (valid Lua identifier: starts with letter/underscore, contains only alphanumeric/underscore)
        local keyStr
        if type(k) == "string" and k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
            keyStr = k  -- Valid identifier, use as-is
        else
            keyStr = string.format("[%q]", tostring(k))  -- Invalid identifier, use bracket notation with quoted key
        end
        
        -- Serialize value
        local valueStr
        if type(v) == "string" then
            valueStr = string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            valueStr = tostring(v)
        elseif type(v) == "table" then
            valueStr = self:_ser(v)
        else
            valueStr = "nil"
        end
        
        parts[#parts+1] = keyStr .. "=" .. valueStr
    end
    -- Return raw Lua table string (no escaping needed for pipe-delimited messages)
    return "{" .. table.concat(parts, ",") .. "}"
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