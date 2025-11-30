-- RPE/Profile/DatasetDB.lua  (REPLACE FILE)

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

local Dataset = assert(RPE.Profile.Dataset, "Dataset.lua must load before DatasetDB.lua")

_G.RPEngineDatasetDB = _G.RPEngineDatasetDB or {}  -- ## SavedVariables: RPEngineDatasetDB

local DB_SCHEMA_VERSION = 2

local DatasetDB = {}
RPE.Profile.DatasetDB = DatasetDB

local DEFAULT_DATASETS = { "DefaultClassic", "Default5e", "DefaultWarcraft" }

local function _isDefaultDataset(name)
    for _, dname in ipairs(DEFAULT_DATASETS) do
        if name == dname then return true end
    end
    return false
end

local function GetCharacterKey()
    local name  = UnitName and UnitName("player") or "Player"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return (name or "Player") .. "-" .. (realm or "Realm")
end

local function EnsureDB()
    local db = _G.RPEngineDatasetDB
    db._schema       = db._schema or DB_SCHEMA_VERSION
    db.datasets      = db.datasets or {}       -- [datasetName] = serialized table (Dataset:ToTable())
    db.currentByChar = db.currentByChar or {}  -- (legacy) ["Name-Realm"] = datasetName
    db.activeByChar  = db.activeByChar  or {}  -- ["Name-Realm"] = { "DS1", "DS2", ... }

    -- Migrate legacy single-active into multi-active on first sight
    for ck, single in pairs(db.currentByChar) do
        if single and single ~= "" and not db.activeByChar[ck] then
            db.activeByChar[ck] = { single }
        end
    end

    return db
end

local function _copyInto(dst, src)
    for k, v in pairs(src or {}) do dst[k] = v end
end

local function _mergeNested(dst, src)
    -- For "extra" bucket: nested maps per category
    for cat, tbl in pairs(src or {}) do
        dst[cat] = dst[cat] or {}
        _copyInto(dst[cat], tbl)
    end
end

