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
        RPE.Debug:Internal(string.format("[Broadcast] _sendAll(%s) sending to RAID", prefix))
        Comms:Send(prefix, flat, "RAID")
    elseif IsInGroup() then
        RPE.Debug:Internal(string.format("[Broadcast] _sendAll(%s) sending to PARTY", prefix))
        Comms:Send(prefix, flat, "PARTY")
    else
        RPE.Debug:Internal(string.format("[Broadcast] _sendAll(%s) sending to WHISPER (solo)", prefix))
        Comms:Send(prefix, flat, "WHISPER", UnitName("player"))
    end

    if ActiveSupergrp and ActiveSupergrp.GetMembers then
        local myKey = toKey(GetFullName("player"))
        for _, memberKey in ipairs(ActiveSupergrp:GetMembers()) do
            if memberKey ~= myKey and not IsInMyBlizzardGroup(memberKey) then
                RPE.Debug:Internal(string.format("[Broadcast] _sendAll(%s) sending WHISPER to supergroup member %s", prefix, memberKey))
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
    
    -- Clear any hash mismatch locks since we just sent our ruleset
    self:_clearHashMismatchLocks()
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
    RPE.Debug:Print(string.format("[Broadcast] Streamed ruleset '%s' (%d rules in total)", rs.name, ruleCount))
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

    RPE.Debug:Print(string.format("[Broadcast] Streaming %d custom datasets to supergroup: %s", #sentNames, table.concat(sentNames, ", ")))
    
    -- Clear any hash mismatch locks since we just sent our datasets
    self:_clearHashMismatchLocks()
end

-- Stream a single dataset to supergroup (sends metadata, then objects)
function Broadcast:_StreamDataset(ds)
    if not ds or not ds.name then
        RPE.Debug:Error("[Broadcast] Invalid dataset to stream")
        return
    end

    -- Debug: log what's in the dataset before streaming
    local counts = ds:Counts()
    local extraCounts = {}
    for categoryName, categoryItems in pairs(ds.extra or {}) do
        if type(categoryItems) == "table" then
            local count = 0
            for _ in pairs(categoryItems) do count = count + 1 end
            if count > 0 then
                extraCounts[categoryName] = count
            end
        end
    end
    
    local recipeCount = ds.recipes and 0 or 0
    if ds.recipes then
        for _ in pairs(ds.recipes) do recipeCount = recipeCount + 1 end
    end
    
    local extraStr = ""
    if recipeCount > 0 then extraStr = extraStr .. ", recipes=" .. recipeCount end
    for categoryName, count in pairs(extraCounts) do
        extraStr = extraStr .. ", " .. categoryName .. "=" .. count
    end
    
    RPE.Debug:Internal(string.format("[Broadcast] Dataset '%s' before stream: items=%d, spells=%d, auras=%d, npcs=%d%s", 
        ds.name, counts.items, counts.spells, counts.auras, counts.npcs, extraStr))
    
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
        ds.description or "",
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

    -- Stream setup wizard if present
    if ds.setupWizard and type(ds.setupWizard) == "table" then
        local wizardStr = self:_ser(ds.setupWizard)
        for _, ch in ipairs(channels) do
            if ch.type == "WHISPER" then
                Comms:Send("DATASET_SETUP_WIZARD", { ds.name, wizardStr }, ch.type, ch.target)
            else
                Comms:Send("DATASET_SETUP_WIZARD", { ds.name, wizardStr }, ch.type)
            end
        end
    end

    -- Stream metadata (description and security level)
    local metaFlags = {
        ds.name,
        ds.description or "",
        ds.securityLevel or "Open",
    }
    for _, ch in ipairs(channels) do
        if ch.type == "WHISPER" then
            Comms:Send("DATASET_META_FLAGS", metaFlags, ch.type, ch.target)
        else
            Comms:Send("DATASET_META_FLAGS", metaFlags, ch.type)
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
    flat[#flat+1] = (ev.turnOrderType or "INITIATIVE")

    -- serialize teamNames and teamResourceIds
    local tnParts = {}
    if ev.teamNames and type(ev.teamNames) == "table" then
        for i = 1, #ev.teamNames do
            tnParts[#tnParts+1] = tostring(ev.teamNames[i] or "")
        end
    end
    flat[#flat+1] = table.concat(tnParts, ",")
    
    local trParts = {}
    if ev.teamResourceIds and type(ev.teamResourceIds) == "table" then
        for i = 1, #ev.teamResourceIds do
            local resId = ev.teamResourceIds[i] or ""
            trParts[#trParts+1] = (resId ~= "") and tostring(resId) or "nil"
        end
    end
    flat[#flat+1] = table.concat(trParts, ",")

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
        flat[#flat+1] = tostring(u.summonedBy or 0)
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

--- Resync a single player with the full event state (player logged in during event).
--- Only sends to the specified player via whisper.
---@param playerKey string  -- "Name-Realm" (lowercased) of the player to resync
function Broadcast:ResyncPlayer(playerKey)
    if not playerKey or playerKey == "" then return end
    
    local ev = RPE.Core.ActiveEvent
    if not ev or not ev.units then
        RPE.Debug:Warning("[Broadcast] ResyncPlayer: No active event to resync")
        return
    end
    
    -- Build the same payload as StartEvent, but include current turn/tick info
    local flat = { ev.id or "", ev.name or "" }
    flat[#flat+1] = (ev.subtext or "")
    flat[#flat+1] = (ev.difficulty or "NORMAL")
    flat[#flat+1] = (ev.turnOrderType or "INITIATIVE")

    -- Add turn and tickIndex so player catches up to current progress
    flat[#flat+1] = tostring(ev.turn or 1)
    flat[#flat+1] = tostring(ev.tickIndex or 0)

    -- serialize teamNames and teamResourceIds
    local tnParts = {}
    for i = 1, #ev.teamNames do
        tnParts[#tnParts+1] = tostring(ev.teamNames[i] or "")
    end
    flat[#flat+1] = table.concat(tnParts, ",")
    
    local trParts = {}
    for i = 1, #ev.teamResourceIds do
        local resId = ev.teamResourceIds[i] or ""
        trParts[#trParts+1] = (resId ~= "") and tostring(resId) or "nil"
    end
    flat[#flat+1] = table.concat(trParts, ",")

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

        -- Serialize stats table
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
        flat[#flat+1] = tostring(u.summonedBy or 0)
        
        -- Serialize auras for this unit
        local auraParts = {}
        if ev._auraManager then
            local auras = ev._auraManager:All(u.id)
            for _, aura in ipairs(auras or {}) do
                if aura and aura.def then
                    -- Format: auraId|instanceId|stacks|duration
                    local auraEntry = string.format("%s|%s|%d|%d",
                        tostring(aura.def.id or ""),
                        tostring(aura.instanceId or ""),
                        tonumber(aura.stacks or 1),
                        tonumber(aura.duration or 0)
                    )
                    table.insert(auraParts, auraEntry)
                end
            end
        end
        flat[#flat+1] = table.concat(auraParts, ",")
    end

    -- Send only to the specified player via whisper
    local playerName = playerKey:match("^([^-]+)") or playerKey
    Comms:Send("START_EVENT", flat, "WHISPER", playerName)
    
    RPE.Debug:Internal(string.format("[Broadcast] Resynced player %s with event state (turn %d, tick %d)", playerKey, ev.turn or 1, ev.tickIndex or 0))
end


--- Broadcast team resource update
---@param team integer Team ID
---@param amount number Amount to add to the team resource (can be negative)
function Broadcast:UpdateTeamResource(team, amount)
    if not team or not amount then return end
    local flat = { tostring(team), tostring(amount) }
    _sendAll("TEAM_RESOURCE", flat)
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
                flat[#flat+1] = tostring(u.summonedBy or 0)
            end
        end
    end

    -- To Blizzard group (RAID/INSTANCE_CHAT) and whisper to off-group supergroup members
    _sendAll("ADVANCE", flat)
end

function Broadcast:EndEvent()
    _sendAll("END_EVENT", { "ok" })
end

--- Broadcast that the current player is ending their turn
---@param unitId number -- ID of the unit ending their turn
function Broadcast:EndTurn(unitId)
    _sendAll("END_TURN", { tostring(unitId or 0) })
end

function Broadcast:SendIntermission(isIntermission)
    _sendAll("INTERMISSION", { isIntermission and "1" or "0" })
end

--- Apply aura (minimal: auraId + description text).
--- opts: { stacks?:number, rank?:number, instanceId?:string }
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
        tostring(tonumber(opts.rank or 1) or 1),
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
    
    -- Check if this damage is from an aura trigger (opts.isFromAuraTrigger)
    local isFromAuraTrigger = (opts and opts.isFromAuraTrigger) and "1" or "0"

    local function push_one(tgt, damageInfo, o)
        local tId = _toUnitId(tgt) or 0
        if tId == 0 then return end
        
        local school = ""
        local totalAmount = 0
        local crit   = false
        
        -- damageInfo can be either:
        -- 1. A number (old format): single amount for school in opts.school
        -- 2. A table with damageBySchool: multiple schools aggregated
        if type(damageInfo) == "number" then
            -- Old single-amount format
            totalAmount = math.max(0, math.floor(tonumber(damageInfo) or 0))
            school = tostring((o and o.school) or "")
            crit = (o and o.crit) and true or false
        elseif type(damageInfo) == "table" then
            -- New aggregated multi-school format
            -- Build CSV: school1:amount1,school2:amount2,...
            local schools = {}
            for sch, amt in pairs(damageInfo.damageBySchool or {}) do
                local a = math.max(0, math.floor(tonumber(amt) or 0))
                if a > 0 then
                    totalAmount = totalAmount + a
                    table.insert(schools, sch .. ":" .. a)
                end
            end
            school = table.concat(schools, ",")
            crit = (damageInfo.crit and true) or false
        end
        
        if totalAmount <= 0 then return end
        
        local tDelta = (o and o.threat ~= nil) and tostring(math.floor(totalAmount * (tonumber(o.threat) or 1))) or tostring(totalAmount)
        flat[#flat+1] = tostring(tId)
        flat[#flat+1] = tostring(totalAmount)  -- Total damage (for historical reasons)
        flat[#flat+1] = school                  -- Single school or CSV of schools:amounts
        flat[#flat+1] = crit and "1" or "0"
        flat[#flat+1] = tDelta
        flat[#flat+1] = isFromAuraTrigger       -- Flag indicating if damage originated from aura trigger
    end

    local is_tbl = type(targets) == "table"
    local looks_like_entry_list = is_tbl and ((type(targets[1]) == "table") or (targets.target ~= nil and (targets.amount ~= nil or targets.damageBySchool ~= nil)))

    if looks_like_entry_list then
        local list = targets
        if (list.target ~= nil and (list.amount ~= nil or list.damageBySchool ~= nil)) then list = { list } end
        for _, e in ipairs(list) do
            local tgt = (e.target ~= nil) and e.target or e[1]
            -- Support both old single-amount and new multi-school format
            local damageInfo = nil
            local opts_here = {}
            
            if e.damageBySchool ~= nil then
                -- New format: pass the whole table with damageBySchool
                damageInfo = e
                opts_here = { crit = e.crit, threat = e.threat }
            else
                -- Old format: single amount
                damageInfo = (e.amount ~= nil) and e.amount or e[2]
                opts_here = {
                    school = (e.school ~= nil) and e.school or e[3],
                    crit   = (e.crit   ~= nil) and e.crit   or e[4],
                    threat = (e.threat ~= nil) and e.threat or e[5],
                }
            end
            push_one(tgt, damageInfo, opts_here)
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
    
    -- Check if this heal is from an aura trigger (opts.isFromAuraTrigger)
    local isFromAuraTrigger = (opts and opts.isFromAuraTrigger) and "1" or "0"

    local function push_one(tgt, amt, o)
        local tId = _toUnitId(tgt) or 0
        local a   = math.max(0, math.floor(tonumber(amt) or 0))
        if tId == 0 or a <= 0 then return end
        local crit   = ((o and o.crit) and "1") or "0"
        local tDelta = (o and o.threat ~= nil) and tostring(math.floor(a * (tonumber(o.threat) or 1))) or ""
        flat[#flat+1] = tostring(tId)
        flat[#flat+1] = tostring(a)
        flat[#flat+1] = crit
        flat[#flat+1] = tDelta
        flat[#flat+1] = isFromAuraTrigger  -- Add flag after threat
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
---@param absorbAmount number|nil Absorption amount (optional, defaults to 0)
function Broadcast:UpdateUnitHealth(unitId, hp, hpMax, absorbAmount)
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
    
    -- Absorption amount (default to 0)
    absorbAmount = math.max(0, tonumber(absorbAmount) or 0)
    
    local flat = {
        tostring(tId),
        tostring(hp),
        tostring(hpMax),
        tostring(absorbAmount),
    }
    
    _sendAll("UNIT_HEALTH", flat)
end

--- Broadcast resurrection to one or many targets (restores 10% HP and bypasses healing restrictions).
---@param source integer Caster unit ID
---@param targets table Array of {target, amount} entries for resurrection
function Broadcast:Resurrect(source, targets)
    if not (source and targets and #targets > 0) then return end
    
    local flat = {}
    flat[#flat+1] = tostring(source or 0)
    
    for _, entry in ipairs(targets) do
        local tId = _toUnitId(entry.target or entry[1]) or 0
        local amount = math.max(0, math.floor(tonumber(entry.amount or entry[2]) or 0))
        if tId > 0 and amount > 0 then
            flat[#flat+1] = tostring(tId)
            flat[#flat+1] = tostring(amount)
        end
    end
    
    _sendAll("RESURRECT", flat)
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
---@param language string The language being spoken
function Broadcast:SendNPCMessage(unitId, unitName, message, language)
    if not unitId or not unitName or not message then return end
    
    local flat = {
        tostring(tonumber(unitId) or 0),
        tostring(unitName),
        tostring(message),
        tostring(language or "Common"),
    }
    
    _sendAll("NPC_MESSAGE", flat)
end

--- Broadcast a chat message
---@param unitId integer Unit ID of the player.
---@param unitName string Display name of the player.
---@param message string The message to broadcast
function Broadcast:SendDiceMessage(unitId, unitName, message)
    if not unitId or not unitName or not message then return end
    
    local flat = {
        tostring(tonumber(unitId) or 0),
        tostring(unitName),
        tostring(message),
    }
    
    _sendAll("DICE_MESSAGE", flat)
end

--- Broadcast a chat message
---@param unitId integer Unit ID of the player.
---@param unitName string Display name of the player.
---@param message string The message to broadcast
function Broadcast:SendCombatMessage(unitId, unitName, message)
    if not unitId or not unitName or not message then return end
    
    if RPE and RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Broadcast] SendCombatMessage: " .. tostring(message)))
    end
    
    local flat = {
        tostring(tonumber(unitId) or 0),
        tostring(unitName),
        tostring(message),
    }
    
    _sendAll("COMBAT_MESSAGE", flat)
end

--- Broadcast a summon request to the supergroup leader
--- The leader will look up the NPC and add it to the event
---@param npcId string The NPC registry ID (e.g. "NPC-5e9204c0")
---@param summonerUnitId integer The unit ID of the summoner
---@param summonerTeam integer The team of the summoner
function Broadcast:Summon(npcId, summonerUnitId, summonerTeam)
    if not npcId or not summonerUnitId then 
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Broadcast] SUMMON: Missing npcId or summoner ID"))
        end
        return 
    end
    
    local flat = {
        npcId,
        tostring(summonerUnitId),
        tostring(summonerTeam or 1),
    }
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Broadcast] SUMMON: Broadcasting summon for " .. npcId))
    end
    _sendAll("SUMMON", flat)
end

--- Broadcast shield application to one or many targets in a single message (no text field).
--- Back-compat single-target:
---   Broadcast:ApplyShield(source, target, amount, duration)
--- New multi-target:
---   Broadcast:ApplyShield(source, {
---       { target=t1, amount=12, duration=2 },
---       { t2, 7, 3 }, -- tuple-style also allowed
---   })
function Broadcast:ApplyShield(source, targets, amount, duration)
    local sId = _toUnitId(source) or 0
    RPE.Debug:Internal(string.format("[Broadcast:ApplyShield] Source: %d", sId))
    local flat = { tostring(sId) }

    local function push_one(tgt, amt, dur)
        local tId = _toUnitId(tgt) or 0
        local a   = math.max(0, math.floor(tonumber(amt) or 0))
        local d   = math.max(1, math.floor(tonumber(dur) or 1))
        if tId == 0 or a <= 0 then 
            RPE.Debug:Internal(string.format("[Broadcast:ApplyShield] Skipping invalid target: tId=%d, a=%d", tId, a))
            return 
        end
        RPE.Debug:Internal(string.format("[Broadcast:ApplyShield] Adding target: %d, amount: %d, duration: %d", tId, a, d))
        flat[#flat+1] = tostring(tId)
        flat[#flat+1] = tostring(a)
        flat[#flat+1] = tostring(d)
    end

    local is_tbl = type(targets) == "table"
    local looks_like_entry_list = is_tbl and ((type(targets[1]) == "table") or (targets.target ~= nil and targets.amount ~= nil))

    if looks_like_entry_list then
        local list = targets
        if (list.target ~= nil and list.amount ~= nil) then list = { list } end
        for _, e in ipairs(list) do
            local tgt = (e.target ~= nil) and e.target or e[1]
            local amt = (e.amount ~= nil) and e.amount or e[2]
            local dur = (e.duration ~= nil) and e.duration or e[3]
            push_one(tgt, amt, dur)
        end
    else
        -- Back-compat single-target path
        push_one(targets, amount, duration)
    end

    if #flat > 1 then
        RPE.Debug:Internal(string.format("[Broadcast:ApplyShield] Sending SHIELD message with %d entries", (#flat - 1) / 3))
        _sendAll("SHIELD", flat)
    else
        RPE.Debug:Internal("[Broadcast:ApplyShield] No valid targets to shield")
    end
end

--- Broadcast hide/visibility change for a unit.
--- Broadcast:Hide(unitId) - hides the unit
function Broadcast:Hide(unitId)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 then return end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(string.format("[Broadcast] HIDE: Broadcasting hide for unit %d", tId))
    end
    
    _sendAll("HIDE", { tostring(tId) })
end

--- Broadcast unhide for a unit.
--- Broadcast:Unhide(unitId) - unhides the unit
function Broadcast:Unhide(unitId)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 then return end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(string.format("[Broadcast] UNHIDE: Broadcasting unhide for unit %d", tId))
    end
    
    _sendAll("UNHIDE", { tostring(tId) })
end

--- Broadcast comprehensive unit state update (health, engagement, visibility, etc.)
--- This syncs all critical unit state to ensure clients are in sync
---@param unit table The EventUnit to sync
function Broadcast:UpdateState(unit)
    if not unit or not unit.id then return end
    
    local tId = tonumber(unit.id) or 0
    if tId == 0 then return end
    
    local flat = {
        tostring(tId),
        tostring(unit.hp or 0),
        tostring(unit.hpMax or 0),
        unit.engagement and "1" or "0",
        unit.hidden and "1" or "0",
        unit.active and "1" or "0",
        unit.flying and "1" or "0",
    }
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(string.format("[Broadcast] UPDATE_STATE: Unit %d (engagement=%s, hidden=%s, active=%s)",
            tId, tostring(unit.engagement), tostring(unit.hidden), tostring(unit.active)))
    end
    
    _sendAll("UPDATE_STATE", flat)
end

--- Broadcast a help call from a teammate who needs assistance
--- Teammates can use assist-tagged abilities even when it's not their turn
---@param unitId integer Unit ID of the player calling for help
---@param unitName string Display name of the player
function Broadcast:CallHelp(unitId, unitName)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 or not unitName then return end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(string.format("[Broadcast] CALL_HELP: %s (ID %d) needs help", unitName, tId))
    end
    
    _sendAll("CALL_HELP", { tostring(tId), tostring(unitName) })
end

--- Broadcast end of help call (teammate took action)
--- Resets assist spell glow and allows normal turn restrictions
---@param unitId integer Unit ID of the player ending the help call
function Broadcast:CallHelpEnd(unitId)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 then return end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(string.format("[Broadcast] CALL_HELP_END: Unit %d responded", tId))
    end
    
    _sendAll("CALL_HELP_END", { tostring(tId) })
end


--- Broadcast casting information to group members
---@param unitId integer|nil Unit ID of the caster (nil = local player)
---@param spellId string Spell ID from registry
---@param spellName string Display name of spell
---@param icon string|nil Icon texture path for the spell
---@param timeRemaining number Turns remaining in cast
---@param timeTotal number Total cast time in turns
---@param targetId integer|nil Unit ID of the cast target (optional)
function Broadcast:SendCasting(unitId, spellId, spellName, icon, timeRemaining, timeTotal, targetId)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 then return end
    
    icon = icon or ""
    timeRemaining = tonumber(timeRemaining) or 0
    timeTotal = tonumber(timeTotal) or 0
    targetId = tonumber(targetId) or 0
    
    _sendAll("CASTING", { tostring(tId), tostring(spellId), tostring(spellName), tostring(icon), tostring(timeRemaining), tostring(timeTotal), tostring(targetId) })
end

--- Broadcast clear/interrupt of casting to group members
---@param unitId integer|nil Unit ID of the caster (nil = local player)
function Broadcast:SendClearCasting(unitId)
    local tId = _toUnitId(unitId) or 0
    if tId == 0 then return end
    
    _sendAll("CLEAR_CASTING", { tostring(tId) })
end

--- Say hello to the group with TRP3 display name and dataset/ruleset hash.
--- The payload includes the TRP name and hash. Recipients who are leaders will apply the name to EventUnits
--- and check if the hash matches their own. If not, they'll initiate automatic syncing.
function Broadcast:Hello(trpName)
    if not trpName or trpName == "" then return end
    
    -- Generate hash for current datasets and ruleset
    local hash = self:_generateDatasetRulesetHash()
    
    -- Get addon version
    local addonVersion = tostring((_G.RPE and _G.RPE.AddonVersion) or "unknown")
    
    RPE.Debug:Internal(string.format("[Broadcast] _sendAll(HELLO) with name: %s, hash: %s, version: %s", trpName, hash, addonVersion))
    _sendAll("HELLO", { tostring(trpName), tostring(hash), addonVersion })
end

-- Generate a hash representing the current active datasets and ruleset (same logic as Request.lua)
function Broadcast:_generateDatasetRulesetHash()
    local hashData = {}
    
    -- Helper function to recursively hash table contents
    local function hashTable(tbl, prefix)
        if not tbl or type(tbl) ~= "table" then return end
        
        local keys = {}
        for k, _ in pairs(tbl) do
            table.insert(keys, tostring(k))
        end
        table.sort(keys)  -- Ensure consistent ordering
        
        for _, k in ipairs(keys) do
            local v = tbl[k]
            local key = prefix .. k
            
            if type(v) == "table" then
                hashTable(v, key .. ".")
            else
                table.insert(hashData, key .. "=" .. tostring(v))
            end
        end
    end
    
    -- Add active ruleset data with full rule content
    if RPE.ActiveRules then
        table.insert(hashData, "RULESET:" .. tostring(RPE.ActiveRules.name or ""))
        
        -- Hash the actual rules content
        if RPE.ActiveRules.rules then
            hashTable(RPE.ActiveRules.rules, "RULE.")
        end
        
        -- Include other ruleset data
        if RPE.ActiveRules.data then
            hashTable(RPE.ActiveRules.data, "DATA.")
        end
    end
    
    -- Add active datasets with actual content
    local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
    if DatasetDB then
        local activeNames = DatasetDB.GetActiveNamesForCurrentCharacter()
        if activeNames then
            table.sort(activeNames)  -- Ensure consistent ordering
            
            for _, datasetName in ipairs(activeNames) do
                table.insert(hashData, "DATASET:" .. datasetName)
                
                -- Get the actual dataset and hash its content
                local dataset = DatasetDB.GetByName(datasetName)
                if dataset then
                    -- Hash spells, items, NPCs, stats, etc.
                    if dataset.spells then hashTable(dataset.spells, "SPELL.") end
                    if dataset.items then hashTable(dataset.items, "ITEM.") end
                    if dataset.npcs then hashTable(dataset.npcs, "NPC.") end
                    if dataset.stats then hashTable(dataset.stats, "STAT.") end
                    if dataset.auras then hashTable(dataset.auras, "AURA.") end
                    if dataset.recipes then hashTable(dataset.recipes, "RECIPE.") end
                    if dataset.reagents then hashTable(dataset.reagents, "REAGENT.") end
                end
            end
        end
    end
    
    -- Create a simple hash from the concatenated data
    local dataString = table.concat(hashData, "|")
    local hash = 0
    for i = 1, #dataString do
        hash = (hash * 31 + string.byte(dataString, i)) % 2147483647
    end
    return tostring(hash)
end

-- Track ongoing sync operations
Broadcast._syncOperations = {}

--- Automatically sync datasets and ruleset to a player with mismatched hash
---@param playerKey string The player's key (Name-Realm lowercased)
---@param playerName string The player's display name
function Broadcast:_autoSyncPlayer(playerKey, playerName)
    if self._syncOperations[playerKey] then
        RPE.Debug:Warning(string.format("[Broadcast] Sync already in progress for %s", playerName))
        return
    end
    
    -- Check if an event is currently running
    local ev = RPE.Core and RPE.Core.ActiveEvent
    local isEventRunning = ev and ev.IsRunning and ev:IsRunning()
    
    if not isEventRunning then
        -- If no event is running, just lock the Start Event button
        RPE.Debug:Print(string.format("[Broadcast] Hash mismatch with %s - locking Start Event button", playerName))
        
        -- Mark as a "lock-only" sync operation to prevent starting events
        self._syncOperations[playerKey] = {
            playerName = playerName,
            startTime = GetTime(),
            step = "locked", -- Special state: just locked, no actual sync
            lockControls = true,
        }
        
        self:_refreshEventControlSheet()
        return
    end
    
    -- Event is running, proceed with auto-sync
    RPE.Debug:Internal(string.format("[Broadcast] Auto-syncing datasets and ruleset to %s (event in progress).", playerName))
    
    -- Send pause notification to party (excluding leader and target)
    local pausePayload = { playerName, "START" }
    _sendAll("SYNC_PAUSE", pausePayload)
    
    -- Mark sync as in progress
    self._syncOperations[playerKey] = {
        playerName = playerName,
        startTime = GetTime(),
        step = "datasets", -- "datasets" -> "ruleset" -> "complete"
        lockControls = false, -- Don't lock controls during events
    }
    
    -- Start with dataset sync
    self:_sendActiveDatasetToPlayer(playerKey, playerName)
end

--- Send active datasets to a specific player
---@param playerKey string The player's key (Name-Realm lowercased)
---@param playerName string The player's display name
function Broadcast:_sendActiveDatasetToPlayer(playerKey, playerName)
    local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
    if not DatasetDB then
        RPE.Debug:Error("[Broadcast] DatasetDB missing; cannot sync datasets.")
        self:_completeSyncOperation(playerKey, false)
        return
    end

    local names = DatasetDB.GetActiveNamesForCurrentCharacter()
    if not names or #names == 0 then
        RPE.Debug:Internal("[Broadcast] No active datasets to sync.")
        self:_proceedToRulesetSync(playerKey)
        return
    end

    -- Default datasets that don't need to be sent
    local DEFAULT_DATASETS = { "DefaultClassic", "Default5e", "DefaultWarcraft" }
    local function isDefault(name)
        for _, dname in ipairs(DEFAULT_DATASETS) do
            if name == dname then return true end
        end
        return false
    end

    local datasetsToSend = {}
    for _, name in ipairs(names) do
        if not isDefault(name) then
            local ds = DatasetDB.GetByName(name)
            if ds then
                table.insert(datasetsToSend, ds)
            end
        end
    end

    if #datasetsToSend == 0 then
        RPE.Debug:Internal("[Broadcast] Only default datasets active; proceeding to ruleset sync.")
        self:_proceedToRulesetSync(playerKey)
        return
    end

    -- Send datasets to specific player
    for _, ds in ipairs(datasetsToSend) do
        self:_streamDatasetToPlayer(ds, playerKey, playerName)
    end
    
    -- After datasets are sent, proceed to ruleset
    self:_proceedToRulesetSync(playerKey)
end

--- Send active ruleset to a specific player
---@param playerKey string The player's key (Name-Realm lowercased)
function Broadcast:_proceedToRulesetSync(playerKey)
    local syncOp = self._syncOperations[playerKey]
    if not syncOp then return end
    
    syncOp.step = "ruleset"
    
    local RulesetDB = RPE.Profile and RPE.Profile.RulesetDB
    if not RulesetDB then
        RPE.Debug:Error("[Broadcast] RulesetDB missing; cannot sync ruleset.")
        self:_completeSyncOperation(playerKey, false)
        return
    end

    local rs = RulesetDB.LoadActiveForCurrentCharacter()
    if not rs then
        RPE.Debug:Internal("[Broadcast] No active ruleset to sync.")
        self:_completeSyncOperation(playerKey, true)
        return
    end

    self:_streamRulesetToPlayer(rs, playerKey)
    self:_completeSyncOperation(playerKey, true)
end

--- Complete sync operation and unlock UI
---@param playerKey string The player's key
---@param success boolean Whether the sync completed successfully
function Broadcast:_completeSyncOperation(playerKey, success)
    local syncOp = self._syncOperations[playerKey]
    if not syncOp then return end
    
    local duration = GetTime() - syncOp.startTime
    if success then
        RPE.Debug:Internal(string.format("[Broadcast] Auto-sync completed for %s in %.1f seconds", syncOp.playerName, duration))
        
        -- Send unpause notification to party if this was an event sync
        if not syncOp.lockControls then
            local unpausePayload = { syncOp.playerName, "END" }
            _sendAll("SYNC_PAUSE", unpausePayload)
        end
    else
        RPE.Debug:Error(string.format("[Broadcast] Auto-sync failed for %s after %.1f seconds", syncOp.playerName, duration))
        
        -- Send unpause notification even on failure
        if not syncOp.lockControls then
            local unpausePayload = { syncOp.playerName, "END" }
            _sendAll("SYNC_PAUSE", unpausePayload)
        end
    end
    
    local shouldUnlockControls = syncOp.lockControls
    
    -- Remove from tracking
    self._syncOperations[playerKey] = nil
    
    -- Check if any remaining sync operations require control locking
    local hasLockingSync = false
    for _, remainingSyncOp in pairs(self._syncOperations) do
        if remainingSyncOp.lockControls then
            hasLockingSync = true
            break
        end
    end
    
    -- Only unlock UI if this sync was locking controls and no other locking syncs are pending
    if shouldUnlockControls and not hasLockingSync then
        self:_unlockEventControls()
        self:_refreshEventControlSheet()
    end
end

--- Refresh EventControlSheet to update button states
function Broadcast:_refreshEventControlSheet()
    local ecs = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.EventControlSheet
    if ecs and ecs.Refresh then
        ecs:Refresh()
    end
end

--- Clear hash mismatch locks (called when user wants to start event despite mismatches)
function Broadcast:ClearHashMismatchLocks()
    return self:_clearHashMismatchLocks()
end

--- Internal method to clear hash mismatch locks
function Broadcast:_clearHashMismatchLocks()
    local clearedCount = 0
    for playerKey, syncOp in pairs(self._syncOperations) do
        if syncOp.step == "locked" then
            self._syncOperations[playerKey] = nil
            clearedCount = clearedCount + 1
        end
    end
    
    if clearedCount > 0 then
        self:_refreshEventControlSheet()
        RPE.Debug:Print(string.format("[Broadcast] Unlocked Start Event button (%d hash locks cleared)", clearedCount))
    end
    
    return clearedCount
end

--- Lock event control buttons during sync operations
function Broadcast:_lockEventControls()
    local ecs = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.EventControlSheet
    if ecs then
        if ecs.startButton and ecs.startButton.Lock then
            ecs.startButton:Lock()
            RPE.Debug:Internal("[Broadcast] Locked Start Event button during sync")
        end
        -- Only lock tick button if an event is running
        local ev = RPE.Core and RPE.Core.ActiveEvent
        local isEventRunning = ev and ev.IsRunning and ev:IsRunning()
        if isEventRunning and ecs.tickButton and ecs.tickButton.Lock then
            ecs.tickButton:Lock()
            RPE.Debug:Internal("[Broadcast] Locked Next Tick button during sync")
        end
    end
end

--- Unlock event control buttons after sync operations complete
function Broadcast:_unlockEventControls()
    local ecs = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.EventControlSheet
    if ecs then
        if ecs.startButton and ecs.startButton.Unlock then
            ecs.startButton:Unlock()
            RPE.Debug:Internal("[Broadcast] Unlocked Start Event button after sync")
        end
        if ecs.tickButton and ecs.tickButton.Unlock then
            ecs.tickButton:Unlock()
            -- Re-apply tick button state based on event status
            ecs:UpdateTickButtonState()
            RPE.Debug:Internal("[Broadcast] Unlocked Next Tick button after sync")
        end
    end
end

--- Stream dataset to a specific player via whisper
---@param ds table The dataset to stream
---@param playerKey string The player's key (Name-Realm lowercased)
---@param playerName string The player's display name
function Broadcast:_streamDatasetToPlayer(ds, playerKey, playerName)
    if not ds or not ds.name then
        RPE.Debug:Error("[Broadcast] Invalid dataset to stream to player")
        return
    end

    local channels = {{ type = "WHISPER", target = playerName }}

    -- Send metadata first (including autoActivate flag)
    local metaPayload = {
        ds.name,
        tostring(ds.guid or ""),
        tostring(ds.version or 1),
        ds.author or "",
        ds.notes or "",
        "1",  -- autoActivate: 1=true (activate when received)
    }
    
    Comms:Send("DATASET_META", metaPayload, "WHISPER", playerName)

    -- Stream each category to the specific player (same logic as _StreamDataset)
    for itemId, itemDef in pairs(ds.items or {}) do
        local serialized = self:_ser(itemDef)
        local msg = ds.name .. "|" .. itemId .. "|" .. serialized
        Comms:Send("DATASET_ITEM", msg, "WHISPER", playerName)
    end

    for spellId, spellDef in pairs(ds.spells or {}) do
        local serialized = self:_ser(spellDef)
        local msg = ds.name .. "|" .. spellId .. "|" .. serialized
        Comms:Send("DATASET_SPELL", msg, "WHISPER", playerName)
    end

    for auraId, auraDef in pairs(ds.auras or {}) do
        local serialized = self:_ser(auraDef)
        local msg = ds.name .. "|" .. auraId .. "|" .. serialized
        Comms:Send("DATASET_AURA", msg, "WHISPER", playerName)
    end

    for npcId, npcDef in pairs(ds.npcs or {}) do
        local serialized = self:_ser(npcDef)
        local msg = ds.name .. "|" .. npcId .. "|" .. serialized
        Comms:Send("DATASET_NPC", msg, "WHISPER", playerName)
    end

    for categoryName, categoryItems in pairs(ds.extra or {}) do
        for objectId, objectDef in pairs(categoryItems) do
            local serialized = self:_ser(objectDef)
            local msg = ds.name .. "|" .. categoryName .. "|" .. objectId .. "|" .. serialized
            Comms:Send("DATASET_EXTRA", msg, "WHISPER", playerName)
        end
    end

    -- Send completion signal
    Comms:Send("DATASET_COMPLETE", { ds.name }, "WHISPER", playerName)
    
    RPE.Debug:Internal(string.format("Streaming dataset '%s' to %s", ds.name, playerName))
end

--- Stream ruleset to a specific player via whisper
---@param rs table The ruleset to stream
---@param playerKey string The player's key (Name-Realm lowercased)
function Broadcast:_streamRulesetToPlayer(rs, playerKey)
    if not rs or not rs.name then
        RPE.Debug:Error("[Broadcast] Invalid ruleset to stream to player")
        return
    end

    local playerName = playerKey:match("^([^-]+)") or playerKey

    -- Send metadata first
    Comms:Send("RULESET_META", { rs.name }, "WHISPER", playerName)

    -- Stream each rule as individual key-value pair
    for ruleKey, ruleValue in pairs(rs.rules or {}) do
        local valueStr
        if type(ruleValue) == "string" then
            valueStr = string.format("%q", ruleValue)
        elseif type(ruleValue) == "number" or type(ruleValue) == "boolean" then
            valueStr = tostring(ruleValue)
        elseif type(ruleValue) == "table" then
            valueStr = self:_ser(ruleValue)
        else
            valueStr = "nil"
        end
        
        valueStr = _esc(valueStr)
        local rulePayload = { rs.name, ruleKey, valueStr }
        Comms:Send("RULESET_RULE", rulePayload, "WHISPER", playerName)
    end

    -- Send completion signal
    Comms:Send("RULESET_COMPLETE", { rs.name }, "WHISPER", playerName)
    
    RPE.Debug:Internal(string.format("Streaming ruleset '%s' to %s", rs.name, playerName))
end

--- Broadcast a unified LFRP message with location + settings
---@param mapID integer The map ID where the player is located
---@param x number Normalized x coordinate (0-100)
---@param y number Normalized y coordinate (0-100)
---@param settings table Table with { trpName=..., guildName=..., iAm={...}, lookingFor={...}, recruiting=0|1|2, approachable=0|1, broadcastLocation=true|false }
function Broadcast:SendLFRPBroadcast(mapID, x, y, settings)
    if not settings then return end
    
    local LFRPComms = RPE.Core and RPE.Core.LFRP and RPE.Core.LFRP.Comms
    if not LFRPComms then
        return
    end
    
    local channelNumber = LFRPComms:GetChannelNumber()
    if not channelNumber or channelNumber == 0 then
        return
    end
    
    -- Round coordinates to integers for efficiency
    mapID = tonumber(mapID) or 0
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    
    -- Get TRP name and guild name or empty strings
    local trpName = tostring(settings.trpName or "")
    local guildName = tostring(settings.guildName or "")
    
    -- Serialize settings as comma-delimited values within semicolon-delimited fields
    local iAmStr = table.concat(settings.iAm or {0,0,0,0,0}, ",")
    local lookingForStr = table.concat(settings.lookingFor or {0,0,0,0,0}, ",")
    local recruiting = tostring(settings.recruiting or 0)
    local approachable = tostring(settings.approachable or 0)
    local broadcastLocation = settings.broadcastLocation and "1" or "0"
    
    -- Get addon version and developer status
    local addonVersion = tostring((_G.RPE and _G.RPE.AddonVersion) or "unknown")
    local dev = settings.dev and "1" or "0"
    local eventName = tostring(settings.eventName or "")
    
    -- Format: mapID;x;y;trpName;guildName;iAm;lookingFor;recruiting;approachable;broadcastLocation;addonVersion;dev;eventName
    local flat = {
        tostring(mapID),
        tostring(x),
        tostring(y),
        trpName,
        guildName,
        iAmStr,
        lookingForStr,
        recruiting,
        approachable,
        broadcastLocation,
        addonVersion,
        dev,
        eventName,
    }
    
    Comms:Send("LFRP_BROADCAST", flat, "CHANNEL", channelNumber)
end

--- Send loot choices to supergroup leader
---@param choices table Array of {lootId=..., bid=... or choice=...}
---@param distrType string Distribution type ("BID" or "NEED BEFORE GREED")
function Broadcast:SendLootChoice(choices, distrType)
    local flat = { tostring(distrType or "BID") }
    
    for _, choice in ipairs(choices) do
        flat[#flat + 1] = tostring(choice.lootId or "")
        if distrType == "BID" then
            flat[#flat + 1] = tostring(choice.bid or 0)
        else
            flat[#flat + 1] = tostring(choice.choice or "pass")
        end
    end
    
    _sendAll("LOOT_CHOICE", flat)
end

--- Broadcast loot distribution to all players
---@param entries table Array of loot entries from LootEditorWindow
---@param distrType string Distribution type ("BID" or "NEED BEFORE GREED")
---@param timeout number Distribution timeout in seconds
function Broadcast:DistributeLoot(entries, distrType, timeout)
    if not entries or #entries == 0 then return end
    
    local flat = {}
    -- Header: distrType ; timeout ; entryCount
    table.insert(flat, tostring(distrType or "BID"))
    table.insert(flat, tostring(timeout or 60))
    table.insert(flat, tostring(#entries))
    
    -- Each entry: category ; lootId ; name ; icon ; quantity ; rarity ; marker ; allReceive ; restrictedPlayers ; spellRank ; profession
    for _, entry in ipairs(entries) do
        local category = entry.currentCategory or ""
        local lootData = entry.currentLootData or {}
        local name = lootData.name or ""
        -- For copper (and other currencies without an id), use the lowercase name as the lootId
        local lootId = lootData.id or (category == "currency" and name ~= "" and name:lower()) or ""
        local icon = lootData.icon or ""
        local quantity = tostring(entry.currentQuantity or 1)
        local rarity = lootData.rarity or "COMMON"
        local marker = tostring(entry.currentMarker or 0)
        local allReceive = entry.allReceive and "1" or "0"
        
        -- Encode restricted players as comma-separated list
        local restrictedList = {}
        if entry.restrictedPlayers then
            for playerKey, _ in pairs(entry.restrictedPlayers) do
                table.insert(restrictedList, playerKey)
            end
        end
        local restrictedStr = table.concat(restrictedList, ",")
        
        -- Extra data for spells and recipes
        local spellRank = tostring(entry.spellRank or 1)
        local profession = entry.profession or ""
        
        table.insert(flat, category)
        table.insert(flat, lootId)
        table.insert(flat, name)
        table.insert(flat, icon)
        table.insert(flat, quantity)
        table.insert(flat, rarity)
        table.insert(flat, marker)
        table.insert(flat, allReceive)
        table.insert(flat, restrictedStr)
        table.insert(flat, spellRank)
        table.insert(flat, profession)
    end
    
    _sendAll("DISTRIBUTE_LOOT", flat)
end

--- Send loot to winner via broadcast
---@param winnerKey string Winner player key (Name-Realm lowercase)
---@param lootId string The loot ID
---@param lootName string Display name of the loot
---@param category string Loot category (items, currency, spell, recipe)
---@param quantity number Quantity of loot
---@param extraData string|nil Extra data (e.g., spell rank, profession name)
---@param allReceive string|nil "1" if everyone receives this loot, "0" or nil otherwise
function Broadcast:SendLoot(winnerKey, lootId, lootName, category, quantity, extraData, allReceive)
    local flat = { winnerKey, tostring(lootId), tostring(lootName), category, tostring(quantity) }
    if extraData then
        flat[#flat+1] = tostring(extraData)
    end
    if allReceive then
        flat[#flat+1] = tostring(allReceive)
    end
    _sendAll("SEND_LOOT", flat)
end

--- Send an item or currency to a player via trade
--- Removes the item from the giver's inventory or spends the currency
---@param recipientKey string Recipient player key (Name-Realm lowercase)
---@param itemId string The item/currency ID
---@param quantity number Quantity to send
function Broadcast:SendItemToPlayer(recipientKey, itemId, quantity)
    local flat = { recipientKey, tostring(itemId), tostring(quantity) }
    _sendAll("TRADE_ITEM", flat)
end

--- Send currency to another player
---@param recipientKey string Recipient player key (Name-Realm lowercase)
---@param currencyKey string Currency key (e.g. "copper", "honor")
---@param amount number Amount to send
function Broadcast:SendCurrency(recipientKey, currencyKey, amount)
    local flat = { recipientKey, tostring(currencyKey), tostring(amount) }
    _sendAll("TRADE_CURRENCY", flat)
end