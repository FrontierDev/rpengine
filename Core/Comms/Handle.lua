-- RPE/Core/Comms/Handle.lua
RPE              = RPE or {}
RPE.Core         = RPE.Core or {}
RPE.Core.Comms   = RPE.Core.Comms or {}


local Common       = RPE and RPE.Common
local AuraManager  = RPE.Core and RPE.Core.AuraManager
local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
local Comms        = RPE.Core.Comms
local Handle       = RPE.Core.Comms.Handle or {}

RPE.Core.Comms.Handle = Handle

-- Helpers --
-- Simple unescape for fields that come from array payloads using ; delimiter
local function _unesc(s)
    if not s then return "" end
    -- Unescape characters that were escaped for ; delimiter safety
    s = s:gsub("%%0A", "\n")  -- Newline
    s = s:gsub("%%59", ";")  -- Semicolon
    s = s:gsub("%%", "%")  -- Percent (last!)
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

-- URL decode: unescape percent-encoded data (%HH sequences)
local function _urldecode(s)
    if not s then return s end
    return s:gsub("%%([0-9A-Fa-f][0-9A-Fa-f])", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

-- Split string on multi-character delimiter
local function _split(str, delim)
    if not str or str == "" then return {} end
    local result = {}
    local start = 1
    while true do
        local pos = string.find(str, delim, start, true)  -- true = literal match
        if not pos then
            table.insert(result, str:sub(start))
            break
        end
        table.insert(result, str:sub(start, pos - 1))
        start = pos + #delim
    end
    return result
end

-- Simple deserializer for small objects
local function _deserialize(str)
    if not str or str == "" then return {} end
    local chunk, err = loadstring("return " .. str)
    if not chunk then
        RPE.Debug:Error("[Handle] Failed to deserialize object: " .. tostring(err))
        return nil
    end
    local ok, result = pcall(chunk)
    if not ok then
        RPE.Debug:Error("[Handle] Failed to evaluate object")
        return nil
    end
    return result
end

local function _mgr()
    local ev = RPE.Core.ActiveEvent
    return ev._auraManager
end

-- Track in-progress rulesets per sender (name -> { rules = {} })
local _inProgressRulesets = {}

-- Receive ruleset metadata (first message in stream)
Comms:RegisterHandler("RULESET_META", function(data, sender)
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    -- Extract character name from sender (format: "Name-Realm" or just "Name")
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring RULESET_META from self (%s)", sender))
        return
    end

    local RulesetDB = RPE.Profile and RPE.Profile.RulesetDB
    if not RulesetDB then
        RPE.Debug:Error("[Handle] RulesetDB missing; cannot receive ruleset.")
        return
    end

    local args = { strsplit(";", data) }
    local name = args[1]
    if not name or name == "" then
        RPE.Debug:Error("[Handle] RULESET_META missing ruleset name")
        return
    end

    -- Initialize in-progress ruleset
    _inProgressRulesets[sender] = { name = name, rules = {} }
    RPE.Debug:Internal(string.format("[Handle] Starting ruleset stream for '%s' from %s", name, sender))
end)

-- Receive individual rule (key-value pair)
Comms:RegisterHandler("RULESET_RULE", function(data, sender)
    -- Ignore if no in-progress ruleset from this sender
    local inProgress = _inProgressRulesets[sender]
    if not inProgress then
        RPE.Debug:Internal(string.format("[Handle] Received RULESET_RULE with no matching RULESET_META from %s", sender))
        return
    end

    local args = { strsplit(";", data) }
    local rulesetName = args[1]
    local ruleKey = args[2]
    local ruleValue = args[3]  -- already escaped

    if not ruleKey or ruleValue == nil then
        RPE.Debug:Error("[Handle] RULESET_RULE missing key or value")
        return
    end

    -- Unescape the value
    local unescapedValue = _unesc(ruleValue)
    
    -- Deserialize the value (might be string, number, boolean, or table)
    local chunk, err = loadstring("return " .. unescapedValue)
    if not chunk then
        RPE.Debug:Error(string.format("[Handle] Failed to deserialize rule value: %s", tostring(err)))
        return
    end
    
    local ok, value = pcall(chunk)
    if not ok then
        RPE.Debug:Error(string.format("[Handle] Failed to evaluate rule value for key '%s'", ruleKey))
        return
    end

    -- Store in in-progress ruleset
    inProgress.rules[ruleKey] = value
end)

-- Receive ruleset completion signal
Comms:RegisterHandler("RULESET_COMPLETE", function(data, sender)
    local inProgress = _inProgressRulesets[sender]
    if not inProgress then
        RPE.Debug:Internal(string.format("[Handle] Received RULESET_COMPLETE with no matching RULESET_META from %s", sender))
        return
    end

    local RulesetDB = RPE.Profile and RPE.Profile.RulesetDB
    if not RulesetDB then
        RPE.Debug:Error("[Handle] RulesetDB missing; cannot save ruleset.")
        _inProgressRulesets[sender] = nil
        return
    end

    local name = inProgress.name
    if not name or name == "" then
        RPE.Debug:Error("[Handle] RULESET_COMPLETE invalid ruleset name")
        _inProgressRulesets[sender] = nil
        return
    end

    -- Upsert ruleset locally
    local rs = RulesetDB.GetOrCreateByName(name, { rules = inProgress.rules })
    rs.rules = inProgress.rules
    rs.updatedAt = time() or rs.updatedAt
    RulesetDB.Save(rs)

    -- Make it the active ruleset for this character
    RulesetDB.SetActiveForCurrentCharacter(name)

    -- Refresh live ActiveRules snapshot
    if RPE.ActiveRules and RPE.ActiveRules.SetRuleset then
        RPE.ActiveRules:SetRuleset(rs)
    end

    -- Apply dataset requirements from the ruleset
    if RPE.Profile and RPE.Profile.DatasetDB then
        local DatasetDB = RPE.Profile.DatasetDB
        local required = rs:GetRule("dataset_require")
        local exclusive = rs:GetRule("dataset_exclusive")
        
        -- dataset_require should be a comma-separated string or a table
        local requiredList = {}
        if type(required) == "string" and required ~= "" then
            -- Parse comma-separated list: "DS1,DS2,DS3"
            for dsName in required:gmatch("[^,]+") do
                dsName = dsName:match("^%s*(.-)%s*$")  -- trim whitespace
                if dsName ~= "" then
                    table.insert(requiredList, dsName)
                end
            end
        elseif type(required) == "table" then
            requiredList = required
        end
        
        if #requiredList > 0 then
            -- Activate required datasets
            if exclusive and tonumber(exclusive) == 1 then
                -- Exclusive mode: ONLY required datasets are active
                DatasetDB.SetActiveNamesForCurrentCharacter(requiredList)
                RPE.Debug:Print(string.format("Activated %d required datasets (exclusive mode).", #requiredList))
            else
                -- Non-exclusive mode: ensure required datasets are active, keep others
                local current = DatasetDB.GetActiveNamesForCurrentCharacter()
                local active = current or {}
                
                -- Add required datasets to active list
                local activeSet = {}
                for _, dsName in ipairs(active) do
                    activeSet[dsName] = true
                end
                
                for _, dsName in ipairs(requiredList) do
                    if not activeSet[dsName] then
                        table.insert(active, dsName)
                        activeSet[dsName] = true
                    end
                end
                
                DatasetDB.SetActiveNamesForCurrentCharacter(active)
                RPE.Debug:Internal(string.format("[Handle] Ensured %d required datasets are active", #requiredList))
            end
            
            -- Rebuild registries from all active datasets
            if RPE.Core then
                local function _refreshRegistry(reg, method)
                    if reg and type(reg[method]) == "function" then
                        pcall(function() reg[method](reg) end)
                    end
                end
                _refreshRegistry(RPE.Core.ItemRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.SpellRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.AuraRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.NPCRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.RecipeRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.InteractionRegistry, "RefreshFromActiveDatasets")
                _refreshRegistry(RPE.Core.StatRegistry, "RefreshFromActiveDatasets")
            end
        end
    end

    -- Cleanup
    _inProgressRulesets[sender] = nil

    local ruleCount = 0
    for _ in pairs(inProgress.rules) do ruleCount = ruleCount + 1 end
    RPE.Debug:Print(string.format("Applied Ruleset '%s' from %s (%d rules).", name, sender, ruleCount))
end)

-- Receive dataset push: count ; dataset_export1 ; dataset_export2 ; ...
-- Receive streaming dataset: metadata, then objects, then complete signal
-- Track in-progress datasets per sender
local _inProgressDatasets = {}

Comms:RegisterHandler("DATASET_META", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_META FULL DATA:\n%s", data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    -- Extract character name from sender (format: "Name-Realm" or just "Name")
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_META from self (%s)", sender))
        return
    end
    
    local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
    local Dataset = RPE.Profile and RPE.Profile.Dataset
    
    if not (DatasetDB and Dataset) then
        RPE.Debug:Error("[Handle] DatasetDB/Dataset missing; cannot receive datasets.")
        return
    end

    local args = { strsplit(";", data) }
    local name = args[1]
    local guid = args[2]
    local version = tonumber(args[3]) or 1
    local author = args[4]
    local notes = args[5]
    local autoActivate = (args[6] == "1")  -- Default to true if not specified
    
    if not name or name == "" then
        RPE.Debug:Error("[Handle] DATASET_META missing name")
        return
    end
    
    -- Create or update dataset
    local ds = DatasetDB.GetByName(name) or Dataset:New(name)
    ds.guid = guid ~= "" and guid or ds.guid
    ds.version = version
    ds.author = author ~= "" and author or nil
    ds.notes = notes ~= "" and notes or nil
    
    -- Clear existing data for fresh import
    ds.items = {}
    ds.spells = {}
    ds.auras = {}
    ds.npcs = {}
    ds.extra = {}  -- Initialize extra categories for streaming
    
    -- Track this dataset as in-progress with autoActivate flag
    if not _inProgressDatasets[sender] then _inProgressDatasets[sender] = {} end
    _inProgressDatasets[sender][name] = { ds = ds, autoActivate = autoActivate }
    
    RPE.Debug:Internal(string.format("[Handle] Creating dataset '%s' from %s (autoActivate=%s)", name, sender, tostring(autoActivate)))
end)

Comms:RegisterHandler("DATASET_ITEM", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_ITEM FULL DATA (length %d):\n%s", #data, data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_ITEM from self (%s)", sender))
        return
    end
    
    -- Format: datasetName|itemId|rawSerializedObject
    local firstPipe = data:find("|", 1, true)
    if not firstPipe then return end
    
    local name = data:sub(1, firstPipe - 1)
    local remainder = data:sub(firstPipe + 1)
    local secondPipe = remainder:find("|", 1, true)
    if not secondPipe then return end
    
    local itemId = remainder:sub(1, secondPipe - 1)
    local defStr = remainder:sub(secondPipe + 1)
    
    if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
        RPE.Debug:Error(string.format("[Handle] DATASET_ITEM for unknown dataset '%s' from %s", name, sender))
        return
    end
    
    local tracking = _inProgressDatasets[sender][name]
    local ds = tracking.ds or tracking
    RPE.Debug:Internal(string.format("[Handle] Item %s raw string (first 150 chars): %s", itemId, (defStr or ""):sub(1, 150)))
    RPE.Debug:Internal(string.format("[Handle] Item %s FULL STRING TO DESERIALIZE:\n%s", itemId, defStr))
    local def = _deserialize(defStr)
    
    -- Always add the item, even if def is nil (empty item definition)
    ds.items[itemId] = def or {}
    if def then
        RPE.Debug:Internal(string.format("[Handle] Added item %s to dataset '%s': name=%s, icon=%s, type=%s", itemId, name, def.name or "N/A", def.icon or "missing", type(def)))
    else
        RPE.Debug:Internal(string.format("[Handle] Added item %s to dataset '%s' (def=nil)", itemId, name))
    end
end)

Comms:RegisterHandler("DATASET_SPELL", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_SPELL FULL DATA (length %d):\n%s", #data, data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_SPELL from self (%s)", sender))
        return
    end
    
    -- Format: datasetName|spellId|rawSerializedObject
    RPE.Debug:Internal(string.format("[Handle] DATASET_SPELL raw data length: %d, first 300 chars: %s", #data, data:sub(1, 300)))
    local firstPipe = data:find("|", 1, true)
    if not firstPipe then 
        RPE.Debug:Error(string.format("[Handle] DATASET_SPELL has no first pipe delimiter"))
        return 
    end
    
    local name = data:sub(1, firstPipe - 1)
    local remainder = data:sub(firstPipe + 1)
    local secondPipe = remainder:find("|", 1, true)
    if not secondPipe then 
        RPE.Debug:Error(string.format("[Handle] DATASET_SPELL has no second pipe delimiter (name=%s)", name))
        return 
    end
    
    local spellId = remainder:sub(1, secondPipe - 1)
    local defStr = remainder:sub(secondPipe + 1)
    
    RPE.Debug:Internal(string.format("[Handle] DATASET_SPELL parsed: name=%s, id=%s, defStr length=%d, last 100 chars: %s", name, spellId, #defStr, defStr:sub(-100)))
    
    if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
        RPE.Debug:Error(string.format("[Handle] DATASET_SPELL for unknown dataset '%s' from %s", name, sender))
        return
    end
    
    local tracking = _inProgressDatasets[sender][name]
    local ds = tracking.ds or tracking
    RPE.Debug:Internal(string.format("[Handle] Spell %s raw string (first 150 chars): %s", spellId, (defStr or ""):sub(1, 150)))
    RPE.Debug:Internal(string.format("[Handle] Spell %s FULL STRING TO DESERIALIZE:\n%s", spellId, defStr))
    local def = _deserialize(defStr)
    
    -- Always add the spell, even if def is nil (empty spell definition)
    ds.spells[spellId] = def or {}
    RPE.Debug:Internal(string.format("[Handle] Added spell %s to dataset '%s' (def type: %s)", spellId, name, type(def)))
end)

Comms:RegisterHandler("DATASET_AURA", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_AURA FULL DATA (length %d):\n%s", #data, data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_AURA from self (%s)", sender))
        return
    end
    
    -- Format: datasetName|auraId|rawSerializedObject
    local firstPipe = data:find("|", 1, true)
    if not firstPipe then return end
    
    local name = data:sub(1, firstPipe - 1)
    local remainder = data:sub(firstPipe + 1)
    local secondPipe = remainder:find("|", 1, true)
    if not secondPipe then return end
    
    local auraId = remainder:sub(1, secondPipe - 1)
    local defStr = remainder:sub(secondPipe + 1)
    
    if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
        RPE.Debug:Error(string.format("[Handle] DATASET_AURA for unknown dataset '%s' from %s", name, sender))
        return
    end
    
    local tracking = _inProgressDatasets[sender][name]
    local ds = tracking.ds or tracking
    RPE.Debug:Internal(string.format("[Handle] Aura %s raw string (first 150 chars): %s", auraId, (defStr or ""):sub(1, 150)))
    RPE.Debug:Internal(string.format("[Handle] Aura %s FULL STRING TO DESERIALIZE:\n%s", auraId, defStr))
    local def = _deserialize(defStr)
    
    -- Always add the aura, even if def is nil (empty aura definition)
    ds.auras[auraId] = def or {}
    RPE.Debug:Internal(string.format("[Handle] Added aura %s to dataset '%s' (def type: %s)", auraId, name, type(def)))
end)

Comms:RegisterHandler("DATASET_NPC", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_NPC FULL DATA (length %d):\n%s", #data, data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_NPC from self (%s)", sender))
        return
    end
    
    -- Format: datasetName|npcId|rawSerializedObject
    local firstPipe = data:find("|", 1, true)
    if not firstPipe then return end
    
    local name = data:sub(1, firstPipe - 1)
    local remainder = data:sub(firstPipe + 1)
    local secondPipe = remainder:find("|", 1, true)
    if not secondPipe then return end
    
    local npcId = remainder:sub(1, secondPipe - 1)
    local defStr = remainder:sub(secondPipe + 1)
    
    if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
        RPE.Debug:Error(string.format("[Handle] DATASET_NPC for unknown dataset '%s' from %s", name, sender))
        return
    end
    
    local tracking = _inProgressDatasets[sender][name]
    local ds = tracking.ds or tracking
    RPE.Debug:Internal(string.format("[Handle] NPC %s raw string (first 150 chars): %s", npcId, (defStr or ""):sub(1, 150)))
    RPE.Debug:Internal(string.format("[Handle] NPC %s FULL STRING TO DESERIALIZE:\n%s", npcId, defStr))
    local def = _deserialize(defStr)
    
    -- Always add the NPC, even if def is nil (empty NPC definition)
    ds.npcs[npcId] = def or {}
    RPE.Debug:Internal(string.format("[Handle] Added NPC %s to dataset '%s' (def type: %s)", npcId, name, type(def)))
end)

-- Generic handler for DATASET_XXX extra category messages
-- Matches DATASET_STATS, DATASET_INTERACTIONS, DATASET_RECIPES, etc.
local function _registerExtraCategoryHandler(categoryName)
    local messageType = "DATASET_" .. categoryName:upper()
    Comms:RegisterHandler(messageType, function(data, sender)
        -- CRITICAL: Never process messages from ourselves - prevent self-corruption
        local senderName = sender:match("^([^-]+)") or sender
        local myName = UnitName("player")
        if senderName == myName then
            RPE.Debug:Internal(string.format("[Handle] Ignoring %s from self (%s)", messageType, sender))
            return
        end
        
        -- Format: datasetName|itemId|rawSerializedObject
        local firstPipe = data:find("|", 1, true)
        if not firstPipe then return end
        
        local name = data:sub(1, firstPipe - 1)
        local remainder = data:sub(firstPipe + 1)
        local secondPipe = remainder:find("|", 1, true)
        if not secondPipe then return end
        
        local itemId = remainder:sub(1, secondPipe - 1)
        local defStr = remainder:sub(secondPipe + 1)
        
        if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
            RPE.Debug:Error(string.format("[Handle] %s for unknown dataset '%s' from %s", messageType, name, sender))
            return
        end
        
        local tracking = _inProgressDatasets[sender][name]
        local ds = tracking.ds or tracking
        RPE.Debug:Internal(string.format("[Handle] %s %s raw string (first 150 chars): %s", categoryName, itemId, (defStr or ""):sub(1, 150)))
        RPE.Debug:Internal(string.format("[Handle] %s %s FULL STRING TO DESERIALIZE:\n%s", categoryName, itemId, defStr))
        local def = _deserialize(defStr)
        
        -- Ensure the extra table exists
        ds.extra = ds.extra or {}
        -- Ensure the category exists within extra
        ds.extra[categoryName] = ds.extra[categoryName] or {}
        
        -- Add the item to the extra category
        ds.extra[categoryName][itemId] = def or {}
        RPE.Debug:Internal(string.format("[Handle] Added %s %s to dataset '%s' (def type: %s)", categoryName, itemId, name, type(def)))
    end)
end

-- Pre-register handlers for common extra categories
_registerExtraCategoryHandler("stats")
_registerExtraCategoryHandler("interactions")
_registerExtraCategoryHandler("recipes")
_registerExtraCategoryHandler("achievements")

Comms:RegisterHandler("DATASET_COMPLETE", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DATASET_COMPLETE FULL DATA:\n%s", data))
    -- CRITICAL: Never process messages from ourselves - prevent self-corruption
    local senderName = sender:match("^([^-]+)") or sender
    local myName = UnitName("player")
    if senderName == myName then
        RPE.Debug:Internal(string.format("[Handle] Ignoring DATASET_COMPLETE from self (%s)", sender))
        return
    end
    
    local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
    
    if not DatasetDB then
        RPE.Debug:Error("[Handle] DatasetDB missing; cannot finalize datasets.")
        return
    end
    
    local args = { strsplit(";", data) }
    local name = args[1]
    
    if not _inProgressDatasets[sender] or not _inProgressDatasets[sender][name] then
        RPE.Debug:Error(string.format("[Handle] DATASET_COMPLETE for unknown dataset '%s' from %s", name, sender))
        return
    end
    
    local tracking = _inProgressDatasets[sender][name]
    local ds = tracking.ds or tracking
    
    -- Save to DB (but don't activate by default)
    DatasetDB.Save(ds)
    
    -- Check if the current ruleset requires this dataset
    local shouldActivate = false
    if RPE.ActiveRules then
        local required = RPE.ActiveRules:GetRequiredDatasets()
        if required then
            for _, reqName in ipairs(required) do
                if reqName == name then
                    shouldActivate = true
                    break
                end
            end
        end
    end
    
    -- Only activate if required by current ruleset
    if shouldActivate then
        DatasetDB.SetActiveNamesForCurrentCharacter({ name })
        
        -- Rebuild registries from all active datasets when activated
        if RPE.Core then
            local function _refreshRegistry(reg, method)
                if reg and type(reg[method]) == "function" then
                    pcall(function() reg[method](reg) end)
                end
            end
            _refreshRegistry(RPE.Core.ItemRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.SpellRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.AuraRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.NPCRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.RecipeRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.InteractionRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.StatRegistry, "RefreshFromActiveDatasets")
        end
    end
    
    local counts = ds:Counts()
    RPE.Debug:Print(string.format("[Handle] Completed dataset '%s' from %s (%d items, %d spells, %d auras, %d npcs)%s", 
        name, sender, counts.items, counts.spells, counts.auras, counts.npcs,
        shouldActivate and " [activated by ruleset]" or " [saved, not activated]"))
    
    -- Debug: log first item if exists
    if ds.items then
        local firstId = next(ds.items)
        if firstId then
            local firstItem = ds.items[firstId]
            RPE.Debug:Internal(string.format("[Handle] First item in dataset: id=%s, has_icon=%s", firstId, (type(firstItem) == "table" and firstItem.icon) or "N/A"))
        end
    end
    
    -- Clean up
    _inProgressDatasets[sender][name] = nil
end)

Comms:RegisterHandler("START_EVENT", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] START_EVENT FULL DATA (length %d):\n%s", #data, data))
    local args = { strsplit(";", data) }
    local id   = args[1]
    local name = args[2]

    -- Determine if subtext and difficulty are present (new format)
    local subtext, difficulty, teamNamesStr, startIdx
    if args[5] ~= nil and tonumber(args[5]) == nil then
        -- New format: subtext and difficulty present
        subtext      = _unesc(args[3] or "")
        difficulty   = args[4] or "NORMAL"
        teamNamesStr = args[5] or ""
        startIdx     = 6
    elseif args[4] ~= nil and tonumber(args[4]) == nil then
        -- Older new format: subtext present but no difficulty
        subtext      = _unesc(args[3] or "")
        difficulty   = "NORMAL"
        teamNamesStr = args[4] or ""
        startIdx     = 5
    else
        -- Oldest format: no subtext or difficulty
        subtext      = ""
        difficulty   = "NORMAL"
        teamNamesStr = args[3] or ""
        startIdx     = 4
    end

    local teamNames = {}
    local idx = 1
    for tn in string.gmatch(teamNamesStr, "([^,]+)") do
        teamNames[idx] = tn
        idx = idx + 1
    end

    local units = {}
    local i = startIdx
    while i <= #args do
        local u = {}
        u.id         = tonumber(args[i]); i = i + 1
        u.key        = args[i];           i = i + 1
        u.name       = args[i];           i = i + 1
        u.team       = tonumber(args[i]); i = i + 1
        u.isNPC      = args[i] == "1";    i = i + 1
        u.hp         = tonumber(args[i]); i = i + 1
        u.hpMax      = tonumber(args[i]); i = i + 1
        u.initiative = tonumber(args[i]); i = i + 1
        u.raidMarker = tonumber(args[i]); i = i + 1
        if not u.raidMarker or u.raidMarker <= 0 then
            u.raidMarker = nil
        end
        u.unitType = args[i] ~= "" and args[i] or nil; i = i + 1
        u.unitSize = args[i] ~= "" and args[i] or nil; i = i + 1
        u.active   = args[i] == "1"; i = i + 1
        u.hidden   = args[i] == "1"; i = i + 1
        u.flying   = args[i] == "1"; i = i + 1

        -- New: parse stats string
        u.stats = {}
        local statsStr = args[i] or ""; i = i + 1
        if statsStr ~= "" then
            for pair in string.gmatch(statsStr, "([^,]+)") do
                local k, v = pair:match("([^=]+)=([^=]+)")
                if k then
                    u.stats[k] = tonumber(v) or 0
                end
            end
        end

        u.fileDataId = tonumber(args[i]) or nil; i = i + 1
        u.displayId  = tonumber(args[i]) or nil; i = i + 1
        u.cam        = tonumber(args[i]) or nil; i = i + 1
        u.rot        = tonumber(args[i]) or nil; i = i + 1
        u.z          = tonumber(args[i]) or nil; i = i + 1
        
        -- New: parse spells string
        local spellsStr = args[i] or ""; i = i + 1
        u.spells = {}
        if spellsStr ~= "" then
            for sid in string.gmatch(spellsStr, "([^,]+)") do
                if sid and sid ~= "" then
                    table.insert(u.spells, sid)
                end
            end
        end
        
        -- New: parse summonedBy
        u.summonedBy = tonumber(args[i]) or 0; i = i + 1
        
        units[#units+1] = u
    end

    RPE.Core.ActiveEvent:OnStart({
        id        = id,
        name      = name,
        subtext   = subtext,
        difficulty = difficulty,
        teamNames = teamNames,
        units     = units,
    })
end)



-- Receive an advance (either start of a new turn or a new tick)
Comms:RegisterHandler("ADVANCE", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] ADVANCE FULL DATA:\n%s", data))
    local UnitClass = RPE.Core.Unit
    local args = { strsplit(";", data) }
    local id   = args[1]
    local name = args[2]
    local subtext = args[3]
    local mode    = args[4]

    if not id or not name or not mode then
        RPE.Debug:Error("[Handle] ADVANCE missing id, name, or mode.")
        return
    end

    local ev = RPE.Core.ActiveEvent
    if not ev then
        RPE.Debug:Error("[Handle] ADVANCE but no ActiveEvent.")
        return
    end
    ev._snapshot = ev._snapshot or {}

    -- New delta format? args[5] == "DELTAS"
    if args[5] == "DELTAS" then
        local n = tonumber(args[6]) or 0
        local i = 7
        local structureChanged = false   -- ✅ track roster changes

        for _ = 1, n do
            local uId = tonumber(args[i]) or 0; i = i + 1
            local op  = args[i] or "U";          i = i + 1
            local kvS = args[i] or "";           i = i + 1
            local stS = args[i] or "";           i = i + 1

            local fields = UnitClass.KVDecode(kvS)
            local stats  = (stS ~= "" and UnitClass.StatsDecode(stS)) or nil

            if op == "N" then
                local key = fields.key and fields.key:lower() or nil
                if key then
                    local u = ev.units[key]
                    if not u then
                        u = UnitClass.New(uId, {
                            key        = key,
                            name       = fields.name,
                            team       = fields.team,
                            isNPC      = fields.isNPC,
                            hp         = fields.hp,
                            hpMax      = fields.hpMax,
                            initiative = fields.initiative or 0,
                            raidMarker = fields.raidMarker or nil,
                            unitType   = fields.unitType,
                            unitSize   = fields.unitSize,
                            active     = fields.active or false,
                            hidden     = fields.hidden or false,
                            flying     = fields.flying or false,
                            displayId  = fields.displayId or nil,
                            fileDataId = fields.fileDataId or nil,
                            cam        = fields.cam or nil,
                            rot        = fields.rot or nil,
                            z          = fields.z or nil,
                            summonedBy = fields.summonedBy or 0,
                        })
                        
                        -- If this is an NPC, look up spells from the registry
                        if fields.isNPC and RPE.Core and RPE.Core.NPCRegistry then
                            -- Try to find the NPC in the registry by searching for matching name
                            -- (we don't have npcId in the delta, so we search by name)
                            local NPCRegistry = RPE.Core.NPCRegistry
                            local nameToMatch = fields.name and fields.name:lower() or nil
                            if nameToMatch then
                                for npcId, npcDef in NPCRegistry:Pairs() do
                                    if npcDef and npcDef.name and npcDef.name:lower() == nameToMatch then
                                        if type(npcDef.spells) == "table" then
                                            u.spells = npcDef.spells
                                            if RPE.Debug and RPE.Debug.Internal then
                                                RPE.Debug:Internal(("[Handle] Populated spells for NPC %s from registry"):format(fields.name))
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        
                        ev.units[key] = u
                        structureChanged = true
                    else
                        UnitClass.ApplyKV(u, fields)
                    end
                    if type(stats) == "table" then u.stats = stats end
                    ev._snapshot[uId] = u:ToSyncState()
                end

            elseif op == "U" then
                local target
                for _, uu in pairs(ev.units or {}) do
                    if tonumber(uu.id) == uId then target = uu break end
                end
                if target then
                    UnitClass.ApplyKV(target, fields)
                    if type(stats) == "table" then target.stats = stats end
                    ev._snapshot[uId] = target:ToSyncState()
                end

            elseif op == "R" then
                for k, uu in pairs(ev.units or {}) do
                    if tonumber(uu.id) == uId then ev.units[k] = nil break end
                end
                ev._snapshot[uId] = nil
                structureChanged = true
            end
        end

        -- ✅ Keep UI/state sane after roster changes
        -- Only rebuild ticks if we're at the START of a turn (tickIndex == 0)
        -- Mid-turn additions will be processed in the next turn's batching
        if structureChanged and ev.RebuildTicks then
            -- Only rebuild if we're not currently in the middle of processing ticks
            if ev.tickIndex == 0 then
                ev:RebuildTicks()
            end
            -- Don't refresh portrait row here - let ShowTick handle it after AdvanceClient
            if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
                RPE.Core.Windows.UnitFrameWidget:Refresh(true)
            end
        end

        ev:AdvanceClient(mode, nil, subtext)
        return
    end

    -------------------------------------------------------------------------
    -- Legacy path: full units list (kept for backward compatibility)
    -------------------------------------------------------------------------
    local units = {}
    local i = 5
    while i <= #args do
        local u = {}
        u.id         = tonumber(args[i]); i = i + 1
        u.key        = args[i];           i = i + 1
        u.name       = args[i];           i = i + 1
        u.team       = tonumber(args[i]); i = i + 1
        u.isNPC      = args[i] == "1";    i = i + 1
        u.hp         = tonumber(args[i]); i = i + 1
        u.hpMax      = tonumber(args[i]); i = i + 1
        u.initiative = tonumber(args[i]); i = i + 1
        local rm     = tonumber(args[i]); i = i + 1
        u.raidMarker = (rm and rm > 0) and rm or nil
        u.unitType = args[i] ~= "" and args[i] or nil; i = i + 1
        u.unitSize = args[i] ~= "" and args[i] or nil; i = i + 1
        u.active = args[i] == "1"; i = i + 1
        u.hidden = args[i] == "1"; i = i + 1
        u.flying = args[i] == "1"; i = i + 1

        -- stats CSV
        u.stats = {}
        local statsCSV = args[i] or "";   i = i + 1
        for pair in string.gmatch(statsCSV, "([^,]+)") do
            local k, v = pair:match("([^=]+)=([^=]+)")
            if k then u.stats[k] = tonumber(v) or 0 end
        end
        
        -- model data
        u.fileDataId = tonumber(args[i]) or nil; i = i + 1
        u.displayId  = tonumber(args[i]) or nil; i = i + 1
        u.cam        = tonumber(args[i]) or nil; i = i + 1
        u.rot        = tonumber(args[i]) or nil; i = i + 1
        u.z          = tonumber(args[i]) or nil; i = i + 1
        
        -- spells
        local spellsStr = args[i] or ""; i = i + 1
        u.spells = {}
        if spellsStr ~= "" then
            for sid in string.gmatch(spellsStr, "([^,]+)") do
                if sid and sid ~= "" then
                    table.insert(u.spells, sid)
                end
            end
        end
        
        -- summonedBy
        u.summonedBy = tonumber(args[i]) or 0; i = i + 1

        units[#units+1] = u
    end

    ev:AdvanceClient(mode, units, subtext)
end)


Comms:RegisterHandler("END_EVENT", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] END_EVENT FULL DATA:\n%s", data))

    local ev = RPE.Core.ActiveEvent
    if not ev then
        RPE.Debug:Error("[Handle] END_EVENT but no ActiveEvent.")
        return
    end

    ev:OnEndClient()
end)

-- APPLY
Comms:RegisterHandler("AURA_APPLY", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] AURA_APPLY FULL DATA:\n%s", data))
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local sId, tId = tonumber(args[1]) or 0, tonumber(args[2]) or 0
    local auraId, stacks, desc = args[3], tonumber(args[5]) or 0, _unesc(args[6] or "")

    if tId == 0 or not auraId or auraId == "" then 
        RPE.Debug:Error("[Handle:AURA_APPLY] Aura ID was not valid.")
        return 
    end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Apply(sId ~= 0 and sId or nil, tId, auraId, {
            stacks = (stacks > 0) and stacks or nil,
            -- description is UI-only; your tooltip can read desc from the aura instance if you store it,
            -- or just use local AuraRegistry text. We're not mutating instance here.
        })
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_APPLY error: " .. tostring(err))
    end
end)

-- REMOVE: tId ; auraId ; fromSourceId
Comms:RegisterHandler("AURA_REMOVE", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] AURA_REMOVE FULL DATA:\n%s", data))
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local tId  = tonumber(args[1]) or 0
    local aura = args[2]
    local sId  = tonumber(args[3] or "0") or 0
    if tId == 0 or not aura or aura == "" then return end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Remove(tId, aura, (sId ~= 0) and sId or nil)
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_REMOVE error: " .. tostring(err))
    end
end)

