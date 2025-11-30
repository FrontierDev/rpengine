-- RPE_UI/Windows/ShopWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window     = RPE_UI.Elements.Window
local Panel      = RPE_UI.Elements.Panel
local TextBtn    = RPE_UI.Elements.TextButton
local Text       = RPE_UI.Elements.Text
local VGroup     = RPE_UI.Elements.VerticalLayoutGroup
local HGroup     = RPE_UI.Elements.HorizontalLayoutGroup
local IconButton = RPE_UI.Elements.IconButton
local Common     = RPE.Common or {}
local ShopItem   = RPE_UI.Prefabs and RPE_UI.Prefabs.ShopItem
local ItemReg    = RPE.Core and RPE.Core.ItemRegistry
local Colors     = RPE_UI.Colors

---@class ShopWindow
local ShopWindow = {}
_G.RPE_UI.Windows.ShopWindow = ShopWindow
ShopWindow.__index = ShopWindow
ShopWindow.Name = "ShopWindow"

local ITEMS_PER_PAGE = 12
local COLUMNS = 2
local INDICATOR_WIDTH = 50

--------------------------------------------------------------------------------
-- == HELPERS ==
--------------------------------------------------------------------------------
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.ShopWindow = self
end

-- Lerp helper
local function lerpColor(r1, g1, b1, r2, g2, b2, t)
    return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t
end

--------------------------------------------------------------------------------
-- == DATA GENERATION ==
--------------------------------------------------------------------------------
function ShopWindow:GetDailyFluctuation()
    local dateKey = date("%Y%m%d")
    local y, m, d = tonumber(dateKey:sub(1,4)), tonumber(dateKey:sub(5,6)), tonumber(dateKey:sub(7,8))
    local hash = (y * 374761393 + m * 668265263 + d * 2147483647) % 100000
    return (hash % 21) - 10 -- -10..+10
end

function ShopWindow:GetLocationModifier()
    return math.random(-10, 100)
end

function ShopWindow:GetReputationLevel()
    return math.random(-40, 40)
end

--------------------------------------------------------------------------------
-- == PRICE MULTIPLIER CALCULATION ==
--------------------------------------------------------------------------------
function ShopWindow:GetPriceMultiplier()
    local daily  = self.fluctuation or 0
    local loc    = self.locationMod or 0
    local rep    = self.reputation or 0

    local dailyMult = 1 + (daily / 100)
    local locMult   = 1 + (loc / 100)
    local repMult   = 1 - (rep / 100)

    local finalMult = dailyMult * locMult * repMult
    return finalMult, dailyMult, locMult, repMult
end

--------------------------------------------------------------------------------
-- == COLOR FUNCTIONS ==
--------------------------------------------------------------------------------
local function colorFluctuation(val)
    if val < 0 then return Colors.Get("textBonus")
    elseif val > 0 then return Colors.Get("textMalus")
    else return Colors.Get("textMuted") end
end

-- Location modifier: positive = red (bad), negative = green (good)
local function colorLocation(val)
    if val > 0 then return Colors.Get("textMalus")
    elseif val < 0 then return Colors.Get("textBonus")
    else return Colors.Get("textMuted") end
end

-- Reputation: -40 (red) → 0 (yellow) → +40 (green)
local function colorReputation(val)
    local rR, rG, rB = Colors.Get("textMalus")
    local yR, yG, yB = 0.95, 0.85, 0.35
    local gR, gG, gB = Colors.Get("textBonus")

    if val <= 0 then
        local t = (val + 40) / 40
        return lerpColor(rR, rG, rB, yR, yG, yB, t)
    else
        local t = val / 40
        return lerpColor(yR, yG, yB, gR, gG, gB, t)
    end
end

--------------------------------------------------------------------------------
-- == INDICATOR CREATION ==
--------------------------------------------------------------------------------
local function createIndicatorGroup(parent, name, iconPath)
    local group = HGroup:New("RPE_Shop_" .. name .. "Group", {
        parent = parent,
        spacingX = 4,
        alignV = "CENTER",
        width = INDICATOR_WIDTH,
        autoSize = false,
    })
    parent:Add(group)

    local icon = IconButton:New("RPE_Shop_" .. name .. "Icon", {
        parent = group,
        width = 20, height = 20,
        icon = iconPath,
        hoverDarkenFactor = 1.0,
        hasBorder = false, noBackground = true,
    })
    group:Add(icon)

    local text = Text:New("RPE_Shop_" .. name .. "Text", {
        parent = group,
        text = "0%",
        fontTemplate = "GameFontNormal",
        justifyH = "LEFT",
    })
    group:Add(text)

    return group, icon, text
