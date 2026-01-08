-- RPE/Profile/RulesetDB.lua
-- Persistence layer for RulesetProfile objects using RPEngineRulesetDB.

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

local RulesetProfile = RPE.Profile.RulesetProfile

-- SavedVariables root (declared in .toc as `## SavedVariables: RPEngineRulesetDB`)
_G.RPEngineRulesetDB = _G.RPEngineRulesetDB or {}

local DB_SCHEMA_VERSION = 1

local RulesetDB = {}
RPE.Profile.RulesetDB = RulesetDB

-- === Internal helpers ===
local function GetCharacterKey()
    local name = UnitName and UnitName("player") or "Player"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return (name or "Player") .. "-" .. (realm or "Realm")
end

local function EnsureDB()
    local db = _G.RPEngineRulesetDB
    db._schema = db._schema or DB_SCHEMA_VERSION
    db.rulesets = db.rulesets or {}       -- [ "RulesetName" ] = serialized RulesetProfile
    db.currentByChar = db.currentByChar or {} -- [ "Name-Realm" ] = "RulesetName"
    return db
end

local function GetDefaultRulesetRules()
    return {
        exp_per_level = "83+pow((5*$level$), 1.5)",
        hit_system = "1d20",
        equipment_slots = "left,right,bottom",
        resource_types = "HEALTH,MANA,ACTION,BONUS_ACTION",
        max_level = "20",
        max_professions = "2",
        max_generic_traits = "2",
        max_racial_traits = "3",
        max_class_traits = "1",
        health_regen = "0.2*$stat.WIS_MOD$",
        mana_regen = "0.2*$stat.WIS_MOD$",
    }
end

-- === Public API ===
--- Load the active ruleset for the current character (or nil).
---@return RulesetProfile|nil
function RulesetDB.LoadActiveForCurrentCharacter()
    local db = EnsureDB()
    local key = GetCharacterKey()
    local rsName = db.currentByChar[key]
    if not rsName or rsName == "" then return nil end

    local t = db.rulesets[rsName]
    if not t then
        db.currentByChar[key] = nil
        return nil
    end
    return RulesetProfile.FromTable(t)
end

--- Set which ruleset name should be active for the current character.
---@param name string
function RulesetDB.SetActiveForCurrentCharacter(name)
    assert(type(name) == "string" and name ~= "", "Active ruleset name required")
    local db = EnsureDB()
    local key = GetCharacterKey()
    db.currentByChar[key] = name
end

--- Get or create the active ruleset for the current character.
--- If none is mapped, defaults to "DefaultRuleset".
---@return RulesetProfile
function RulesetDB.GetOrCreateActive()
    local db = EnsureDB()
    local key = GetCharacterKey()
    local rsName = db.currentByChar[key]

    if not rsName or rsName == "" then
        rsName = "DefaultRuleset"
        db.currentByChar[key] = rsName
    end

    return RulesetDB.GetOrCreateByName(rsName)
end

--- Get active ruleset names for the current character as an array (for compatibility with DatasetDB pattern).
---@return string[]
function RulesetDB.GetActiveNamesForCurrentCharacter()
    local db = EnsureDB()
    local key = GetCharacterKey()
    local rsName = db.currentByChar[key]
    if rsName and rsName ~= "" then
        return { rsName }
    end
    return {}
end

--- Save (upsert) a ruleset by name.
---@param ruleset RulesetProfile
function RulesetDB.Save(ruleset)
    assert(getmetatable(ruleset) == RulesetProfile, "Save: RulesetProfile expected")
    local db = EnsureDB()
    ruleset.updatedAt = time() or ruleset.updatedAt
    db.rulesets[ruleset.name] = ruleset:ToTable()
end

--- Get an existing ruleset by name (or nil).
---@param name string
---@return RulesetProfile|nil
function RulesetDB.GetByName(name)
    local db = EnsureDB()
    local t = db.rulesets[name]
    return t and RulesetProfile.FromTable(t) or nil
end

--- Create a new ruleset with this name (fails if name exists).
---@param name string
---@param opts table|nil
---@return RulesetProfile
function RulesetDB.CreateNew(name, opts)
    assert(type(name) == "string" and name ~= "", "CreateNew: name required")
    local db = EnsureDB()
    assert(db.rulesets[name] == nil, "CreateNew: ruleset with this name already exists")

    -- For "DefaultRuleset", populate with default rules
    local rules = opts and opts.rules or {}
    if name == "DefaultRuleset" and (not opts or not opts.rules or next(opts.rules) == nil) then
        rules = GetDefaultRulesetRules()
    end
    
    local rs = RulesetProfile:New(name, { rules = rules })
    db.rulesets[name] = rs:ToTable()
    return rs