-- DISPEL: tId ; typesCSV ; max ; helpful01
Comms:RegisterHandler("AURA_DISPEL", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] AURA_DISPEL FULL DATA:\n%s", data))
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local tId  = tonumber(args[1]) or 0
    local types = {}
    for ty in (args[2] or ""):gmatch("([^,]+)") do types[#types+1] = ty end
    local max     = tonumber(args[3]) or 1
    local helpful = (args[4] == "1")
    if tId == 0 then return end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Dispel(tId, { types = types, max = max, helpful = helpful })
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_DISPEL error: " .. tostring(err))
    end
end)


-- === Scaffold: remote stat modifications (currently rejected) ===============
-- STATMOD: tId ; auraId ; instanceId ; op ; statId ; value
Comms:RegisterHandler("AURA_STATMOD", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] AURA_STATMOD FULL DATA:\n%s", data))
    -- Disabled by default: we don't accept remote stat writes yet.
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Print("[Handle] Ignored AURA_STATMOD from " .. tostring(sender) .. " (remote stat mods disabled).")
    end
end)

Comms:RegisterHandler("DAMAGE", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] DAMAGE FULL DATA:\n%s", data))
    -- Do NOT early-return on self: SpellActions no longer applies locally.
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end

    -- helper to find a unit quickly
    local function findUnitById(tid)
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tid then return u end
        end
    end

    while i <= #args do
        local tId    = tonumber(args[i]) or 0; i = i + 1
        local totalAmount = math.max(0, math.floor(tonumber(args[i] or 0))); i = i + 1
        local schoolCSV  = args[i] or "";                                      i = i + 1
        local isCrit = (args[i] == "1");                                   i = i + 1
        local tDelta = tonumber(args[i] or ""); if tDelta == nil then tDelta = totalAmount end; i = i + 1

        if tId > 0 and totalAmount > 0 then
            local target = findUnitById(tId)
            if target then
                -- Parse damage by school from CSV (format: school1:amount1,school2:amount2,...)
                -- Or if it's a single school format: "School"
                local damageBySchool = {}
                if schoolCSV:find(":") then
                    -- Multi-school format: "Fire:5,Physical:23"
                    for damageStr in string.gmatch(schoolCSV, "([^,]+)") do
                        local school, amount = damageStr:match("^([^:]+):(%d+)$")
                        if school and amount then
                            damageBySchool[school] = tonumber(amount) or 0
                        end
                    end
                else
                    -- Single school format: "Physical" or "Fire"
                    if schoolCSV ~= "" then
                        damageBySchool[schoolCSV] = totalAmount
                    else
                        damageBySchool["Physical"] = totalAmount
                    end
                end
                
                if RPE and RPE.Debug and RPE.Debug.Print then
                    local schoolStr = ""
                    for school, amount in pairs(damageBySchool) do
                        if schoolStr ~= "" then schoolStr = schoolStr .. ", " end
                        schoolStr = schoolStr .. school .. ":" .. amount
                    end
                    RPE.Debug:Internal(string.format(
                        "[Handle] DAMAGE to target %d: %s (total=%d, crit=%s)",
                        tId, schoolStr, totalAmount, tostring(isCrit)
                    ))
                end
                
                -- Track original damage for logging
                local absorbedAmount = 0
                local remainingDamage = totalAmount
                
                -- Apply absorption shields if they exist
                if target.absorption and remainingDamage > 0 then
                    for shieldId, shield in pairs(target.absorption) do
                        if shield.amount > 0 and remainingDamage > 0 then
                            local absorbed = math.min(remainingDamage, shield.amount)
                            absorbedAmount = absorbedAmount + absorbed
                            remainingDamage = remainingDamage - absorbed
                            shield.amount = shield.amount - absorbed
                            
                            if RPE and RPE.Debug and RPE.Debug.Internal then
                                RPE.Debug:Internal(string.format(
                                    "[Handle] DAMAGE ABSORBED: %d damage blocked by shield (from source %d), %d remaining",
                                    absorbed, shield.sourceId, remainingDamage
                                ))
                            end
                        end
                    end
                    
                    -- Clean up shields that are completely absorbed
                    local toRemove = {}
                    for shieldId, shield in pairs(target.absorption) do
                        if shield.amount <= 0 then
                            table.insert(toRemove, shieldId)
                            if RPE and RPE.Debug and RPE.Debug.Internal then
                                RPE.Debug:Internal(string.format(
                                    "[Handle] Shield %s fully absorbed and removed", shieldId
                                ))
                            end
                        end
                    end
                    for _, shieldId in ipairs(toRemove) do
                        target.absorption[shieldId] = nil
                    end
                    
                    -- Broadcast updated absorption to UI
                    local totalAbsorption = 0
                    for _, shield in pairs(target.absorption) do
                        if shield.amount then
                            totalAbsorption = totalAbsorption + shield.amount
                        end
                    end
                    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if B and B.UpdateUnitHealth then
                        B:UpdateUnitHealth(target.id, target.hp, target.hpMax, totalAbsorption)
                    end
                end
                
                target:ApplyDamage(remainingDamage, isCrit, absorbedAmount)
                if sId ~= 0 then target:AddThreat(sId, tDelta) end

                local AuraTriggers = RPE.Core and RPE.Core.AuraTriggers
                
                -- Emit ON_HIT_TAKEN trigger for the target - now for each school separately
                if AuraTriggers and AuraTriggers.Emit then
                    for school, amount in pairs(damageBySchool) do
                        AuraTriggers:Emit("ON_HIT_TAKEN", ev or {}, tId, tId, { 
                            damageAmount = amount, 
                            school = school,
                            sourceId = sId,
                        })
                    end
                end
                
                -- Emit ON_CRIT trigger for attacker if this is a crit
                if isCrit and sId ~= 0 and AuraTriggers and AuraTriggers.Emit then
                    for school, amount in pairs(damageBySchool) do
                        AuraTriggers:Emit("ON_CRIT", ev or {}, sId, tId, { 
                            damageAmount = amount, 
                            school = school,
                        })
                    end
                end
                
                -- Emit ON_CRIT_TAKEN trigger for target if this is a crit
                if isCrit and AuraTriggers and AuraTriggers.Emit then
                    -- For ON_CRIT_TAKEN, use total damage and primary school
                    local primarySchool = "Physical"
                    local maxAmount = 0
                    for school, amount in pairs(damageBySchool) do
                        if amount > maxAmount then
                            maxAmount = amount
                            primarySchool = school
                        end
                    end
                    AuraTriggers:Emit("ON_CRIT_TAKEN", ev or {}, tId, tId, { 
                        damageAmount = remainingDamage, 
                        school = primarySchool,
                        sourceId = sId,
                    })
                end

                -- Emit ON_KILL trigger when target dies from damage dealt by attacker
                if sId ~= 0 and (target:IsDead() or target.hp < 1) then                 
                    if AuraTriggers and AuraTriggers.Emit then
                        -- For ON_KILL, use total damage and primary school
                        local primarySchool = "Physical"
                        local maxAmount = 0
                        for school, amount in pairs(damageBySchool) do
                            if amount > maxAmount then
                                maxAmount = amount
                                primarySchool = school
                            end
                        end
                        AuraTriggers:Emit("ON_KILL", ev or {}, sId, tId, { damageAmount = remainingDamage, school = primarySchool })
                    end
                end

                local getMyId = RPE.Core.GetLocalPlayerUnitId
                local myId    = getMyId and getMyId() or nil
                
                if myId and tId == myId then
                    -- Player took damage, show debug message
                end
                
                if myId and sId == myId then
                    -- target:SetAttackedLast(true)
                end

                if myId and tId == myId then
                    RPE.Core.Windows.PlayerUnitWidget:Refresh()
                end

                -- Portrait updates handled by ShowTick

                -- optional: route crit/school to UI if you like
            end
        end
    end
