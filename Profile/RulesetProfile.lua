-- RPE/Profile/RulesetProfile.lua
-- Data class for ruleset profiles (identified by their *name*).
-- Stores arbitrary rules in a table (key -> value).

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

---@class RulesetProfile
---@field name string
---@field rules table<string, any>  -- includes special rules: dataset_require, dataset_exclusive
---@field createdAt number
---@field updatedAt number
local RulesetProfile = {}
RulesetProfile.__index = RulesetProfile
RPE.Profile.RulesetProfile = RulesetProfile

-- --- Construction -----------------------------------------------------------

--- Create a new in-memory ruleset profile.
---@param name string
---@param opts table|nil  -- { rules = {}, createdAt, updatedAt }
function RulesetProfile:New(name, opts)
    assert(type(name) == "string" and name ~= "", "RulesetProfile: name required")
    opts = opts or {}

    local now = time() or 0
    local o = setmetatable({
        name      = name,
        rules     = opts.rules or {},
        createdAt = opts.createdAt or now,
        updatedAt = opts.updatedAt or now,
    }, self)

    return o
end

-- --- Rules API ---------------------------------------------------------------

--- Get a rule value by key.
---@param key string
---@return any
function RulesetProfile:GetRule(key)
    return self.rules[key]
end

--- Set a rule value by key.
---@param key string
---@param value any
function RulesetProfile:SetRule(key, value)
    self.rules[key] = value
    self.updatedAt = time() or self.updatedAt
end

--- Remove a rule by key.
---@param key string
function RulesetProfile:RemoveRule(key)
    self.rules[key] = nil
    self.updatedAt = time() or self.updatedAt
end

--- Export all rules (shallow copy).
---@return table
function RulesetProfile:GetRules()
    local copy = {}
    for k, v in pairs(self.rules) do
        copy[k] = v
    end
    return copy
end

-- --- Serialization ----------------------------------------------------------

--- Serialize to a plain table for SavedVariables.
---@return table
function RulesetProfile:ToTable()
    return {
        name      = self.name,
        rules     = self.rules,
        createdAt = self.createdAt,
        updatedAt = self.updatedAt,
    }
end

--- Construct from a plain table (SavedVariables).
---@param t table
---@return RulesetProfile
function RulesetProfile.FromTable(t)
    assert(type(t) == "table", "FromTable: table required")
    return RulesetProfile:New(t.name or "", {
        rules     = type(t.rules) == "table" and t.rules or {},
        createdAt = t.createdAt,
        updatedAt = t.updatedAt,
    })
end

return RulesetProfile
