-- RPE/Core/Item.lua
-- Base Item definition (core, non-UI)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@alias ItemCategory "CONSUMABLE"|"EQUIPMENT"|"MATERIAL"|"QUEST"|"MISC"

---@class Item
---@field id string
---@field name string
---@field category ItemCategory
---@field icon string|number|nil
---@field stackable boolean|false
---@field maxStack number|1
---@field description string|nil
---@field rarity string|nil  -- e.g. "common"|"uncommon"|"rare"|"epic"|"legendary"
---@field data table         -- arbitrary extensions (e.g., stat rolls, charges)
---@field itemLevel number|nil
---@field basePriceU number|0          -- Base value in economy units (1u = 4 copper)
---@field vendorSellable boolean|false -- Whether this item can appear in vendor shops
---@field priceOverrideC number|0      -- Explicit price override in copper (if >0, overrides base price)
---@field tags string[]|nil
local Item = {}
Item.__index = Item
RPE.Core.Item = Item

local Common = _G.RPE and _G.RPE.Common

-- ===== Utils =====
local function deepcopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = deepcopy(v)
        else
            out[k] = v
        end
    end
    return out
end

local function normalize_stack(o)
    if not o.stackable then
        o.maxStack = 1
    else
        o.maxStack = math.max(1, tonumber(o.maxStack or 1) or 1)
    end
end

-- ===== Ctor =====
--- Create a new item.
---@param id string
---@param name string
---@param category ItemCategory
---@param opts table|nil  -- { icon, stackable, maxStack, description, rarity, data, itemLevel }
---@return Item
function Item:New(id, name, category, opts)
    -- Local helpers
    local function trim(s)
        if type(s) ~= "string" then return "" end
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    local function genId()
        local CommonLocal = _G.RPE and _G.RPE.Common
        if CommonLocal and CommonLocal.GenerateGUID then
            return CommonLocal:GenerateGUID("item")
        end
        return ("item-%04x%04x"):format(math.random(0x1000, 0xFFFF), math.random(0x1000, 0xFFFF))
    end
    local function logOnce(msg)
        if msg then print("|cffd1ff52[RPE]|r " .. msg) end
    end

    opts = type(opts) == "table" and opts or {}

    local sane = {
        id              = trim(id),
        name            = trim(name),
        category        = trim(category),
        icon            = opts.icon,                 -- may be number or string
        stackable       = not not opts.stackable,    -- boolean
        maxStack        = tonumber(opts.maxStack) or 1,
        description     = opts.description,
        rarity          = tostring(opts.rarity or "common"),
        data            = opts.data and deepcopy(opts.data) or {},
        itemLevel       = tonumber(opts.itemLevel) or nil,
        basePriceU      = tonumber(opts.basePriceU) or 0,
        vendorSellable  = opts.vendorSellable and true or false,
        priceOverrideC  = tonumber(opts.priceOverrideC) or 0,
        tags            = type(opts.tags) == "table" and opts.tags or {},
    }

    -- ID
    if sane.id == "" then
        sane.id = genId()
        logOnce("Missing item id; generated " .. sane.id)
    end

    -- Name
    if sane.name == "" then
        sane.name = sane.id
        logOnce("Missing item name; defaulted to id '" .. sane.id .. "'")
    end

    -- Category
    if sane.category == "" then
        sane.category = "MISC"
        logOnce("Missing item category; defaulted to MISC")
    end

    -- Rarity (validate)
    local validRarity = { common=true, uncommon=true, rare=true, epic=true, legendary=true }
    if not validRarity[sane.rarity] then
        sane.rarity = "common"
        logOnce("Invalid rarity; defaulted to common")
    end

    -- Icon (default to question-mark if missing/falsey)
    if not sane.icon or sane.icon == "" then
        sane.icon = 134400 -- Interface\\ICONS\\INV_Misc_QuestionMark.blp
    end

    -- Stack normalization
    sane.maxStack = math.max(1, math.floor(tonumber(sane.maxStack) or 1))

    local o = setmetatable(sane, self)
    normalize_stack(o)
    return o
end


-- ===== Basic info =====
function Item:ToString()
    return ("Item[%s] %s (%s)"):format(self.id, self.name, self.category)
end

--- Lightweight validity check.
---@return boolean ok, string|nil err
function Item:Validate()
    if type(self.id) ~= "string" or self.id == "" then return false, "invalid id" end
    if type(self.name) ~= "string" or self.name == "" then return false, "invalid name" end
    if type(self.category) ~= "string" or self.category == "" then return false, "invalid category" end
    if self.stackable and (type(self.maxStack) ~= "number" or self.maxStack < 1) then
        return false, "invalid maxStack"
    end
    return true
end

-- ===== Stack helpers =====
function Item:IsStackable() return self.stackable end
function Item:GetStackLimit() return self.stackable and (self.maxStack or 1) or 1 end