end)

Comms:RegisterHandler("HEAL", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] HEAL FULL DATA:\n%s", data))
    -- Do NOT early-return on self: SpellActions no longer applies locally.
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end

    -- helper to find a unit quickly
    local function findUnitById(tid)
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tid then return u end
        end
    end

    while i <= #args do
        local tId    = tonumber(args[i]) or 0; i = i + 1
        local amount = math.max(0, math.floor(tonumber(args[i]) or 0)); i = i + 1
        local isCrit = (args[i] == "1");                                i = i + 1
        local tDelta = tonumber(args[i] or "") or 0; i = i + 1

        if tId > 0 and amount > 0 then
            local target = findUnitById(tId)
            if target then
                target:Heal(amount, isCrit)
                if sId ~= 0 then target:AddThreat(sId, -tDelta) end -- heals often reduce threat vs damage

                local AuraTriggers = RPE.Core and RPE.Core.AuraTriggers
                
                -- Emit ON_HEAL_TAKEN trigger for the target
                if AuraTriggers and AuraTriggers.Emit then
                    AuraTriggers:Emit("ON_HEAL_TAKEN", ev or {}, tId, tId, { 
                        healAmount = amount,
                        sourceId = sId,
                        isCrit = isCrit,
                    })
                end
                
                -- Emit ON_CRIT trigger for healer if this was a crit heal
                if isCrit and sId ~= 0 and AuraTriggers and AuraTriggers.Emit then
                    AuraTriggers:Emit("ON_CRIT", ev or {}, sId, tId, { 
                        healAmount = amount,
                        isCrit = true,
                    })
                end
                
                -- Emit ON_CRIT_TAKEN trigger for target if this was a crit heal
                if isCrit and AuraTriggers and AuraTriggers.Emit then
                    AuraTriggers:Emit("ON_CRIT_TAKEN", ev or {}, tId, tId, { 
                        healAmount = amount,
                        sourceId = sId,
                        isCrit = true,
                    })
                end

                local getMyId = RPE.Core.GetLocalPlayerUnitId
                local myId    = getMyId and getMyId() or nil

                if myId and sId == myId then
                    -- target:SetProtectedLast(true) -- already handled via Event:MarkProtected
                end

                if myId and tId == myId then
                    RPE.Core.Windows.PlayerUnitWidget:Refresh()
                end

                -- Portrait updates handled by ShowTick

                -- optional: route crit flag to UI
            end
        end
    end
