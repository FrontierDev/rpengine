-- RPE/Core/StatRegistry.lua
-- Read-only runtime index of Stats, rebuilt from one or MORE datasets.
-- Source of truth = Datasets. This registry is a transient cache for lookups.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Common = RPE.Common or {}

---@class StatRegistry
---@field _stats table<string, any>
---@field _onRefresh fun(count:number)[]|nil
local StatRegistry = {}
StatRegistry.__index = StatRegistry
RPE.Core.StatRegistry = StatRegistry

-- ---------------------------------------------------------------------------
-- Basics
-- ---------------------------------------------------------------------------

function StatRegistry:Init()
    if not self._stats then self._stats = {} end
end

--- Register a Stat definition in the registry (dev/debug). Normal flow uses Refresh*.
---@param statId string
---@param statDef table
function StatRegistry:Register(statId, statDef)
    self:Init()
    assert(statId and type(statId) == "string", "StatRegistry:Register requires a statId string")
    self._stats[statId] = statDef
end

--- Retrieve a Stat definition by id.
---@param id string
---@return table|nil
function StatRegistry:Get(id)
    self:Init()
    return self._stats[id]
end

--- Return the backing map (read-only by convention).
---@return table<string, any>
function StatRegistry:All()
    self:Init()
    return self._stats
end

--- Clear the registry (transient).
function StatRegistry:Clear()
    self._stats = {}
end

--- Register a refresh callback (called after RefreshFromActiveDatasets).
function StatRegistry:OnRefresh(fn)
    self._onRefresh = self._onRefresh or {}
    table.insert(self._onRefresh, fn)
end

local function _emitRefreshed(self, count)
    if self._onRefresh then
        for _, fn in ipairs(self._onRefresh) do
            if type(fn) == "function" then
                pcall(fn, count)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Dataset integration
-- ---------------------------------------------------------------------------

local function _statFromDatasetEntry(id, t)
    if type(t) ~= "table" then return nil end
    local src = {}
    for k, v in pairs(t) do src[k] = v end
    src.id = src.id or id
    return src
end

function StatRegistry:RefreshFromDatasetNames(datasetNames)
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
        if ds and type(ds.extra) == "table" and type(ds.extra.stats) == "table" then
            for id, entry in pairs(ds.extra.stats) do
                local obj = _statFromDatasetEntry(id, entry)
                if obj and obj.id then
                    -- later datasets override earlier ones
                    newMap[obj.id] = obj
                end
            end
        end
    end

    local count = 0
    for _ in pairs(newMap) do count = count + 1 end

    self._stats = newMap
    _emitRefreshed(self, count)
    return count
end

--- Convenience: rebuild from the current character's ACTIVE dataset list.
--- Uses GetActiveNamesForCurrentCharacter() and merges in order (later wins).
---@return integer count
function StatRegistry:RefreshFromActiveDatasets()
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
function StatRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

-- Singleton instance
local _instance = setmetatable({}, StatRegistry)
_instance:Init()
RPE.Core.StatRegistry = _instance

return _instance
