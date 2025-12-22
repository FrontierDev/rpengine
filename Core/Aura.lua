-- RPE/Core/Aura.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local AuraRegistry = assert(RPE.Core.AuraRegistry, "AuraRegistry required")

local function _activeProfile()
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        local ok, p = pcall(RPE.Profile.DB.GetOrCreateActive)
        if ok and p then return p end
    end
    return nil
end

---@class Aura
---@field id string         -- def id
---@field def table
---@field instanceId integer
---@field sourceId string     -- unit key
---@field targetId string     -- unit key
---@field startTurn integer
---@field expiresOn integer|nil
---@field nextTick integer|nil
---@field stacks integer
---@field charges integer|nil
---@field snapshot table|nil -- author-defined values frozen at apply
---@field rngSeed integer|nil
---@field isTrait boolean|nil -- whether this aura is a permanent trait
---@field removeOnDamageTaken boolean|nil -- remove aura if target takes damage
---@field crowdControl table|nil -- crowd control effects: blockAllActions, blockActionsByTag[], failAllDefences, failDefencesByStats[], slowMovement
local Aura = {}
Aura.__index = Aura
RPE.Core.Aura = Aura

local _nextInstanceId = 1
local function nextId()
    local id = _nextInstanceId
    _nextInstanceId = _nextInstanceId + 1
    return id
end

---Create a new aura instance (internal).
---@param def table
---@param sourceId integer
---@param targetId integer
---@param nowTurn integer
---@param opts table|nil
function Aura.New(def, sourceId, targetId, nowTurn, opts)
    opts = opts or {}
    local o = {
        id         = def.id,
        def        = def,
        _def       = def,
        description= def.description,
        _descTemplate = def.description or "",
        instanceId = nextId(),
        sourceId     = sourceId,
        targetId     = targetId,
        startTurn  = nowTurn,
        stacks     = math.max(1, tonumber(opts.stacks) or 1),
        charges    = opts.charges,            -- optional
        rngSeed    = opts.rngSeed,
        snapshot   = opts.snapshot,           -- optional
        removeOnDamageTaken = def.removeOnDamageTaken,  -- Copy from definition
        crowdControl = def.crowdControl,      -- Copy crowd control settings from definition
    }
    -- Duration -> absolute expiry turn (if duration>0)
    if def.duration and def.duration.turns and def.duration.turns > 0 then
        o.expiresOn = nowTurn + def.duration.turns
    end
    -- Tick schedule
    if def.tick and def.tick.period and def.tick.period > 0 then
        o.nextTick = nowTurn + def.tick.period
    end
    return setmetatable(o, Aura)
end

function Aura:IsExpiredAt(turn)
    return self.expiresOn and turn >= self.expiresOn
end

function Aura:CanTickAt(turn)
    return self.nextTick and turn >= self.nextTick
end

function Aura:AdvanceTick(turn)
    if not self.def.tick then return end
    local period = self.def.tick.period
    if period and period > 0 then
        -- advance to next multiple at/after 'turn'
        local n = math.max(1, math.floor((turn - (self.nextTick or turn)) / period) + 1)
        self.nextTick = (self.nextTick or turn) + n * period
    end
end

function Aura:AddStacks(n)
    n = n or 1
    local newStacks = math.min(self.def.maxStacks or 1, (self.stacks or 1) + n)
    local changed = (newStacks ~= self.stacks)
    self.stacks = newStacks
    return changed
end

function Aura:SetStacks(n)
    n = math.max(1, math.min(self.def.maxStacks or 1, n))
    local changed = (n ~= self.stacks)
    self.stacks = n
    return changed
end

function Aura:ExtendDuration(turns)
    if not self.expiresOn then return false end
    local before = self.expiresOn
    self.expiresOn = self.expiresOn + (turns or 0)
    return self.expiresOn ~= before
end

function Aura:RefreshDuration(nowTurn)
    if not self.def.duration or (self.def.duration.turns or 0) <= 0 then return false end
    local before = self.expiresOn
    self.expiresOn = nowTurn + self.def.duration.turns
    return self.expiresOn ~= before