end

--------------------------------------------------------------------------------
-- == INDICATOR UPDATE ==
--------------------------------------------------------------------------------
function ShopWindow:UpdateIndicators()
    local function bind(icon, text, val, colorFn, tooltipSpec)
        local r, g, b = colorFn(val)
        text:SetText(tooltipSpec.textFunc(val))
        text:SetColor(r, g, b, 1)
        if icon and icon.icon then icon.icon:SetVertexColor(r, g, b, 1) end

        if Common and Common.ShowTooltip then
            local function showTooltip(anchor)
                Common:ShowTooltip(anchor, {
                    title = tooltipSpec.title,
                    titleColor = { r, g, b },
                    lines = tooltipSpec.linesFunc(val),
                })
            end
            local function hideTooltip()
                if GameTooltip then GameTooltip:Hide() end
            end
            icon.frame:SetScript("OnEnter", function() showTooltip(icon.frame) end)
            icon.frame:SetScript("OnLeave", hideTooltip)
            text.frame:SetScript("OnEnter", function() showTooltip(text.frame) end)
            text.frame:SetScript("OnLeave", hideTooltip)
        end
    end

    bind(self.fluctIcon, self.fluctText, self.fluctuation, colorFluctuation, {
        title = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\chart.png:16:16|t Daily Market Fluctuation",
        textFunc = function(v) return string.format("%+d%%", v) end,
        linesFunc = function(v)
            local sign = v > 0 and "increased" or (v < 0 and "decreased" or "remained stable")
            return {
                { left = string.format("Shop prices have %s by %d%% today.", sign, math.abs(v)) },
                { left = "Resets daily.", r = 0.7, g = 0.7, b = 0.7 },
            }
        end,
    })

    bind(self.locIcon, self.locText, self.locationMod, colorLocation, {
        title = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\world.png:16:16|t Location Modifier",
        textFunc = function(v) return string.format("%+d%%", v) end,
        linesFunc = function(v)
            local sign = v > 0 and "higher" or (v < 0 and "lower" or "average")
            return {
                { left = string.format("Local prices are %s than normal by %d%%.", sign, math.abs(v)) },
                { left = "Based on distance to trading center.", r = 0.7, g = 0.7, b = 0.7 },
            }
        end,
    })

    bind(self.repIcon, self.repText, self.reputation, colorReputation, {
        title = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\reputation.png:16:16|t Reputation",
        textFunc = function(v) return string.format("%+d", v) end,
        linesFunc = function(v)
            local standing = v >= 20 and "Friendly" or v <= -20 and "Hostile" or "Neutral"
            return {
                { left = string.format("Standing: %s", standing) },
                { left = string.format("Reputation: %+d", v), r = 0.9, g = 0.9, b = 0.9 },
            }
        end,
    })
end

