-- RPE_UI/Prefabs/LootEditorEntry.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local IconButton            = RPE_UI.Elements.IconButton
local Text                  = RPE_UI.Elements.Text

---@class LootEditorEntry: FrameElement
---@field raidMarkerTexture Texture
---@field lootIcon Texture
---@field lootName Text
---@field lootQuantity Text
---@field minusButton IconButton
---@field plusButton IconButton
---@field cancelButton IconButton
---@field currentMarker integer|nil
---@field onMinusClick fun(self:LootEditorEntry)|nil
---@field onPlusClick fun(self:LootEditorEntry)|nil
---@field onCancelClick fun(self:LootEditorEntry)|nil
---@field onMarkerChange fun(self:LootEditorEntry, markerIndex:integer)|nil
---@field onLootChange fun(self:LootEditorEntry, category:string, lootId:string, lootData:table)|nil
---@field currentCategory string|nil
---@field currentLootData table|nil
---@field currentQuantity number
local LootEditorEntry = setmetatable({}, { __index = FrameElement })
LootEditorEntry.__index = LootEditorEntry
RPE_UI.Prefabs.LootEditorEntry = LootEditorEntry

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

local function GetRarityColor(rarity)
    return RARITY_COLORS[rarity] or "ffffffff"
end

function LootEditorEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "LootEditorEntry:New requires opts.parent")

    local width     = opts.width or 400
    local height    = opts.height or 32
    local iconSize  = opts.iconSize or 16
    local lootNameWidth = 300
    local buttonSize = opts.buttonSize or 24

    local f = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)

    -- === Highlight texture ===
    local hl = f:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    hl:Hide()

    -- === Progress bar (hidden by default) ===
    local progressBar = CreateFrame("StatusBar", nil, f)
    progressBar:SetSize(width - 40, 4)
    progressBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 2)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(100)
    progressBar:GetStatusBarTexture():SetHorizTile(false)
    progressBar:GetStatusBarTexture():SetVertTile(false)
    progressBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    progressBar:Hide()

    f:SetScript("OnEnter", function() hl:Show() end)
    f:SetScript("OnLeave", function() hl:Hide() end)

    ---@type LootEditorEntry
    local o = FrameElement.New(self, "LootEditorEntry", f, opts.parent)
    o.currentMarker = 0
    o.currentQuantity = 1
    o.restrictedPlayers = {} -- Set of player names who can receive this loot
    o.allReceive = false -- If true, all players automatically receive this loot
    o.progressBar = progressBar

    -- Horizontal layout for all elements
    local hGroup = HorizontalLayoutGroup:New(name .. "_HGroup", {
        parent        = o,
        autoSize      = false,
        width         = width,
        height        = height,
        alignV        = "CENTER",
        spacingX      = 4,
        paddingLeft   = 20,
        paddingRight  = 2,
        paddingTop    = 0,
        paddingBottom = 0,
    })
    o:AddChild(hGroup)

    -- Raid Marker (texture icon)
    local markerContainer = CreateFrame("Frame", nil, hGroup.frame)
    markerContainer:SetSize(16, 16)
    local markerTexture = markerContainer:CreateTexture(nil, "ARTWORK")
    markerTexture:SetAllPoints()
    o.raidMarkerTexture = markerTexture
    local markerElement = FrameElement.New(FrameElement, "MarkerFrame", markerContainer, hGroup)
    hGroup:Add(markerElement)

    -- Loot Icon Container
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local ic = iconContainer:CreateTexture(nil, "ARTWORK")
    ic:SetAllPoints()
    o.lootIcon = ic
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)

    -- Loot Name (fixed width 300px)
    o.lootName = Text:New(name .. "_LootName", {
        parent       = hGroup,
        width        = 300,
        height       = height,
        text         = "Loot Name",
        fontTemplate = "GameFontNormalSmall",
        justifyH     = "LEFT",
    })
    o.lootName.frame:SetWidth(300)
    o.lootName.fs:ClearAllPoints()
    o.lootName.fs:SetPoint("LEFT", o.lootName.frame, "LEFT", 0, 0)
    o.lootName.fs:SetJustifyH("LEFT")
    hGroup:Add(o.lootName)

    -- Loot Quantity
    o.lootQuantity = Text:New(name .. "_LootQuantity", {
        parent       = hGroup,
        width        = 40,
        height       = height,
        text         = "1",
        x            = -10,
        fontTemplate = "GameFontNormalSmall",
        justifyH     = "CENTER",
    })
    o.lootQuantity.fs:ClearAllPoints()
    o.lootQuantity.fs:SetPoint("CENTER", o.lootQuantity.frame, "CENTER", -20, 0)
    hGroup:Add(o.lootQuantity)

    -- Minus Button
    o.minusButton = IconButton:New(name .. "_MinusBtn", {
        parent  = hGroup,
        width   = buttonSize,
        height  = buttonSize,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\minus.png",
        tooltip = "Decrease quantity",
        noBackground = true,
        onClick = function(btn)
            if o.onMinusClick then
                o.onMinusClick(o)
            end
        end,
    })
    hGroup:Add(o.minusButton)

    -- Plus Button
    o.plusButton = IconButton:New(name .. "_PlusBtn", {
        parent  = hGroup,
        width   = buttonSize,
        height  = buttonSize,
        icon    = "Interface\\Addons\\RPEngine\\UI\\Textures\\plus.png",
        tooltip = "Increase quantity",
        noBackground = true,
        onClick = function(btn)
            if o.onPlusClick then
                o.onPlusClick(o)
            end
        end,
    })
    hGroup:Add(o.plusButton)

    -- Distribute Button (icon changes based on allReceive flag)
    local function GetDistributeIcon()
        if o.allReceive then
            return "Interface\\Icons\\INV_Misc_Bag_08"  -- Loot bag icon for "all receive"
        else
            return "Interface\\Buttons\\UI-GroupLoot-Dice-Up"  -- Dice icon for bidding
        end
    end
    
    o.distributeButton = IconButton:New(name .. "_DistributeBtn", {
        parent  = hGroup,
        width   = buttonSize,
        height  = buttonSize,
        icon    = GetDistributeIcon(),
        tooltip = "Distribute this item",
        noBackground = true,
        onClick = function(btn)
            if o.onDistributeClick then
                o.onDistributeClick(o)
            end
        end,
    })
    hGroup:Add(o.distributeButton)

    -- Cancel Button
    o.cancelButton = IconButton:New(name .. "_CancelBtn", {
        parent  = hGroup,
        width   = buttonSize - 4,
        height  = buttonSize - 4,
        icon    = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        tooltip = "Remove item",
        noBackground = true,
        onClick = function(btn)
            if o.onCancelClick then
                o.onCancelClick(o)
            end
        end,
    })
    hGroup:Add(o.cancelButton)

    o.onMinusClick = opts.onMinusClick
    o.onPlusClick = opts.onPlusClick
    o.onDistributeClick = opts.onDistributeClick
    o.onCancelClick = opts.onCancelClick
    o.onMarkerChange = opts.onMarkerChange

    -- Right-click context menu for raid marker selection
    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function(frame, button)
        if button == "RightButton" then
            o:ShowMarkerMenu()
        end
    end)

    return o
