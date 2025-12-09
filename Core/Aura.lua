-- RPE/Core/Aura.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local AuraRegistry = assert(RPE.Core.AuraRegistry, "AuraRegistry required")

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
        instanceId = nextId(),
        sourceId     = tonumber(sourceId),
        targetId     = tonumber(targetId),
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

-- ===== Tooltip ==============================================================
function Aura:GetTooltip()
    local def = self.def or AuraRegistry:Get(self.id) or {}

    -- Prefer the target unit's profile (so $stat.*$ matches the bearer of the aura).
    local profile = (function()
        local tu = select(1, Common:FindUnitById(self.targetId))
        return Common:ProfileForUnit(tu)
            or (RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive())
    end)()

    local spec  = { title = def.name or self.id or "Aura", lines = {} }
    local lines = spec.lines

    -- Description (gold, wrapped) — resolve $stat.FOO$ against the profile
    local desc = tostring(def.description or "")
    if desc ~= "" then
        desc = desc:gsub("%$stat%.([%w_]+)%$", function(statId)
            local s = profile and profile.stats and profile.stats[statId]
            local v = s and s:GetValue(profile) or 0
            -- Show integers plainly; otherwise round to 0 decimals like spells typically do
            if math.type and math.type(v) == "integer" then
                return tostring(v)
            else
                return string.format("%.0f", v)
            end
        end)
        table.insert(lines, { text = desc, r = 1, g = 0.82, b = 0, wrap = true })
    end

    return spec
end