--------------------------------------------------------------------------------
-- == BUILD UI ==
--------------------------------------------------------------------------------
function ShopWindow:BuildUI()
    self.root = Window:New("RPE_Shop_Window", {
        width = 420, height = 360,
        point = "CENTER",
        autoSize = true,
    })

    -- Header
    self.header = Panel:New("RPE_Shop_Header", { parent = self.root })
    self.header.frame:SetHeight(40)
    self.header.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.header.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)

    local headerGroup = HGroup:New("RPE_Shop_HeaderGroup", {
        parent = self.header,
        spacingX = 32,
        x = 12,
        alignV = "CENTER",
        autoSize = true,
    })
    headerGroup.frame:SetPoint("CENTER", self.header.frame, "CENTER", 0, 0)
    self.header:Add(headerGroup)

    -- Title
    self.titleText = Text:New("RPE_Shop_TitleText", {
        parent = headerGroup,
        text = "Shop",
        fontTemplate = "GameFontNormalLarge",
        justifyH = "CENTER",
    })
    headerGroup:Add(self.titleText)

    -- Indicators
    self.fluctGroup, self.fluctIcon, self.fluctText =
        createIndicatorGroup(headerGroup, "Fluct", "Interface\\AddOns\\RPEngine\\UI\\Textures\\chart.png")
    self.locGroup, self.locIcon, self.locText =
        createIndicatorGroup(headerGroup, "Location", "Interface\\AddOns\\RPEngine\\UI\\Textures\\world.png")
    self.repGroup, self.repIcon, self.repText =
        createIndicatorGroup(headerGroup, "Reputation", "Interface\\AddOns\\RPEngine\\UI\\Textures\\reputation.png")

    -- Initialize modifiers
    self.fluctuation = self:GetDailyFluctuation()
    self.locationMod = self:GetLocationModifier()
    self.reputation  = self:GetReputationLevel()

    -- Update indicators
    self:UpdateIndicators()

    -- Content
    self.content = Panel:New("RPE_Shop_Content", { parent = self.root, autoSize = true })
    self.content.frame:SetPoint("TOPLEFT", self.header.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 40)

    self.itemGroup = VGroup:New("RPE_Shop_ItemGroup", {
        parent = self.content,
        padding = { left = 12, right = 12, top = 8, bottom = 8 },
        spacingY = 6,
        x = 12,
        alignH = "CENTER",
        autoSize = true,
    })

    -- Footer
    self.footer = Panel:New("RPE_Shop_Footer", { parent = self.root })
    self.footer.frame:SetHeight(30)
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)

    local navGroup = HGroup:New("RPE_Shop_FooterNav", {
        parent = self.footer,
        spacingX = 10,
        alignV = "CENTER",
        alignH = "CENTER",
        autoSize = true,
    })

    self.closeBtn = TextBtn:New("RPE_Shop_CloseBtn", {
        parent = navGroup, width = 80, height = 22,
        text = "Close", onClick = function() self:Hide() end,
    })
    navGroup:Add(self.closeBtn)

    self.prevBtn = TextBtn:New("RPE_Shop_PrevBtn", {
        parent = navGroup, width = 70, height = 22,
        text = "Prev", noBorder = true, onClick = function() self:PrevPage() end,
    })
    navGroup:Add(self.prevBtn)

    self.pageText = Text:New("RPE_Shop_PageText", {
        parent = navGroup,
        text = "Page 1 / 1", fontTemplate = "GameFontNormalSmall",
    })
    navGroup:Add(self.pageText)

    self.nextBtn = TextBtn:New("RPE_Shop_NextBtn", {
        parent = navGroup, width = 70, height = 22,
        text = "Next", noBorder = true, onClick = function() self:NextPage() end,
    })
    navGroup:Add(self.nextBtn)

    -- State
    self.items = {}
    self.page = 1

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

