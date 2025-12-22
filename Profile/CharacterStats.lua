-- RPE/Profile/CharacterStats.lua
-- Stat definition and runtime values (base, equipment, auras, etc.)

RPE = RPE or {}
RPE.Stats = RPE.Stats or {}

---@alias StatCategory "RESOURCE"|"PRIMARY"|"SECONDARY"|"MELEE"|"RANGED"|"SPELL"|"DEFENSE"|"RESISTANCE"|"SKILL"

---@class CharacterStat
---@field id string
---@field category StatCategory
---@field base number|table        -- number OR { ruleKey=string|nil, expr=string|nil, default=number }
---@field recovery number|table|nil -- number OR { ruleKey=string|nil, expr=string|nil, default=number }
---@field equipMod number|nil
---@field auraMod number|nil
---@field min number|table
---@field max number|table
---@field visible boolean|0|1
---@field name string
---@field defenceName string|nil   -- display name for defense tooltips (e.g., "Fire Resistance")
---@field icon string|nil
---@field tooltip string|nil
---@field pct 0|1
---@field rule string|nil          -- LEGACY (deprecated). If present, treated as base expr with default=(numeric base or 0).
---@field itemTooltipFormat string|nil
---@field itemTooltipColor any
---@field itemTooltipPriority number
---@field itemLevelWeight number|nil -- per-point weight for item-level calculation
---@field _userCustomizedBase boolean|nil -- marks that user has customized the base value (should not be overwritten by dataset)
---@field sourceDataset string|nil -- marks which dataset this stat came from
---@field setupBonus number|nil -- bonus applied from the setup wizard (stored as delta from definition base)
local CharacterStat = {}
CharacterStat.__index = CharacterStat
RPE.Stats.CharacterStat = CharacterStat

-- =========================
-- Helpers / shared
-- =========================

local function finiteOrNil(x)
    if type(x) ~= "number" or x ~= x then return nil end -- reject NaN
    return x -- allow math.huge and -math.huge too
end

-- Add near the top of CharacterStats.lua (helpers section is fine)
local function _asBucket(x)
    if type(x) == "table" then
        return {
            ADD       = tonumber(x.ADD)       or 0,
            PCT_ADD   = tonumber(x.PCT_ADD)   or 0,
            MULT      = (tonumber(x.MULT) and tonumber(x.MULT) ~= 0) and tonumber(x.MULT) or 1,
            FINAL_ADD = tonumber(x.FINAL_ADD) or 0,
        }
    end
    -- Back-compat: flat numbers behave like ADD
    return { ADD = tonumber(x) or 0, PCT_ADD = 0, MULT = 1, FINAL_ADD = 0 }
end

local function _applyBuckets(base, equip, auraBucket)
    local v = (tonumber(base) or 0) + (tonumber(equip) or 0) + (auraBucket.ADD or 0)
    v = v * (1 + (auraBucket.PCT_ADD or 0) / 100)
    v = v * (auraBucket.MULT or 1)
    v = v + (auraBucket.FINAL_ADD or 0)
    return v
end


-- ========= Rule compiler (sand-boxed) =========
local function buildRuleFunc(expr, depth)
    if type(expr) ~= "string" or expr == "" then return nil end
    depth = (depth or 0) + 1
    if depth > 5 then
        geterrorhandler()("Stat rule recursion too deep")
        return function() return 0 end
    end

    -- Expand helpers:
    --   $stat.ID$  -> __lookup("ID")
    --   $rule.KEY$ -> __rule("KEY")
    local luaExpr = expr
    luaExpr = luaExpr:gsub("%$stat%.([%w_]+)%$", function(statId)
        return string.format('__lookup("%s")', statId)
    end)
    luaExpr = luaExpr:gsub("%$rule%.([%w_]+)%$", function(ruleKey)
        return string.format('__rule("%s")', ruleKey)
    end)

    local chunk, err = loadstring("return " .. luaExpr)
    if not chunk then
        geterrorhandler()("Stat rule parse error: " .. tostring(err) .. " (expr=" .. tostring(luaExpr) .. ")")
        return nil
    end

    -- We return a closure that evaluates in a restricted environment each time.
    return function(profile)
        local env = {
            __lookup = function(id)
                local s = nil
                if profile and profile.GetStat then
                    s = profile:GetStat(id)
                else
                    if profile and profile.stats then
                        for _, st in pairs(profile.stats) do
                            if st and st.id == id then
                                s = st
                                break
                            end
                        end
                    end
                end
                if not s then return 0 end
                return s:GetValue(profile)
            end,
            __rule = function(key)
                local rs = RPE.ActiveRules and RPE.ActiveRules.rules
                if not rs then return 0 end
                local expr2 = rs[key]
                if type(expr2) ~= "string" or expr2 == "" then return 0 end
                local f = buildRuleFunc(expr2, depth)
                return f and f(profile) or 0
            end,
            math = math,
        }
        setfenv(chunk, env)
        local ok, val = pcall(chunk)
        if not ok then return 0 end
        return tonumber(val) or 0
    end
