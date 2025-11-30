-- RPE/Core/Spell.lua
-- Base Spell definition (core, non-UI, data-only)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@alias CastType "INSTANT"|"CAST_TURNS"|"CHANNEL"
---@alias GroupLogic "ALL"|"ANY"|"NONE"
---@alias GroupPhase "validate"|"precast"|"onStart"|"onTick"|"onResolve"|"onInterrupt"

---@class SpellCost
---@field resource string
---@field amount number|string
---@field when "onStart"|"onResolve"|"perTick"|nil
---@field refundOnInterrupt boolean|nil

---@class SpellCooldown
---@field turns number|nil
---@field charges number|nil
---@field rechargeTurns number|nil
---@field sharedGroup string|nil
---@field starts "onStart"|"onResolve"|nil

---@class SpellCastInfo
---@field type CastType
---@field turns number|nil
---@field tickIntervalTurns number|nil
---@field concentration boolean|nil
---@field moveAllowed boolean|nil

---@class SpellTargeterInfo
---@field default string|nil

---@class SpellRequirementRef
---@field key string
---@field args table|nil

---@class SpellActionTargets
---@field ref string|nil
---@field targeter string|nil
---@field args table|nil

---@class SpellActionRef
---@field key string
---@field args table|nil
---@field targets SpellActionTargets|nil

---@class SpellGroup
---@field phase GroupPhase
---@field logic GroupLogic|nil
---@field requirements string[]|nil
---@field actions SpellActionRef[]|nil

---@class Spell
---@field id string
---@field name string
---@field description string|nil
---@field icon string|number|nil
---@field costs SpellCost[]|nil
---@field cast SpellCastInfo|nil
---@field cooldown SpellCooldown|nil
---@field targeter SpellTargeterInfo|nil
---@field requirements string[]|nil
---@field groups SpellGroup[]|nil
---@field tags table|nil
---@field data table|nil
---@field npcOnly boolean|nil
---@field rank number
---@field maxRanks number|nil    
---@field unlockLevel number|nil    
---@field rankInterval number|nil   
local Spell = {}
Spell.__index = Spell
RPE.Core.Spell = Spell

-- ===== Utils =====
local function _activeProfile()
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        local ok, p = pcall(RPE.Profile.DB.GetOrCreateActive)
        if ok and p then return p end
    end
    return nil
end

local function deepcopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = (type(v) == "table") and deepcopy(v) or v
    end
    return out
end

local function norm_cast(c)
    if type(c) ~= "table" then return { type = "INSTANT" } end
    local t = (c.type == "CAST_TURNS" or c.type == "CHANNEL") and c.type or "INSTANT"
    return {
        type = t,
        turns = tonumber(c.turns or 0),
        tickIntervalTurns = tonumber(c.tickIntervalTurns or 1),
        concentration = not not c.concentration,
        moveAllowed = not not c.moveAllowed,
    }
end

local function norm_cooldown(cd)
    if type(cd) ~= "table" then return nil end
    return {
        turns = cd.turns and tonumber(cd.turns) or nil,
        charges = cd.charges and tonumber(cd.charges) or nil,
        rechargeTurns = cd.rechargeTurns and tonumber(cd.rechargeTurns) or nil,
        sharedGroup = cd.sharedGroup,
        starts = (cd.starts == "onStart" or cd.starts == "onResolve") and cd.starts or nil,
    }
end

local function norm_costs(list)
    if type(list) ~= "table" then return nil end
    local out = {}
    for _, c in ipairs(list) do
        if type(c) == "table" and type(c.resource) == "string" then
            table.insert(out, {
                resource = c.resource,
                amount   = c.amount,
                perRank  = c.perRank,
                when     = (c.when == "onStart" or c.when == "onResolve" or c.when == "perTick") and c.when or nil,
                refundOnInterrupt = not not c.refundOnInterrupt,
            })
        end
    end
    return next(out) and out or nil
end


---Get the maximum target count across all actions (defaults to 1).
---@return integer
function Spell:GetMaxTargets()
    local maxT = 1
    -- allow legacy: targeter.maxTargets
    if self.targeter and tonumber(self.targeter.maxTargets) then
        maxT = math.max(maxT, tonumber(self.targeter.maxTargets))
    end
    for _, g in ipairs(self.groups or {}) do
        for _, act in ipairs(g.actions or {}) do
            local mt = act.targets and tonumber(act.targets.maxTargets) or nil
            if mt and mt > maxT then maxT = mt end
        end
    end
    return maxT