end

function LootEditorEntry:ShowMarkerMenu()
    if not (RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu) then
        return
    end

    local markers = {
        [1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
        [5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull"
    }

    RPE_UI.Common:ContextMenu(self.frame, function(level, menuList)
        if level == 1 then
            -- Raid marker options
            for idx, label in ipairs(markers) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Set Marker: " .. label
                info.icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. idx
                info.checked = (self.currentMarker == idx)
                info.isNotRadio = false
                info.func = function()
                    self:SetRaidMarker(idx)
                    if self.onMarkerChange then
                        self.onMarkerChange(self, idx)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end

            local clearInfo = UIDropDownMenu_CreateInfo()
            clearInfo.text = "Clear Marker"
            clearInfo.checked = (self.currentMarker == nil or self.currentMarker == 0)
            clearInfo.isNotRadio = false
            clearInfo.func = function()
                self:SetRaidMarker(0)
                if self.onMarkerChange then
                    self.onMarkerChange(self, 0)
                end
            end
            UIDropDownMenu_AddButton(clearInfo, level)

            UIDropDownMenu_AddSeparator(level)

            -- Set Quantity section
            local setQuantity = UIDropDownMenu_CreateInfo()
            setQuantity.notCheckable = true
            setQuantity.text = "Set Quantity..."
            setQuantity.func = function()
                self:ShowQuantityPopup()
            end
            UIDropDownMenu_AddButton(setQuantity, level)

            UIDropDownMenu_AddSeparator(level)

            -- Set Item section
            local setItem = UIDropDownMenu_CreateInfo()
            setItem.notCheckable = true
            setItem.text = "Set Item..."
            setItem.hasArrow = true
            setItem.value = "items"
            setItem.menuList = "SET_ITEM_LIST"
            UIDropDownMenu_AddButton(setItem, level)

            -- Set Currency section
            local setCurrency = UIDropDownMenu_CreateInfo()
            setCurrency.notCheckable = true
            setCurrency.text = "Set Currency..."
            setCurrency.hasArrow = true
            setCurrency.value = "currency"
            setCurrency.menuList = "SET_CURRENCY_LIST"
            UIDropDownMenu_AddButton(setCurrency, level)

            -- Set Spell section
            local setSpell = UIDropDownMenu_CreateInfo()
            setSpell.notCheckable = true
            setSpell.text = "Set Spell..."
            setSpell.hasArrow = true
            setSpell.value = "spells"
            setSpell.menuList = "SET_SPELL_LIST"
            UIDropDownMenu_AddButton(setSpell, level)

            -- Set Recipe section
            local setRecipe = UIDropDownMenu_CreateInfo()
            setRecipe.notCheckable = true
            setRecipe.text = "Set Recipe..."
            setRecipe.hasArrow = true
            setRecipe.value = "recipes"
            setRecipe.menuList = "SET_RECIPE_LIST"
            UIDropDownMenu_AddButton(setRecipe, level)

            UIDropDownMenu_AddSeparator(level)

            -- Restrict to... section
            local restrictTo = UIDropDownMenu_CreateInfo()
            restrictTo.notCheckable = true
            restrictTo.text = "Restrict to..."
            restrictTo.hasArrow = true
            restrictTo.value = "restrict"
            restrictTo.menuList = "RESTRICT_TO_PLAYERS"
            UIDropDownMenu_AddButton(restrictTo, level)

            -- All Receive Loot option
            local allReceive = UIDropDownMenu_CreateInfo()
            allReceive.text = "All Receive Loot"
            allReceive.checked = self.allReceive or false
            allReceive.isNotRadio = true
            allReceive.keepShownOnClick = true
            allReceive.func = function()
                self.allReceive = not self.allReceive
                self:UpdateDistributeIcon()
            end
            UIDropDownMenu_AddButton(allReceive, level)

        elseif level == 2 and menuList == "RESTRICT_TO_PLAYERS" then
            -- Clear All option
            local clearInfo = UIDropDownMenu_CreateInfo()
            clearInfo.notCheckable = true
            clearInfo.text = "Clear All"
            clearInfo.func = function()
                self.restrictedPlayers = {}
            end
            UIDropDownMenu_AddButton(clearInfo, level)

            UIDropDownMenu_AddSeparator(level)

            -- Get list of group members
            local players = self:GetGroupPlayers()
            
            if #players == 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "No group members"
                UIDropDownMenu_AddButton(info, level)
            else
                -- Show all players with checkmarks for multi-select
                for _, playerData in ipairs(players) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = playerData.displayName
                    info.checked = self.restrictedPlayers[playerData.unitName] or false
                    info.keepShownOnClick = true
                    info.isNotRadio = true
                    info.func = function()
                        if self.restrictedPlayers[playerData.unitName] then
                            self.restrictedPlayers[playerData.unitName] = nil
                        else
                            self.restrictedPlayers[playerData.unitName] = true
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end

        elseif level == 2 and menuList == "SET_CURRENCY_LIST" then
            -- Show all currencies directly (no grouping)
            local registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
            if not registry or not registry.All then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "Registry not available"
                UIDropDownMenu_AddButton(info, level)
                return
            end

            local allItems = registry:All()
            if not allItems then return end

            -- Collect currency items
            local currencies = {}
            for itemId, itemDef in pairs(allItems) do
                if itemDef and itemDef.category == "CURRENCY" then
                    table.insert(currencies, { id = itemId, def = itemDef })
                end
            end

            -- Sort alphabetically
            table.sort(currencies, function(a, b)
                local aName = (a.def and a.def.name) or a.id
                local bName = (b.def and b.def.name) or b.id
                return tostring(aName):lower() < tostring(bName):lower()
            end)

            -- Built-in currencies with icons
            local builtInCurrencies = {
                { name = "Copper", key = "copper", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
                { name = "Justice", key = "justice", icon = 463446 },
                { name = "Conquest", key = "conquest", icon = 1523630 },
                { name = "Honor", key = "honor", icon = 1455894 },
                { name = "Valor", key = "valor", icon = 463447 },
            }
            
            -- Add all built-in currencies
            for _, currency in ipairs(builtInCurrencies) do
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = currency.name
                if currency.icon then
                    info.icon = currency.icon
                end
                info.func = function()
                    self.currentCategory = "currency"
                    self.currentLootData = { name = currency.name, icon = currency.icon }
                    if self.onLootChange then
                        self.onLootChange(self, "currency", currency.key, self.currentLootData)
                    end
                    self:SetLootName(currency.name)
                    if currency.icon then
                        self:SetLootIcon(currency.icon)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end

            -- Add separator if there are custom currencies
            if #currencies > 0 then
                UIDropDownMenu_AddSeparator(level)
            end

            -- Add all custom currency items from registry
            for _, currency in ipairs(currencies) do
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = (currency.def and currency.def.name) or currency.id
                if currency.def and currency.def.icon then
                    info.icon = currency.def.icon
                end
                info.func = function()
                    self.currentCategory = "currency"
                    self.currentLootData = currency.def
                    if self.onLootChange then
                        self.onLootChange(self, "currency", currency.id, currency.def)
                    end
                    self:SetLootName((currency.def and currency.def.name) or currency.id)
                    if currency.def and currency.def.icon then
                        self:SetLootIcon(currency.def.icon)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end

        elseif level == 2 and (menuList == "SET_ITEM_LIST" or menuList == "SET_SPELL_LIST" or menuList == "SET_RECIPE_LIST") then
            -- Get loot from registries directly
            local category = UIDROPDOWNMENU_MENU_VALUE
            if not category then return end

            -- Get registry based on category
            local registry, getAll
            if category == "items" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                getAll = registry and registry.All and function() return registry:All() end
            elseif category == "recipes" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.RecipeRegistry
                getAll = registry and registry.All and function() return registry:All() end
            elseif category == "spells" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
                getAll = registry and registry.All and function() return registry:All() end
            end

            if not (registry and getAll) then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "Registry not available"
                UIDropDownMenu_AddButton(info, level)
                return
            end

            local allLoot = getAll()
            if not allLoot or not next(allLoot) then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "No " .. category .. " available"
                UIDropDownMenu_AddButton(info, level)
                return
            end

            -- Collect and sort (filter out CURRENCY items for items category)
            local lootList = {}
            for lootId, lootDef in pairs(allLoot) do
                -- For items, exclude CURRENCY category
                if category == "items" and lootDef and lootDef.category == "CURRENCY" then
                    -- Skip currency items
                else
                    table.insert(lootList, { id = lootId, def = lootDef })
                end
            end
            table.sort(lootList, function(a, b)
                local aName = (a.def and a.def.name) or a.id
                local bName = (b.def and b.def.name) or b.id
                return tostring(aName):lower() < tostring(bName):lower()
            end)

            -- Group into chunks of 20
            local itemsPerGroup = 20
            local groups = {}
            for i = 1, #lootList, itemsPerGroup do
                local groupItems = {}
                for j = i, math.min(i + itemsPerGroup - 1, #lootList) do
                    table.insert(groupItems, lootList[j])
                end
                table.insert(groups, groupItems)
            end

            -- Create submenu for each group
            for groupIdx, groupItems in ipairs(groups) do
                if #groupItems > 0 then
                    local firstName = (groupItems[1].def and groupItems[1].def.name) or groupItems[1].id
                    local lastName = (groupItems[#groupItems].def and groupItems[#groupItems].def.name) or groupItems[#groupItems].id
                    firstName = tostring(firstName):sub(1, 1):upper()
                    lastName = tostring(lastName):sub(1, 2):upper()
                    local rangeLabel = (firstName == lastName) and firstName or (firstName .. "-" .. lastName)

                    local info = UIDropDownMenu_CreateInfo()
                    info.notCheckable = true
                    info.text = rangeLabel
                    info.hasArrow = true
                    info.value = category .. "|" .. tostring(groupIdx)
                    info.menuList = "SET_LOOT_SELECT"
                    UIDropDownMenu_AddButton(info, level)
                end
            end

        elseif level == 3 and menuList == "SET_LOOT_SELECT" then
            -- Show loot in selected group
            local encodedValue = UIDROPDOWNMENU_MENU_VALUE
            if not encodedValue then return end

            -- Decode: "category|groupIdx"
            local pipeIdx = encodedValue:find("|", 1, true)
            if not pipeIdx then return end
            local category = encodedValue:sub(1, pipeIdx - 1)
            local groupIdx = tonumber(encodedValue:sub(pipeIdx + 1))

            -- Get registry based on category
            local registry, getAll
            if category == "items" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                getAll = registry and registry.All and function() return registry:All() end
            elseif category == "recipes" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.RecipeRegistry
                getAll = registry and registry.All and function() return registry:All() end
            elseif category == "spells" then
                registry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
                getAll = registry and registry.All and function() return registry:All() end
            end

            if not (registry and getAll) then return end

            local allLoot = getAll()
            if not allLoot then return end

            -- Collect and sort (filter out CURRENCY items for items category)
            local lootList = {}
            for lootId, lootDef in pairs(allLoot) do
                -- For items, exclude CURRENCY category
                if category == "items" and lootDef and lootDef.category == "CURRENCY" then
                    -- Skip currency items
                else
                    table.insert(lootList, { id = lootId, def = lootDef })
                end
            end
            table.sort(lootList, function(a, b)
                local aName = (a.def and a.def.name) or a.id
                local bName = (b.def and b.def.name) or b.id
                return tostring(aName):lower() < tostring(bName):lower()
            end)

            -- Reconstruct groups to find selected one
            local itemsPerGroup = 20
            local selectedGroupItems = {}
            local currentGroupIdx = 0
            for i = 1, #lootList, itemsPerGroup do
                currentGroupIdx = currentGroupIdx + 1
                if currentGroupIdx == groupIdx then
                    for j = i, math.min(i + itemsPerGroup - 1, #lootList) do
                        table.insert(selectedGroupItems, lootList[j])
                    end
                    break
                end
            end

            if #selectedGroupItems == 0 then return end

            for _, loot in ipairs(selectedGroupItems) do
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = (loot.def and loot.def.name) or loot.id
                if loot.def and loot.def.icon then
                    info.icon = loot.def.icon
                end
                info.func = function()
                    -- Store category and data for formatting
                    self.currentCategory = category
                    self.currentLootData = loot.def
                    
                    -- Set the loot
                    if self.onLootChange then
                        self.onLootChange(self, category, loot.id, loot.def)
                    end
                    
                    -- Update display
                    self:SetLootName((loot.def and loot.def.name) or loot.id)
                    
                    -- For recipes, get the icon from the output item
                    local iconToSet = nil
                    if category == "recipes" and loot.def and loot.def.outputItemId then
                        local itemReg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                        if itemReg then
                            local outputItem = itemReg:Get(loot.def.outputItemId)
                            if outputItem and outputItem.icon then
                                iconToSet = outputItem.icon
                                -- Store the icon in the loot data so it gets passed to LootWindow
                                self.currentLootData.icon = iconToSet
                            end
                        end
                    elseif loot.def and loot.def.icon then
                        iconToSet = loot.def.icon
                    end
                    
                    if iconToSet then
                        self:SetLootIcon(iconToSet)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

function LootEditorEntry:ShowQuantityPopup()
    local Popup = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    if not Popup then return end
    
    local currentQty = tostring(self.currentQuantity or 1)
    
    Popup.Prompt(
        "Set Quantity",
        "Enter quantity (positive number):",
        currentQty,
        function(text)
            local qty = tonumber(text)
            if qty and qty > 0 and math.floor(qty) == qty then
                self:SetQuantity(qty)
            else
                -- Invalid input - could show error message but for now just ignore
            end
        end,
        nil -- onCancel
    )
end

function LootEditorEntry:SetRaidMarker(markerIndex)
    if self.raidMarkerTexture then
        markerIndex = tonumber(markerIndex) or 0
        self.currentMarker = markerIndex
        local texturePath = RAID_MARKERS[markerIndex]
        if texturePath then
            self.raidMarkerTexture:SetTexture(texturePath)
            self.raidMarkerTexture:Show()
        else
            self.raidMarkerTexture:SetTexture(nil)
            self.raidMarkerTexture:Hide()
        end
    end
end

function LootEditorEntry:SetLootIcon(texturePath)
    if self.lootIcon then
        if texturePath and texturePath ~= "" then
            self.lootIcon:SetTexture(texturePath)
            self.lootIcon:Show()
        else
            self.lootIcon:SetTexture(nil)
            self.lootIcon:Hide()
        end
    end
end

function LootEditorEntry:SetLootName(name)
    if self.lootName then
        local displayName = name or ""
        
        -- Show placeholder for empty entries
        if displayName == "" then
            displayName = "|cff808080(Empty - right-click to set)|r"
        elseif self.currentCategory == "items" or self.currentCategory == "currency" then
            -- Items and currency: [Name] with rarity color
            local rarity = self.currentLootData and self.currentLootData.rarity
            local color = GetRarityColor(rarity)
            displayName = "|c" .. color .. "[" .. displayName .. "]|r"
        elseif self.currentCategory == "spells" or self.currentCategory == "recipes" then
            -- Spells and recipes: Learn: Name (yellow)
            displayName = "|cffffff00Learn: " .. displayName .. "|r"
        end
        
        self.lootName:SetText(displayName)
    end
end

function LootEditorEntry:SetQuantity(qty)
    qty = tonumber(qty) or 1
    self.currentQuantity = qty
    if self.lootQuantity then
        self.lootQuantity:SetText(tostring(qty))
    end
end

function LootEditorEntry:SetOnMinusClick(fn)
    self.onMinusClick = fn
end

function LootEditorEntry:SetOnPlusClick(fn)
    self.onPlusClick = fn
end

function LootEditorEntry:SetOnDistributeClick(fn)
    self.onDistributeClick = fn
end

function LootEditorEntry:SetOnCancelClick(fn)
    self.onCancelClick = fn
end

function LootEditorEntry:SetOnMarkerChange(fn)
    self.onMarkerChange = fn
end

function LootEditorEntry:SetOnLootChange(fn)
    self.onLootChange = fn
end

function LootEditorEntry:GetGroupPlayers()
    local players = {}
    
    -- Get players from the active event
    local event = RPE.Core.ActiveEvent
    if event and event.units then
        for key, unit in pairs(event.units) do
            -- Only include player units (exclude NPCs)
            if not unit.isNPC then
                table.insert(players, {
                    unitName = key,  -- The key is used for lookups in restrictedPlayers
                    displayName = unit.name or key
                })
            end
        end
    end
    
    -- Sort alphabetically by display name
    table.sort(players, function(a, b)
        return (a.displayName or ""):lower() < (b.displayName or ""):lower()
    end)
    
    return players
end

function LootEditorEntry:ShowProgressBar()
    if self.progressBar then
        self.progressBar:SetValue(100)
        self.progressBar:Show()
    end
end

function LootEditorEntry:HideProgressBar()
    if self.progressBar then
        self.progressBar:Hide()
    end
end

function LootEditorEntry:SetProgress(percent)
    if self.progressBar then
        self.progressBar:SetValue(percent)
    end
end

function LootEditorEntry:UpdateDistributeIcon()
    if self.distributeButton and self.distributeButton.frame then
        local icon
        if self.allReceive then
            icon = "Interface\\Icons\\INV_Misc_Bag_08"  -- Loot bag icon for "all receive"
        else
            icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"  -- Dice icon for bidding
        end
        
        -- Update all textures on the button frame to the new icon
        local frame = self.distributeButton.frame
        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if region and region.SetTexture then
                region:SetTexture(icon)
            end
        end
    end
end

return LootEditorEntry