end

--- Get or create a ruleset by name.
---@param name string
---@param opts table|nil
---@return RulesetProfile
function RulesetDB.GetOrCreateByName(name, opts)
    local existing = RulesetDB.GetByName(name)
    if existing then
        RPE.Debug:Print(string.format("Loaded ruleset: %s", name))
        return existing
    end

    RPE.Debug:Print(string.format("Creating new ruleset: %s", name))
    return RulesetDB.CreateNew(name, opts)
end

--- Rename a ruleset.
---@param oldName string
---@param newName string
function RulesetDB.Rename(oldName, newName)
    assert(type(oldName) == "string" and oldName ~= "", "Rename: oldName required")
    assert(type(newName) == "string" and newName ~= "", "Rename: newName required")

    local db = EnsureDB()
    assert(db.rulesets[oldName], "Rename: source ruleset not found")
    assert(not db.rulesets[newName], "Rename: target name already exists")

    -- Move data
    db.rulesets[newName] = db.rulesets[oldName]
    db.rulesets[newName].name = newName
    db.rulesets[oldName] = nil
end

--- Delete a ruleset by name.
---@param name string
function RulesetDB.Delete(name)
    local db = EnsureDB()
    if not db.rulesets[name] then return end
    db.rulesets[name] = nil
end

--- List all ruleset names.
---@return string[]
function RulesetDB.ListNames()
    local db = EnsureDB()
    local out = {}
    for k, _ in pairs(db.rulesets) do
        table.insert(out, k)
    end
    table.sort(out)
    return out
end

-- Debug + auto-load on login
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(_, event)
    local db = EnsureDB()

    if event == "PLAYER_LOGIN" then
        -- Ensure DefaultRuleset exists from Data/Classic/DefaultRuleset.lua
        if not db.rulesets["DefaultClassic"] then
            local defaultData = RPE.Data.Classic and RPE.Data.Classic.DefaultRuleset
            if defaultData then
                db.rulesets["DefaultClassic"] = defaultData
                RPE.Debug:Print("Loaded DefaultRuleset from data")
            end
        end
        
        local rs = RulesetDB.LoadActiveForCurrentCharacter()
        if rs then
            -- set as active rules for this character
            if RPE.ActiveRules then
                RPE.ActiveRules:SetRuleset(rs)
            end
            RPE.Debug:Print(("Loaded active ruleset: %s"):format(rs.name))
            
            -- Apply dataset requirements from the ruleset
            if RPE.Profile and RPE.Profile.DatasetDB then
                local DatasetDB = RPE.Profile.DatasetDB
                local required = rs:GetRule("dataset_require")
                local exclusive = rs:GetRule("dataset_exclusive")
                
                -- dataset_require should be a comma-separated string or a table
                local requiredList = {}
                if type(required) == "string" and required ~= "" then
                    -- Parse comma-separated list: "DS1,DS2,DS3"
                    for name in required:gmatch("[^,]+") do
                        name = name:match("^%s*(.-)%s*$")  -- trim whitespace
                        if name ~= "" then
                            table.insert(requiredList, name)
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
                        RPE.Debug:Print(string.format("Activated %d required datasets (exclusive mode)", #requiredList))
                    else
                        -- Non-exclusive mode: ensure required datasets are active, keep others
                        local current = DatasetDB.GetActiveNamesForCurrentCharacter()
                        local active = current or {}
                        
                        -- Add required datasets to active list
                        local activeSet = {}
                        for _, name in ipairs(active) do
                            activeSet[name] = true
                        end
                        
                        for _, name in ipairs(requiredList) do
                            if not activeSet[name] then
                                table.insert(active, name)
                                activeSet[name] = true
                            end
                        end
                        
                        DatasetDB.SetActiveNamesForCurrentCharacter(active)
                        RPE.Debug:Print(string.format("Ensured %d required datasets are active", #requiredList))
                    end
                end
            end
        else
            RPE.Debug:Print("No active ruleset found for this character.")
        end

        local ruleset = _G.RPE_UI.Windows.Ruleset.New({ width = 640, height = 420, point = "CENTER" })
        RPE_UI.Common:Hide(ruleset)

        -- Debug print count
        local n = 0
        for _ in pairs(db.rulesets) do n = n + 1 end
    elseif event == "PLAYER_LOGOUT" then
        local rs = RulesetDB.LoadActiveForCurrentCharacter()
        if rs then
            RulesetDB.Save(rs)
        end
    end
end)

return RulesetDB