end

-- Normalize RECOVERY into a variant (similar to base; no legacy migration):
--   number -> { kind="literal", value=<num> }
--   { ruleKey, default } -> { kind="rule", key=..., default=... }
--   { expr, default }    -> { kind="expr", expr=..., default=... }
local function normalizeRecoveryVariant(val)
    if type(val) == "number" then
        return { kind = "literal", value = val }
    elseif type(val) == "table" then
        local def = tonumber(val.default) or 0
        if type(val.ruleKey) == "string" and val.ruleKey ~= "" then
            return { kind = "rule", key = val.ruleKey, default = def }
        elseif type(val.expr) == "string" and val.expr ~= "" then
            return { kind = "expr", expr = val.expr, default = def }
        else
            return { kind = "literal", value = def }
        end
    end
    return { kind = "literal", value = tonumber(val) or 0 }
end

-- Resolve recovery using the normalized variant; mirrors _resolveBase but
-- is fully independent so we don't need to edit existing methods.
function CharacterStat:_resolveRecovery(profile)
    -- Lazily normalize on first use or if user swapped the shape at runtime.
    local v = self._recoveryVariant
    if not v or (v._source ~= self.recovery) then
        v = normalizeRecoveryVariant(self.recovery)
        v._source = self.recovery
        self._recoveryVariant = v
        self._recoveryFunc = nil
        self._recoveryFuncKey = nil
    end

    if v.kind == "literal" then
        return tonumber(v.value) or 0
    elseif v.kind == "rule" then
        local rules = RPE.ActiveRules and RPE.ActiveRules.rules
        local expr  = rules and rules[v.key] or nil
        if type(expr) == "number" then
            return expr
        elseif type(expr) ~= "string" or expr == "" then
            return tonumber(v.default) or 0
        end

        local cacheKey = "recovery:rule:" .. tostring(v.key) .. ":" .. tostring(expr)
        if self._recoveryFuncKey ~= cacheKey then
            self._recoveryFunc    = buildRuleFunc(expr)
            self._recoveryFuncKey = cacheKey
        end
        local f = self._recoveryFunc
        if not f then return tonumber(v.default) or 0 end
        local ok, result = pcall(f, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)

    elseif v.kind == "expr" then
        local cacheKey = "recovery:expr:" .. tostring(v.expr)
        if self._recoveryFuncKey ~= cacheKey then
            self._recoveryFunc    = buildRuleFunc(v.expr)
            self._recoveryFuncKey = cacheKey
        end
        local f = self._recoveryFunc
        if not f then return tonumber(v.default) or 0 end
        local ok, result = pcall(f, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)
    end

    return 0
end