--------------------------------------------------------------------------------
-- == PAGE + ITEM DISPLAY ==
--------------------------------------------------------------------------------
function ShopWindow:_updatePageText()
    local totalPages = math.max(1, math.ceil(#self.items / ITEMS_PER_PAGE))
    self.pageText:SetText(("Page %d / %d"):format(self.page, totalPages))
end

function ShopWindow:Refresh()
    for _, child in ipairs(self.itemGroup.children or {}) do
        if child.Destroy then child:Destroy() end
    end
    self.itemGroup.children = {}

    local finalMult = self:GetPriceMultiplier()
    local startIdx = (self.page - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(#self.items, startIdx + ITEMS_PER_PAGE - 1)
    local slice = {}

    for i = startIdx, endIdx do table.insert(slice, self.items[i]) end

    for row = 1, math.ceil(#slice / COLUMNS) do
        local rowGroup = HGroup:New("RPE_Shop_Row_" .. row, {
            parent = self.itemGroup, spacingX = 10, alignV = "CENTER", autoSize = true,
        })
        self.itemGroup:Add(rowGroup)

        for c = 1, COLUMNS do
            local idx = (row - 1) * COLUMNS + c
            local itemData = slice[idx]
            if itemData then
                local adjusted = math.floor((itemData.price or 0) * finalMult)
                local entry = ShopItem:New("RPE_ShopItem_" .. idx, {
                    parent = rowGroup,
                    itemId = itemData.id,
                    cost = Common:FormatCopper(adjusted),
                    stack = itemData.stack or 1,
                })
                rowGroup:Add(entry)
            end
        end
    end
    self:_updatePageText()
end

--------------------------------------------------------------------------------
-- == NAVIGATION + PLACEHOLDER ITEMS ==
--------------------------------------------------------------------------------
function ShopWindow:AddItems(opts)
    opts = opts or {}
    
    -- normalize tags to a table
    local tags = opts.tags
    if type(tags) == "string" then
        local parsed = {}
        for token in tags:gmatch("[^,]+") do
            local trimmed = token:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then table.insert(parsed, trimmed) end
        end
        tags = parsed
    elseif type(tags) ~= "table" then
        tags = {}
    end

    local maxRarity = opts.maxRarity
    local maxStock = opts.maxStock
    if type(maxStock) == "string" then
        if maxStock:lower() == "inf" or maxStock:lower() == "infinite" then
            maxStock = math.huge
        else
            maxStock = tonumber(maxStock)
        end
    end
    if type(maxStock) ~= "number" or maxStock ~= maxStock or maxStock <= 0 then
        maxStock = math.huge
    end
    local matchAll  = opts.matchAll == true
    local seen      = {}
    local added     = 0

    local reg = ItemReg and ItemReg:All() or {}
    for id, item in pairs(reg) do
        if seen[id] then
            -- skip duplicate
        else
            local include = true

            -- === Tag filter ===
            if #tags > 0 then
                include = false
                if type(item.tags) == "table" then
                    local matches = 0
                    for _, tag in ipairs(tags) do
                        for _, itag in ipairs(item.tags) do
                            if string.lower(itag) == string.lower(tag) then
                                matches = matches + 1
                                break
                            end
                        end
                    end
                    if matchAll then
                        include = (matches == #tags)
                    else
                        include = (matches > 0)
                    end
                end
            end

            -- === Rarity filter ===
            if include and maxRarity and Common and Common.RarityRank then
                local ranks = Common.RarityRank
                local itemRank = ranks[item.rarity or "common"] or 1
                local maxRank  = ranks[maxRarity] or math.huge
                if itemRank > maxRank then
                    include = false
                end
            end

            if include then
                local price = (item.GetPrice and item:GetPrice()) or math.random(1000, 100000)

                local entry = {
                    id = item.id,
                    price = price,
                }

                if maxStock ~= math.huge then
                    entry.stack = (item.stackable and math.random(1, item.maxStack or 5)) or 1
                end

                table.insert(self.items, entry)
                seen[id] = true
                added = added + 1
                if added >= maxStock then
                    break
                end
            end
        end
    end
end


function ShopWindow:AddPlaceholderItems(n)
    self.items = {}
    local reg = ItemReg and ItemReg:All() or {}
    local ids = {}
    for id in pairs(reg) do table.insert(ids, id) end

    local target = n or 20
    local seen = {}
    local i = 1

    while #self.items < target and i <= #ids do
        local randomId = ids[math.random(1, #ids)]
        local item = reg[randomId]

        if item and not seen[item.id] then
            local price = (item.GetPrice and item:GetPrice()) or math.random(1000, 100000)

            table.insert(self.items, {
                id = item.id,
                price = price,
                stack = math.random(1, 10),
            })

            seen[item.id] = true
        end

        i = i + 1
    end

    self.page = 1
    self:Refresh()
end

function ShopWindow:NextPage()
    local maxPages = math.max(1, math.ceil(#self.items / ITEMS_PER_PAGE))
    if self.page < maxPages then self.page = self.page + 1; self:Refresh() end
end

function ShopWindow:PrevPage()
    if self.page > 1 then self.page = self.page - 1; self:Refresh() end
end

--------------------------------------------------------------------------------
-- == INSTANCE ==
--------------------------------------------------------------------------------
function ShopWindow.New()
    local self = setmetatable({}, ShopWindow)
    self:BuildUI()
    return self
end

function ShopWindow:Show() if self.root then self.root:Show() end end
function ShopWindow:Hide() if self.root then self.root:Hide() end end

return ShopWindow