end)

-- SHIELD: apply absorption shield to targets (sId ; tId ; amount ; duration ; tId ; amount ; duration ; ...)
Comms:RegisterHandler("SHIELD", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] SHIELD FULL DATA:\n%s", data))
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then 
        RPE.Debug:Internal("[Handle] SHIELD: No active event or units")
        return 
    end
    RPE.Debug:Internal(string.format("[Handle] SHIELD: Processing for source %d, turn %d", sId, ev.turn or 0))

    -- helper to find a unit quickly
    local function findUnitById(tid)
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tid then return u end
        end
    end

    local shieldedUnits = {}  -- Track which units got shields for UI refresh

    while i <= #args do
        local tId      = tonumber(args[i]) or 0; i = i + 1
        local amount   = math.max(0, math.floor(tonumber(args[i]) or 0)); i = i + 1
        local duration = math.max(1, math.floor(tonumber(args[i]) or 1)); i = i + 1

        if tId > 0 and amount > 0 then
            local target = findUnitById(tId)
            if target then
                RPE.Debug:Internal(string.format("[Handle] SHIELD: Applying %d absorption to target %s (id=%d), duration=%d", 
                    amount, target.name or "?", tId, duration))
                -- Apply shield: create or add to existing absorption
                if not target.absorption then
                    target.absorption = {}
                end
                
                -- Store shield with duration and source
                local shieldId = tostring(sId) .. "-" .. tostring(ev.turn or 0)
                target.absorption[shieldId] = {
                    amount = amount,
                    sourceId = sId,
                    duration = duration,
                    appliedTurn = ev.turn or 0,
                }
                
                shieldedUnits[tId] = target
                
                if RPE and RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(string.format(
                        "[Handle] SHIELD: Applied %d absorption to %s for %d turn(s) (from source %d)",
                        amount, target.name or tostring(tId), duration, sId
                    ))
                end
            end
        end
    end

    -- Refresh UI for all shielded units
    RPE.Debug:Internal(string.format("[Handle] SHIELD: Refreshing UI for %d shielded units", 
        #(function() local c=0; for _ in pairs(shieldedUnits) do c=c+1 end; return {} end)()))
    for tId, target in pairs(shieldedUnits) do
        -- Calculate total absorption
        local totalAbsorption = 0
        if target.absorption then
            for shieldId, shield in pairs(target.absorption) do
                if shield.amount then
                    totalAbsorption = totalAbsorption + shield.amount
                end
            end
        end
        RPE.Debug:Internal(string.format("[Handle] SHIELD: Unit %s (id=%d) has total absorption=%d", 
            target.name or "?", tId, totalAbsorption))

        -- Update EventWidget portraits
        if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
            local eventWidget = RPE.Core.Windows.EventWidget
            RPE.Debug:Internal("[Handle] SHIELD: Checking EventWidget portraits...")
            if eventWidget.portraitsByKey then
                -- Find portrait by matching unit key
                local found = false
                for unitKey, portrait in pairs(eventWidget.portraitsByKey) do
                    if portrait.unit and tonumber(portrait.unit.id) == tonumber(tId) then
                        found = true
                        RPE.Debug:Internal(string.format("[Handle] SHIELD: Found EventWidget portrait for unit %d", tId))
                        -- Ensure health is set before setting absorption
                        if portrait.SetHealth and target.hp and target.hpMax then
                            RPE.Debug:Internal(string.format("[Handle] SHIELD: Setting EventWidget health %d/%d", target.hp, target.hpMax))
                            portrait:SetHealth(target.hp, target.hpMax)
                        end
                        if portrait.SetAbsorption then
                            RPE.Debug:Internal(string.format("[Handle] SHIELD: Setting EventWidget absorption %d", totalAbsorption))
                            portrait:SetAbsorption(totalAbsorption)
                        end
                        break
                    end
                end
                if not found then
                    RPE.Debug:Internal(string.format("[Handle] SHIELD: No EventWidget portrait found for unit %d", tId))
                end
            end
        end

        -- Update UnitFrameWidget portraits (for NPCs)
        if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
            local unitFrameWidget = RPE.Core.Windows.UnitFrameWidget
            RPE.Debug:Internal("[Handle] SHIELD: Checking UnitFrameWidget portraits...")
            if unitFrameWidget.portraitsByKey then
                local found = false
                for unitKey, portrait in pairs(unitFrameWidget.portraitsByKey) do
                    if portrait.unit and tonumber(portrait.unit.id) == tonumber(tId) then
                        found = true
                        RPE.Debug:Internal(string.format("[Handle] SHIELD: Found UnitFrameWidget portrait for unit %d", tId))
                        if portrait.SetHealth and target.hp and target.hpMax then
                            RPE.Debug:Internal(string.format("[Handle] SHIELD: Setting UnitFrame health %d/%d", target.hp, target.hpMax))
                            portrait:SetHealth(target.hp, target.hpMax)
                        end
                        if portrait.SetAbsorption then
                            RPE.Debug:Internal(string.format("[Handle] SHIELD: Setting UnitFrame absorption %d", totalAbsorption))
                            portrait:SetAbsorption(totalAbsorption)
                        end
                        break
                    end
                end
                if not found then
                    RPE.Debug:Internal(string.format("[Handle] SHIELD: No UnitFrameWidget portrait found for unit %d", tId))
                end
            end
        end

        -- Update TargetWindow portraits
        if RPE.Core.Windows and RPE.Core.Windows.TargetWindow then
            local targetWindow = RPE.Core.Windows.TargetWindow
            if targetWindow.portraitsByKey then
                for unitKey, portrait in pairs(targetWindow.portraitsByKey) do
                    if portrait.unit and tonumber(portrait.unit.id) == tonumber(tId) then
                        if portrait.SetHealth and target.hp and target.hpMax then
                            portrait:SetHealth(target.hp, target.hpMax)
                        end
                        if portrait.SetAbsorption then
                            portrait:SetAbsorption(totalAbsorption)
                        end
                        break
                    end
                end
            end
        end

        -- Update PlayerUnitWidget if this is the local player
        local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
        if myId and tonumber(target.id) == tonumber(myId) then
            if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
                RPE.Core.Windows.PlayerUnitWidget:Refresh()
            end
        end
    end
end)

-- HEALTH: tId ; hp ; hpMax
Comms:RegisterHandler("HEALTH", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] HEALTH FULL DATA:\n%s", data))
    local args = { strsplit(";", data) }
    local tId   = tonumber(args[1]) or 0
    local hp    = tonumber(args[2]) or 0
    local hpMax = tonumber(args[3]) or 1
    if tId == 0 then return end

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    local unit = Common:FindUnitById(tId)
    if not unit then return end

    -- Clamp + apply
    hp    = Common:Clamp(hp,    0, hpMax)
    hpMax = Common:Clamp(hpMax, 1, hpMax)
    unit.hpMax = hpMax
    unit.hp    = hp

    -- UI refresh
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if myId and tonumber(unit.id) == tonumber(myId) then
        if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
            RPE.Core.Windows.PlayerUnitWidget:Refresh()
        end
    end
    -- Portrait updates handled by ShowTick
    if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
        RPE.Core.Windows.UnitFrameWidget:Refresh(true)
    end
end)