-- Normalize BASE into a variant:
--   number -> { kind="literal", value=<num> }
--   { ruleKey, default } -> { kind="rule", key=..., default=... }
--   { expr, default }    -> { kind="expr", expr=..., default=... }
-- Legacy: if legacyRule is present, prefer { kind="expr", expr=legacyRule, default=legacyDefault }
local function normalizeBaseVariant(base, legacyRule, legacyDefault)
    if type(base) == "number" then
        return { kind = "literal", value = base }
    elseif type(base) == "table" then
        local def = tonumber(base.default) or 0
        if type(base.ref) == "string" and base.ref ~= "" then
            -- Stat reference: convert to an expr that gets the referenced stat's value
            return { kind = "ref", ref = base.ref, default = def }
        elseif type(base.ruleKey) == "string" and base.ruleKey ~= "" then
            return { kind = "rule", key = base.ruleKey, default = def }
        elseif type(base.expr) == "string" and base.expr ~= "" then
            return { kind = "expr", expr = base.expr, default = def }
        else
            -- malformed table -> treat as literal of its default (safe)
            return { kind = "literal", value = def }
        end
    end
    -- Legacy migration: promote legacy final-value rule to base expr
    if type(legacyRule) == "string" and legacyRule ~= "" then
        local def = tonumber(legacyDefault) or 0
        return { kind = "expr", expr = legacyRule, default = def, _migrated = true }
    end
    -- Fallback to literal 0
    return { kind = "literal", value = tonumber(base) or 0 }
end

-- Returns numeric base value using the variant & fallbacks.
function CharacterStat:_resolveBase(profile)
    local v = self._baseVariant
    if not v then
        -- Normalize on first use if needed
        self._baseVariant = normalizeBaseVariant(self.base, self.rule, (type(self.base) == "number" and self.base) or 0)
        v = self._baseVariant
    end

    if v.kind == "literal" then
        return tonumber(v.value) or 0
    elseif v.kind == "ref" then
        -- Reference to another stat: get its current value (respect active datasets)
        local s = profile and profile.GetStat and profile:GetStat(v.ref) or nil
        if not s and profile and profile.stats then
            for _, st in pairs(profile.stats) do
                if st and st.id == v.ref then s = st; break end
            end
        end
        return s and s:GetValue(profile) or (tonumber(v.default) or 0)
    elseif v.kind == "rule" then
        -- Look up rule string from active ruleset
        local rules = RPE.ActiveRules and RPE.ActiveRules.rules
        local expr  = rules and rules[v.key] or nil
        if type(expr) == "number" then
            return expr
        elseif type(expr) ~= "string" or expr == "" then
            if not self._missingLogged then
                geterrorhandler()(string.format("Stat '%s' base used default (rule key '%s' missing).", self.id, tostring(v.key)))
                self._missingLogged = true
            end
            return tonumber(v.default) or 0
        end

        local cacheKey = "rule:" .. tostring(v.key) .. ":" .. tostring(expr)
        if self._baseFuncKey ~= cacheKey then
            self._baseFunc = buildRuleFunc(expr)
            self._baseFuncKey = cacheKey
        end

        if not self._baseFunc then
            return tonumber(v.default) or 0
        end

        local ok, result = pcall(self._baseFunc, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)

    elseif v.kind == "expr" then
        local cacheKey = "expr:" .. tostring(v.expr)
        if self._baseFuncKey ~= cacheKey then
            self._baseFunc = buildRuleFunc(v.expr)
            self._baseFuncKey = cacheKey
        end
        if not self._baseFunc then
            return tonumber(v.default) or 0
        end
        local ok, result = pcall(self._baseFunc, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)
    end

    return 0
end

-- Normalize a BOUND (min/max) into a variant:
--   number -> { kind="number", value=<num> }
--   { ref="STAT" } -> { kind="ref", ref="STAT" }
--   { ruleKey, default } -> { kind="rule", key=..., default=... }
--   { expr, default }    -> { kind="expr", expr=..., default=... }
local function normalizeBoundVariant(bound)
    if type(bound) == "number" then
        return { kind = "number", value = bound }
    elseif type(bound) == "table" then
        if bound.ref then
            return { kind = "ref", ref = tostring(bound.ref) }
        end
        local def = tonumber(bound.default) or math.huge
        if type(bound.ruleKey) == "string" and bound.ruleKey ~= "" then
            return { kind = "rule", key = bound.ruleKey, default = def }
        elseif type(bound.expr) == "string" and bound.expr ~= "" then
            return { kind = "expr", expr = bound.expr, default = def }
        else
            return { kind = "number", value = def }
        end
    end
    return nil -- no bound