end

function Aura.FromTable(src)
    if not src or not src.id then return nil end
    local def = {}
    for k,v in pairs(src) do def[k] = v end
    def.id = src.id
    return def
end

-- Serialize minimal state (for save/sync).
function Aura:ToState()
    return {
        id = self.id,
        instanceId = self.instanceId,
        sourceId = self.sourceId,
        targetId = self.targetId,
        startTurn = self.startTurn,
        expiresOn = self.expiresOn,
        nextTick = self.nextTick,
        stacks = self.stacks,
        charges = self.charges,
        rngSeed = self.rngSeed,
        snapshot = self.snapshot,
        isTrait = self.isTrait,
        removeOnDamageTaken = self.removeOnDamageTaken,
        crowdControl = self.crowdControl,
    }
end


-- ===== Description rendering helpers (mirrors Spell.lua style) ===========
function Aura:_flattenTriggers()
    local flat = {}
    for ti, trig in ipairs((self._def and self._def.triggers) or {}) do
        table.insert(flat, { trig=trig, ti=ti, idx=#flat+1 })
    end
    return flat
end

function Aura:_resolveActionProperty(entry, propPath, vars)
    local trig = entry.trig
    local act = trig and trig.action or nil
    if not act then return "$["..tostring(entry.idx).."]."..tostring(propPath).."$" end
    local args = act.args or {}

    local profile = vars and vars.profile
    local Formula = RPE.Core and RPE.Core.Formula

    if propPath == "school" then
        local raw = args.school or "Physical"
        if type(raw) == "string" then
            local slot = raw:match("^%$wep%.([%w_]+)%$")
            if slot then
                local norm = string.lower(slot)
                if norm == "mh" then norm = "mainhand"
                elseif norm == "oh" then norm = "offhand"
                elseif norm == "rng" or norm == "bow" then norm = "ranged" end

                local item = nil
                if profile and type(profile.GetEquipped) == "function" then
                    local ok, id = pcall(profile.GetEquipped, profile, norm)
                    if ok and id then
                        if type(id) == "table" then item = id end
                        if type(id) == "string" then
                            local reg = RPE.Core and RPE.Core.ItemRegistry
                            if reg and type(reg.Get) == "function" then
                                local ok2, defit = pcall(reg.Get, reg, id)
                                if ok2 and defit then item = defit end
                            end
                        end
                    end
                end
                if not item and profile and type(profile.equipment) == "table" then
                    local ent = profile.equipment[norm]
                    if ent then
                        if type(ent) == "table" then item = ent end
                        if type(ent) == "string" then
                            local reg = RPE.Core and RPE.Core.ItemRegistry
                            if reg and type(reg.Get) == "function" then
                                local ok2, defit = pcall(reg.Get, reg, ent)
                                if ok2 and defit then item = defit end
                            end
                        end
                    end
                end
                if item then
                    local d = (type(item) == "table") and (item.data or item) or {}
                    local ds = d.damageSchool or d.school or d.damage_school
                    if ds and ds ~= "" then return tostring(ds) end
                end
                return "Physical"
            end
        end
        return tostring(raw)
    end

    if propPath == "amount" or propPath:match("^amount%.") then
        if not Formula then return tostring(args.amount or "") end
        local parsed = Formula:Parse(args.amount, profile)
        if not parsed then return "0" end
        if propPath == "amount.min" then return tostring(parsed.min or parsed.value or 0)
        elseif propPath == "amount.max" then return tostring(parsed.max or parsed.value or 0)
        elseif propPath == "amount.avg" then
            local a = parsed.min or parsed.value or 0
            local b = parsed.max or parsed.value or 0
            return tostring(math.floor(((a+b)/2)+0.5))
        else
            return Formula:Format(parsed)
        end
    end

    if propPath == "auraId" then
        return tostring(args.auraId or args.resourceId or "")
    end

    local v = args
    for seg in string.gmatch(propPath, "[^%.]+") do
        if type(v) == "table" then v = v[seg] else v = nil break end
    end
    if v ~= nil then return tostring(v) end

    return "$["..tostring(entry.idx).."]."..tostring(propPath).."$"
end

function Aura:RenderDescription(vars, tmpl)
    local template = tmpl or self._descTemplate or self.description or ""    
    if template == "" then return "" end
    local flat = self:_flattenTriggers()
    local function repl(idxStr, propPath)
        local idx = tonumber(idxStr)
        local entry = flat[idx]
        if not entry then
            return "$["..idxStr.."]."..propPath.."$"
        end
        return self:_resolveActionProperty(entry, propPath, vars) or "?"
    end

    vars = vars or {}
    if vars.profile == nil then
        local tu = select(1, Common:FindUnitById(self.targetId))
        vars.profile = Common:ProfileForUnit(tu) or (_activeProfile and _activeProfile())
    end

    return template:gsub("%$%[(%d+)%]%.([%w_%.]+)%$", repl)
end

function Aura:RefreshDescription(vars)
    return self:RenderDescription(vars)
end

-- Static method to render description from a raw aura definition table
function Aura.RenderDescriptionFromDef(def, vars, tmpl)
    local template = tmpl or (def and def.description) or ""
    if template == "" then return "" end
    local flat = {}
    if def and def.triggers then
        for ti, trig in ipairs(def.triggers) do
            table.insert(flat, { trig=trig, ti=ti, idx=#flat+1 })
        end
    end
    local function repl(idxStr, propPath)
        local idx = tonumber(idxStr)
        local entry = flat[idx]
        if not entry then
            return "$["..idxStr.."]."..propPath.."$"
        end
        local trig = entry.trig
        local act = trig and trig.action or nil
        if not act then return "$["..idxStr.."]."..propPath.."$" end
        local args = act.args or {}
        local profile = vars and vars.profile
        local Formula = RPE.Core and RPE.Core.Formula
        if propPath == "school" then
            local raw = args.school or "Physical"
            if type(raw) == "string" then
                local slot = raw:match("^%$wep%.([%w_]+)%$")
                if slot then
                    -- For UI tooltips, default to Physical since no equipped items context
                    return "Physical"
                end
            end
            return tostring(raw)
        elseif propPath == "amount" or propPath:match("^amount%.") then
            if not Formula then return tostring(args.amount or "") end
            local parsed = Formula:Parse(args.amount, profile)
            if not parsed then return "0" end
            if propPath == "amount.min" then return tostring(parsed.min or parsed.value or 0)
            elseif propPath == "amount.max" then return tostring(parsed.max or parsed.value or 0)
            elseif propPath == "amount.avg" then
                local a = parsed.min or parsed.value or 0
                local b = parsed.max or parsed.value or 0
                return tostring(math.floor(((a+b)/2)+0.5))
            else
                return Formula:Format(parsed)
            end
        elseif propPath == "auraId" then
            return tostring(args.auraId or args.resourceId or "")
        else
            local v = args
            for seg in string.gmatch(propPath, "[^%.]+") do
                if type(v) == "table" then v = v[seg] else v = nil break end
            end
            if v ~= nil then return tostring(v) end
        end
        return "$["..idxStr.."]."..propPath.."$"
    end
    vars = vars or {}
    if vars.profile == nil then vars.profile = _activeProfile() end
    return template:gsub("%$%[(%d+)%]%.([%w_%.]+)%$", repl)
end


-- ===== Tooltip ==============================================================
function Aura:GetTooltip()
    local def = AuraRegistry:Get(self.id) or self.def or {}
    if not self._def then self._def = def end

    -- Prefer the target unit's profile (so $stat.*$ matches the bearer of the aura).
    local profile = (function()
        local tu = select(1, Common:FindUnitById(self.targetId))
        return Common:ProfileForUnit(tu)
            or (RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive())
    end)()

    local spec  = { title = def.name or self.id or "Aura", lines = {} }
    local lines = spec.lines

    -- Description (gold, wrapped)
    local desc = self:RenderDescription({ profile = profile }, def.description or "") or ""
    if desc ~= "" then
        table.insert(lines, { text = desc, r = 1, g = 0.82, b = 0, wrap = true })
    end

    return spec
end

