-- RPE/Core/SpellRegistry.lua  (REPLACE FILE)
-- Read-only runtime index of Spells, rebuilt from one or MORE datasets.
-- Source of truth = Datasets. This registry is a transient cache for lookups.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Spell  = assert(RPE.Core.Spell, "RPE.Core.Spell must be loaded before SpellRegistry")
local Common = RPE.Common or {}

---@class SpellRegistry
---@field _spells table<string, any>
---@field _onRefresh fun(count:number)[]|nil
local SpellRegistry = {}
SpellRegistry.__index = SpellRegistry
RPE.Core.SpellRegistry = SpellRegistry

-- ---------------------------------------------------------------------------
-- Basics
-- ---------------------------------------------------------------------------

function SpellRegistry:Init()
    if not self._spells then self._spells = {} end
end

--- Register a Spell in the registry (dev/debug). Normal flow uses Refresh*.
--- Accepts either a Spell table OR (id, defTable) like Dataset:ApplyToRegistries().
function SpellRegistry:Register(a, b)
    self:Init()

    local obj = nil
    if type(a) == "table" and a.id then
        -- direct object
        obj = a
    elseif type(a) == "string" and type(b) == "table" then
        -- (id, defTable) → build Spell from dataset-style table
        obj = (function(id, t)
            if type(t) ~= "table" then return nil end
            local src = {}
            for k, v in pairs(t) do src[k] = v end
            src.id = src.id or id

            -- Prefer factory if present
            if type(Spell.FromTable) == "function" then
                local ok, s = pcall(Spell.FromTable, src)
                if ok and s then return s end
            end

            -- Fallback to Spell:New(id, name, opts) — pass all other keys as opts
            local opts = {}
            for k, v in pairs(src) do
                if k ~= "id" and k ~= "name" then opts[k] = v end
            end
            if type(Spell.New) == "function" then
                return Spell:New(src.id, src.name or src.id, opts)
            end

            -- Last resort: store the table directly
            return src
        end)(a, b)
    else
        error("SpellRegistry:Register requires Spell or (id, defTable)")
    end

    assert(obj and obj.id, "SpellRegistry:Register: invalid object")
    self._spells[obj.id] = obj
end

--- Retrieve a Spell by id.
---@param id string
---@return any|nil
function SpellRegistry:Get(id)
    self:Init()
    return self._spells[id]
end

--- Return the backing map (read-only by convention).
---@return table<string, any>
function SpellRegistry:All()
    self:Init()
    return self._spells
end

--- Clear the registry (transient).
function SpellRegistry:Clear()
    self._spells = {}
end

--- Debug print.
function SpellRegistry:Dump()
    self:Init()
    for id, sp in pairs(self._spells) do
        local name = (Common and Common.ColorByQuality and Common:ColorByQuality(sp.name or id, "common"))
                  or (sp.name or id)
    end
end

-- ---------------------------------------------------------------------------
-- Refresh notifications (optional global bus + local listeners)
-- ---------------------------------------------------------------------------

function SpellRegistry:OnRefreshed(cb)
    if type(cb) ~= "function" then return end
    self._onRefresh = self._onRefresh or {}
    table.insert(self._onRefresh, cb)
end

local function _emitRefreshed(self, count)
    local Events = RPE and RPE.Core and RPE.Core.Events
    if Events and type(Events.Emit) == "function" then
        pcall(Events.Emit, Events, "SPELLS_REFRESHED", { count = count })
    end
    if self._onRefresh then
        for _, fn in ipairs(self._onRefresh) do
            pcall(fn, count)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Dataset → Registry rebuild
-- ---------------------------------------------------------------------------

local function _spellFromDatasetEntry(id, t)
    if type(t) ~= "table" then return nil end
    local src = {}
    for k, v in pairs(t) do src[k] = v end
    src.id = src.id or id

    if type(Spell.FromTable) == "function" then
        local ok, s = pcall(Spell.FromTable, src)
        if ok and s then return s end
    end

    local opts = {}
    for k, v in pairs(src) do if k ~= "id" and k ~= "name" then opts[k] = v end end
    if type(Spell.New) == "function" then
        return Spell:New(src.id, src.name or src.id, opts)
    end
    return src
end

--- Rebuild the registry from a single Dataset table (expects ds.spells hash).
---@param ds table|nil  -- dataset { spells = { [id] = {name=..., ...} } }
---@return integer count
function SpellRegistry:RefreshFromDataset(ds)
    self:Init()
    local count = 0

    if not (ds and type(ds.spells) == "table") then
        self._spells = {}
        _emitRefreshed(self, 0)
        return 0
    end

    local newMap = {}
    for id, entry in pairs(ds.spells) do
        local obj = _spellFromDatasetEntry(id, entry)
        if obj and obj.id then
            newMap[obj.id] = obj
            count = count + 1
        end
    end

    self._spells = newMap
    _emitRefreshed(self, count)
    return count
end

--- Rebuild the registry by *merging multiple datasets* by name.
--- Later names override earlier ones on id conflicts.
---@param datasetNames string[]|nil
---@return integer count
function SpellRegistry:RefreshFromDatasetNames(datasetNames)
    self:Init()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then
        self:Clear()
        _emitRefreshed(self, 0)
        return 0
    end

    local names = {}
    if type(datasetNames) == "table" then
        for _, n in ipairs(datasetNames) do
            if type(n) == "string" and n ~= "" then table.insert(names, n) end
        end
    end

    local newMap = {}
    for _, name in ipairs(names) do
        local ds = DB.GetByName and DB.GetByName(name)
        if ds and type(ds.spells) == "table" then
            for id, entry in pairs(ds.spells) do
                local obj = _spellFromDatasetEntry(id, entry)
                if obj and obj.id then
                    newMap[obj.id] = obj -- later datasets override earlier
                end
            end
        end
    end

    local count = 0
    for _ in pairs(newMap) do count = count + 1 end

    self._spells = newMap
    _emitRefreshed(self, count)
    return count
end

--- Convenience: rebuild from the current character's ACTIVE dataset list.
---@return integer count
function SpellRegistry:RefreshFromActiveDatasets()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then
        self:Clear()
        _emitRefreshed(self, 0)
        return 0
    end
    local names = (DB.GetActiveNamesForCurrentCharacter and DB:GetActiveNamesForCurrentCharacter()) or {}
    return self:RefreshFromDatasetNames(names)
end

-- Back-compat shim (old callers used singular name)
function SpellRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

return SpellRegistry