end

-- Resolve a bound variant to a number (or nil if absent)
local function resolveBoundVariant(self, v, profile, cachePrefix)
    if not v then return nil end
    if v.kind == "number" then
        return tonumber(v.value) or nil
    elseif v.kind == "ref" then
        local s = profile and profile.GetStat and profile:GetStat(v.ref) or nil
        if not s and profile and profile.stats then
            for _, st in pairs(profile.stats) do
                if st and st.id == v.ref then s = st; break end
            end
        end
        return s and s:GetValue(profile) or nil
    elseif v.kind == "rule" then
        local rules = RPE.ActiveRules and RPE.ActiveRules.rules
        local expr  = rules and rules[v.key] or nil
        if type(expr) == "number" then
            return expr
        elseif type(expr) ~= "string" or expr == "" then
            return tonumber(v.default) or 0
        end

        local key = cachePrefix .. ":rule:" .. tostring(v.key) .. ":" .. tostring(expr)
        if self._boundFuncs[key] == nil then
            self._boundFuncs[key] = buildRuleFunc(expr)
        end
        local f = self._boundFuncs[key]
        if not f then return tonumber(v.default) or 0 end
        local ok, result = pcall(f, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)
    elseif v.kind == "expr" then
        local key = cachePrefix .. ":expr:" .. tostring(v.expr)
        if self._boundFuncs[key] == nil then
            self._boundFuncs[key] = buildRuleFunc(v.expr)
        end
        local f = self._boundFuncs[key]
        if not f then return tonumber(v.default) or 0 end
        local ok, result = pcall(f, profile)
        if not ok then return tonumber(v.default) or 0 end
        return finiteOrNil(result) or (tonumber(v.default) or 0)
    end
    return nil
end

-- =========================
-- ctor / data assignment
-- =========================

--- Create a new stat object.
---@param id string
---@param category StatCategory
---@param base number|table|nil  -- number OR { ruleKey=string, default=number } OR { expr=string, default=number }
---@param opts table|nil         -- { min, max, visible, name, icon, tooltip, pct, rule (LEGACY), recovery, itemTooltipFormat, itemTooltipColor, itemTooltipPriority, itemLevelWeight }
---@return CharacterStat
function CharacterStat:New(id, category, base, opts)
    assert(type(id) == "string" and id ~= "", "Stat id required")
    opts = opts or {}

    local o = setmetatable({
        id        = id,
        name      = opts.name or id,
        category  = category or "PRIMARY",

        -- Base can be number or table (ruleKey/expr + default)
        base      = base ~= nil and base or 0,
        recovery  = (opts.recovery ~= nil) and opts.recovery or 0,  -- only applies to resources.

        -- Legacy 'rule' (previously used to compute final) now treated as base expr with default=(numeric base or 0)
        rule      = (type(opts.rule) == "string" and opts.rule ~= "") and opts.rule or nil,

        -- Bounds accept number, {ref="ID"}, {ruleKey,default}, {expr,default}
        min       = (opts.min ~= nil) and opts.min or -math.huge,
        max       = (opts.max ~= nil) and opts.max or  math.huge,

        visible   = (opts.visible == 0 or opts.visible == false) and 0 or 1,
        icon      = opts.icon,
        defenceName = opts.defenceName,
        tooltip   = opts.tooltip,
        pct       = (opts.pct == 1 or opts.pct == true) and 1 or 0,
        itemTooltipFormat   = opts.itemTooltipFormat,
        itemTooltipColor    = opts.itemTooltipColor,    -- {r,g,b,a} or string palette key
        itemTooltipPriority = tonumber(opts.itemTooltipPriority) or 0,

        -- [ilvl]
        itemLevelWeight     = (opts.itemLevelWeight ~= nil) and tonumber(opts.itemLevelWeight) or nil,

        -- caches for base rule/expr
        _baseVariant   = nil,
        _baseFunc      = nil,
        _baseFuncKey   = nil,
        _missingLogged = false,

        -- bounds caches/variants
        _minVariant    = nil,
        _maxVariant    = nil,
        _boundFuncs    = {},   -- compiled funcs for min/max rule/expr (keyed)
    }, self)

    -- Normalize the base immediately (uses legacy rule if present)
    o._baseVariant = normalizeBaseVariant(o.base, o.rule, (type(o.base) == "number" and o.base) or 0)

    -- Normalize bounds immediately
    o._minVariant = normalizeBoundVariant(o.min)
    o._maxVariant = normalizeBoundVariant(o.max)

    return o
