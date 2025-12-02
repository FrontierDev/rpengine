-- RPE/Core/NPCRegistry.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local NPCRegistry = { defs = {} }
RPE.Core.NPCRegistry = NPCRegistry

-- Optional dependencies (used by RefreshFromActiveDataset / Spawn helpers)
local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
local Unit      = RPE.Core and RPE.Core.Unit

-- ---------------------------------------------
-- Internals
-- ---------------------------------------------
local function _copyShallow(dst, src)
    for k, v in pairs(src or {}) do 
        dst[k] = v 
    end

    return dst
end

local function _copyDeep(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = (type(v) == "table") and _copyDeep(v) or v
    end
    return out
end

local function _normNPC(id, def)
    -- Accept flexible authoring keys; normalize into a stable proto.
    local d = _copyDeep(def or {})
    d.id        = d.id or id
    d.key       = d.key or id
    d.name      = d.name or id
    d.team      = tonumber(d.team) or 1
    d.tags      = (type(d.tags) == "table") and d.tags or nil
    d.icon      = d.icon
    d.model     = d.model
    d.raidMarker= tonumber(d.raidMarker) or nil

    -- HP / initiative
    -- Try to extract from hp.base and hp.perPlayer (set by NPC editor)
    local hpBase = tonumber((d.hp and d.hp.base) or d.hpBase or d.hpMax or d.maxHP or d.maxHp or d.healthMax)
    local hpPerPlayer = tonumber((d.hp and d.hp.perPlayer) or d.hpPerPlayer) or 0
    
    -- hpMax is the base HP value (without perPlayer scaling)
    d.hpMax     = (hpBase and hpBase > 0) and math.floor(hpBase) or 100
    -- Also store the per-player scaling factor for later use
    d.hpPerPlayer = hpPerPlayer
    -- hpStart defaults to hpMax, but can be overridden
    d.hpStart   = tonumber(d.startHP or d.health) or d.hpMax
    d.initiative= math.floor(tonumber(d.initiative) or 0)

    -- Stats: keep table as-is (seed fill happens when building a unit seed)
    d.stats     = (type(d.stats) == "table") and _copyDeep(d.stats) or nil

    -- Anything else stays under .extra to avoid polluting Unit.New
    local keep = { id=true,key=true,name=true,team=true,tags=true,icon=true,model=true,raidMarker=true,hpMax=true,hpPerPlayer=true,hpStart=true,initiative=true,stats=true }
    local extra = {}
    for k, v in pairs(d) do if not keep[k] then extra[k] = v end end
    d.extra = next(extra) and extra or nil
    return d
end

-- ---------------------------------------------
-- API
-- ---------------------------------------------
function NPCRegistry:Init()
    if not self.defs then self.defs = {} end
end

function NPCRegistry:Clear()
    self.defs = {}
end

--- Register a single NPC prototype.
---@param id string
---@param def table
function NPCRegistry:Register(id, def)
    self:Init()
    assert(type(id) == "string" and id ~= "", "NPCRegistry:Register: id required")
    assert(type(def) == "table", "NPCRegistry:Register: def table required")
    self.defs[id] = _normNPC(id, def)
end

--- Get a normalized prototype (or nil).
function NPCRegistry:Get(id)
    self:Init()
    return self.defs[id]
end

function NPCRegistry:Has(id)
    return self.defs and self.defs[id] ~= nil
end

--- Iterate all prototypes: for id, proto in NPCRegistry:Pairs() do ...
function NPCRegistry:Pairs()
    self:Init()
    return pairs(self.defs)
end

--- Replace all defs by reading DatasetDB's merged active dataset (plural version supports multiple active datasets).
function NPCRegistry:RefreshFromActiveDatasets()
    self:Clear()
    local ds = DatasetDB and DatasetDB.LoadActiveForCurrentCharacter and DatasetDB:LoadActiveForCurrentCharacter()
    if not ds then return end
    for id, def in pairs(ds.npcs or {}) do
        self:Register(id, def)
    end
end

function NPCRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

-- ---------------------------------------------
-- Builders / Helpers
-- ---------------------------------------------

--- Build a Unit.New seed from an NPC id with optional overrides.
--- Returns a table suitable for Unit.New(id, seed).
---@param npcId string
---@param overrides table|nil  -- { name, team, hp, hpMax, initiative, stats = {..}, raidMarker, key }
function NPCRegistry:BuildUnitSeed(npcId, overrides)
    overrides = overrides or {}
    local proto = self:Get(npcId)
    assert(proto, ("NPCRegistry:BuildUnitSeed: unknown npc '%s'"):format(tostring(npcId)))

    local seed = {
        key        = overrides.key        or proto.key or npcId,
        name       = overrides.name       or proto.name or npcId,
        team       = tonumber(overrides.team or proto.team or 1),
        isNPC      = true,
        hpMax      = tonumber(overrides.hpMax or proto.hpMax) or 100,
        hp         = tonumber(overrides.hp    or proto.hpStart) or tonumber(overrides.hpMax or proto.hpMax) or 100,
        initiative = tonumber(overrides.initiative or proto.initiative) or 0,
        raidMarker = tonumber(overrides.raidMarker or proto.raidMarker) or nil,
        active     = overrides.active ~= nil and overrides.active or (proto.active ~= nil and proto.active or false),
        hidden     = overrides.hidden ~= nil and overrides.hidden or (proto.hidden ~= nil and proto.hidden or false),
        flying     = overrides.flying ~= nil and overrides.flying or (proto.flying ~= nil and proto.flying or false),
        stats      = {},
        spells     = (type(proto.spells) == "table") and proto.spells or nil,
    }

    -- Merge stats: start from proto.stats then apply overrides.stats
    if type(proto.stats) == "table" then 
        _copyShallow(seed.stats, proto.stats)
    end
    if type(overrides.stats) == "table" then 
        _copyShallow(seed.stats, overrides.stats) 
    end

    -- If rules define 'npc_stats', ensure all listed keys exist so Unit:SeedNPCStats
    -- won't overwrite provided values. Missing ones will be left absent so Unit can seed them.
    local rules = RPE.ActiveRules
    if rules and rules.Get then
        local list = rules:Get("npc_stats")
        if type(list) == "table" then
            for _, statId in ipairs(list) do
                if seed.stats[statId] == nil and type(proto.stats) == "table" and proto.stats[statId] ~= nil then
                    seed.stats[statId] = tonumber(proto.stats[statId]) or proto.stats[statId]
                end
            end
        end
    end

    -- Include model data for 3D portraits
    seed.displayId   = proto.displayId   or proto.modelDisplayId
    seed.fileDataId  = proto.fileDataId
    seed.cam         = proto.cam
    seed.rot         = proto.rot
    seed.z           = proto.z

    return seed
end

--- Convenience: instantiate an EventUnit directly (if Unit.lua is loaded).
--- Returns EventUnit or nil + error.
---@param numericUnitId integer
---@param npcId string
---@param overrides table|nil
function NPCRegistry:SpawnUnitInstance(numericUnitId, npcId, overrides)
    assert(Unit and Unit.New, "NPCRegistry:SpawnUnitInstance requires Unit.lua loaded")
    local seed = self:BuildUnitSeed(npcId, overrides)
    return Unit.New(numericUnitId, seed)
end

-- ---------------------------------------------
-- Debug slash
-- ---------------------------------------------
SLASH_RPENPCS1 = "/rpenpcs"
SlashCmdList["RPENPCS"] = function(msg)
    local self = NPCRegistry
    local n = 0
    for id, proto in pairs(self.defs or {}) do
        n = n + 1
    end
end

return NPCRegistry