-- UNIT_HEALTH: tId ; hp ; hpMax ; absorbAmount (for any unit, including NPCs)
Comms:RegisterHandler("UNIT_HEALTH", function(data, sender)
    RPE.Debug:Internal(string.format("[Handle] UNIT_HEALTH FULL DATA:\n%s", data))
    local args = { strsplit(";", data) }
    local tId   = tonumber(args[1]) or 0
    local hp    = tonumber(args[2]) or 0
    local hpMax = tonumber(args[3]) or 1
    local absorbAmount = tonumber(args[4]) or 0
    if tId == 0 then return end

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    local unit, unitKey = Common:FindUnitById(tId)
    if not unit then return end

    -- Clamp + apply
    hp    = Common:Clamp(hp,    0, hpMax)
    hpMax = Common:Clamp(hpMax, 1, hpMax)
    unit.hpMax = hpMax
    unit.hp    = hp

    -- Update absorption display in EventWidget
    if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
        local eventWidget = RPE.Core.Windows.EventWidget
        if eventWidget.portraitsByKey and unitKey then
            local portrait = eventWidget.portraitsByKey[unitKey]
            if portrait and portrait.SetAbsorption then
                portrait:SetAbsorption(absorbAmount)
            end
        end
    end
    
    -- Update absorption display in UnitFrameWidget (NPC portraits)
    if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
        local unitFrameWidget = RPE.Core.Windows.UnitFrameWidget
        if unitFrameWidget.portraitsByKey and unitKey then
            local portrait = unitFrameWidget.portraitsByKey[unitKey]
            if portrait and portrait.SetAbsorption then
                portrait:SetAbsorption(absorbAmount)
            end
        end
    end

    -- Update absorption display in TargetWindow (NPC target portraits)
    if RPE.Core.Windows and RPE.Core.Windows.TargetWindow then
        local targetWindow = RPE.Core.Windows.TargetWindow
        if targetWindow.portraitsByKey and unitKey then
            local portrait = targetWindow.portraitsByKey[unitKey]
            if portrait and portrait.SetAbsorption then
                portrait:SetAbsorption(absorbAmount)
            end
        end
    end
    
    -- UI refresh - refresh EventWidget's portrait row if unit is in current tick
    if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
        RPE.Core.Windows.EventWidget:RefreshPortraitRow(false)
    end
    
    -- Also refresh UnitFrameWidget
    if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
        RPE.Core.Windows.UnitFrameWidget:Refresh(true)
    end
    
    -- Also refresh PlayerUnitWidget if this is the local player
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if myId and tonumber(unit.id) == tonumber(myId) then
        if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
            RPE.Core.Windows.PlayerUnitWidget:Refresh()
        end
    end
end)