end

--- Bulk-apply fields from a table. Missing fields are left unchanged.
--- Accepts:
---   id, name, category, base(number|table), equipMod, auraMod, min, max, visible, icon, tooltip, pct, rule(legacy), recovery, itemLevelWeight
--- `min`/`max` may be numbers, { ref="STAT_ID" }, { ruleKey, default }, or { expr, default }.
---@param t table
---@return CharacterStat
function CharacterStat:SetData(t)
    if type(t) ~= "table" then return self end

    if t.id       ~= nil then self.id       = tostring(t.id) end
    if t.name     ~= nil then self.name     = t.name end
    if t.category ~= nil then self.category = t.category end
    if t.recovery ~= nil then
        self.recovery = t.recovery  -- keep number OR table as-is
        self._recoveryVariant  = nil
        self._recoveryFunc     = nil
        self._recoveryFuncKey  = nil
    end

    -- Base assignment / normalization
    if t.base ~= nil then
        self.base = t.base
        -- Re-normalize base and clear compiled cache
        self._baseVariant   = normalizeBaseVariant(self.base, self.rule, (type(self.base) == "number" and self.base) or 0)
        self._baseFunc      = nil
        self._baseFuncKey   = nil
        self._missingLogged = false
    end

    -- Bounds (min/max) — accept number/ref/ruleKey/expr and normalize
    if t.min ~= nil then
        self.min = t.min
        self._minVariant = normalizeBoundVariant(self.min)
        -- Note: _boundFuncs kept; keys are namespaced, no need to wipe
    end

    if t.max ~= nil then
        self.max = t.max
        self._maxVariant = normalizeBoundVariant(self.max)
    end

    -- Visibility & presentation
    if t.visible ~= nil then
        self.visible = (t.visible == 0 or t.visible == false) and 0 or 1
    end

    if t.icon ~= nil then
        self.icon = (type(t.icon) == "string" and t.icon ~= "") and t.icon or nil
    end

    if t.defenceName ~= nil then
        self.defenceName = (type(t.defenceName) == "string" and t.defenceName ~= "") and t.defenceName or nil
    end

    if t.tooltip ~= nil then
        self.tooltip = (type(t.tooltip) == "string" and t.tooltip ~= "") and t.tooltip or nil
    end

    if t.pct ~= nil then
        self.pct = (t.pct == 1 or t.pct == true) and 1 or 0
    end

    -- LEGACY: if a 'rule' field is provided, treat as base expr with default=(numeric base or 0)
    if t.rule ~= nil then
        self.rule = (type(t.rule) == "string" and t.rule ~= "") and t.rule or nil
        if self.rule then
            local currentDefault = 0
            if type(self.base) == "number" then currentDefault = self.base end
            self._baseVariant   = normalizeBaseVariant(self.base, self.rule, currentDefault)
            self._baseFunc      = nil
            self._baseFuncKey   = nil
            self._missingLogged = false
        end
    end

    if t.itemTooltipFormat ~= nil then
        self.itemTooltipFormat = (type(t.itemTooltipFormat) == "string" and t.itemTooltipFormat ~= "")
            and t.itemTooltipFormat
            or nil
    end

    if t.itemTooltipColor ~= nil then
        self.itemTooltipColor = t.itemTooltipColor
    end
    if t.itemTooltipPriority ~= nil then
        self.itemTooltipPriority = tonumber(t.itemTooltipPriority) or 0
    end

    -- [ilvl] per-stat weight for item-level calculation
    if t.itemLevelWeight ~= nil then
        self.itemLevelWeight = tonumber(t.itemLevelWeight)
    end

    return self
