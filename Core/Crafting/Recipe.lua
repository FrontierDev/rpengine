-- RPE/Core/Recipe.lua
-- Lightweight recipe object. References items by *item id* only.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Common       = RPE.Common or {}
local ItemRegistry = RPE.Core.ItemRegistry  -- optional at runtime

---@class Recipe
---@field id string
---@field name string
---@field profession string
---@field category string|nil
---@field skill number|nil
---@field quality string|number|nil
---@field outputItemId string
---@field outputQty number
---@field tools string[]|nil
---@field reagents table[]|nil
---@field optional table[]|nil
---@field cost table<string, number>|nil   -- e.g. { Copper = 1345, ["i-3567"] = 1 }
---@field tags string[]|nil   -- e.g. { "rare", "consumable", "food" }
local Recipe = {}
Recipe.__index = Recipe
RPE.Core.Recipe = Recipe

-- Normalize quality to your Common.QualityColors keys
local function _qualityKey(q)
    if q == nil then return nil end
    if type(q) == "string" then return q:lower() end
    local map = { [0]="common", [1]="common", [2]="uncommon", [3]="rare", [4]="epic", [5]="legendary" }
    return map[tonumber(q) or 1] or "common"
end

local function _copyArray(tbl)
    local out = {}
    for i, v in ipairs(tbl or {}) do
        if type(v) == "table" then
            local t = {}
            for k2, v2 in pairs(v) do t[k2] = v2 end
            out[i] = t
        else
            out[i] = v
        end
    end
    return out
end

local function _copyTable(tbl)
    local out = {}
    for k, v in pairs(tbl or {}) do out[k] = v end
    return out
end

---@param id string
---@param name string
---@param profession string
---@param outputItemId string
---@param opts table|nil
function Recipe:New(id, name, profession, outputItemId, opts)
    assert(type(id) == "string" and id ~= "", "Recipe: id required")
    assert(type(name) == "string" and name ~= "", "Recipe: name required")
    assert(type(profession) == "string" and profession ~= "", "Recipe: profession required")
    assert(type(outputItemId) == "string" and outputItemId ~= "", "Recipe: outputItemId required")

    opts = opts or {}

    local o = setmetatable({
        id           = id,
        name         = name,
        profession   = profession,
        category     = opts.category or nil,
        skill        = tonumber(opts.skill) or nil,
        quality      = _qualityKey(opts.quality),
        outputItemId = outputItemId,
        outputQty    = tonumber(opts.outputQty) or 1,
        tools        = _copyArray(opts.tools or {}),
        reagents     = _copyArray(opts.reagents or {}),
        optional     = _copyArray(opts.optional or {}),
        cost         = _copyTable(opts.cost or {}),   -- 💰 new cost table
        tags         = _copyArray(opts.tags or {}),   -- 🏷️ recipe tags for categorization
    }, self)
    return o
end

-- Factory from raw table (dataset entry)
function Recipe.FromTable(t)
    assert(type(t) == "table", "Recipe.FromTable: table required")
    local id           = assert(t.id, "Recipe.FromTable: id required")
    local name         = t.name or id
    local profession   = assert(t.profession or t.prof, "Recipe.FromTable: profession required")
    local outputItemId = assert(t.outputItemId or t.output or t.item, "Recipe.FromTable: outputItemId required")

    return Recipe:New(
        id, name, profession, outputItemId,
        {
            category  = t.category,
            skill     = t.skill or t.reqSkill,
            quality   = t.quality,
            outputQty = t.outputQty or t.qty or 1,
            tools     = t.tools,
            reagents  = t.reagents or t.mats,
            optional  = t.optional or t.opt,
            cost      = t.cost, -- directly accept cost table
            tags      = t.tags, -- recipe tags
        }
    )
end

function Recipe:ToTable()
    return {
        id           = self.id,
        name         = self.name,
        profession   = self.profession,
        category     = self.category,
        skill        = self.skill,
        quality      = self.quality,
        outputItemId = self.outputItemId,
        outputQty    = self.outputQty,
        tools        = _copyArray(self.tools),
        reagents     = _copyArray(self.reagents),
        optional     = _copyArray(self.optional),
        cost         = _copyTable(self.cost),
        tags         = _copyArray(self.tags),
    }
end

-- Convenience: resolve output item from the registry (if present)
function Recipe:GetOutputItem()
    if not ItemRegistry or not ItemRegistry.Get then return nil end
    return ItemRegistry:Get(self.outputItemId)
end

-- Pretty name (quality colored if provided)
function Recipe:GetDisplayName()
    local q = self.quality and _qualityKey(self.quality) or nil
    if q and Common and Common.ColorByQuality then
        return Common:ColorByQuality(self.name, q)
    end
    return self.name
end

-- === Cost formatting =========================================================
---Returns a formatted cost string (gold/silver/copper + item icons)
---@return string
function Recipe:GetFormattedCost()
    if not self.cost or next(self.cost) == nil then
        return "|cffaaaaaaNo cost|r"
    end

    local parts = {}

    -- Monetary part
    local copper = tonumber(self.cost.Copper or self.cost.copper or 0)
    if copper > 0 and Common and Common.FormatCopper then
        table.insert(parts, Common:FormatCopper(copper))
    end

    -- Item cost part
    for key, qty in pairs(self.cost) do
        if key ~= "Copper" and key ~= "copper" then
            local count = tonumber(qty) or 1
            local icon = ""
            if ItemRegistry and ItemRegistry.Get then
                local item = ItemRegistry:Get(key)
                if item and item.icon then
                    icon = ("|T%s:12:12|t"):format(item.icon)
                end
            end
            local name = (ItemRegistry and ItemRegistry.Get and ItemRegistry:Get(key))
                and (ItemRegistry:Get(key).name or key)
                or key
            table.insert(parts, string.format("%s %d", icon, count))
        end
    end

    return table.concat(parts, "  ")
end

return Recipe