-- ATTACK_SPELL: sId ; tId ; spellId ; spellName ; hitSystem ; attackRoll ; thresholdStatsCSV ; damageCSV ; auraEffectsJSON
Comms:RegisterHandler("ATTACK_SPELL", function(data, sender)
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1
    local tId  = tonumber(args[i]) or 0; i = i + 1
    local spellId = args[i] or ""; i = i + 1
    local spellName = args[i] or ""; i = i + 1
    local hitSystem = args[i] or "complex"; i = i + 1
    local attackRoll = tonumber(args[i]) or 0; i = i + 1
    local thresholdStatsCSV = args[i] or ""; i = i + 1
    local damageCSV = args[i] or ""; i = i + 1
    local auraEffectsJSON = args[i] or ""; i = i + 1

    if sId == 0 or tId == 0 or spellId == "" or spellName == "" then
        RPE.Debug:Error("[Handle] ATTACK_SPELL missing required fields")
        return
    end

    -- Parse threshold stats from CSV
    local thresholdStats = {}
    if thresholdStatsCSV ~= "" then
        for stat in string.gmatch(thresholdStatsCSV, "([^,]+)") do
            local trimmed = stat:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                table.insert(thresholdStats, trimmed)
            end
        end
    end

    -- Parse damage by school from CSV (format: school1:amount1,school2:amount2,...)
    local damageBySchool = {}
    if damageCSV ~= "" then
        for damageStr in string.gmatch(damageCSV, "([^,]+)") do
            local school, amount = damageStr:match("^([^:]+):(%d+)$")
            if school and amount then
                damageBySchool[school] = tonumber(amount) or 0
            end
        end
    end
    
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[Handle] ATTACK_SPELL received damageCSV=\'%s\', parsed as: %s'):format(
            damageCSV, 
            table.concat((function() local t = {} for s, a in pairs(damageBySchool) do table.insert(t, s..":"..a) end return t end)(), ",")))
    end

    -- Parse aura effects from JSON (format: auraId|actionKey|argsJSON||auraId|actionKey|argsJSON)
    local auraEffects = {}
    if auraEffectsJSON ~= "" then
        -- Replace || with a marker, then split properly
        local marker = "\001"  -- Use a rare character as separator
        local normalized = auraEffectsJSON:gsub("||", marker)
        
        for effectStr in string.gmatch(normalized, "[^" .. marker .. "]+") do
            if effectStr ~= "" then
                local parts = { strsplit("|", effectStr) }
                if #parts >= 3 then
                    table.insert(auraEffects, {
                        auraId = parts[1],
                        actionKey = parts[2],
                        argsJSON = parts[3] or "",
                    })
                elseif #parts == 2 then
                    -- Handle case where argsJSON is empty
                    table.insert(auraEffects, {
                        auraId = parts[1],
                        actionKey = parts[2],
                        argsJSON = "",
                    })
                end
            end
        end
    end
    
    -- Debug: Log parsed aura effects
    if RPE and RPE.Debug and RPE.Debug.Print then
        if #auraEffects > 0 then
            local effectDescs = {}
            for _, effect in ipairs(auraEffects) do
                table.insert(effectDescs, effect.auraId .. "|" .. effect.actionKey .. "|" .. effect.argsJSON)
            end
            RPE.Debug:Internal(('[Handle] ATTACK_SPELL parsed auraEffects: %s'):format(table.concat(effectDescs, " + ")))
        else
            RPE.Debug:Internal(('[Handle] ATTACK_SPELL no auraEffects parsed (input was: "%s")'):format(auraEffectsJSON))
        end
    end

    -- Get active event and find attacker
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then
        RPE.Debug:Error("[Handle] ATTACK_SPELL but no ActiveEvent")
        return
    end

    local attacker = nil
    for _, u in pairs(ev.units) do
        if tonumber(u.id) == sId then
            attacker = u
            break
        end
    end

    if not attacker then
        RPE.Debug:Error("[Handle] ATTACK_SPELL attacker not found: " .. tostring(sId))
        return
    end

    -- Check if this is the local player being attacked
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if not myId or tonumber(myId) ~= tId then
        -- NPC-to-NPC attack: broadcast combat message instead of triggering player reaction
        local target = nil
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tId then
                target = u
                break
            end
        end
        
        if target and target.isNPC then
            -- Calculate total damage from all schools for messaging
            local totalDamage = 0
            for _, amount in pairs(damageBySchool) do
                totalDamage = totalDamage + (tonumber(amount) or 0)
            end
            
            -- Build damage string with all schools
            local damageStrings = {}
            for school, amount in pairs(damageBySchool) do
                if tonumber(amount) and tonumber(amount) > 0 then
                    table.insert(damageStrings, math.floor(amount) .. " " .. school)
                end
            end
            
            -- Broadcast combat message for NPC-to-NPC attack
            if #damageStrings > 0 then
                local damageText = table.concat(damageStrings, ", ")
                local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
                if Broadcast and Broadcast.SendCombatMessage then

                    Broadcast:SendCombatMessage(sId, attacker.name, ("%s deals %s damage to %s."):format(attacker.name, damageText, target.name))
                end
            end
            
            -- Use Broadcast:Damage so it goes through the DAMAGE handler and applies absorption
            local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
            if Broadcast and Broadcast.Damage then
                -- Determine primary damage school
                local primarySchool = ""
                local maxDamage = 0
                for school, amount in pairs(damageBySchool) do
                    if tonumber(amount) and tonumber(amount) > maxDamage then
                        maxDamage = tonumber(amount)
                        primarySchool = school
                    end
                end
                Broadcast:Damage(sId, tId, totalDamage, { school = primarySchool, crit = false })
            end
            
            -- Apply deferred aura effects AFTER damage (so they happen in correct order)
            if #auraEffects > 0 then
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(('[Handle] Applying %d aura effects to NPC target'):format(#auraEffects))
                end
                
                local SpellActions = RPE.Core and RPE.Core.SpellActions
                if SpellActions then
                    for _, effect in ipairs(auraEffects) do
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[Handle] Applying aura effect to NPC: auraId=%s, action=%s'):format(
                                effect.auraId, effect.actionKey))
                        end
                        
                        -- Parse args from JSON if present
                        local effectArgs = {}
                        if effect.argsJSON and effect.argsJSON ~= "" then
                            -- Simple JSON parsing for args
                            for key, val in string.gmatch(effect.argsJSON, '([%w_]+)=([^,}]+)') do
                                effectArgs[key] = val
                            end
                        end
                        
                        -- Execute the action on target
                        local ok, err = pcall(function()
                            -- Ensure we have fresh reference to event with AuraManager
                            local currentEv = RPE.Core.ActiveEvent or ev
                            -- Wrap event in context object with .event property
                            local ctx = { event = currentEv }
                            SpellActions:Run(effect.actionKey, ctx, { caster = sId }, { tId }, effectArgs)
                        end)
                        
                        if not ok and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal("|cffff5555[Handle] Aura effect error:|r " .. tostring(err))
                        end
                    end
                end
            end
            
            -- Emit ON_HIT_TAKEN trigger for the target
            local AuraTriggers = RPE.Core and RPE.Core.AuraTriggers
            if AuraTriggers and AuraTriggers.Emit then
                AuraTriggers:Emit("ON_HIT_TAKEN", ev or {}, tId, tId, {
                    damageAmount = totalDamage,
                    sourceId = sId,
                    isCrit = false,
                })
            end
        end
        return
    end

    -- Get the spell definition for context
    local SpellRegistry = RPE.Core and RPE.Core.SpellRegistry
    local spell = nil
    if SpellRegistry and SpellRegistry.Get then
        spell = SpellRegistry:Get(spellId)
    end

    -- Calculate total damage from all schools
    local totalDamage = 0
    for _, amount in pairs(damageBySchool) do
        totalDamage = totalDamage + (tonumber(amount) or 0)
    end

    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[Handle] ATTACK_SPELL: %s (%s) attacks with %s [attackRoll=%d, totalDamage=%d, auraEffects=%d]')
            :format(attacker.name, tostring(sId), spellName, attackRoll, totalDamage, #auraEffects))
    end

    -- Trigger player reaction dialog
    -- Track defending state separately
    RPE.Core = RPE.Core or {}
    RPE.Core._isDefendingThisTurn = true
    -- Refresh action bar requirements so reaction spells are enabled
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Start then
        -- Check if player is failing all defences or specific defence stats due to crowd control
        local AuraManager = ev and ev._auraManager
        local isFailingAllDefences = AuraManager and AuraManager:IsFailingAllDefences(tId)
        
        -- If player is failing all defences, skip the dialog and immediately fail the defence
        if isFailingAllDefences then
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Print(("You are unable to defend yourself against %s."):format(attacker.name or "Unknown"))
            end
            
            -- Immediately apply damage without dialog
            local isCrit = false
            for _, effect in ipairs(auraEffects) do
                if effect.auraId == "CRIT_FLAG" and effect.argsJSON and effect.argsJSON:match("isCrit=true") then
                    isCrit = true
                    break
                end
            end
            
            -- Determine primary damage school
            local primarySchool = ""
            local maxDamage = 0
            for school, amount in pairs(damageBySchool) do
                if tonumber(amount) and tonumber(amount) > maxDamage then
                    maxDamage = tonumber(amount)
                    primarySchool = school
                end
            end
            
            -- Apply full damage (failed defence means no mitigation)
            local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
            if B and B.Damage then
                B:Damage(sId, tId, totalDamage, { school = primarySchool, crit = isCrit, threat = totalDamage })
            end
            
            -- Apply aura effects since attack hit
            if #auraEffects > 0 then
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(('[Handle] Applying %d aura effects from attack (auto-failed defence)'):format(#auraEffects))
                end
                
                local SpellActions = RPE.Core and RPE.Core.SpellActions
                if SpellActions then
                    for _, effect in ipairs(auraEffects) do
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[Handle] Applying aura effect: auraId=%s, action=%s'):format(
                                effect.auraId, effect.actionKey))
                        end
                        
                        -- Parse args from JSON if present
                        local effectArgs = {}
                        if effect.argsJSON and effect.argsJSON ~= "" then
                            for key, val in string.gmatch(effect.argsJSON, '([%w_]+)=([^,}]+)') do
                                effectArgs[key] = val
                            end
                        end
                        
                        -- Execute the action on target with proper context
                        local ok, err = pcall(function()
                            local currentEv = RPE.Core.ActiveEvent or ev
                            local ctx = { event = currentEv }
                            SpellActions:Run(effect.actionKey, ctx, { caster = sId }, { tId }, effectArgs)
                        end)
                        
                        if not ok and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal("|cffff5555[Handle] Aura effect error:|r " .. tostring(err))
                        end
                    end
                end
            end
            
            -- Emit ON_HIT_TAKEN trigger for the target
            local AuraTriggers = RPE.Core and RPE.Core.AuraTriggers
            if AuraTriggers and AuraTriggers.Emit then
                AuraTriggers:Emit("ON_HIT_TAKEN", ev or {}, tId, tId, {
                    damageAmount = totalDamage,
                    sourceId = sId,
                    isCrit = isCrit,
                })
            end
            return
        end
        
        -- Dummy spell/action tables for now (real values would come from NPC data)
        local dummyAction = {
            hitModifier = "$stat.NPC_MELEE_HIT$",
            hitThreshold = thresholdStats,  -- Array of stat IDs
        }
        
        -- Completion callback: will be called when player chooses a defense
        -- For AC mode: hitResult is (attackRoll >= AC), lhs is attackRoll, rhs is playerAC
        -- For complex/simple: hitResult is defendSuccess (boolean), lhs is player defense roll, rhs is mitigated damage
        local function onAttackComplete(hitResult, roll, lhs, rhs)
            local playerDefends
            local mitigatedDamage = totalDamage  -- Default to full damage
            
            if hitSystem == "ac" then
                -- AC mode: hitResult tells us if attack hit (attackRoll >= AC)
                -- In AC mode, there's no mitigation - either hit or miss
                playerDefends = not hitResult  -- If hitResult is true (hit), playerDefends is false
                mitigatedDamage = hitResult and totalDamage or 0  -- Full damage on hit, no damage on miss
            else
                -- Complex/Simple mode: hitResult is defendSuccess (boolean)
                -- rhs is mitigated damage to apply (0 if fully defended, otherwise partial damage)
                playerDefends = hitResult  -- hitResult is defendSuccess
                mitigatedDamage = rhs or 0  -- Use the mitigated damage passed from handler
            end
            
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(('[Handle] Attack complete: hitSystem=%s, playerRoll=%d, lhs=%d, rhs=%d, attackerRoll=%d, playerDefends=%s, mitigatedDamage=%d')
                    :format(hitSystem, roll or 0, lhs or 0, rhs or 0, attackRoll, tostring(playerDefends), mitigatedDamage))
            end
            
            -- Apply damage based on result
            if playerDefends then
                -- Player successfully defended - apply mitigated damage
                if mitigatedDamage > 0 then
                    -- Check if this was a critical hit
                    local isCrit = false
                    for _, effect in ipairs(auraEffects) do
                        if effect.auraId == "CRIT_FLAG" and effect.argsJSON and effect.argsJSON:match("isCrit=true") then
                            isCrit = true
                            break
                        end
                    end
                    
                    -- Determine primary damage school
                    local primarySchool = ""
                    local maxDamage = 0
                    for school, amount in pairs(damageBySchool) do
                        if tonumber(amount) and tonumber(amount) > maxDamage then
                            maxDamage = tonumber(amount)
                            primarySchool = school
                        end
                    end
                    
                    -- Use Broadcast:Damage so it goes through the DAMAGE handler and applies absorption
                    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if B and B.Damage then
                        B:Damage(sId, tId, mitigatedDamage, { school = primarySchool, crit = isCrit, threat = mitigatedDamage })
                    end
                else
                    -- Fully defended - no damage taken
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Print("[Handle] You fully defend against the attack - no damage taken!")
                    end
                end
            else
                -- Attack hits - apply full damage
                if mitigatedDamage > 0 then
                    -- Check if this was a critical hit
                    local isCrit = false
                    for _, effect in ipairs(auraEffects) do
                        if effect.auraId == "CRIT_FLAG" and effect.argsJSON and effect.argsJSON:match("isCrit=true") then
                            isCrit = true
                            break
                        end
                    end
                    
                    -- Determine primary damage school
                    local primarySchool = ""
                    local maxDamage = 0
                    for school, amount in pairs(damageBySchool) do
                        if tonumber(amount) and tonumber(amount) > maxDamage then
                            maxDamage = tonumber(amount)
                            primarySchool = school
                        end
                    end
                    
                    -- Use Broadcast:Damage so it goes through the DAMAGE handler and applies absorption
                    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if B and B.Damage then
                        B:Damage(sId, tId, mitigatedDamage, { school = primarySchool, crit = isCrit, threat = mitigatedDamage })
                    end
                end
            end
            
            -- Apply triggered aura effects if attacker hit (only in AC mode when not defended)
            -- In complex/simple mode, only apply if not defended
            local shouldApplyEffects = (hitSystem == "ac" and not playerDefends) or (hitSystem ~= "ac" and not playerDefends)
            if shouldApplyEffects and #auraEffects > 0 then
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(('[Handle] Applying %d aura effects from attack'):format(#auraEffects))
                end
                
                local SpellActions = RPE.Core and RPE.Core.SpellActions
                if SpellActions then
                    for _, effect in ipairs(auraEffects) do
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[Handle] Applying aura effect: auraId=%s, action=%s'):format(
                                effect.auraId, effect.actionKey))
                        end
                        
                        -- Parse args from JSON if present
                        local effectArgs = {}
                        if effect.argsJSON and effect.argsJSON ~= "" then
                            -- Simple JSON parsing for args (can be enhanced if needed)
                            -- For now, just try to deserialize basic key=value pairs
                            for key, val in string.gmatch(effect.argsJSON, '([%w_]+)=([^,}]+)') do
                                effectArgs[key] = val
                            end
                        end
                        
                        -- Execute the action on target with proper context containing AuraManager
                        local ok, err = pcall(function()
                            -- Ensure we have fresh reference to event with AuraManager
                            local currentEv = RPE.Core.ActiveEvent or ev
                            -- Wrap event in context object with .event property
                            local ctx = { event = currentEv }
                            SpellActions:Run(effect.actionKey, ctx, { caster = sId }, { tId }, effectArgs)
                        end)
                        
                        if not ok and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal("|cffff5555[Handle] Aura effect error:|r " .. tostring(err))
                        end
                    end
                end
            end
        end
        
        -- Pass attack details to the reaction dialog for display
        local turnNum = nil
        if ev and ev.turn then
            turnNum = ev.turn
        end
        
        -- Determine primary damage school (pick the one with most damage, or first)
        local primarySchool = "Physical"
        local maxDamage = 0
        for school, amount in pairs(damageBySchool) do
            if tonumber(amount) and tonumber(amount) > maxDamage then
                maxDamage = tonumber(amount)
                primarySchool = school
            end
        end
        
        local attackDetails = {
            attackRoll = attackRoll,
            predictedDamage = totalDamage,
            damageSchool = primarySchool,
            damageBySchool = damageBySchool,  -- Full breakdown by school
            spellName = spellName,
            turn = turnNum,  -- Include turn number if available
            thresholdStats = thresholdStats,  -- Include threshold stats for complex defense
            failingDefenceStats = {},  -- Track which specific defence stats are failing
        }
        
        -- Check which specific defence stats are failing due to crowd control
        if AuraManager then
            for _, statId in ipairs(thresholdStats) do
                if AuraManager:IsDefenceStatFailing(tId, statId) then
                    table.insert(attackDetails.failingDefenceStats, statId)
                end
            end
        end
        
        PlayerReaction:Start(hitSystem, spell or { name = spellName, id = spellId }, dummyAction, sId, tId, onAttackComplete, attackDetails)
    else
        RPE.Debug:Error("[Handle] PlayerReaction module not available")
    end
end)