end

---Collect combined target flags across spell.targeter and all actions (deduped).
---@return string|nil
function Spell:GetTargetFlags()
    local set = {}
    local function addFlags(v)
        if type(v) == "string" then
            for tok in v:gmatch("%S+") do set[tok] = true end
        elseif type(v) == "table" then
            for k, b in pairs(v) do if b then set[k] = true end end
        end
    end

    -- legacy: flags on spell.targeter
    if self.targeter and self.targeter.flags then addFlags(self.targeter.flags) end

    -- per-action flags
    for _, g in ipairs(self.groups or {}) do
        for _, act in ipairs(g.actions or {}) do
            if act.targets and act.targets.flags then addFlags(act.targets.flags) end
        end
    end

    local parts = {}
    for k in pairs(set) do table.insert(parts, k) end
    table.sort(parts)
    return #parts > 0 and table.concat(parts, " ") or nil
end

---Flatten all actions with their targeting info (maxTargets + flags).
---@return table[]  -- { key=string, maxTargets=int, flags=string|nil }
function Spell:GetActionTargetSpecs()
    local out = {}
    for _, g in ipairs(self.groups or {}) do
        for _, act in ipairs(g.actions or {}) do
            local t = act.targets or {}
            table.insert(out, {
                key        = act.key,
                maxTargets = tonumber(t.maxTargets) or 1,
                flags      = t.flags,
            })
        end
    end
    return out
end


-- ===== Ctor =====
function Spell:New(id, name, opts)
    assert(type(id) == "string" and id ~= "", "Spell id required")
    assert(type(name) == "string" and name ~= "", "Spell name required")
    opts = opts or {}

    local o = setmetatable({
        id          = id,
        name        = name,
        description = opts.description,
        icon        = opts.icon,
        costs       = norm_costs(opts.costs),
        cast        = norm_cast(opts.cast),
        cooldown    = norm_cooldown(opts.cooldown),
        targeter    = type(opts.targeter) == "table" and deepcopy(opts.targeter) or nil,
        requirements= type(opts.requirements) == "table" and deepcopy(opts.requirements) or nil,
        groups      = type(opts.groups) == "table" and deepcopy(opts.groups) or nil,
        tags        = type(opts.tags) == "table" and deepcopy(opts.tags) or nil,
        data        = type(opts.data) == "table" and deepcopy(opts.data) or {},
        npcOnly     = not not opts.npcOnly,
        rank        = tonumber(opts.rank) or 1,
        maxRanks     = tonumber(opts.maxRanks) or 1,
        unlockLevel  = tonumber(opts.unlockLevel) or 1,
        rankInterval = tonumber(opts.rankInterval) or 10,
    }, self)

    o._descTemplate = o.description or ""

    return o
end

-- ===== Basic info =====
function Spell:ToString()
    local ct = self.cast and self.cast.type or "INSTANT"
    return ("Spell[%s] %s <%s>"):format(self.id, self.name, ct)
end

function Spell:Validate()
    if type(self.id) ~= "string" or self.id == "" then return false, "invalid id" end
    if type(self.name) ~= "string" or self.name == "" then return false, "invalid name" end

    if self.costs then
        for _, c in ipairs(self.costs) do
            if type(c.resource) ~= "string" then return false, "cost missing resource" end
            if c.amount == nil then return false, "cost missing amount" end
        end
    end

    if self.cast then
        local t = self.cast.type
        if t ~= "INSTANT" and t ~= "CAST_TURNS" and t ~= "CHANNEL" then
            return false, "invalid cast.type"
        end
        if (t == "CAST_TURNS" or t == "CHANNEL")
           and (type(self.cast.turns) ~= "number" or self.cast.turns < 1) then
            return false, "invalid cast.turns"
        end
    end

    if self.groups then
        for _, g in ipairs(self.groups) do
            if not g.phase then return false, "group missing phase" end
            if g.logic and (g.logic ~= "ALL" and g.logic ~= "ANY" and g.logic ~= "NONE") then
                return false, "invalid group.logic"
            end
        end
    end

    return true
