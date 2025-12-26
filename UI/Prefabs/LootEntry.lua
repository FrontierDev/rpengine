-- RPE_UI/Prefabs/LootEntry.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local IconButton            = RPE_UI.Elements.IconButton
local TextButton            = RPE_UI.Elements.TextButton
local Text                  = RPE_UI.Elements.Text

---@class LootEntry: FrameElement
---@field lootIcon Texture
---@field lootQuantity Text
---@field bidMinusButton TextButton
---@field bidPlusButton TextButton
---@field needButton TextButton
---@field greedButton TextButton
---@field passButton TextButton
---@field bidAmountText Text
---@field distributionType string
---@field currentBid number
---@field lootData table
local LootEntry = setmetatable({}, { __index = FrameElement })
LootEntry.__index = LootEntry
RPE_UI.Prefabs.LootEntry = LootEntry

local RARITY_COLORS = {
    ["POOR"]      = "ff9d9d9d",
    ["COMMON"]    = "ffffffff",
    ["UNCOMMON"]  = "ff1eff00",
    ["RARE"]      = "ff0070dd",
    ["EPIC"]      = "ffa335ee",
    ["LEGENDARY"] = "ffff8000",
    ["ARTIFACT"]  = "ffe6cc80",
    ["HEIRLOOM"]  = "ffe6cc80",
}

local QUALITY_COLORS = {
    common    = { r = 1.00, g = 1.00, b = 1.00 },
    uncommon  = { r = 0.12, g = 1.00, b = 0.00 },
    rare      = { r = 0.00, g = 0.44, b = 0.87 },
    epic      = { r = 0.64, g = 0.21, b = 0.93 },
    legendary = { r = 1.00, g = 0.50, b = 0.00 },
}

local function GetRarityColor(rarity)
    return RARITY_COLORS[rarity] or "ffffffff"
end

function LootEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "LootEntry:New requires opts.parent")

    local width     = opts.width or 200
    local height    = opts.height or 32
    local iconSize  = 32

    local f = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Highlight texture
    local hl = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    hl:Hide()

    -- Progress bar (hidden by default)
    local progressBar = CreateFrame("StatusBar", nil, f)
    progressBar:SetSize(width - 16, 4)
    progressBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 2)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(100)
    progressBar:GetStatusBarTexture():SetHorizTile(false)
    progressBar:GetStatusBarTexture():SetVertTile(false)
    progressBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    progressBar:Hide()

    ---@type LootEntry
    local o = FrameElement.New(self, "LootEntry", f, opts.parent)
    o.distributionType = opts.distributionType or "BID"
    o.currentBid = 0
    o.lootData = opts.lootData or {}
    o.progressBar = progressBar
    o.choice = nil  -- tracks: nil, "need", "greed", "pass"

    -- Setup hover scripts after o is created
    f:SetScript("OnEnter", function() 
        hl:Show()
        o:ShowTooltip()
    end)
    f:SetScript("OnLeave", function() 
        hl:Hide()
        o:HideTooltip()
    end)

    -- Horizontal layout
    local hGroup = HorizontalLayoutGroup:New(name .. "_HGroup", {
        parent        = o,
        autoSize      = false,
        width         = width,
        height        = height,
        alignV        = "CENTER",
        alignH        = "CENTER",
        spacingX      = 4,
        paddingLeft   = 6,
        paddingRight  = 2,
        paddingTop    = 0,
        paddingBottom = 0,
    })
    o:AddChild(hGroup)

    -- Raid Marker (texture icon) - displayed to the left of item icon
    local markerContainer = CreateFrame("Frame", nil, hGroup.frame)
    markerContainer:SetSize(16, 16)
    local markerTexture = markerContainer:CreateTexture(nil, "ARTWORK")
    markerTexture:SetAllPoints()
    o.raidMarkerTexture = markerTexture
    local markerElement = FrameElement.New(FrameElement, "MarkerFrame", markerContainer, hGroup)
    hGroup:Add(markerElement)

    -- Loot Icon
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local icon = iconContainer:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    o.lootIcon = icon
    
    -- Quality border (rarity border around icon)
    local t = 2  -- border thickness
    o.qBorder = {
        top    = iconContainer:CreateTexture(nil, "OVERLAY", nil, 2),
        bottom = iconContainer:CreateTexture(nil, "OVERLAY", nil, 2),
        left   = iconContainer:CreateTexture(nil, "OVERLAY", nil, 2),
        right  = iconContainer:CreateTexture(nil, "OVERLAY", nil, 2),
    }
    o.qBorder.top   :SetPoint("TOPLEFT",     iconContainer, "TOPLEFT",     0, 0)
    o.qBorder.top   :SetPoint("TOPRIGHT",    iconContainer, "TOPRIGHT",    0, 0)
    o.qBorder.top   :SetHeight(t)

    o.qBorder.bottom:SetPoint("BOTTOMLEFT",  iconContainer, "BOTTOMLEFT",  0, 0)
    o.qBorder.bottom:SetPoint("BOTTOMRIGHT", iconContainer, "BOTTOMRIGHT", 0, 0)
    o.qBorder.bottom:SetHeight(t)

    o.qBorder.left  :SetPoint("TOPLEFT",     iconContainer, "TOPLEFT",     0, 0)
    o.qBorder.left  :SetPoint("BOTTOMLEFT",  iconContainer, "BOTTOMLEFT",  0, 0)
    o.qBorder.left  :SetWidth(t)

    o.qBorder.right :SetPoint("TOPRIGHT",    iconContainer, "TOPRIGHT",    0, 0)
    o.qBorder.right :SetPoint("BOTTOMRIGHT", iconContainer, "BOTTOMRIGHT", 0, 0)
    o.qBorder.right :SetWidth(t)

    -- Start hidden
    o.qBorder.top:Hide(); o.qBorder.bottom:Hide(); o.qBorder.left:Hide(); o.qBorder.right:Hide()
    
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)

    -- Quantity label (positioned over icon like InventorySlot)
    o.lootQuantity = Text:New(name .. "_Qty", {
        parent = o,
        fontTemplate = "NumberFontNormalYellow",
        fontSize = 14,
        textPoint = "BOTTOMRIGHT",
        textPointRelative = "BOTTOMRIGHT",
        textX = iconSize * 0.4,
        textY = iconSize * -0.4,
        text = nil,
    })
    o.lootQuantity:SetAllPoints(iconContainer)
    o.lootQuantity:Hide()

    -- BID buttons (minus/plus)
    if o.distributionType == "BID" then
        o.bidMinusButton = IconButton:New(name .. "_BidMinus", {
            parent = hGroup,
            width = 24,
            height = 24,
            icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\minus.png",
            tooltip = "Decrease bid",
            noBackground = true,
            onClick = function()
                o:DecrementBid()
            end,
        })
        hGroup:Add(o.bidMinusButton)

        -- Bid amount display
        o.bidAmountText = Text:New(name .. "_BidAmount", {
            parent = hGroup,
            width = 40,
            height = height,
            text = "0",
            fontTemplate = "GameFontNormal",
            justifyH = "CENTER",
        })
        hGroup:Add(o.bidAmountText)

        o.bidPlusButton = IconButton:New(name .. "_BidPlus", {
            parent = hGroup,
            width = 24,
            height = 24,
            icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\plus.png",
            tooltip = "Increase bid",
            noBackground = true,
            onClick = function()
                o:IncrementBid()
            end,
        })
        hGroup:Add(o.bidPlusButton)
    end

    -- NEED BEFORE GREED buttons
    if o.distributionType == "NEED BEFORE GREED" then
        o.needButton = IconButton:New(name .. "_Need", {
            parent = hGroup,
            width = 24,
            height = 24,
            icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
            tooltip = "Need",
            noBackground = true,
            onClick = function()
                o:OnNeedClick()
            end,
        })
        hGroup:Add(o.needButton)

        o.greedButton = IconButton:New(name .. "_Greed", {
            parent = hGroup,
            width = 24,
            height = 24,
            icon = "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
            tooltip = "Greed",
            noBackground = true,
            onClick = function()
                o:OnGreedClick()
            end,
        })
        hGroup:Add(o.greedButton)
    end

    -- Pass button (always shown)
    o.passButton = IconButton:New(name .. "_Pass", {
        parent = hGroup,
        width = 24,
        height = 24,
        icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        tooltip = "Pass",
        noBackground = true,
        onClick = function()
            o:OnPassClick()
        end,
    })
    hGroup:Add(o.passButton)

    -- Set initial loot data if provided
    if opts.lootData then
        o:SetLootData(opts.lootData)
    end

    return o
end