---@param other Item
---@param opts table|nil  -- { matchData=true|false }
function Item:CanStackWith(other, opts)
    if not other or getmetatable(other) ~= Item then return false end
    if not (self.stackable and other.stackable) then return false end
    if self.id ~= other.id then return false end
    opts = opts or { matchData = true }
    if opts.matchData == false then return true end

    local a, b = self.data or {}, other.data or {}
    for k, v in pairs(a) do
        if b[k] ~= v then return false end
    end
    for k, v in pairs(b) do
        if a[k] ~= v then return false end
    end
    return true
end

-- ===== Equality / cloning =====
---@param other Item
---@param opts table|nil  -- { matchData=true|false }
function Item:Equals(other, opts)
    if not other or getmetatable(other) ~= Item then return false end
    if self.id ~= other.id or self.category ~= other.category then return false end
    opts = opts or { matchData = true }
    if opts.matchData == false then return true end
    return self:CanStackWith(other, { matchData = true })
end

--- Clone this item (deep copies `data` by default).
---@param deep boolean|nil
---@return Item
function Item:Clone(deep)
    local copy = setmetatable({
        id          = self.id,
        name        = self.name,
        category    = self.category,
        icon        = self.icon,
        stackable   = self.stackable,
        maxStack    = self.maxStack,
        description = self.description,
        rarity      = self.rarity,
        data        = deep ~= false and deepcopy(self.data) or (self.data or {}),
        itemLevel   = self.itemLevel,
    }, Item)
    return copy
end

-- ===== Data helpers =====
function Item:SetDataKey(key, value)
    self.data = self.data or {}
    self.data[key] = value
    return self
end

function Item:GetDataKey(key, default)
    local d = self.data or {}
    local v = d[key]
    if v == nil then return default end
    return v
end

function Item:MergeData(t, overwrite)
    if type(t) ~= "table" then return self end
    self.data = self.data or {}
    local over = (overwrite ~= false)
    for k, v in pairs(t) do
        if over or self.data[k] == nil then
            self.data[k] = v
        end
    end
    return self
end

function Item:SetIcon(path)        self.icon = path; return self end
function Item:SetDescription(desc) self.description = desc; return self end
function Item:SetRarity(r)         self.rarity = r; return self end
function Item:SetStackable(s, max)
    self.stackable = not not s
    if max ~= nil then self.maxStack = max end
    normalize_stack(self)
    return self
end

-- ===== Serialization =====
function Item:Serialize()
    return {
        id          = self.id,
        name        = self.name,
        category    = self.category,
        icon        = self.icon,
        stackable   = self.stackable,
        maxStack    = self.maxStack,
        description = self.description,
        rarity      = self.rarity,
        data        = self.data and deepcopy(self.data) or nil,
        itemLevel   = self.itemLevel,
        basePriceU      = self.basePriceU,
        vendorSellable  = self.vendorSellable,
        priceOverrideC  = self.priceOverrideC,
        tags            = self.tags and deepcopy(self.tags) or nil,
    }
end

---@param t table
---@return Item
function Item.FromTable(t)
    assert(type(t) == "table", "Item.FromTable expects table")
    return Item:New(
        t.id, t.name, t.category,
        {
            icon        = t.icon,
            stackable   = t.stackable,
            maxStack    = t.maxStack,
            description = t.description,
            rarity      = t.rarity,
            data        = t.data,
            itemLevel   = t.itemLevel,
            basePriceU      = t.basePriceU,
            vendorSellable  = t.vendorSellable,
            priceOverrideC  = t.priceOverrideC,
            tags            = t.tags,
        }
    )
end

--- Calculate the cost of this item in copper.
--- If priceOverrideC > 0, that is used directly.
--- Otherwise: basePriceU * 4 * (itemLevel or rarity modifier)
---@return number priceC -- final cost in copper
function Item:GetPrice()
    local unitToCopper = 4
    local baseU = tonumber(self.basePriceU) or 0
    local ilvl = tonumber(self.itemLevel) or 1

    -- Direct override
    if self.priceOverrideC and self.priceOverrideC > 0 then
        return math.floor(self.priceOverrideC)
    end

    local price = baseU * unitToCopper

    if ilvl > 1 then
        -- Scale linearly by item level
        price = price * ilvl
    else
        -- Scale by rarity if no item level
        local rarityMult = ({
            common    = 1.0,
            uncommon  = 1.2,
            rare      = 1.5,
            epic      = 2.0,
            legendary = 3.0,
        })[self.rarity or "common"] or 1.0

        price = price * rarityMult
    end

    return math.floor(price)
end