-- NPC_MESSAGE: unitId ; unitName ; message
-- Receive a message from a controlled NPC unit
Comms:RegisterHandler("NPC_MESSAGE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    local unitName = args[2] or "NPC"
    local message = args[3] or ""
    local language = args[4] or "Common"
    
    if not unitName or unitName == "" or not message or message == "" then
        return
    end
    
    -- Obfuscate message once based on player's language skill
    local displayMessage = message
    local Language = RPE and RPE.Core and RPE.Core.Language
    if Language then
        displayMessage = Language:ObfuscateText(message, language)
    end
    
    -- Add to chat box if available (pass already-obfuscated message, language=nil to skip re-obfuscation)
    local ChatBoxWidget = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if ChatBoxWidget and ChatBoxWidget.PushNPCMessage then
        ChatBoxWidget:PushNPCMessage(unitName, displayMessage, language)
    end
    
    -- Also add to default Blizzard chat frame (with language prefix if not default)
    if DEFAULT_CHAT_FRAME then
        local r, g, b = 1.0, 1.0, 0.624  -- #FFFF9F
        local playerFaction = UnitFactionGroup("player")
        local defaultLanguage = (playerFaction == "Alliance") and "Common" or "Orcish"
        local languagePrefix = language and language ~= defaultLanguage and ("[" .. language .. "] ") or ""
        DEFAULT_CHAT_FRAME:AddMessage(unitName .. " says: " .. languagePrefix .. displayMessage, r, g, b)
    end
    
    -- Trigger speech bubble if available (pass already-obfuscated message)
    local ChatBoxWidget = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if ChatBoxWidget and ChatBoxWidget.speechBubbleWidget then
        -- Look up the NPC unit to get model data
        local npcUnit = nil
        if unitId > 0 then
            local ActiveEvent = RPE and RPE.Core and RPE.Core.ActiveEvent
            if ActiveEvent and ActiveEvent.units then
                for _, unit in pairs(ActiveEvent.units) do
                    if unit.id == unitId and unit.isNPC then
                        npcUnit = unit
                        break
                    end
                end
            end
        end
        ChatBoxWidget.speechBubbleWidget:ShowBubble(nil, unitName, displayMessage, npcUnit, language)
    end
end)