-- Check for stat key conflicts across active datasets and warn if found
local function _validateStatKeyConflicts(names)
    names = names or {}
    local db = EnsureDB()
    local statsByDataset = {}
    
    -- Collect all stat keys from each dataset
    for _, name in ipairs(names) do
        local t = db.datasets[name]
        if t and t.extra and t.extra.stats then
            statsByDataset[name] = {}
            for statId, _ in pairs(t.extra.stats) do
                statsByDataset[name][statId] = true
            end
        end
    end
    
    -- Check for conflicts between pairs of datasets
    local conflicts = {}
    for i, name1 in ipairs(names) do
        for j = i + 1, #names do
            local name2 = names[j]
            if statsByDataset[name1] and statsByDataset[name2] then
                for statId, _ in pairs(statsByDataset[name1]) do
                    if statsByDataset[name2][statId] then
                        table.insert(conflicts, {
                            stat = statId,
                            datasets = { name1, name2 }
                        })
                    end
                end
            end
        end
    end
    
    -- Print warnings for conflicts
    if #conflicts > 0 then
        RPE.Debug:Print(string.format("WARNING: %d stat key conflicts detected across active datasets:", #conflicts))
        for _, conflict in ipairs(conflicts) do
            RPE.Debug:Print(string.format("  Stat '%s' exists in both '%s' and '%s'", 
                conflict.stat, conflict.datasets[1], conflict.datasets[2]))
        end
    end
    
    return #conflicts == 0
end

-- Merge datasets by ordered list of names; later names override earlier keys.
local function _buildMergedDataset(names)
    names = names or {}
    local db = EnsureDB()

    -- Validate stat key conflicts first
    _validateStatKeyConflicts(names)

    local items, spells, auras, npcs, extra = {}, {}, {}, {}, {}

    for _, name in ipairs(names) do
        local t = db.datasets[name]
        if t then
            _copyInto(items,  t.items  or {})
            _copyInto(spells, t.spells or {})
            _copyInto(auras,  t.auras  or {})
            _copyInto(npcs,   t.npcs   or {})
            _mergeNested(extra, t.extra or {})
        end
    end

    local mergedTitle = (#names > 0) and ("Active (" .. table.concat(names, " + ") .. ")") or "Active (None)"
    local ds = Dataset:New(mergedTitle, {
        version = 1, items = items, spells = spells, auras = auras, npcs = npcs, extra = extra,
        author = nil, notes = "Merged transient dataset (not persisted).",
    })
    return ds
end

local function _normalizeNames(names)
    local out, seen = {}, {}
    local db = EnsureDB()
    if type(names) ~= "table" then return out end
    for _, n in ipairs(names) do
        n = tostring(n or "")
        if n ~= "" and db.datasets[n] and not seen[n] then
            out[#out+1] = n
            seen[n] = true
        end
    end
    return out
end

-- -------- public API --------------------------------------------------------

function DatasetDB.GetActiveNamesForCurrentCharacter()
    local db  = EnsureDB()
    local key = GetCharacterKey()
    local list = db.activeByChar[key]
    return { unpack(list or {}) }
end

function DatasetDB.SetActiveNamesForCurrentCharacter(names)
    local db  = EnsureDB()
    local key = GetCharacterKey()
    
    -- Validate that required datasets are not being removed
    if RPE.ActiveRules then
        local required = RPE.ActiveRules:GetRequiredDatasets()
        local nameSet = {}
        for _, n in ipairs(names or {}) do
            nameSet[n] = true
        end
        
        for _, reqName in ipairs(required) do
            if not nameSet[reqName] then
                RPE.Debug:Warning(string.format("Cannot deactivate required dataset '%s' - it is locked by the active ruleset", reqName))
                return  -- Reject the entire operation
            end
        end
    end
    
    db.activeByChar[key] = _normalizeNames(names)
end

function DatasetDB.AddActive(name)
    local db  = EnsureDB()
    local key = GetCharacterKey()
    if not (name and db.datasets[name]) then return end
    
    -- Check if dataset changes are locked by ruleset
    if RPE.ActiveRules then
        if RPE.ActiveRules:IsDatasetExclusive() then
            local required = RPE.ActiveRules:GetRequiredDatasets()
            local isRequired = false
            for _, reqName in ipairs(required) do
                if reqName == name then
                    isRequired = true
                    break
                end
            end
            if not isRequired then
                RPE.Debug:Warning(string.format("Cannot activate dataset '%s' - exclusive mode only allows required datasets", name))
                return
            end
        end
    end
    
    db.activeByChar[key] = db.activeByChar[key] or {}
    for _, n in ipairs(db.activeByChar[key]) do if n == name then return end end
    
    -- Check for stat key conflicts with already-active datasets BEFORE adding
    local newDataset = db.datasets[name]
    local newStats = {}
    if newDataset and newDataset.extra and newDataset.extra.stats then
        for statId, _ in pairs(newDataset.extra.stats) do
            newStats[statId] = true
        end
    end
    
    local conflicts = {}
    for _, activeName in ipairs(db.activeByChar[key]) do
        local activeDataset = db.datasets[activeName]
        if activeDataset and activeDataset.extra and activeDataset.extra.stats then
            for statId, _ in pairs(activeDataset.extra.stats) do
                if newStats[statId] then
                    table.insert(conflicts, {
                        stat = statId,
                        existing = activeName,
                        new = name
                    })
                end
            end
        end
    end
    
    -- Print warnings for conflicts
    if #conflicts > 0 then
        RPE.Debug:Warning(string.format("Cannot add dataset '%s' - %d stat key conflicts with active datasets:", name, #conflicts))
        for _, conflict in ipairs(conflicts) do
            RPE.Debug:Internal(string.format("  Stat '%s' exists in both '%s' and '%s'", 
                conflict.stat, conflict.existing, conflict.new))
        end
        return  -- Don't add the conflicting dataset
    end
    
    table.insert(db.activeByChar[key], name)
    
    -- When a dataset is activated, add its stats to the profile
    local dataset = db.datasets[name]
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if profile and dataset and dataset.extra and dataset.extra.stats then
        local synced = 0
        for statId, statDef in pairs(dataset.extra.stats) do
            -- Only add if not already present
            if not profile.stats[statId] then
                local stat = profile:GetStat(statId, statDef.category or "PRIMARY")
                if stat then
                    stat:SetData({
                        id              = statId,
                        name            = statDef.name,
                        category        = statDef.category,
                        base            = statDef.base,
                        min             = statDef.min,
                        max             = statDef.max,
                        icon            = statDef.icon,
                        tooltip         = statDef.tooltip,
                        visible         = statDef.visible,
                        pct             = statDef.pct,
                        recovery        = statDef.recovery,
                        itemTooltipFormat   = statDef.itemTooltipFormat,
                        itemTooltipColor    = statDef.itemTooltipColor,
                        itemTooltipPriority = statDef.itemTooltipPriority,
                        itemLevelWeight     = statDef.itemLevelWeight,
                    })
                    if statDef.sourceDataset then stat.sourceDataset = statDef.sourceDataset end
                    synced = synced + 1
                end
            end
        end
        if synced > 0 then
            RPE.Profile.DB.SaveProfile(profile)
        end
    end
    
    -- Refresh sheets to show the new stats
    if RPE_UI.Windows.StatisticSheetInstance and RPE_UI.Windows.StatisticSheetInstance.Refresh then
        RPE.Debug:Internal(string.format("DatasetDB: Adding stats from dataset '%s', refreshing sheets", name))
        RPE_UI.Windows.StatisticSheetInstance:Refresh()
    end
    if RPE_UI.Windows.CharacterSheetInstance and RPE_UI.Windows.CharacterSheetInstance.Refresh then
        RPE_UI.Windows.CharacterSheetInstance:Refresh()
    end
end

function DatasetDB.RemoveActive(name)
    local db  = EnsureDB()
    local key = GetCharacterKey()
    
    -- Check if dataset is required (locked) by ruleset
    if RPE.ActiveRules and RPE.ActiveRules:IsDatasetRequired(name) then
        RPE.Debug:Warning(string.format("Cannot deactivate dataset '%s' - it is required by the active ruleset", name))
        return
    end
    
    local list = db.activeByChar[key] or {}
    local out = {}
    for _, n in ipairs(list) do if n ~= name then out[#out+1] = n end end
    db.activeByChar[key] = out
    
    -- When a dataset is unloaded, remove its stats from profile and refresh sheets
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if profile and profile.stats then
        for statId, stat in pairs(profile.stats) do
            if stat.sourceDataset == name then
                profile.stats[statId] = nil
            end
        end
        RPE.Profile.DB.SaveProfile(profile)
    end
    
    -- Refresh sheets to hide the removed stats
    if RPE_UI.Windows.StatisticSheetInstance and RPE_UI.Windows.StatisticSheetInstance.Refresh then
        RPE.Debug:Internal(string.format("DatasetDB: Removing stats from dataset '%s', refreshing sheets", name))
        RPE_UI.Windows.StatisticSheetInstance:Refresh()
    end
    if RPE_UI.Windows.CharacterSheetInstance and RPE_UI.Windows.CharacterSheetInstance.Refresh then
        RPE_UI.Windows.CharacterSheetInstance:Refresh()
    end
end

function DatasetDB.ToggleActive(name)
    local db  = EnsureDB()
    local key = GetCharacterKey()
    local list = db.activeByChar[key] or {}
    local found = false
    for _, n in ipairs(list) do if n == name then found = true break end end
    if found then DatasetDB.RemoveActive(name) else DatasetDB.AddActive(name) end
end

-- Back-compat: set single active only (replaces the list)
function DatasetDB.SetActiveForCurrentCharacter(name)
    assert(type(name) == "string" and name ~= "", "DatasetDB.SetActiveForCurrentCharacter: name required")
    DatasetDB.SetActiveNamesForCurrentCharacter({ name })
end

-- Convenience: get the single active dataset name (first in list)
function DatasetDB.GetActiveNameForCurrentCharacter()
    local names = DatasetDB.GetActiveNamesForCurrentCharacter()
    return names and names[1] or nil
end

-- Convenience alias for setting single active dataset by name
function DatasetDB.SetActiveNameForCurrentCharacter(name)
    DatasetDB.SetActiveForCurrentCharacter(name)
end

-- Return the *merged* active dataset (transient).
function DatasetDB.LoadActiveForCurrentCharacter()
    local names = DatasetDB.GetActiveNamesForCurrentCharacter()
    return _buildMergedDataset(names)
end

-- Like before, but ensures at least one exists & is active.
function DatasetDB.GetOrCreateActive()
    local _ = EnsureDB()
    return DatasetDB.LoadActiveForCurrentCharacter()
end

function DatasetDB.Save(dataset)
    assert(getmetatable(dataset) == Dataset, "DatasetDB.Save expects a Dataset")
    -- Ignore saving merged transient ("Active (...)") datasets
    if (dataset.notes or ""):find("Merged transient") then
        return
    end
    local db = EnsureDB()
    dataset.updatedAt = (type(time)=="function" and time()) or dataset.updatedAt
    db.datasets[dataset.name] = dataset:ToTable()
end

function DatasetDB.SaveAllActive()
    local names = DatasetDB.GetActiveNamesForCurrentCharacter()
    for _, n in ipairs(names) do
        local ds = DatasetDB.GetByName(n)
        if ds then DatasetDB.Save(ds) end
    end
end

function DatasetDB.GetByName(name)
    local db = EnsureDB()
    local t = db.datasets[name]
    return t and Dataset.FromTable(t) or nil
end

function DatasetDB.CreateNew(name, opts)
    assert(type(name) == "string" and name ~= "", "DatasetDB.CreateNew: name required")
    local db = EnsureDB()
    assert(db.datasets[name] == nil, "DatasetDB.CreateNew: dataset exists")
    local ds = Dataset:New(name, opts)
    db.datasets[name] = ds:ToTable()

    -- Also activate it
    local key = GetCharacterKey()
    db.activeByChar[key] = db.activeByChar[key] or {}
    table.insert(db.activeByChar[key], name)

    return ds
end

function DatasetDB.GetOrCreateByName(name, opts)
    return DatasetDB.GetByName(name) or DatasetDB.CreateNew(name, opts)
end

function DatasetDB.Rename(oldName, newName)
    assert(type(oldName) == "string" and oldName ~= "", "oldName required")
    assert(type(newName) == "string" and newName ~= "", "newName required")
    local db = EnsureDB()
    assert(db.datasets[oldName], "source dataset not found")
    assert(not db.datasets[newName], "target name exists")
    db.datasets[newName] = db.datasets[oldName]
    db.datasets[newName].name = newName
    db.datasets[oldName] = nil
    -- Update active lists
    for ck, list in pairs(db.activeByChar) do
        for i, n in ipairs(list) do
            if n == oldName then list[i] = newName end
        end
    end
    -- legacy, for good measure
    for k, v in pairs(db.currentByChar) do
        if v == oldName then db.currentByChar[k] = newName end
    end
end

function DatasetDB.Delete(name)
    -- Prevent deletion of default datasets
    if _isDefaultDataset(name) then return false end
    
    local db = EnsureDB()
    if not db.datasets[name] then return false end
    db.datasets[name] = nil
    for ck, list in pairs(db.activeByChar) do
        local out = {}
        for _, n in ipairs(list) do if n ~= name then out[#out+1] = n end end
        db.activeByChar[ck] = out
    end
    for k, v in pairs(db.currentByChar) do
        if v == name then db.currentByChar[k] = nil end
    end
    return true
end

function DatasetDB.ListNames()
    local db = EnsureDB()
    local out = {}
    for k in pairs(db.datasets) do out[#out+1] = k end
    table.sort(out)
    return out
end

-- -------- transfer helpers --------------------------------------------------

function DatasetDB.Export(name)
    local ds = name and DatasetDB.GetByName(name) or DatasetDB.GetOrCreateActive()
    if not ds then return "" end
    return ds:ExportString()
end

function DatasetDB.Import(s, nameOverride)
    local ds, err = Dataset.ImportString(s)
    if not ds then return nil, err end
    if nameOverride and nameOverride ~= "" then ds.name = nameOverride end
    DatasetDB.Save(ds)
    return ds
end

-- -------- lifecycle hooks ---------------------------------------------------

local function _ensureDefaultDatasets()
    local db = EnsureDB()
    -- Check default dataset definitions from Data/ files on every login
    -- This allows addon updates to refresh stat definitions without losing player data
    for _, defaultName in ipairs(DEFAULT_DATASETS) do
        local sourceData = nil
        
        -- Get the source data from the Data files
        if defaultName == "DefaultClassic" then
            sourceData = RPE and RPE.Data and RPE.Data.DefaultClassic
        elseif defaultName == "Default5e" then
            sourceData = RPE and RPE.Data and RPE.Data.Default5e
        elseif defaultName == "DefaultWarcraft" then
            sourceData = RPE and RPE.Data and RPE.Data.DefaultWarcraft
        end
        
        if sourceData then
            -- Always update from source (allows stats to be added/changed by addon updates)
            -- Preserve any player-specific modifications by merging
            local existing = db.datasets[defaultName]
            if existing then
                -- Update the stats in the default dataset from the source
                if sourceData.extra and sourceData.extra.stats then
                    existing.extra = existing.extra or {}
                    existing.extra.stats = sourceData.extra.stats
                end
                -- Update other core fields (in case they change in addon updates)
                existing.version = sourceData.version or existing.version
                existing.notes = sourceData.notes or existing.notes
            else
                -- First time: create from source
                db.datasets[defaultName] = sourceData
            end
        else
            -- Fallback: create empty default if file not loaded
            if not db.datasets[defaultName] then
                local ds = Dataset:New(defaultName, { author = "RPEngine", notes = "Default dataset" })
                db.datasets[defaultName] = ds:ToTable()
            end
        end
    end
end

local f = CreateFrame and CreateFrame("Frame")
if f then
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_LOGOUT")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            RPE.Debug:Internal("=== DatasetDB PLAYER_LOGIN START ===")
            -- Ensure default datasets exist
            _ensureDefaultDatasets()
            
            local ds = DatasetDB.GetOrCreateActive()
            if ds then
                local counts = ds:Counts()
                local names  = DatasetDB.GetActiveNamesForCurrentCharacter()
                RPE.Debug:Internal(string.format("Active datasets: %s", table.concat(names or {}, ", ")))
                pcall(function() ds:ApplyToRegistries() end)
            end

            -- Rebuild item registry from the merged active dataset.
            if RPE.Core and RPE.Core.ItemRegistry and RPE.Core.ItemRegistry.RefreshFromActiveDataset then
                RPE.Core.ItemRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.SpellRegistry and RPE.Core.SpellRegistry.RefreshFromActiveDataset then
                RPE.Core.SpellRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.AuraRegistry and RPE.Core.AuraRegistry.RefreshFromActiveDataset then
                RPE.Core.AuraRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.NPCRegistry and RPE.Core.NPCRegistry.RefreshFromActiveDataset then
                RPE.Core.NPCRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.RecipeRegistry and RPE.Core.RecipeRegistry.RefreshFromActiveDataset then
                RPE.Core.RecipeRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.InteractionRegistry and RPE.Core.InteractionRegistry.RefreshFromActiveDataset then
                RPE.Core.InteractionRegistry:RefreshFromActiveDataset()
            end

            if RPE.Core and RPE.Core.StatRegistry and RPE.Core.StatRegistry.RefreshFromActiveDataset then
                RPE.Core.StatRegistry:RefreshFromActiveDataset()
            end

            -- Sync stats from active registries to profile
            local profile = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB and _G.RPE.Profile.DB.GetOrCreateActive()
            RPE.Debug:Internal(string.format("DatasetDB PLAYER_LOGIN: profile = %s (id=%s)", 
                profile and profile.name or "nil", 
                profile and tostring(profile):match("table: (.*)") or "nil"))
            if profile then
                -- Get stats from active dataset's extra.stats (not just StatRegistry)
                local activeDataset = RPE.Profile.DatasetDB.LoadActiveForCurrentCharacter()
                local allStats = {}
                
                -- First, merge in stats from the active dataset's extra.stats
                if activeDataset and activeDataset.extra and activeDataset.extra.stats then
                    for statId, statDef in pairs(activeDataset.extra.stats) do
                        allStats[statId] = statDef
                    end
                end
                
                -- Then also include any stats from StatRegistry (for compatibility)
                if RPE.Core and RPE.Core.StatRegistry then
                    local registryStats = RPE.Core.StatRegistry:All()
                    for statId, statDef in pairs(registryStats) do
                        if not allStats[statId] then
                            allStats[statId] = statDef
                        end
                    end
                end
                
                local statCount = 0
                for _ in pairs(allStats) do statCount = statCount + 1 end
                RPE.Debug:Internal(string.format("DatasetDB: Loading %d stats (from active dataset + registry)", statCount))
                
                local synced = 0
                local hiddenCount = 0
                for statId, statDef in pairs(allStats) do
                    if statDef then
                        -- Get or create stat on profile with proper category
                        local stat = profile:GetStat(statId, statDef.category or "PRIMARY")
                        if stat then
                            synced = synced + 1
                            
                            -- Use SetData to properly apply all fields with validation/normalization
                            stat:SetData({
                                id              = statId,
                                name            = statDef.name,
                                category        = statDef.category,
                                base            = statDef.base,
                                min             = statDef.min,
                                max             = statDef.max,
                                icon            = statDef.icon,
                                tooltip         = statDef.tooltip,
                                visible         = statDef.visible,
                                pct             = statDef.pct,
                                recovery        = statDef.recovery,
                                itemTooltipFormat   = statDef.itemTooltipFormat,
                                itemTooltipColor    = statDef.itemTooltipColor,
                                itemTooltipPriority = statDef.itemTooltipPriority,
                                itemLevelWeight     = statDef.itemLevelWeight,
                            })
                            
                            -- Set sourceDataset directly (not in SetData)
                            if statDef.sourceDataset then stat.sourceDataset = statDef.sourceDataset end
                            
                            -- Track hidden stats for debug
                            if statDef.visible == 0 then hiddenCount = hiddenCount + 1 end
                        end
                    end
                end
                -- Save profile
                if _G.RPE.Profile.DB.SaveProfile then
                    _G.RPE.Profile.DB.SaveProfile(profile)
                end
                
                local profileStatCount = 0
                local profileHiddenCount = 0
                for statId, stat in pairs(profile.stats or {}) do 
                    profileStatCount = profileStatCount + 1
                    if stat.visible == 0 then profileHiddenCount = profileHiddenCount + 1 end
                end
                RPE.Debug:Internal(string.format("DatasetDB: synced %d stats (hidden: %d), profile now has %d stats (hidden: %d)", 
                    synced, hiddenCount, profileStatCount, profileHiddenCount))
            end
            
            -- Now that stats are synced, refresh the existing sheets
            if RPE_UI.Windows.CharacterSheetInstance and RPE_UI.Windows.CharacterSheetInstance.Refresh then
                RPE.Debug:Internal("DatasetDB: Refreshing CharacterSheet with synced stats")
                RPE_UI.Windows.CharacterSheetInstance:Refresh()
            end
            if RPE_UI.Windows.StatisticSheetInstance and RPE_UI.Windows.StatisticSheetInstance.Refresh then
                RPE.Debug:Internal("DatasetDB: Refreshing StatisticSheet with synced stats")
                RPE_UI.Windows.StatisticSheetInstance:Refresh()
            end
            
            RPE.Debug:Internal("=== DatasetDB PLAYER_LOGIN END ===")

            -- Create (and hide) the dataset window.
            local datasetWindow = RPE_UI.Windows.DatasetWindow.New({})
            RPE_UI.Common:Hide(datasetWindow)

        elseif event == "PLAYER_LOGOUT" then
            -- Save all active real datasets on logout
            DatasetDB.SaveAllActive()
        end
    end)
end

return DatasetDB