end


--- Evaluate and roll an action's amount expression.
---@param actionIdx integer  -- 1-based index across all groups
---@param profile table|nil  -- optional profile for stat lookup
---@return number
function Spell:EvaluateAmount(actionIdx, profile)
    self.rankOverride = nil
    local flat = self:_flattenActions()
    local entry = flat[actionIdx]
    if not entry or not entry.act or not entry.act.args then return 0 end

    local Formula = assert(RPE.Core.Formula, "Formula required")

    -- Base amount
    local expr = entry.act.args.amount
    local base = expr and Formula:Roll(expr, profile) or 0

    -- Per-rank formula (rolled once for each rank step)
    local perExpr = entry.act.args.perRank
    local perVal = 0
    local rank = tonumber(self.rankOverride or self.rank or 1) or 1
    if perExpr and perExpr ~= "" and rank > 1 then
        local add = Formula:Roll(perExpr, profile) or 0
        perVal = add * (rank - 1)
    end

    return base + perVal
end

local function _evaluateCost(self, cost, profile)
    local Formula = assert(RPE.Core.Formula, "Formula required")
    local base = cost.amount and Formula:Roll(cost.amount, profile) or 0
    local perRankVal = 0
    local rank = tonumber(self.rankOverride or self.rank or 1) or 1    
    if cost.perRank and cost.perRank ~= "" and rank > 1 then
        perRankVal = (Formula:Roll(cost.perRank, profile) or 0) * (rank - 1)
    end
    return base + perRankVal
end


-- ===== Description system ===================================================
local Formula = assert(RPE.Core.Formula, "Formula required")

local function _targetPhraseFromSpec(self, action)
    local spec = (action and action.targets) or {}
    if spec.ref == "precast" then return "the selected target" end
    if spec.targeter == "CASTER" then return "yourself" end
    if spec.targeter == "ALLY_SINGLE_OR_SELF" then return "an ally (or yourself)" end
    if spec.targeter == "PRECAST" then return "the selected target" end
    local def = self.targeter and self.targeter.default
    if def == "CASTER" then return "yourself" end
    if def == "ALLY_SINGLE_OR_SELF" then return "an ally (or yourself)" end
    if def == "PRECAST" then return "the selected target" end
    return "the target"
end

