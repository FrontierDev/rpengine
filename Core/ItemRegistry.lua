-- RPE/Core/ItemRegistry.lua
-- Read-only runtime index of Items, rebuilt from one or MORE datasets.
-- Source of truth = Datasets. This registry is a transient cache for lookups.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Item   = assert(RPE.Core.Item, "RPE.Core.Item must be loaded before ItemRegistry")
local Common = RPE.Common or {}

---@class ItemRegistry
---@field _items table<string, any>
---@field _onRefresh fun(count:number)[]|nil
local ItemRegistry = {}
ItemRegistry.__index = ItemRegistry
RPE.Core.ItemRegistry = ItemRegistry

-- ---------------------------------------------------------------------------
-- Basics
-- ---------------------------------------------------------------------------

function ItemRegistry:Init()
    if not self._items then self._items = {} end
end

--- Register an Item in the registry (dev/debug). Normal flow uses Refresh*.
---@param item table
function ItemRegistry:Register(item)
    self:Init()
    assert(item and item.id, "ItemRegistry:Register requires an Item with id")
    self._items[item.id] = item
end

--- Retrieve an Item by id.
---@param id string
---@return table|nil
function ItemRegistry:Get(id)
    self:Init()
    return self._items[id]
end

--- Return the backing map (read-only by convention).
---@return table<string, any>
function ItemRegistry:All()
    self:Init()
    return self._items
end

--- Clear the registry (transient).
function ItemRegistry:Clear()
    self._items = {}
end

--- Debug print.
function ItemRegistry:Dump()
    self:Init()
    for id, item in pairs(self._items) do
        local name = (Common and Common.ColorByQuality and Common:ColorByQuality(item.name or id, item.rarity))
                  or (item.name or id)
    end
end

--- Get the item equipped in a specific slot (from player profile).
--- @param slot string (e.g., "mainhand", "offhand", "ranged")
--- @return table|nil the equipped item definition, or nil if nothing equipped
function ItemRegistry:GetEquipped(slot)
    self:Init()
    slot = (slot or ""):upper()
    
    -- Try to get active player profile
    local profile = nil
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        local ok, p = pcall(RPE.Profile.DB.GetOrCreateActive)
        if ok and p then profile = p end
    end
    
    if not profile then return nil end
    
    -- Try profile:GetEquipped(slot) method first
    if type(profile.GetEquipped) == "function" then
        local ok, itemId = pcall(profile.GetEquipped, profile, slot)
        if ok and itemId then
            return self:Get(itemId)
        end
    end
    
    -- Try profile.equipment table
    if type(profile.equipment) == "table" then
        local itemId = profile.equipment[slot]
        if itemId then
            return self:Get(itemId)
        end
    end
    
    return nil
end

-- ---------------------------------------------------------------------------
-- Refresh notifications (lightweight; optional global bus integration)
-- ---------------------------------------------------------------------------

function ItemRegistry:OnRefreshed(cb)
    if type(cb) ~= "function" then return end
    self._onRefresh = self._onRefresh or {}
    table.insert(self._onRefresh, cb)
end

local function _emitRefreshed(self, count)
    -- Optional global bus if present
    local Events = RPE and RPE.Core and RPE.Core.Events
    if Events and type(Events.Emit) == "function" then
        pcall(Events.Emit, Events, "ITEMS_REFRESHED", { count = count })
    end
    -- Local listeners
    if self._onRefresh then
        for _, fn in ipairs(self._onRefresh) do
            pcall(fn, count)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Dataset → Registry rebuild
-- ---------------------------------------------------------------------------

-- Build an Item object from a dataset entry table.
local function _itemFromDatasetEntry(id, t)
    if type(t) ~= "table" then return nil end
    local src = {}
    for k, v in pairs(t) do src[k] = v end
    src.id = src.id or id

    -- Prefer factory if provided
    if type(Item.FromTable) == "function" then
        local ok, obj = pcall(Item.FromTable, src)
        if ok and obj then return obj end
        -- fall through if factory failed
    end

    -- Fallback constructor: Item:New(id, name, category, opts)
    if type(Item.New) == "function" then
        return Item:New(
            src.id,
            src.name or id,
            src.category or "MISC",
            {
                icon        = src.icon,
                stackable   = src.stackable and true or false,
                maxStack    = tonumber(src.maxStack) or 1,
                description = src.description,
                rarity      = src.rarity or "common",
                data        = (type(src.data) == "table" or type(src.data) == "string") and src.data or nil,
            }
        )
    end

    -- Last resort: store the table directly
    return src
end

--- Rebuild the registry from a single Dataset table (expects ds.items hash).
--- This remains for single-dataset edits / previews.
---@param ds table|nil  -- dataset { items = { [id] = {name=..., ...} } }
---@return integer count
function ItemRegistry:RefreshFromDataset(ds)
    self:Init()
    local count = 0

    if not (ds and type(ds.items) == "table") then
        self._items = {}
        _emitRefreshed(self, 0)
        return 0
    end

    local newMap = {}
    for id, entry in pairs(ds.items) do
        local obj = _itemFromDatasetEntry(id, entry)
        if obj and obj.id then
            newMap[obj.id] = obj
            count = count + 1
        end
    end

    self._items = newMap
    _emitRefreshed(self, count)
    return count
end

--- Rebuild the registry by *merging multiple datasets* by name.
--- Later names override earlier ones on id conflicts.
---@param datasetNames string[]|nil
---@return integer count
function ItemRegistry:RefreshFromDatasetNames(datasetNames)
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
        if ds and type(ds.items) == "table" then
            for id, entry in pairs(ds.items) do
                local obj = _itemFromDatasetEntry(id, entry)
                if obj and obj.id then
                    -- later datasets override earlier ones
                    newMap[obj.id] = obj
                end
            end
        end
    end

    local count = 0
    for _ in pairs(newMap) do count = count + 1 end

    self._items = newMap
    _emitRefreshed(self, count)
    return count
end

--- Convenience: rebuild from the current character's ACTIVE dataset list.
--- Uses GetActiveNamesForCurrentCharacter() and merges in order (later wins).
---@return integer count
function ItemRegistry:RefreshFromActiveDatasets()
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
function ItemRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

return ItemRegistry
