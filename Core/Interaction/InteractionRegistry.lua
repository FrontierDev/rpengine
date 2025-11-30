-- RPE/Core/InteractionRegistry.lua
-- Read-only runtime index of Interactions, rebuilt from ACTIVE datasets.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Interaction = assert(RPE.Core.Interaction, "Interaction.lua must be loaded before InteractionRegistry")

---@class InteractionRegistry
---@field _map table<string, Interaction>
---@field _onRefresh fun(count:number)[]|nil
---@field _seeded boolean|nil
local InteractionRegistry = {}
InteractionRegistry.__index = InteractionRegistry
RPE.Core.InteractionRegistry = InteractionRegistry

-- ---- internals -------------------------------------------------------------

function InteractionRegistry:Init()
    if not self._map then self._map = {} end
end

local function _indexInteraction(self, inter)
    self._map[inter.id] = inter
end

local function _emitRefreshed(self, count)
    if self._onRefresh then
        for _, fn in ipairs(self._onRefresh) do pcall(fn, count) end
    end
end

-- ---- public API ------------------------------------------------------------

function InteractionRegistry:Clear()
    self._map = {}
end

function InteractionRegistry:OnRefreshed(cb)
    if type(cb) ~= "function" then return end
    self._onRefresh = self._onRefresh or {}
    table.insert(self._onRefresh, cb)
end

---@param id string
---@return Interaction|nil
function InteractionRegistry:Get(id)
    self:Init()
    return self._map[id]
end

function InteractionRegistry:All()
    self:Init()
    return self._map
end

---Find all interactions that match an NPC by id or title.
---@param npcId string|number
---@param npcTitle string|nil
---@return Interaction[]
function InteractionRegistry:GetForNPC(npcId, npcTitle)
    self:Init()
    local out = {}
    for _, inter in pairs(self._map) do
        if inter:Matches(npcId, npcTitle) then
            table.insert(out, inter)
        end
    end
    return out
end

function InteractionRegistry:Dump()
    self:Init()
    for id, inter in pairs(self._map) do
    end
end

-- ---- dataset rebuild -------------------------------------------------------

local function _interactionsBucket(ds)
    if not ds or not ds.extra then return nil end
    return ds.extra["interactions"]
end

---@param ds table|nil
function InteractionRegistry:RefreshFromDataset(ds)
    self:Init()
    self:Clear()

    local bucket = _interactionsBucket(ds)
    local count = 0
    if type(bucket) == "table" then
        for id, def in pairs(bucket) do
            local ok, inter = pcall(RPE.Core.Interaction.FromTable, type(def) == "table" and (function()
                local t = {}; for k,v in pairs(def) do t[k] = v end; t.id = t.id or id; return t end)() or { id = id })
            if ok and inter and inter.id then
                _indexInteraction(self, inter)
                count = count + 1
            end
        end
    end

    _emitRefreshed(self, count)
    return count
end

---@param datasetNames string[]|nil
function InteractionRegistry:RefreshFromDatasetNames(datasetNames)
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
        local bucket = _interactionsBucket(ds)
        if type(bucket) == "table" then
            for id, def in pairs(bucket) do
                merged[id] = def  -- later datasets override earlier ones
            end
        end
    end

    local count = 0
    for id, def in pairs(merged) do
        local t = {}; for k,v in pairs(def) do t[k] = v end; t.id = t.id or id
        local ok, inter = pcall(RPE.Core.Interaction.FromTable, t)
        if ok and inter and inter.id then
            _indexInteraction(self, inter)
            count = count + 1
        end
    end

    _emitRefreshed(self, count)
    return count
end

function InteractionRegistry:RefreshFromActiveDatasets()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then
        self:Clear()
        self:SeedDefaults(true)
        _emitRefreshed(self, 1)
        return 1
    end

    local names = (DB.GetActiveNamesForCurrentCharacter and DB:GetActiveNamesForCurrentCharacter()) or {}
    local count = self:RefreshFromDatasetNames(names)

    -- fallback: seed defaults if no datasets or empty
    if count == 0 then
        -- self:SeedDefaults(true)
        -- count = 1
    end

    return count
end


function InteractionRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

-- ---- default seed ----------------------------------------------------------

--[[
function InteractionRegistry:SeedDefaults(force)
    if self._seeded and not force then return end
    self._seeded = true
    self:Init()
    self:Clear()

    local I = RPE.Core.Interaction
    local defaults = {
        I:New(RPE.Common:GenerateGUID("ixn"), "31146", {
            options = {
                { label = "Talk", action = "DIALOGUE", },
                { label = "Trade", action = "SHOP", },
                {
                    label = "Train Blacksmithing",
                    action = "TRAIN",
                    args = {
                        type = "RECIPES",
                        maxLevel = 50,
                        profession = "Blacksmithing"
                    }
                },
                { label = "Auction House", action = "AUCTION", },                
            },
        }),
        I:New(RPE.Common:GenerateGUID("ixn"), "52031", {
            options = {
                {
                    label = "Ink Store",
                    action = "SHOP",
                    args = {
                        tags = { "ink" },
                        maxRarity = "epic",
                        maxStock = "inf",
                        matchAll = false,
                    }
                },
            }
        }),
        I:New(RPE.Common:GenerateGUID("ixn"), "8383", {
            options = {
                {
                    label = "Warrior Trainer",
                    action = "TRAIN",
                    args = {
                        type = "SPELLS",
                        maxLevel = 60,
                        tags = { "Warrior" }
                    }
                },
            },
        }),
        I:New(RPE.Common:GenerateGUID("ixn"), "type:beast", {
            options = {
                { label = "Skin", description = "Attempt to skin the leather or hide off this creature.", action = "SKIN", mapID = { 37 }, output = { { itemId = "i-123456", qty = "1d3", chance = 1 }, { itemId = "i-7890", qty = "1d2", chance = 0.1 }   } },            
            },
        }),
        I:New(RPE.Common:GenerateGUID("ixn"), "type:humanoid", {
            options = {
                { label = "Salvage", description = "Attempt to obtain cloth from this creature.", action = "SALVAGE", requiresDead = true, mapID = { 37 }, output = { { itemId = "i-123456", qty = "1d3", chance = 1 }, { itemId = "i-7890", qty = "1d2", chance = 0.1 }   } },                        
            },
        }),
        I:New(RPE.Common:GenerateGUID("ixn"), "type:humanoid", {
            options = {
                { label = "Raise Dead", description = "...", action = "RAISE", requiresDead = true, },                        
            },
        }),
    }

    for _, inter in ipairs(defaults) do
        _indexInteraction(self, inter)
    end

    _emitRefreshed(self, #defaults)
    return #defaults
end

InteractionRegistry:SeedDefaults(true)
--]]

return InteractionRegistry