function LootEntry:SetLootData(lootData)
    self.lootData = lootData or {}
    
    -- Determine which registry to use based on category
    -- Handle both 'category' and 'currentCategory' field names
    local category = lootData.category or lootData.currentCategory
    local lootId = lootData.lootId or (lootData.currentLootData and lootData.currentLootData.id)
    local icon = lootData.icon or (lootData.currentLootData and lootData.currentLootData.icon)
    local raidMarker = lootData.raidMarker or 0
    
    -- Set raid marker if present
    if self.raidMarkerTexture then
        local RAID_MARKERS = {
            [0] = nil,
            [1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
            [2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
            [3] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
            [4] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
            [5] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
            [6] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
            [7] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
            [8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
        }
        markerIndex = tonumber(raidMarker) or 0
        local texturePath = RAID_MARKERS[markerIndex]
        if texturePath then
            self.raidMarkerTexture:SetTexture(texturePath)
            self.raidMarkerTexture:Show()
        else
            self.raidMarkerTexture:SetTexture(nil)
            self.raidMarkerTexture:Hide()
        end
    end

    if not icon then
        -- Try to look up icon from registry based on category
        if category == "spells" then
            local spellReg = RPE and RPE.Core and RPE.Core.SpellRegistry
            if spellReg and lootId then
                local spell = spellReg:Get(lootId)
                if spell then
                    icon = spell.icon
                end
            end
        elseif category == "recipe" or category == "recipes" then
            -- For recipes, get the output item's icon (fallback if not already provided)
            local recipeReg = RPE and RPE.Core and RPE.Core.RecipeRegistry
            local itemReg = RPE and RPE.Core and RPE.Core.ItemRegistry
            if recipeReg and itemReg and lootId then
                local recipe = recipeReg:Get(lootId)
                if recipe and recipe.outputItemId then
                    local outputItem = itemReg:Get(recipe.outputItemId)
                    if outputItem then
                        icon = outputItem.icon
                    end
                end
            end
        else
            -- For items and currency, use ItemRegistry
            local itemReg = RPE and RPE.Core and RPE.Core.ItemRegistry
            if itemReg and lootId then
                local item = itemReg:Get(lootId)
                if item then
                    icon = item.icon
                end
            end
        end
    end
    
    -- Set icon
    if self.lootIcon and icon then
        self.lootIcon:SetTexture(icon)
        self.lootIcon:Show()
    end
    
    -- Set quality border based on category and rarity
    local rarity = nil
    if self.qBorder then
        if category == "recipe" or category == "recipes" or category == "spells" then
            -- Spells and recipes get yellow border
            self:SetQualityBorderColor(1.0, 1.0, 0.0, 1)
            self:ShowQualityBorder(true)
        else
            -- For items, look up rarity from the registry
            local itemReg = RPE and RPE.Core and RPE.Core.ItemRegistry
            if itemReg and lootId then
                local itemDef = itemReg:Get(lootId)
                if itemDef then
                    rarity = itemDef.rarity
                end
            end
            
            if rarity then
                -- Items use their rarity color
                local qc = QUALITY_COLORS[rarity] or QUALITY_COLORS["common"]
                self:SetQualityBorderColor(qc.r or 1, qc.g or 1, qc.b or 1, 1)
                self:ShowQualityBorder(true)
            else
                self:ShowQualityBorder(false)
            end
        end
    end
    
    -- Set quantity (only show if > 1)
    if self.lootQuantity then
        local quantity = tonumber(lootData.quantity or lootData.currentQuantity) or 1
        if quantity > 1 then
            self.lootQuantity:SetText(tostring(quantity))
            self.lootQuantity:Show()
        else
            self.lootQuantity:SetText("")
            self.lootQuantity:Hide()
        end
    end
    
    -- If player cannot learn this recipe, lock interactive buttons (keep only Pass)
    if lootData.cannotLearn then
        if self.needButton then
            self.needButton:Lock()
            self.needButton:SetTooltip("You do not have the required profession")
        end
        if self.greedButton then
            self.greedButton:Lock()
            self.greedButton:SetTooltip("You do not have the required profession")
        end
        if self.bidMinusButton then
            self.bidMinusButton:Lock()
            self.bidMinusButton:SetTooltip("You do not have the required profession")
        end
        if self.bidPlusButton then
            self.bidPlusButton:Lock()
            self.bidPlusButton:SetTooltip("You do not have the required profession")
        end
    else
        -- Unlock buttons if the flag is false or not set
        if self.needButton then
            self.needButton:Unlock()
            self.needButton:SetTooltip("Need")
        end
        if self.greedButton then
            self.greedButton:Unlock()
            self.greedButton:SetTooltip("Greed")
        end
        if self.bidMinusButton then
            self.bidMinusButton:Unlock()
            self.bidMinusButton:SetTooltip("Decrease bid")
        end
        if self.bidPlusButton then
            self.bidPlusButton:Unlock()
            self.bidPlusButton:SetTooltip("Increase bid")
        end
    end
end

function LootEntry:ShowQualityBorder(show)
    local qb = self.qBorder
    if not qb then return end
    if show then
        qb.top:Show(); qb.bottom:Show(); qb.left:Show(); qb.right:Show()
    else
        qb.top:Hide(); qb.bottom:Hide(); qb.left:Hide(); qb.right:Hide()
    end
end

function LootEntry:SetQualityBorderColor(r, g, b, a)
    local qb = self.qBorder
    if not qb then return end
    qb.top:SetColorTexture(r, g, b, a or 1)
    qb.bottom:SetColorTexture(r, g, b, a or 1)
    qb.left:SetColorTexture(r, g, b, a or 1)
    qb.right:SetColorTexture(r, g, b, a or 1)
end

function LootEntry:IncrementBid()
    self.currentBid = (self.currentBid or 0) + 1
    if self.bidAmountText then
        self.bidAmountText:SetText(tostring(self.currentBid))
    end
end

function LootEntry:DecrementBid()
    self.currentBid = math.max(0, (self.currentBid or 0) - 1)
    if self.bidAmountText then
        self.bidAmountText:SetText(tostring(self.currentBid))
    end
end

function LootEntry:OnNeedClick()
    if self.choice == "need" then
        -- Clicking again reverts decision
        self:ClearChoice()
    else
        -- Clear previous choice and set to need
        self:ClearChoice()
        self.choice = "need"
        if self.needButton then
            self.needButton:SetColor(0.3, 1, 0.3, 1)  -- Green highlight
        end
    end
    
    if self.onNeed then
        self.onNeed(self)
    end
end

function LootEntry:OnGreedClick()
    if self.choice == "greed" then
        -- Clicking again reverts decision
        self:ClearChoice()
    else
        -- Clear previous choice and set to greed
        self:ClearChoice()
        self.choice = "greed"
        if self.greedButton then
            self.greedButton:SetColor(1, 0.8, 0.2, 1)  -- Gold highlight
        end
    end
    
    if self.onGreed then
        self.onGreed(self)
    end
end

function LootEntry:OnPassClick()
    if self.choice == "pass" then
        -- Clicking again reverts decision
        self:ClearChoice()
    else
        -- Clear previous choice and set to pass
        self:ClearChoice()
        self.choice = "pass"
        
        -- Desaturate icon
        if self.lootIcon and self.lootIcon.SetDesaturated then
            self.lootIcon:SetDesaturated(true)
        end
    end
    
    if self.onPass then
        self.onPass(self)
    end
end

function LootEntry:ShowProgressBar()
    if self.progressBar then
        self.progressBar:SetValue(100)
        self.progressBar:Show()
    end
end

function LootEntry:HideProgressBar()
    if self.progressBar then
        self.progressBar:Hide()
    end
end

function LootEntry:SetProgress(percent)
    if self.progressBar then
        self.progressBar:SetValue(percent)
    end
end

function LootEntry:ClearChoice()
    -- Reset visual state
    if self.needButton then
        self.needButton:SetColor(1, 1, 1, 1)
    end
    if self.greedButton then
        self.greedButton:SetColor(1, 1, 1, 1)
    end
    if self.lootIcon and self.lootIcon.SetDesaturated then
        self.lootIcon:SetDesaturated(false)
    end
    
    self.choice = nil
end

function LootEntry:ShowTooltip()
    if not self.lootData then return end
    
    -- Handle both 'category'/'lootId' and 'currentCategory'/'currentLootData' field names
    local category = self.lootData.category or self.lootData.currentCategory
    local lootId = self.lootData.lootId or (self.lootData.currentLootData and self.lootData.currentLootData.id)
    
    -- Handle spells
    if category == "spells" then
        local spellReg = RPE and RPE.Core and RPE.Core.SpellRegistry
        if spellReg and lootId then
            local spell = spellReg:Get(lootId)
            if spell and spell.GetTooltip then
                local spec = spell:GetTooltip(self.lootData.rank or 1)
                if spec then
                    local Common = RPE and RPE.Common
                    if Common and Common.ShowTooltip then
                        Common:ShowTooltip(self.frame, spec)
                        return
                    end
                end
            end
        end
    end
    
    -- Handle items and currency
    local registry = RPE and RPE.Core and RPE.Core.ItemRegistry
    if registry and lootId then
        local item = registry:Get(lootId)
        if item and item.ShowTooltip then
            -- Use Item's ShowTooltip method which returns a spec
            local spec = item:ShowTooltip()
            if spec then
                local Common = RPE and RPE.Common
                if Common and Common.ShowTooltip then
                    Common:ShowTooltip(self.frame, spec)
                    return
                end
            end
        end
    end
    
    -- Fallback to GameTooltip for basic display
    GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    if self.lootData.name then
        GameTooltip:SetText(self.lootData.name, 1, 1, 1)
        if self.lootData.description then
            GameTooltip:AddLine(self.lootData.description, nil, nil, nil, true)
        end
    end
    
    GameTooltip:Show()
end

function LootEntry:HideTooltip()
    GameTooltip:Hide()
end

return LootEntry