function Item:ShowTooltip()
    -- Build a tooltip spec the renderer can consume.
    local spec = {
        title = Common and Common.ColorByQuality and Common:ColorByQuality(self.name or "Item", self.rarity) or (self.name or "Item"),
        lines = {}
    }

    local lines = spec.lines

    if self.itemLevel and RPE.ActiveRules:Get("show_item_level") == 1 and self.category == "EQUIPMENT" then
        local itemLevel = "Item Level "..tostring(self.itemLevel)
        table.insert(lines, { text = itemLevel, r = 1, g = 1, b = 0, wrap = false })
    elseif self.category == "MATERIAL" then
        table.insert(lines, { text = "Crafting Reagent", r = 0, g = 0.66, b = 0.66, wrap = false })
    elseif self.category == "QUEST" then
        table.insert(lines, { text = "Quest Item", r = 1, g = 1, b = 1, wrap = false })
    end

    -- Category line (weapon/armor/accessory)
    if self.data and self.data.hand and self.data.weaponType then
        table.insert(lines, { left = self.data.hand, right = self.data.weaponType, r = 1, g = 1, b = 1, wrap = false })
    elseif self.data and self.data.armorType and self.data.armorMaterial then
        table.insert(lines, { left = self.data.armorType, right = self.data.armorMaterial, r = 1, g = 1, b = 1, wrap = false })
    elseif self.data and self.data.accessoryType then
        table.insert(lines, { text = self.data.accessoryType, r = 1, g = 1, b = 1, wrap = false })
    end

    -- Weapon damage + swing cost
    if self.data and self.data.minDamage and self.data.maxDamage and self.data.damageSchool and self.data.swingCost then
        local damageRange = string.format("%d - %d damage", self.data.minDamage, self.data.maxDamage)
        table.insert(lines, { left = damageRange, right = tostring(self.data.swingCost), r = 1, g = 1, b = 1, wrap = false })
    end

    -- ==== Stats ====
    local statLines = {}
    for k, v in pairs(self.data or {}) do
        if type(k) == "string" and k:match("^stat_") then
            local statId = k:gsub("^stat_", "")
            local stat = RPE.Stats and RPE.Stats.Get and RPE.Stats:Get(statId)
            if stat then
                local formatted = stat.FormatForItemTooltip and stat:FormatForItemTooltip(v)
                if formatted and formatted ~= "" then
                    local r, g, b, a = 1, 1, 1, 1
                    if stat.GetItemTooltipColor then
                        local R, G, B, A = stat:GetItemTooltipColor()
                        r = R or r; g = G or g; b = B or b; a = A or a
                    end

                    local priority = stat.itemTooltipPriority or 0

                    -- Check allow_* lists in active rules
                    local allowed = false
                    local rules = RPE.ActiveRules and RPE.ActiveRules.rules
                    if rules then
                        for key, list in pairs(rules) do
                            if type(key) == "string" and key:match("^allow_") then
                                if type(list) == "table" then
                                    for _, allowedId in ipairs(list) do
                                        if allowedId == statId then allowed = true break end
                                    end
                                elseif type(list) == "string" then
                                    for allowedId in list:gmatch("([^,%s]+)") do
                                        if allowedId == statId then allowed = true break end
                                    end
                                end
                            end
                            if allowed then break end
                        end
                    end

                    if not allowed then
                        r, g, b, a = 0.5, 0.5, 0.5, 1
                        priority = priority * 0.5
                    end

                    table.insert(statLines, { priority = priority, text = formatted, r = r, g = g, b = b, a = a })
                end
            end
        end
    end

    table.sort(statLines, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
    for _, s in ipairs(statLines) do
        table.insert(lines, { text = s.text, r = s.r, g = s.g, b = s.b, wrap = false })
    end

    -- Spacer --
    table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })

    -- ==== Sockets ====
    if self.data then
        local socketTypes = {
            { key = "red_sockets",    icon = Common.InlineIcons.Socket_Red,    label = "Red Socket" },
            { key = "blue_sockets",   icon = Common.InlineIcons.Socket_Blue,   label = "Blue Socket" },
            { key = "yellow_sockets", icon = Common.InlineIcons.Socket_Yellow, label = "Yellow Socket" },
            { key = "meta_sockets",   icon = Common.InlineIcons.Socket_Meta,   label = "Meta Socket" },
            { key = "cog_sockets",    icon = Common.InlineIcons.Socket_Cog,    label = "Cogwheel Socket" },
        }

        for _, st in ipairs(socketTypes) do
            local count = tonumber(self.data[st.key]) or 0
            for i = 1, count do
                table.insert(lines, {
                    text = st.icon .. " " .. st.label,
                    r = 1, g = 1, b = 1, wrap = false
                })
            end
        end
    end

    -- ==== Economy ====
    local priceC = self:GetPrice()
    if priceC and priceC > 0 then
        local formatted = Common and Common.FormatCopper and Common:FormatCopper(priceC) or (tostring(priceC) .. "c")
        table.insert(lines, { text = "Market Price: " .. formatted, r = 1, g = 1, b = 1, wrap = false })
    end

    -- ==== Item not in dataset ====
    if self.id then
        local reg = RPE.Core and RPE.Core.ItemRegistry
        local item = reg and reg.Get and reg:Get(self.id) or nil
        if RPE and RPE.Debug and RPE.Debug.Warning and not item then
            RPE.Debug:Warning("Item not available in active datasets; cannot equip or use.")
        end
    end

    return spec
end

return Item