end

-- =========================
-- Public API
-- =========================

--- Current effective value (clamped).
---@param profile CharacterProfile|nil
---@return number
function CharacterStat:GetValue(profile)
    local baseValue = self:_resolveBase(profile)
    
    -- Add setupBonus (from setup wizard) to the base value
    baseValue = baseValue + (self.setupBonus or 0)

    local pid = profile and profile.name
    local equip, auraBucket = 0, { ADD=0, PCT_ADD=0, MULT=1, FINAL_ADD=0 }
    if pid then
        local equipMods = RPE.Core.StatModifiers.equip[pid]
        local auraMods  = RPE.Core.StatModifiers.aura[pid]
        if equipMods then equip = equipMods[self.id] or 0 end
        if auraMods  then auraBucket = _asBucket(auraMods[self.id]) end
    end

    local v = _applyBuckets(baseValue, equip, auraBucket)

    local min = resolveBoundVariant(self, self._minVariant, profile, self.id .. ":min") or -math.huge
    local max = resolveBoundVariant(self, self._maxVariant, profile, self.id .. ":max") or  math.huge
    if v < min then v = min end
    if v > max then v = max end
    return v
end


--- Maximum possible value for this stat (after base + mods, not the current pool).
---@param profile CharacterProfile|nil
---@return number
function CharacterStat:GetMaxValue(profile)
    -- If max is a ref, defer to that stat unchanged
    if type(self._maxVariant) == "table" and self._maxVariant.kind == "ref" then
        local refId = self._maxVariant.ref
        local s = profile and profile.GetStat and profile:GetStat(refId) or nil
        if not s and profile and profile.stats then
            for _, st in pairs(profile.stats) do
                if st and st.id == refId then s = st; break end
            end
        end
        return s and s:GetValue(profile) or 0
    end

    local baseValue = self:_resolveBase(profile)
    
    -- Add setupBonus (from setup wizard) to the base value
    baseValue = baseValue + (self.setupBonus or 0)

    local pid = profile and profile.name
    local equip, auraBucket = 0, { ADD=0, PCT_ADD=0, MULT=1, FINAL_ADD=0 }
    if pid then
        local equipMods = RPE.Core.StatModifiers.equip[pid]
        local auraMods  = RPE.Core.StatModifiers.aura[pid]
        if equipMods then equip = equipMods[self.id] or 0 end
        if auraMods  then auraBucket = _asBucket(auraMods[self.id]) end
    end

    local v = _applyBuckets(baseValue, equip, auraBucket)

    local max = resolveBoundVariant(self, self._maxVariant, profile, self.id .. ":max") or  math.huge
    if v > max then v = max end
    return v
end


function RPE.Stats:GetValue(id)
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile then return 0 end
    return profile:GetStatValue(id)
end

function RPE.Stats:Get(id)
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile then return nil end
    if profile and profile.GetStat then return profile:GetStat(id) end
    if profile and profile.stats then
        for _, st in pairs(profile.stats) do if st and st.id == id then return st end end
    end
    return nil
end

--- Public getter for recovery (mirrors GetValue pattern, but only returns the configured recovery rate/value).
---@param profile CharacterProfile|nil
---@return number
function CharacterStat:GetRecovery(profile)
    return self:_resolveRecovery(profile)
end

--- Set recovery as a literal number (does not alter existing code paths).
---@param v number
function CharacterStat:SetRecovery(v)
    self.recovery = tonumber(v) or 0
    self._recoveryVariant  = nil
    self._recoveryFunc     = nil
    self._recoveryFuncKey  = nil
end

--- Set recovery via rule key with default.
---@param ruleKey string
---@param default number
function CharacterStat:SetRecoveryRule(ruleKey, default)
    self.recovery = { ruleKey = tostring(ruleKey), default = tonumber(default) or 0 }
    self._recoveryVariant  = nil
    self._recoveryFunc     = nil
    self._recoveryFuncKey  = nil