function Spell:_flattenActions()
    local flat = {}
    for gi, group in ipairs(self.groups or {}) do
        for ai, act in ipairs(group.actions or {}) do
            table.insert(flat, { act=act, group=group, gi=gi, ai=ai, idx=#flat+1 })
        end
    end
    return flat
end

local function _parseAmount(act, profile)
    return Formula:Parse(act.args and act.args.amount, profile)
end

local function _parseAmountWithRank(self, act, profile)
    local Formula = assert(RPE.Core.Formula, "Formula required")
    local parsed = Formula:Parse(act.args and act.args.amount, profile)
    if not parsed then return nil end

    local rank = tonumber(self.rankOverride or self.rank or 1) or 1
    if rank > 1 then
        local perExpr = act.args and act.args.perRank
        if perExpr and perExpr ~= "" then
            local perParsed = Formula:Parse(perExpr, profile)
            if perParsed then
                local extraMin = (perParsed.min or perParsed.value or 0) * (rank - 1)
                local extraMax = (perParsed.max or perParsed.value or 0) * (rank - 1)
                local extraVal = (perParsed.value or 0) * (rank - 1)

                if parsed.min then parsed.min = parsed.min + extraMin end
                if parsed.max then parsed.max = parsed.max + extraMax end
                if parsed.value then parsed.value = parsed.value + extraVal end
            end
        end
    end

    return parsed
end


local function _formatAmount(parsed, mode)
    if not parsed then return "0" end
    if mode == "min" then return tostring(parsed.min or parsed.value or 0)
    elseif mode == "max" then return tostring(parsed.max or parsed.value or 0)
    elseif mode == "avg" then
        local a, b = parsed.min or parsed.value or 0, parsed.max or parsed.value or 0
        return tostring(math.floor(((a+b)/2)+0.5))
    end
    return Formula:Format(parsed)
end

function Spell:_resolveActionProperty(entry, propPath, vars)
    local act   = entry.act
    local group = entry.group
    local args  = act.args or {}

    if propPath == "amount" or propPath:match("^amount%.") then
        local parsed = _parseAmountWithRank(self, act, vars and vars.profile)
        if     propPath == "amount.min" then return _formatAmount(parsed, "min")
        elseif propPath == "amount.max" then return _formatAmount(parsed, "max")
        elseif propPath == "amount.avg" then return _formatAmount(parsed, "avg")
        elseif propPath == "amount.raw" then return tostring(args.amount or "")
        else   return _formatAmount(parsed)
        end
    elseif propPath == "school" then
        return tostring(args.school or "Physical")
    elseif propPath == "target" then
        return _targetPhraseFromSpec(self, act)
    elseif propPath == "auraId" then
        return tostring(args.auraId or "")
    elseif propPath == "duration" or propPath == "durationTurns" then
        return tostring(args.durationTurns or args.duration or "")
    elseif propPath == "stacks" then
        return tostring(args.stacks or 1)
    elseif propPath == "key" then
        return tostring(act.key)
    elseif propPath == "phase" then
        return tostring(group.phase or "onResolve")
    else
        local v = args
        for seg in string.gmatch(propPath, "[^%.]+") do
            if type(v) == "table" then v = v[seg] else v = nil break end
        end
        if v ~= nil then return tostring(v) end
    end
    return "?"
end

function Spell:RenderDescription(vars, tmpl)
    local template = tmpl or self._descTemplate or self.description or ""    
    if template == "" then return "" end
    local flat = self:_flattenActions()
    local function repl(idxStr, propPath)
        local idx = tonumber(idxStr)
        local entry = flat[idx]
        if not entry then
            return "$["..idxStr.."]."..propPath.."$"
        end
        return self:_resolveActionProperty(entry, propPath, vars) or "?"
    end

    vars = vars or {}
    if vars.profile == nil then vars.profile = _activeProfile() end

    return template:gsub("%$%[(%d+)%]%.([%w_%.]+)%$", repl)
end

function Spell:RefreshDescription(vars)
    return self:RenderDescription(vars)  -- do NOT assign to self.description
end

-- ===== Requirement formatting ===============================================

--- Format a requirement string into human-readable text.
--- E.g., "equip.mainhand" -> "Requires main hand"
local function _formatRequirement(reqStr)
    if not reqStr or reqStr == "" then return nil end
    
    -- Handle OR operators: "equip.sword OR equip.dagger" -> "Requires sword or dagger"
    if reqStr:find(" OR ") then
        local parts = {}
        local buffer = ""
        local i = 1
        while i <= #reqStr do
            if i + 3 <= #reqStr and reqStr:sub(i, i+3) == " OR " then
                if buffer ~= "" then
                    table.insert(parts, buffer)
                    buffer = ""
                end
                i = i + 4
            else
                buffer = buffer .. reqStr:sub(i, i)
                i = i + 1
            end
        end
        if buffer ~= "" then table.insert(parts, buffer) end
        
        local formatted = {}
        for _, part in ipairs(parts) do
            local fmt = _formatRequirement(part:match("^%s*(.-)%s*$"))
            if fmt then table.insert(formatted, fmt:match("^Requires (.+)$") or fmt) end
        end
        if #formatted > 0 then
            return "Requires " .. table.concat(formatted, " or ")
        end
        return nil
    end
    
    -- Trim whitespace
    reqStr = reqStr:match("^%s*(.-)%s*$") or reqStr
    
    -- equip.SLOT.TYPE format (e.g., "equip.mainhand.sword")
    if reqStr:match("^equip%.") then
        local parts = {}
        for part in reqStr:gmatch("[^.]+") do
            table.insert(parts, part)
        end
        
        if #parts >= 2 then
            local slot = parts[2]:lower()
            local itemType = parts[3] and parts[3]:lower() or nil
            
            -- Slot name formatting
            local slotName = slot
            if slot == "mainhand" then slotName = "Main Hand"
            elseif slot == "offhand" then slotName = "Off-hand"
            elseif slot == "dual" then slotName = "Dual Wielding"
            elseif slot == "twohand" then slotName = "Two-Handed Weapon"
            end
            
            if itemType then
                return "Requires " .. itemType .. " in " .. slotName
            else
                return "Requires " .. slotName
            end
        end
    end
    
    -- inventory.ITEMID format (e.g., "inventory.12345")
    if reqStr:match("^inventory%.") then
        local itemId = reqStr:match("^inventory%.(.+)$")
        if itemId then
            local ItemRegistry = RPE and RPE.Core and RPE.Core.ItemRegistry
            local itemName = itemId
            if ItemRegistry then
                local item = ItemRegistry:Get(itemId)
                if item and item.name then
                    itemName = item.name
                end
            end
            return "Requires " .. itemName
        end
    end
    
    return nil
end

--- Evaluate all requirements from spell and spell groups, return list of requirement texts.
--- Returns: { { text=string, met=boolean }, ... }
local function _evaluateRequirements(spell, ctx)
    local Requirements = RPE and RPE.Core and RPE.Core.SpellRequirements
    if not Requirements then return {} end
    
    local seen = {}  -- dedup requirements
    local result = {}
    
    -- First, add spell-level requirements
    for _, req in ipairs(spell.requirements or {}) do
        local reqStr = req
        
        -- Handle both formats: plain string or {key="..."} object
        if type(req) == "table" and req.key then
            reqStr = req.key
        end
        
        if type(reqStr) == "string" and reqStr ~= "" and not seen[reqStr] then
            seen[reqStr] = true
            
            local formatted = _formatRequirement(reqStr)
            if formatted then
                local ok = Requirements:EvalRequirement(ctx or {}, reqStr)
                table.insert(result, { text = formatted, met = ok })
            end
        end
    end
    
    -- Then, add group-level requirements
    if spell.groups then
        for _, group in ipairs(spell.groups) do
            for _, req in ipairs(group.requirements or {}) do
                local reqStr = req
                
                -- Handle both formats: plain string or {key="..."} object
                if type(req) == "table" and req.key then
                    reqStr = req.key
                end
                
                if type(reqStr) == "string" and reqStr ~= "" and not seen[reqStr] then
                    seen[reqStr] = true
                    
                    local formatted = _formatRequirement(reqStr)
                    if formatted then
                        local ok = Requirements:EvalRequirement(ctx or {}, reqStr)
                        table.insert(result, { text = formatted, met = ok })
                    end
                end
            end
        end
    end
    
    return result
end

-- ===== Training Cost ========================================================
---Returns a formatted training cost string based on spell rank and unlock level
---@param rank number|nil The spell rank (defaults to self.rank)
---@return string Formatted cost string (gold/silver/copper)
function Spell:GetFormattedTrainingCost(rank)
    rank = tonumber(rank or self.rank or 1) or 1
    local unlockLevel = tonumber(self.unlockLevel or 1) or 1
    
    -- Cost formula: base per rank (100 copper) + per level (50 copper)
    local copper = (rank * 100) + (unlockLevel * 50)
    
    if Common and Common.FormatCopper then
        return Common:FormatCopper(copper)
    end
    return tostring(copper) .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
end

-- ===== Tooltip ==============================================================
function Spell:GetTooltip(rank)
    local profile = _activeProfile()
    local spec  = { title = nil, lines = {} }
    local lines = spec.lines
    local rank  = tonumber(rank or self.rank or 1) or 1

    -- First line: Spell name (gold left) | Rank (grey right)
    table.insert(lines, {
        left  = self.name or self.id or "Spell",
        r     = 1, g = 0.82, b = 0, -- gold
        right = RPE.ActiveRules:Get("use_spell_ranks") == 1 and ("Rank %d"):format(rank) or nil,
        r2    = 0.7, g2 = 0.7, b2 = 0.7, -- grey
    })

    -- NPC-only marker (red line)
    if self.npcOnly then
        table.insert(lines, {
            left = "NPC Only",
            r = 1, g = 0.3, b = 0.3,
        })
    end

    -- Costs (first cost left) | Cooldown (right)
    local firstCost, restCosts = nil, {}
    if self.costs and #self.costs > 0 then
        for i, c in ipairs(self.costs) do
            local amt = _evaluateCost(self, c, profile)
            local res = c.resource or ""
            local text = string.format("%s %s", tostring(amt), tostring(res))

            if i == 1 then
                firstCost = text
            else
                table.insert(restCosts, text)
            end
        end
    end

    -- Cooldown
    local cdText
    if self.cooldown and self.cooldown.turns then
        local t = tonumber(self.cooldown.turns) or 0
        cdText = ("%d turn%s cooldown"):format(t, (t == 1 and "" or "s"))
    end

    -- Show first cost + cooldown on same line
    if firstCost or cdText then
        table.insert(lines, {
            left  = firstCost or "",
            right = cdText or "",
            r = 1, g = 1, b = 1,
        })
    end

    -- Remaining costs, one per line
    for _, cost in ipairs(restCosts) do
        table.insert(lines, { left = cost, r = 1, g = 1, b = 1 })
    end

    -- Cast time
    if self.cast then
        local ct = self.cast
        local castLine
        if ct.type == "INSTANT" then
            castLine = "Instant"
        elseif ct.type == "CAST_TURNS" then
            castLine = ("%d turn cast"):format(tonumber(ct.turns) or 1)
        elseif ct.type == "CHANNEL" then
            local total = tonumber(ct.turns) or 1
            local every = tonumber(ct.tickIntervalTurns) or 1
            castLine = ("Channel %d turn%s (tick %d)"):
                       format(total, (total == 1 and "" or "s"), every)
        end
        if castLine then
            table.insert(lines, { left = castLine, r = 1, g = 1, b = 1 })
        end
    end

    -- Requirements
    local reqs = _evaluateRequirements(self, nil)
    for _, req in ipairs(reqs) do
        local r, g, b = 1, 1, 1  -- white if met
        if not req.met then
            r, g, b = 0.95, 0.55, 0.55  -- textMalus red if not met
        end
        table.insert(lines, { left = req.text, r = r, g = g, b = b })
    end

    -- Spacer
    table.insert(lines, { left = " " })

    -- Description (gold, wrapped)
    self.rankOverride = rank
    local desc = self:RenderDescription({ profile = profile }, self.description or "") or ""
    self.rankOverride = nil    
    if desc ~= "" then
        table.insert(lines, { left = desc, r = 1, g = 0.82, b = 0, wrap = true })
    end

    -- Spacer
    table.insert(lines, { left = " " })

    -- Rank availability info (grey line, shows explicit levels)
    if (self.maxRanks and self.maxRanks > 1) and (self.unlockLevel and self.unlockLevel > 0) and RPE.ActiveRules:Get("use_spell_ranks_lvl") == 1 then
        local levels = {}
        local start  = self.unlockLevel or 1
        local step   = self.rankInterval or 1
        local maxR   = self.maxRanks or 1

        for r = 1, maxR do
            table.insert(levels, start + (r - 1) * step)
        end

        table.insert(lines, {
            left = "Unlocks at Level " .. table.concat(levels, ", "),
            r = 0.7, g = 0.7, b = 0.7,  -- grey text
        })
    end

    return spec
end


-- ===== Serialization ========================================================
function Spell:Serialize()
    return {
        id          = self.id,
        name        = self.name,
        description = self.description,
        icon        = self.icon,
        costs       = self.costs and deepcopy(self.costs) or nil,
        cast        = self.cast and deepcopy(self.cast) or nil,
        cooldown    = self.cooldown and deepcopy(self.cooldown) or nil,
        targeter    = self.targeter and deepcopy(self.targeter) or nil,
        requirements= self.requirements and deepcopy(self.requirements) or nil,
        groups      = self.groups and deepcopy(self.groups) or nil,
        tags        = self.tags and deepcopy(self.tags) or nil,
        data        = self.data and deepcopy(self.data) or nil,
        npcOnly     = not not self.npcOnly,
        maxRanks     = self.maxRanks,
        unlockLevel  = self.unlockLevel,
        rankInterval = self.rankInterval,
    }
end

function Spell.FromTable(t)
    assert(type(t) == "table", "Spell.FromTable expects table")
    return Spell:New(t.id, t.name, {
        description = t.description,
        icon        = t.icon,
        costs       = t.costs,
        cast        = t.cast,
        cooldown    = t.cooldown,
        targeter    = t.targeter,
        requirements= t.requirements,
        groups      = t.groups,
        tags        = t.tags,
        data        = t.data,
        npcOnly     = t.npcOnly,
        maxRanks    = t.maxRanks,
        unlockLevel = t.unlockLevel,
        rankInterval= t.rankInterval,
    })
end

return Spell
