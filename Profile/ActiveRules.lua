-- RPE/ActiveRules.lua
-- Turn a RulesetProfile into a deserialized snapshot of rules.
-- Lives in RPE namespace (not RPE_UI).

RPE = RPE or {}

---@class ActiveRules
---@field rules table<string, any>
local ActiveRules = {}
ActiveRules.__index = ActiveRules
RPE.ActiveRules = ActiveRules

-- Utility: split comma-separated values, trimming whitespace
local function splitList(str)
    local out = {}
    for token in string.gmatch(str, "([^,]+)") do
        local t = token:gsub("^%s*(.-)%s*$", "%1") -- trim
        if t ~= "" then
            table.insert(out, t)
        end
    end
    return out
end

-- Try to coerce a string into boolean, number, or leave as string
local function coerceScalar(str)
    local lower = str:lower()
    if lower == "true" then
        return true
    elseif lower == "false" then
        return false
    end
    local num = tonumber(str)
    if num ~= nil then
        return num
    end
    return str
end

--- Parse a rule value:
--- - If it looks like "{A,B,C}", return { ... } with coercion
--- - Else attempt to coerce to boolean/number/string
local function parseRuleValue(v)
    if type(v) ~= "string" then return v end
    local trimmed = v:gsub("^%s*(.-)%s*$", "%1")
    if trimmed:match("^%b{}$") then
        local inner = trimmed:sub(2, -2) -- strip {}
        local parts = splitList(inner)
        for i, p in ipairs(parts) do
            parts[i] = coerceScalar(p)
        end
        return parts
    else
        return coerceScalar(trimmed)
    end
end

--- Create a snapshot from a ruleset profile or table
---@param ruleset RulesetProfile|table
---@return ActiveRules
function ActiveRules:FromRuleset(ruleset)
    local rules = {}
    if ruleset and ruleset.rules then
        for k, v in pairs(ruleset.rules) do
            rules[k] = parseRuleValue(v)
        end
    end
    return setmetatable({ rules = rules }, self)
end

--- Replace the snapshot with a new ruleset
---@param ruleset RulesetProfile|table
function ActiveRules:SetRuleset(ruleset)
    local snap = ActiveRules:FromRuleset(ruleset)
    self.name = ruleset.name
    self.rules = snap.rules
end

-- Supports:
--   allow_<category>: { "STAT_A", "STAT_B" }  -- only these are shown for that category
--   enable_stats: { "STAT_X", ... }           -- always enable specific stats
--   disable_stats: { "STAT_Y", ... }          -- always disable specific stats
function ActiveRules:IsStatEnabled(statId, category)
    local rules = self.rules or {}
    if category then
        local key = "allow_" .. string.lower(category)
        local allow = rules[key]
        if type(allow) == "table" then
            for _, v in ipairs(allow) do
                if v == statId then 
                    return true 
                end
            end
            return false -- category has an allow-list and statId not in it
        end
    end

    -- Default: enabled
    return true
end

--- Get a rule value by key. Falls back to `default` if absent.
--- Get a rule value by key.  
--- - Returns the raw value (table, number, boolean, string) if present.  
--- - Falls back to `default` if the key is missing.  
---@param key string
---@param default any
---
--- Hit system rules:
---   hit_system: "complex" | "simple" | "ac"  (default: "complex")
---     - "complex": Uses hitModifier vs hitThreshold (user-specified thresholds)
---     - "simple": Uses hitModifier vs $stat.DEFENCE$
---     - "ac": No roll; checks against $stat.AC$ (defender only; no roll damage)
---   
---   hit_roll: "1d20" (default)  -- Roll formula for complex/simple
---   hit_base_threshold: 10 (default)  -- Base DC for complex/simple
---   hit_aoe_roll_mode: "per_target" | "single_roll" (default: "per_target")
---   always_hit: 0 | 1 (default: 0)
---   hit_default_requires: { "DAMAGE", "HEAL" } (default: actions requiring hits)
function ActiveRules:Get(key, default)
    if not key then return default end
    local rules = self.rules or {}

    -- case-sensitive first, then fallback to lowercase
    local v = rules[key]
    if v == nil then v = rules[string.lower(key)] end
    if v == nil then return default end

    -- If it's a table, return a shallow copy (so callers don't mutate internals)
    if type(v) == "table" then
        local copy = {}
        for i, val in ipairs(v) do
            copy[i] = val
        end
        return copy
    end

    return v
end

--- Check if a dataset is required (locked) by rules
---@param datasetName string
---@return boolean
function ActiveRules:IsDatasetRequired(datasetName)
    local required = self:Get("dataset_require")
    if not required then return false end
    
    -- required could be a table or a parsed list
    if type(required) == "table" then
        for _, name in ipairs(required) do
            if name == datasetName then
                return true
            end
        end
    end
    return false
end

--- Get list of all required datasets
---@return table
function ActiveRules:GetRequiredDatasets()
    local required = self:Get("dataset_require")
    if type(required) == "table" then
        return required
    end
    return {}
end

--- Check if dataset mode is exclusive (only required datasets allowed)
---@return boolean
function ActiveRules:IsDatasetExclusive()
    local exclusive = self:Get("dataset_exclusive")
    return tonumber(exclusive) == 1
end

return ActiveRules