end

--- Set recovery via expression with default.
---@param expr string
---@param default number
function CharacterStat:SetRecoveryExpr(expr, default)
    self.recovery = { expr = tostring(expr), default = tonumber(default) or 0 }
    self._recoveryVariant  = nil
    self._recoveryFunc     = nil
    self._recoveryFuncKey  = nil
end

--- Set base as a literal number (overwrites any rule/expr).
---@param v number
function CharacterStat:SetBase(v)
    assert(type(v) == "number", "SetBase: number expected")
    self.base = v
    self._baseVariant = { kind = "literal", value = v }
    self._baseFunc, self._baseFuncKey = nil, nil
    self._missingLogged = false
end

--- Set base from a rule key with default.
---@param ruleKey string
---@param default number
function CharacterStat:SetBaseRule(ruleKey, default)
    self.base = { ruleKey = ruleKey, default = default or 0 }
    self._baseVariant = normalizeBaseVariant(self.base, nil, default or 0)
    self._baseFunc, self._baseFuncKey = nil, nil
    self._missingLogged = false
end

--- Set base from an expression with default.
---@param expr string
---@param default number
function CharacterStat:SetBaseExpr(expr, default)
    self.base = { expr = expr, default = default or 0 }
    self._baseVariant = normalizeBaseVariant(self.base, nil, default or 0)
    self._baseFunc, self._baseFuncKey = nil, nil
    self._missingLogged = false
end

--- Apply equipment modifier (flat).
---@param v number
function CharacterStat:SetEquipMod(v)
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    local pid = profile.name
    _G.RPE.Core.StatModifiers.equip[pid] = _G.RPE.Core.StatModifiers.equip[pid] or {}
    _G.RPE.Core.StatModifiers.equip[pid][self.id] = tonumber(v) or 0

    if _G.RPE.Core.Windows.StatisticSheet then
        _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(self.id)
    end
end

function CharacterStat:SetAuraMod(profile, v)
    if not profile then return end
    local pid = profile.name                      -- <<< was profile.id
    RPE.Core.StatModifiers.aura[pid] = RPE.Core.StatModifiers.aura[pid] or {}
    RPE.Core.StatModifiers.aura[pid][self.id] = tonumber(v) or 0

    if _G.RPE.Core.Windows.StatisticSheet then
        _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(self.id)
    end
end

--- Increment equipment modifier (adds delta to current).
---@param delta number
function CharacterStat:AddEquipMod(delta)
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    local pid = profile.name
    local mods = _G.RPE.Core.StatModifiers.equip
    mods[pid] = mods[pid] or {}

    local cur = mods[pid][self.id] or 0
    local newVal = cur + (tonumber(delta) or 0)
    mods[pid][self.id] = newVal

    if _G.RPE.Core.Windows.StatisticSheet then
        _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(self.id)
    end
end

--- Increment aura modifier (adds delta to current).
---@param profile CharacterProfile
---@param delta number
function CharacterStat:AddAuraMod(profile, delta)
    if not profile then return end
    local pid = profile.name                      -- <<< was profile.id
    local mods = RPE.Core.StatModifiers.aura
    mods[pid] = mods[pid] or {}

    local cur = mods[pid][self.id] or 0
    local newVal = cur + (tonumber(delta) or 0)
    mods[pid][self.id] = newVal

    if _G.RPE.Core.Windows.StatisticSheet then
        _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(self.id)
    end
end

function CharacterStat:SetVisible(flag)
    self.visible = (flag and 1 or 0)
end

function CharacterStat:IsVisible()
    return self.visible == 1
end

function CharacterStat:SetPercentage(flag)
    self.pct = (flag and 1 or 0)
end

function CharacterStat:IsPercentage()
    return self.pct == 1
end

--- Render this stat for an item tooltip, if format is defined.
---@param value number
---@return string|nil
function CharacterStat:FormatForItemTooltip(value)
    if not self.itemTooltipFormat or self.itemTooltipFormat == "" then
        return nil
    end

    local sign = (tonumber(value) >= 0) and "+" or "" -- prefix plus for positives
    local valStr = sign .. tostring(value)

    return self.itemTooltipFormat:gsub("%$value%$", valStr)
