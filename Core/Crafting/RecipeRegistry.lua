-- RPE/Core/RecipeRegistry.lua
-- Read-only runtime index of Recipes, rebuilt from ACTIVE datasets.
-- Source of truth = Datasets (category: extra["recipes"]).

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Recipe = assert(RPE.Core.Recipe, "Recipe.lua must be loaded before RecipeRegistry")
local Common = RPE.Common or {}

---@class RecipeRegistry
---@field _map table<string, Recipe>
---@field _byProfession table<string, table<string, Recipe>>  -- profession -> id -> recipe
---@field _onRefresh fun(count:number)[]|nil
local RecipeRegistry = {}
RecipeRegistry.__index = RecipeRegistry
RPE.Core.RecipeRegistry = RecipeRegistry

-- ---- internals -------------------------------------------------------------

function RecipeRegistry:Init()
    if not self._map then self._map = {} end
    if not self._byProfession then self._byProfession = {} end
end

local function _indexRecipe(self, r)
    self._map[r.id] = r
    local p = r.profession or "Misc"
    self._byProfession[p] = self._byProfession[p] or {}
    self._byProfession[p][r.id] = r
end

local function _emitRefreshed(self, count)
    local Events = RPE and RPE.Core and RPE.Core.Events
    if Events and type(Events.Emit) == "function" then
        pcall(Events.Emit, Events, "RECIPES_REFRESHED", { count = count })
    end
    if self._onRefresh then
        for _, fn in ipairs(self._onRefresh) do pcall(fn, count) end
    end
end

-- ---- public API ------------------------------------------------------------

function RecipeRegistry:Clear()
    self._map = {}
    self._byProfession = {}
end

function RecipeRegistry:OnRefreshed(cb)
    if type(cb) ~= "function" then return end
    self._onRefresh = self._onRefresh or {}
    table.insert(self._onRefresh, cb)
end

---@param id string
---@return Recipe|nil
function RecipeRegistry:Get(id)
    self:Init()
    return self._map[id]
end

---@param profession string
---@return table<string, Recipe>  -- map by id
function RecipeRegistry:GetByProfession(profession)
    self:Init()
    return self._byProfession[profession] or {}
end

function RecipeRegistry:All()
    self:Init()
    return self._map
end

function RecipeRegistry:Dump()
    self:Init()
    for id, r in pairs(self._map) do
        local pname = r.profession or "?"
        local disp  = (Common and Common.ColorByQuality and r.quality and Common:ColorByQuality(r.name, r.quality))
                      or r.name
    end
end

-- ---- dataset rebuild -------------------------------------------------------

-- Expect recipes under merged dataset's extra["recipes"] as:
-- recipes = {
--   ["bs_sword_01"] = {
--      name="Copper Shortsword", profession="Blacksmithing", category="Basics",
--      skill=1, quality="uncommon", outputItemId="item_copper_sword", outputQty=1,
--      tools={"Blacksmith Hammer","Anvil"},
--      reagents={{id="copper_bar", qty=2},{id="rough_stone", qty=1}},
--      optional={{id="shining_gem", qty=1, bonus="+2% success"}},
--   },
--   ...
-- }
local function _recipesBucket(ds)
    if not ds or not ds.extra then return nil end
    return ds.extra["recipes"]
end

---@param ds table|nil  -- merged Dataset
function RecipeRegistry:RefreshFromDataset(ds)
    self:Init()
    self:Clear()

    local bucket = _recipesBucket(ds)
    local count = 0
    if type(bucket) == "table" then
        for id, def in pairs(bucket) do
            local ok, r = pcall(Recipe.FromTable, type(def)=="table" and (function()
                local t = {}
                for k,v in pairs(def) do t[k]=v end
                t.id = t.id or id
                return t
            end)() or { id = id })
            if ok and r and r.id then
                _indexRecipe(self, r)
                count = count + 1
            end
        end
    end

    _emitRefreshed(self, count)
    return count
end

---@param datasetNames string[]|nil
function RecipeRegistry:RefreshFromDatasetNames(datasetNames)
    self:Init()
    self:Clear()

    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then _emitRefreshed(self, 0); return 0 end

    local names = {}
    if type(datasetNames) == "table" then
        for _, n in ipairs(datasetNames) do
            if type(n) == "string" and n ~= "" then table.insert(names, n) end
        end
    end

    local merged = {}
    for _, name in ipairs(names) do
        local ds = DB.GetByName and DB.GetByName(name)
        local bucket = _recipesBucket(ds)
        if type(bucket) == "table" then
            for id, def in pairs(bucket) do
                merged[id] = def               -- later datasets override earlier ones
            end
        end
    end

    local count = 0
    for id, def in pairs(merged) do
        local t = {}
        for k,v in pairs(def) do t[k]=v end
        t.id = t.id or id
        local ok, r = pcall(Recipe.FromTable, t)
        if ok and r and r.id then
            _indexRecipe(self, r)
            count = count + 1
        end
    end

    _emitRefreshed(self, count)
    return count
end

function RecipeRegistry:RefreshFromActiveDatasets()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then self:Clear(); _emitRefreshed(self, 0); return 0 end
    local names = (DB.GetActiveNamesForCurrentCharacter and DB:GetActiveNamesForCurrentCharacter()) or {}
    return self:RefreshFromDatasetNames(names)
end

-- Back-compat alias
function RecipeRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

return RecipeRegistry
