-- RPE/Core/Item.lua
-- Base Item definition (core, non-UI)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@alias ItemCategory "CONSUMABLE"|"EQUIPMENT"|"MATERIAL"|"QUEST"|"MISC"|"MODIFICATION"

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
        spellId = (opts.spellId and opts.spellId ~= "") and opts.spellId or nil,  -- spell to cast when consumed (string or number)
        spellRank = tonumber(opts.spellRank) or nil,  -- rank of spell to cast
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
        spellId = self.spellId,
        spellRank = self.spellRank,
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
            spellId = t.spellId,
            spellRank = t.spellRank,
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

function Item:ShowTooltip(instanceGuid)
    -- Build a tooltip spec the renderer can consume.
    -- instanceGuid: optional instance GUID for this item (used for retrieving instance-specific modifications)
    local spec = {
        title = Common and Common.ColorByQuality and Common:ColorByQuality(self.name or "Item", self.rarity) or (self.name or "Item"),
        lines = {}
    }

    local lines = spec.lines

    -- For MODIFICATION items, show socket type (for gems), stats, and description
    if self.category == "MODIFICATION" then
        -- Check if this is a gem by looking for the "gem" tag
        local isGem = false
        if self.tags then
            for _, tag in ipairs(self.tags) do
                if tag == "gem" then
                    isGem = true
                    break
                end
            end
        end
        
        -- For gems, show socket type in grey text (like spell ranks)
        if isGem and self.data and self.data.socket_type then
            local socketType = self.data.socket_type
            
            -- Split by comma and title case each part
            local parts = {}
            for part in socketType:gmatch("[^,]+") do
                local trimmed = part:match("^%s*(.-)%s*$")  -- trim whitespace
                if trimmed ~= "" then
                    -- Title case: capitalize first letter, lowercase the rest
                    local titleCased = trimmed:sub(1, 1):upper() .. trimmed:sub(2):lower()
                    table.insert(parts, titleCased)
                end
            end
            
            if #parts > 0 then
                local formatted = table.concat(parts, "/")
                table.insert(lines, {
                    text = formatted .. " Gem",
                    r = 0.7, g = 0.7, b = 0.7,  -- grey, like spell ranks
                    wrap = false
                })
            end
        end

        -- Show stats from the modification (only for gems)
        if isGem then
            local statLines = {}
            for k, v in pairs(self.data or {}) do
                if type(k) == "string" and k:match("^stat_") then
                    local statId = k:gsub("^stat_", "")
                    local stat = RPE.Stats and RPE.Stats.Get and RPE.Stats:Get(statId)
                    if stat then
                        local formatted = stat.FormatForItemTooltip and stat:FormatForItemTooltip(v)
                        if formatted and formatted ~= "" then
                            -- Support $value_pct$ token: convert decimal to percentage (0.1 → +10%)
                            formatted = formatted:gsub("%$value_pct%$", function()
                                local pctValue = tonumber(v)
                                if pctValue then
                                    return string.format("%+.0f%%", pctValue * 100)
                                end
                                return "$value_pct$"
                            end)
                            
                            local r, g, b, a = 1, 1, 1, 1
                            if stat.GetItemTooltipColor then
                                local R, G, B, A = stat:GetItemTooltipColor()
                                r = R or r; g = G or g; b = B or b; a = A or a
                            end

                            local priority = stat.itemTooltipPriority or 0

                            -- Allowed stats are determined by presence in the StatRegistry
                            local allowed = false
                            local reg = RPE.Core and RPE.Core.StatRegistry
                            if reg and reg.Get then
                                local s = reg:Get(statId)
                                if s ~= nil then allowed = true end
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

            -- Sort by priority (higher first)
            table.sort(statLines, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
            for _, s in ipairs(statLines) do
                table.insert(lines, { text = s.text, r = s.r, g = s.g, b = s.b, wrap = false })
            end
        end

        -- Description for modifications (green text for enchants/other mods)
        if self.description and self.description ~= "" then
            table.insert(lines, { text = self.description, r = 0, g = 1, b = 0, wrap = true })
            table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
        end

        table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
        if isGem and self.spellId then
            local SpellReg = RPE and RPE.Core and RPE.Core.SpellRegistry
            if SpellReg and SpellReg.Get then
                local spell = SpellReg:Get(self.spellId)
                if spell and spell.description then
                    -- Set rank override from item's spellRank
                    spell.rankOverride = self.spellRank or 1
                    local renderedDesc = spell:RenderDescription()
                    spell.rankOverride = nil
                    
                    -- Build cost string like "Use (1 bonus action, 5 mana): "
                    local costParts = {}
                    if spell.costs and #spell.costs > 0 then
                        -- Format resource costs (ACTION, BONUS_ACTION, REACTION, and custom resources)
                        local function formatResourceName(res)
                            local formatted = tostring(res):upper():gsub("_", " ")
                            formatted = formatted:gsub("(%S)(%S*)", function(first, rest)
                                return first:upper() .. rest:lower()
                            end)
                            return formatted
                        end
                        
                        local actionOnly = { ACTION = true, BONUS_ACTION = true, REACTION = true }
                        
                        for _, c in ipairs(spell.costs) do
                            local resId = string.upper(c.resource or "")
                            local formatted = formatResourceName(c.resource or "")
                            
                            -- For action economy resources, omit the amount; for others, include it
                            local text
                            if actionOnly[resId] then
                                text = formatted
                            else
                                text = tostring(c.amount or 0) .. " " .. formatted
                            end
                            table.insert(costParts, text)
                        end
                    end
                    
                    local usePrefix = "Use"
                    if #costParts > 0 then
                        usePrefix = usePrefix .. " (" .. table.concat(costParts, ", ") .. ")"
                    end
                    usePrefix = usePrefix .. ": "
                    
                    local spellText = usePrefix .. renderedDesc
                    
                    -- Append cooldown info if spell has one
                    if spell.cooldown and spell.cooldown.turns and tonumber(spell.cooldown.turns) > 0 then
                        local t = tonumber(spell.cooldown.turns) or 0
                        local cdText = (" (%d turn%s cooldown)"):format(t, (t == 1 and "" or "s"))
                        spellText = spellText .. cdText
                    end
                    
                    table.insert(lines, { text = spellText, r = 0.2, g = 1, b = 0.2, wrap = true })
                    table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
                end
            end
        end
        
        local priceC = self:GetPrice()
        if priceC and priceC > 0 then
            local formatted = Common and Common.FormatCopper and Common:FormatCopper(priceC) or (tostring(priceC) .. "c")
            table.insert(lines, { text = "Market Price: " .. formatted, r = 1, g = 1, b = 1, wrap = false })
        end
        
        return spec
    end

    if self.itemLevel and RPE.ActiveRules:Get("show_item_level") == 1 and self.category == "EQUIPMENT" then
        local baseItemLevel = self.itemLevel
        local effectiveItemLevel = baseItemLevel
        
        -- Calculate effective item level based on total stats (base + mods)
        local ItemMod = RPE.Core and RPE.Core.ItemModification
        local ItemLevelCalc = RPE.Core and RPE.Core.ItemLevel
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
        
        if ItemMod and ItemLevelCalc and profile and instanceGuid then
            local modBonuses = ItemMod:GetTotalModificationBonuses(profile, instanceGuid) or {}
            
            -- Check if there are any mod bonuses
            local hasModBonuses = false
            for _, _ in pairs(modBonuses) do
                hasModBonuses = true
                break
            end
            
            if hasModBonuses then
                -- Build a combined stat table for item level calculation
                local combinedStats = {}
                
                -- Add base stats
                for k, v in pairs(self.data or {}) do
                    if type(k) == "string" and k:match("^stat_") then
                        combinedStats[k] = (combinedStats[k] or 0) + (tonumber(v) or 0)
                    end
                end
                
                -- Add mod bonuses
                for statId, bonus in pairs(modBonuses) do
                    local key = "stat_" .. statId
                    combinedStats[key] = (combinedStats[key] or 0) + (tonumber(bonus) or 0)
                end
                
                -- Calculate effective item level
                local tempItem = { data = combinedStats, rarity = self.rarity }
                effectiveItemLevel = ItemLevelCalc:FromItem(tempItem) or baseItemLevel
            end
        end
        
        local itemLevelText
        if effectiveItemLevel ~= baseItemLevel then
            itemLevelText = "Item Level " .. tostring(baseItemLevel) .. " (" .. tostring(effectiveItemLevel) .. ")"
        else
            itemLevelText = "Item Level " .. tostring(baseItemLevel)
        end
        table.insert(lines, { text = itemLevelText, r = 1, g = 1, b = 0, wrap = false })
    elseif self.category == "MATERIAL" then
        if RPE.ActiveRules:Get("show_reagent_tiers") == 1 and self.data.tier then
            table.insert(lines, { text = "Tier " .. self.data.tier ..  " Crafting Material", r = 0, g = 0.66, b = 0.66, wrap = false })
        else
            table.insert(lines, { text = "Crafting Reagent", r = 0, g = 0.66, b = 0.66, wrap = false })
        end
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
    if self.data and self.data.minDamage and self.data.maxDamage and self.data.damageSchool then
        local damageRange = string.format("%d - %d damage", self.data.minDamage, self.data.maxDamage)
        table.insert(lines, { left = damageRange, right = tostring(self.data.swingCost or ""), r = 1, g = 1, b = 1, wrap = false })
    end

    -- ==== Stats ====
    local statLines = {}
    
    -- Get modification bonuses if available
    local modBonuses = {}
    if self.category == "EQUIPMENT" then
        local ItemMod = RPE.Core and RPE.Core.ItemModification
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
        if ItemMod and profile and instanceGuid then
            modBonuses = ItemMod:GetTotalModificationBonuses(profile, instanceGuid) or {}
        end
    end
    
    -- Collect all stat IDs from both base item and modifications
    local allStatIds = {}
    for k, v in pairs(self.data or {}) do
        if type(k) == "string" and k:match("^stat_") then
            local statId = k:gsub("^stat_", "")
            allStatIds[statId] = true
        end
    end
    for statId, _ in pairs(modBonuses) do
        allStatIds[statId] = true
    end
    
    for statId, _ in pairs(allStatIds) do
        local baseValue = tonumber(self.data["stat_" .. statId]) or 0
        local modValue = tonumber(modBonuses[statId]) or 0
        local totalValue = baseValue + modValue
        
        if totalValue ~= 0 then
            local stat = RPE.Stats and RPE.Stats.Get and RPE.Stats:Get(statId)
            if stat then
                local formatted = stat.FormatForItemTooltip and stat:FormatForItemTooltip(totalValue)
                if formatted and formatted ~= "" then
                    -- Support $value_pct$ token: convert decimal to percentage (0.1 → +10%)
                    formatted = formatted:gsub("%$value_pct%$", function()
                        local pctValue = tonumber(totalValue)
                        if pctValue then
                            return string.format("%+.0f%%", pctValue * 100)
                        end
                        return "$value_pct$"
                    end)
                    
                    local r, g, b, a = 1, 1, 1, 1
                    if stat.GetItemTooltipColor then
                        local R, G, B, A = stat:GetItemTooltipColor()
                        r = R or r; g = G or g; b = B or b; a = A or a
                    end

                    local priority = stat.itemTooltipPriority or 0

                    -- Allowed stats are determined by presence in the StatRegistry
                    local allowed = false
                    local reg = RPE.Core and RPE.Core.StatRegistry
                    if reg and reg.Get then
                        local s = reg:Get(statId)
                        if s ~= nil then allowed = true end
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

    -- Sort by priority (higher first)
    table.sort(statLines, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
    for _, s in ipairs(statLines) do
        table.insert(lines, { text = s.text, r = s.r, g = s.g, b = s.b, wrap = false })
    end

    -- ==== Sockets (with Applied Gems) ====
    local displayedGemIds = {}  -- Track which gems we display in sockets
    if self.data then
        local ItemMod = RPE.Core and RPE.Core.ItemModification
        local ItemReg = RPE.Core and RPE.Core.ItemRegistry
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
        
        -- Build a map of applied gems by socket type
        local appliedGemsBySocket = {}
        if ItemMod and profile then
            -- Use instanceGuid if provided, otherwise fall back to self.id
            local lookupId = instanceGuid or self.id
            local applied = ItemMod:GetAppliedModifications(profile, lookupId)
            for _, mod in ipairs(applied) do
                -- Look up the full item data from the registry using itemId
                local fullMod = ItemReg and ItemReg:Get(mod.itemId)
                if not fullMod then fullMod = mod end  -- fallback to the mod object itself
                
                -- Check if this is a gem
                local isGem = false
                if fullMod.tags then
                    for _, tag in ipairs(fullMod.tags) do
                        if tag == "gem" then
                            isGem = true
                            break
                        end
                    end
                end
                
                if isGem and fullMod.data and fullMod.data.socket_type then
                    -- Parse socket types and map each to the gem
                    for socketType in fullMod.data.socket_type:gmatch("[^,]+") do
                        local trimmed = socketType:match("^%s*(.-)%s*$"):lower()
                        if trimmed ~= "" then
                            appliedGemsBySocket[trimmed] = fullMod
                        end
                    end
                end
            end
        end
        
        local socketTypes = {
            { key = "red_sockets",    icon = Common.InlineIcons.Socket_Red,    label = "Red Socket",      socketName = "red" },
            { key = "blue_sockets",   icon = Common.InlineIcons.Socket_Blue,   label = "Blue Socket",     socketName = "blue" },
            { key = "yellow_sockets", icon = Common.InlineIcons.Socket_Yellow, label = "Yellow Socket",   socketName = "yellow" },
            { key = "meta_sockets",   icon = Common.InlineIcons.Socket_Meta,   label = "Meta Socket",     socketName = "meta" },
            { key = "cog_sockets",    icon = Common.InlineIcons.Socket_Cog,    label = "Cogwheel Socket", socketName = "cogwheel" },
        }

        local shownGemsInThisLoop = {}  -- Track gems we've already shown in this socket loop
        local socketSectionStarted = false  -- Track if we've added a spacer for sockets
        for _, st in ipairs(socketTypes) do
            local count = tonumber(self.data[st.key]) or 0
            local socketName = st.socketName
            local gemInSocket = appliedGemsBySocket[socketName]
            
            -- Only add spacer before the first socket section
            if (count > 0 or gemInSocket) and not socketSectionStarted then
                table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
                socketSectionStarted = true
            end
            
            -- Display the gem if one is applied (and we haven't shown it yet)
            if gemInSocket and not shownGemsInThisLoop[gemInSocket.id or gemInSocket.name] then
                local gemIcon = (type(gemInSocket.icon) == "number") and ("|T" .. gemInSocket.icon .. ":0:0:2:0|t") or tostring(gemInSocket.icon or "")
                local gemDisplay = Common and Common.ColorByQuality and Common:ColorByQuality(gemInSocket.name, gemInSocket.rarity) or gemInSocket.name
                table.insert(lines, {
                    text = gemIcon .. " " .. gemDisplay,
                    r = 1, g = 1, b = 1, wrap = false
                })
                -- Track this gem as shown in both tracking systems
                shownGemsInThisLoop[gemInSocket.id or gemInSocket.name] = true
                displayedGemIds[gemInSocket.name] = true
                if gemInSocket.id then displayedGemIds[gemInSocket.id] = true end
            end
            
            -- Display empty sockets (only those not filled by a gem that we showed)
            local gemShownForThisSocket = gemInSocket and not not shownGemsInThisLoop[gemInSocket.id or gemInSocket.name]
            local startIndex = gemShownForThisSocket and 2 or 1
            for i = startIndex, count do
                table.insert(lines, {
                    text = st.icon .. " " .. st.label,
                    r = 1, g = 1, b = 1, wrap = false
                })
            end
        end
    end

    -- Store displayedGemIds in the object so we can access it later
    self._displayedGemIds = displayedGemIds

    -- ==== Applied Modifications (non-gem) ====
    -- Show non-gem modifications (enchants, etc.) grouped by primary tag
    if self.category == "EQUIPMENT" then
        local ItemMod = RPE.Core and RPE.Core.ItemModification
        local ItemReg = RPE.Core and RPE.Core.ItemRegistry
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
        
        if ItemMod and profile then
            -- Use instanceGuid if provided, otherwise fall back to self.id
            local lookupId = instanceGuid or self.id
            local applied = ItemMod:GetAppliedModifications(profile, lookupId)
            local displayedGemIds = self._displayedGemIds or {}
            
            -- Group non-gem modifications by their primary tag
            local modsByTag = {}
            local tagOrder = {}  -- to preserve insertion order
            
            for _, mod in ipairs(applied) do
                -- Look up the full item data from the registry using itemId
                local fullMod = ItemReg and ItemReg:Get(mod.itemId)
                if not fullMod then fullMod = mod end  -- fallback to the mod object itself
                
                -- Skip if we already displayed this gem in the sockets section
                if displayedGemIds[fullMod.name] or displayedGemIds[fullMod.id] then
                    -- Skip this gem, it was already displayed in sockets
                else
                    local isGem = false
                    if fullMod.tags then
                        for _, tag in ipairs(fullMod.tags) do
                            if tag == "gem" then
                                isGem = true
                                break
                            end
                        end
                    end
                    
                    if not isGem then
                        -- Get primary tag (first tag, or "other" if no tags)
                        local primaryTag = (fullMod.tags and fullMod.tags[1]) or "other"
                        
                        if not modsByTag[primaryTag] then
                            modsByTag[primaryTag] = {}
                            table.insert(tagOrder, primaryTag)
                        end
                        table.insert(modsByTag[primaryTag], fullMod)
                    end
                end
            end
            
            -- Display mods grouped by tag with spacing between groups
            for i, tag in ipairs(tagOrder) do
                local mods = modsByTag[tag]
                if #mods > 0 then
                    -- Add spacer before this group
                    table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
                    
                    for _, mod in ipairs(mods) do
                        -- Show modification icon and name with rarity coloring
                        local modIcon = (type(mod.icon) == "number") and ("|T" .. mod.icon .. ":0:0:2:0|t") or tostring(mod.icon or "")
                        local modDisplay = Common and Common.ColorByQuality and Common:ColorByQuality(mod.name, mod.rarity) or mod.name
                        table.insert(lines, { text = modIcon .. " " .. modDisplay, r = 1, g = 1, b = 1, wrap = true })
                    end
                end
            end
            
            -- Add trailing spacer if we displayed any mods
            if #tagOrder > 0 then
                table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
            end
        end
    end

    -- ==== Consumable Spell ====
    if self.spellId then
        local SpellReg = RPE and RPE.Core and RPE.Core.SpellRegistry
        if SpellReg and SpellReg.Get then
            local spell = SpellReg:Get(self.spellId)
            if spell and spell.description then
                -- Set rank override from item's spellRank
                spell.rankOverride = self.spellRank or 1
                local renderedDesc = spell:RenderDescription()
                spell.rankOverride = nil
                
                -- Build cost string like "Use (1 bonus action, 5 mana): "
                local costParts = {}
                if spell.costs and #spell.costs > 0 then
                    -- Format resource costs (ACTION, BONUS_ACTION, REACTION, and custom resources)
                    local function formatResourceName(res)
                        local formatted = tostring(res):upper():gsub("_", " ")
                        formatted = formatted:gsub("(%S)(%S*)", function(first, rest)
                            return first:upper() .. rest:lower()
                        end)
                        return formatted
                    end
                    
                    local actionOnly = { ACTION = true, BONUS_ACTION = true, REACTION = true }
                    
                    for _, c in ipairs(spell.costs) do
                        local resId = string.upper(c.resource or "")
                        local formatted = formatResourceName(c.resource or "")
                        
                        -- For action economy resources, omit the amount; for others, include it
                        local text
                        if actionOnly[resId] then
                            text = formatted
                        else
                            text = tostring(c.amount or 0) .. " " .. formatted
                        end
                        table.insert(costParts, text)
                    end
                end
                
                local usePrefix = "Use"
                if #costParts > 0 then
                    usePrefix = usePrefix .. " (" .. table.concat(costParts, ", ") .. ")"
                end
                usePrefix = usePrefix .. ": "
                
                local spellText = usePrefix .. renderedDesc
                
                -- Append cooldown info if spell has one
                if spell.cooldown and spell.cooldown.turns and tonumber(spell.cooldown.turns) > 0 then
                    local t = tonumber(spell.cooldown.turns) or 0
                    local cdText = (" (%d turn%s cooldown)"):format(t, (t == 1 and "" or "s"))
                    spellText = spellText .. cdText
                end
                
                table.insert(lines, { text = spellText, r = 0.2, g = 1, b = 0.2, wrap = true })
                table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
            end
        end
    end

    -- ==== Description ====
    if self.description and self.description ~= "" then
        local descColor = self.category == "MODIFICATION" and { r = 0, g = 1, b = 0 } or { r = 1, g = 1, b = 0 }
        table.insert(lines, { text = self.description, r = descColor.r, g = descColor.g, b = descColor.b, wrap = true })
        table.insert(lines, { text = " ", r = 1, g = 1, b = 1, wrap = false })
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