end

--- Resolve tooltip color for this stat entry.
---@return number, number, number, number
function CharacterStat:GetItemTooltipColor()
    local c = self.itemTooltipColor
    if not c then
        return 0.9, 0.9, 0.9, 1 -- default gray
    end
    if type(c) == "string" then
        return RPE_UI.Colors.Get(c) -- palette lookup
    elseif type(c) == "table" then
        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
    end
    return 0.9, 0.9, 0.9, 1
end

-- [ilvl] Convenience: set per-stat item-level weight.
---@param w number|nil
function CharacterStat:SetItemLevelWeight(w)
    if w == nil then
        self.itemLevelWeight = nil
    else
        self.itemLevelWeight = tonumber(w) or 0
    end
end

-- =========================
-- Serialization
-- =========================

--- Serialize to SavedVariables (keeps new base variant; omits legacy final-value 'rule').
function CharacterStat:ToTable()
    local baseOut = self.base
    if type(self._baseVariant) == "table" then
        local v = self._baseVariant
        if v.kind == "literal" then baseOut = tonumber(v.value) or 0
        elseif v.kind == "rule"  then baseOut = { ruleKey = v.key,  default = v.default or 0 }
        elseif v.kind == "expr"  then baseOut = { expr    = v.expr, default = v.default or 0 }
        end
    end

    -- Persist min/max in their normalized shapes
    local function emitBound(v)
        if not v then return nil end
        if v.kind == "number" then return v.value
        elseif v.kind == "ref" then return { ref = v.ref }
        elseif v.kind == "rule" then return { ruleKey = v.key, default = v.default or 0 }
        elseif v.kind == "expr" then return { expr = v.expr, default = v.default or 0 }
        end
        return nil
    end

    return {
        id       = self.id,
        name     = self.name,
        category = self.category,
        base     = baseOut,
        recovery = self.recovery,
        min      = emitBound(self._minVariant),
        max      = emitBound(self._maxVariant),
        visible  = (self.visible == nil) and 1 or self.visible,
        pct      = self.pct or 0,
        icon     = self.icon,
        defenceName = self.defenceName,
        tooltip  = self.tooltip,
        itemTooltipFormat   = self.itemTooltipFormat,
        itemTooltipColor    = self.itemTooltipColor,
        itemTooltipPriority = self.itemTooltipPriority,
        itemLevelWeight     = self.itemLevelWeight, -- [ilvl]
        sourceDataset       = self.sourceDataset, -- Track which dataset this stat came from
        setupBonus          = self.setupBonus, -- Bonus from setup wizard
    }
end

function CharacterStat.FromTable(t)
    local stat = CharacterStat:New(
        t.id,
        t.category,
        t.base,
        {
            name    = t.name,
            min     = t.min,  -- can be number/ref/ruleKey/expr
            max     = t.max,  -- can be number/ref/ruleKey/expr
            visible = (t.visible == 0) and 0 or 1,
            pct     = (t.pct == 1 or t.pct == true) and 1 or 0,
            icon    = t.icon,
            defenceName = t.defenceName,
            tooltip = t.tooltip,
            rule    = t.rule, -- legacy (still migrated into base if present)
            recovery = t.recovery or 0,
            itemTooltipFormat   = t.itemTooltipFormat,
            itemTooltipColor    = t.itemTooltipColor,
            itemTooltipPriority = t.itemTooltipPriority,
            itemLevelWeight     = t.itemLevelWeight, -- [ilvl]
        }
    )
    -- Ensure normalized bound variants from loaded data
    stat._minVariant = normalizeBoundVariant(stat.min)
    stat._maxVariant = normalizeBoundVariant(stat.max)
    -- Restore dynamic fields
    if t.sourceDataset then stat.sourceDataset = t.sourceDataset end
    if t.setupBonus then stat.setupBonus = t.setupBonus end
    return stat
end

return CharacterStat