-- Handle SUMMON message from a summoner - supergroup leader adds the unit
Comms:RegisterHandler("SUMMON", function(data, sender)
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Comms] Received SUMMON from " .. tostring(sender)))
    end
    
    -- Only the leader processes SUMMON messages
    if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal("[Comms] SUMMON: Ignoring (not leader)")
        end
        return
    end
    
    local args = { strsplit(";", data) }
    local ev = RPE.Core.ActiveEvent
    if not ev then 
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal("[Comms] SUMMON: No active event")
        end
        return 
    end
    
    -- Parse message: npcId; summonerUnitId; summonerTeam
    local npcId = args[1]
    local summonerUnitId = tonumber(args[2]) or 0
    local summonerTeam = tonumber(args[3]) or 1
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Comms] SUMMON: Parsed args - npcId=%s, summonerUnitId=%s (raw), summonerTeam=%s"):format(
            tostring(args[1]), tostring(args[2]), tostring(args[3])))
        RPE.Debug:Internal(("[Comms] SUMMON: Converted - npcId=%s, summonerUnitId=%d, summonerTeam=%d"):format(
            npcId, summonerUnitId, summonerTeam))
    end
    
    if not npcId or npcId == "" then
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal("[Comms] SUMMON: Missing npcId")
        end
        return
    end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Comms] SUMMON: Adding %s on team %d, summoned by unit %d"):format(
            npcId, summonerTeam, summonerUnitId))
    end
    
    -- Leader adds the NPC to the event just like AddNPCFromRegistry
    local summoned = ev:AddNPCFromRegistry(npcId, {
        team = summonerTeam,
        active = true,
        hidden = false,
        flying = false,
        summonedBy = summonerUnitId,
    })
    
    if summoned then
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Comms] SUMMON: Successfully added unit %d (%s)"):format(
                summoned.id, summoned.name))
        end
        
        -- Refresh UI to show the new unit
        if ev.RebuildTicks then ev:RebuildTicks() end
        if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
            RPE.Core.Windows.UnitFrameWidget:Refresh(true)
        end
    else
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Comms] SUMMON: Failed to add unit for %s"):format(npcId))
        end
    end
end)

-- Handle HIDE: hide a unit
Comms:RegisterHandler("HIDE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Handle] HIDE: unitId=%d"):format(unitId))
    end
    
    if unitId <= 0 then return end
    
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    
    -- Find the unit and hide it
    local unit = nil
    local unitKey = nil
    for key, u in pairs(ev.units) do
        if tonumber(u.id) == unitId then
            unit = u
            unitKey = key
            break
        end
    end
    
    if unit then
        unit.hidden = true
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Handle] HIDE: Unit %d (%s) is now hidden"):format(unit.id, unit.name))
        end
        
        -- Refresh EventWidget portraits (includes player portraits)
        if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
            local eventWidget = RPE.Core.Windows.EventWidget
            if eventWidget.portraitsByKey and unitKey then
                local portrait = eventWidget.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
            if eventWidget.RefreshPortraitRow then
                eventWidget:RefreshPortraitRow(false)
            end
        end
        
        -- Refresh UnitFrameWidget portraits (NPC portraits)
        if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
            local unitFrameWidget = RPE.Core.Windows.UnitFrameWidget
            if unitFrameWidget.portraitsByKey and unitKey then
                local portrait = unitFrameWidget.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
        end
        
        -- Refresh TargetWindow portraits (target unit portraits)
        if RPE.Core.Windows and RPE.Core.Windows.TargetWindow then
            local targetWindow = RPE.Core.Windows.TargetWindow
            if targetWindow.portraitsByKey and unitKey then
                local portrait = targetWindow.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
        end
    end
end)

-- Handle UNHIDE: unhide a unit
Comms:RegisterHandler("UNHIDE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[Handle] UNHIDE: unitId=%d"):format(unitId))
    end
    
    if unitId <= 0 then return end
    
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    
    -- Find the unit and unhide it
    local unit = nil
    local unitKey = nil
    for key, u in pairs(ev.units) do
        if tonumber(u.id) == unitId then
            unit = u
            unitKey = key
            break
        end
    end
    
    if unit then
        unit.hidden = false
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[Handle] UNHIDE: Unit %d (%s) is now revealed"):format(unit.id, unit.name))
        end
        
        -- Refresh EventWidget portraits (includes player portraits)
        if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
            local eventWidget = RPE.Core.Windows.EventWidget
            if eventWidget.portraitsByKey and unitKey then
                local portrait = eventWidget.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
            if eventWidget.RefreshPortraitRow then
                eventWidget:RefreshPortraitRow(false)
            end
        end
        
        -- Refresh UnitFrameWidget portraits (NPC portraits)
        if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
            local unitFrameWidget = RPE.Core.Windows.UnitFrameWidget
            if unitFrameWidget.portraitsByKey and unitKey then
                local portrait = unitFrameWidget.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
        end
        
        -- Refresh TargetWindow portraits (target unit portraits)
        if RPE.Core.Windows and RPE.Core.Windows.TargetWindow then
            local targetWindow = RPE.Core.Windows.TargetWindow
            if targetWindow.portraitsByKey and unitKey then
                local portrait = targetWindow.portraitsByKey[unitKey]
                if portrait and portrait.Refresh then
                    portrait:Refresh()
                end
            end
        end
    end
end)

-- Handle DICE_MESSAGE: display dice rolls in chat
Comms:RegisterHandler("DICE_MESSAGE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    local unitName = args[2] or ""
    local message = args[3] or ""
    
    if not message or message == "" then
        return
    end
    
    -- Display the dice message
    RPE.Debug:Dice(message)
end)

-- Handle COMBAT_MESSAGE: display combat outcomes in chat
Comms:RegisterHandler("COMBAT_MESSAGE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    local unitName = args[2] or ""
    local message = args[3] or ""
    
    if not message or message == "" then
        return
    end
    
    -- Display the combat message
    RPE.Debug:Combat(message)
end)

-- Handle CALL_HELP: a teammate needs assistance
Comms:RegisterHandler("CALL_HELP", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    local unitName = args[2] or ""
    
    -- Mark that help has been called and spells can be cast out of turn
    RPE.Core = RPE.Core or {}
    RPE.Core._helpRequestsThisTurn = (RPE.Core._helpRequestsThisTurn or 0) + 1

    -- Enable reaction glow on all action bar buttons with "assist" or "reaction" tag
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.slots then
        local glowedCount = 0
        for i, slot in ipairs(actionBar.slots) do
            if slot and slot.action and slot.action.spellId then
                local SR = RPE.Core and RPE.Core.SpellRegistry
                local spell = SR and SR:Get(slot.action.spellId)
                -- Check if spell has assist or reaction tag
                if spell and spell.tags and type(spell.tags) == "table" then
                    for _, tag in ipairs(spell.tags) do
                        local lowerTag = tag:lower()
                        if lowerTag == "assist" or lowerTag == "reaction" then
                            -- Enable reaction glow on assist/reaction-tagged spells
                            if slot.reactionGlow then
                                slot:ShowReactionGlow()
                                glowedCount = glowedCount + 1
                            end
                            break
                        end
                    end
                end
            end
        end

        -- Refresh requirements so slots are enabled immediately
        if actionBar and actionBar.RefreshRequirements then
            actionBar:RefreshRequirements()
        end
    end
    
    -- Display the help call message
    if RPE.Debug and RPE.Debug.Combat then
        RPE.Debug:Combat(unitName .. " needs help!")
    else
        print(unitName .. " needs help!")
    end
end)

-- Handle CALL_HELP_END: teammate responded to help call
Comms:RegisterHandler("CALL_HELP_END", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    
    -- Decrement the help call counter
    RPE.Core = RPE.Core or {}
    RPE.Core._helpRequestsThisTurn = math.max(0, (RPE.Core._helpRequestsThisTurn or 1) - 1)
    
    -- Disable reaction glow on all action bar buttons
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.slots then
        local glowsDisabled = 0
        for i, slot in ipairs(actionBar.slots) do
            if slot and slot.reactionGlow then
                slot:HideReactionGlow()
                glowsDisabled = glowsDisabled + 1
            end
        end
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print(string.format("[CALL_HELP_END] Disabled %d reaction glows", glowsDisabled))
        end
        -- Refresh requirements so slots are disabled immediately
        if actionBar.RefreshRequirements then
            actionBar:RefreshRequirements()
        end
    else
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print("[CALL_HELP_END] ActionBarWidget or slots not found")
        end
    end
end)

Comms:RegisterHandler("TRP_NAME", function(raw, sender)
    -- Raw is a semicolon-joined payload; first field is the display name
    local trpName = nil
    if type(raw) == "string" then
        trpName = (select(1, strsplit(";", raw))) or raw
    else
        trpName = tostring(raw or "")
    end

    if not trpName or trpName == "" then return end

    -- Only the leader should apply incoming TRP names to EventUnit objects
    if not (RPE and RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then return end

    -- Resolve sender to an event unit id (uses _toUnitId helper above)
    local senderUnitId = _toUnitId(sender) or 0
    if senderUnitId == 0 then return end

    local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
    if not ev or not ev.units then return end

    for _, u in pairs(ev.units) do
        if tonumber(u.id) == tonumber(senderUnitId) then
            -- Apply the TRP name to the EventUnit and update any portraits
            u.name = trpName
            if u._portraits and type(u._portraits) == "table" then
                for _, p in ipairs(u._portraits) do
                    if p and p.SetName then
                        p:SetName(trpName)
                    end
                end
            end
            RPE.Debug:Internal(string.format("[Broadcast] Applied TRP name '%s' to unit id %d (sender=%s)", trpName, senderUnitId, sender))
            break
        end
    end
end)