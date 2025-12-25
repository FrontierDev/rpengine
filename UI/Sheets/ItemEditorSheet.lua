-- RPE_UI/Windows/ItemEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules

local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton

-- Prefabs
local InventorySlot = RPE_UI.Prefabs and RPE_UI.Prefabs.InventorySlot

local Common    = _G.RPE and _G.RPE.Common
local ItemLevel = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemLevel

---@class ItemEditorSheet
---@field Name string
---@field sheet any
---@field grid any
---@field slots table
---@field parent any
---@field rows integer
---@field cols integer
---@field editingName string|nil
---@field _items table
---@field _page integer
---@field _perPage integer
---@field pageText Text
local ItemEditorSheet = {}
_G.RPE_UI.Windows.ItemEditorSheet = ItemEditorSheet
ItemEditorSheet.__index = ItemEditorSheet
ItemEditorSheet.Name = "ItemEditorSheet"

-- Static popup for copying item IDs safely (disabled - use Clipboard instead)
-- StaticPopupDialogs["RPE_COPY_ID"] = {
--     text = "Copy (Ctrl+C) Item ID:",
--     button1 = "Close",
--     hasEditBox = 1,
--     editBoxWidth = 240,
--     timeout = 0,
--     whileDead = true,
--     hideOnEscape = true,
--     preferredIndex = 3,
--     OnShow = function(self, data)
--         local box = _G[self:GetName().."EditBox"]
--         if box then
--             box:SetText(data or "")
--             box:HighlightText()
--             box:SetFocus()
--         end
--     end,
--     OnHide = function(self)
--         local box = _G[self:GetName().."EditBox"]
--         if box then box:SetText("") end
--     end,
-- }


-- ---------------------------------------------------------------------------
-- Bind the dataset being edited
-- ---------------------------------------------------------------------------
function ItemEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then
        self.editingName = name
    else
        self.editingName = nil
    end
end

-- Works with either colon- or dot-style DB API (GetByName/GetByKey/Get)
function ItemEditorSheet:GetEditingDataset()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
    if not (DB and self.editingName) then return nil end

    local candidates = { "GetByName", "GetByKey", "Get" }
    for _, fname in ipairs(candidates) do
        local fn = DB[fname]
        if type(fn) == "function" then
            -- try colon-style
            local ok1, ds1 = pcall(fn, DB, self.editingName)
            if ok1 and ds1 then return ds1 end
            -- try dot-style
            local ok2, ds2 = pcall(fn, self.editingName)
            if ok2 and ds2 then return ds2 end
        end
    end
    return nil
end

-- Window broadcast hook
function ItemEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- Get item from registry if available, or reconstruct from editing dataset if not
function ItemEditorSheet:GetOrReconstructItem(itemId)
    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
    local item = reg and reg.Get and reg:Get(itemId)
    
    -- If item is in the active registry, return it
    if item then return item end
    
    -- Fallback: reconstruct from the editing dataset
    local ds = self:GetEditingDataset()
    if not (ds and ds.items and ds.items[itemId]) then return nil end
    
    local itemDef = ds.items[itemId]
    local ItemCore = _G.RPE and _G.RPE.Core and _G.RPE.Core.Item
    if not ItemCore or not ItemCore.FromTable then return nil end
    
    -- Reconstruct item object from the dataset definition
    return ItemCore.FromTable(itemDef)
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function _collectItemsSorted(ds)
    local items = (ds and ds.items) or {}
    local list = {}
    for id, t in pairs(items) do
        t = t or {}
        table.insert(list, {
            id       = id,
            icon     = t.icon or t.iconId or 134400, -- fallback icon id
            name     = t.name or id,
            rarity   = t.rarity or "common",
            category = t.category or "MISC",
        })
    end
    table.sort(list, function(a,b)
        local an = tostring(a.name or ""):lower()
        local bn = tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function _newItemId()
    if Common and Common.GenerateGUID then
        return Common:GenerateGUID("item")
    end
    return "item-" .. tostring(math.random(0x1000, 0xFFFF)) .. tostring(math.random(0x1000, 0xFFFF))
end

local function _trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- icon id resolve (support legacy string paths)
local function _norm(p) return (tostring(p or ""):gsub("\\","/"):lower()) end
local _iconPathToId -- cached reverse map
local function _iconIdFromAny(v)
    if v == nil then return nil end
    local n = tonumber(v); if n then return n end
    local s = _norm(v)
    if not s:find("^interface/icons/") then return nil end
    if not _iconPathToId then
        _iconPathToId = {}
        local il = _G.RPE and _G.RPE.Assets and _G.RPE.Assets.Icons
        if il and il.IDS then
            for id, path in pairs(il.IDS) do
                _iconPathToId[_norm(path)] = id
            end
        end
    end
    return _iconPathToId[s]
end

local ITEM_CATEGORIES = {
    "MISC","CONSUMABLE","QUEST","EQUIPMENT","MATERIAL","KEY","CURRENCY","MODIFICATION",
}
local RARITY_CHOICES = { "common","uncommon","rare","epic","legendary" }

local function _applyNormalizeStack(values)
    values.stackable = values.stackable and true or false
    local ms = tonumber(values.maxStack)
    if not values.stackable then
        values.maxStack = 1
    else
        values.maxStack = (ms and ms > 0 and ms) or 1
    end
end

-- === Placeholder item-level calculation ===
local function _computeItemLevel(values)
    local lvl = 1
    local rar = tostring(values.rarity or "common")
    local rarBonus = { common=0, uncommon=5, rare=10, epic=20, legendary=30 }
    lvl = lvl + (rarBonus[rar] or 0)

    if type(values.data) == "table" then
        for k, v in pairs(values.data) do
            if type(k) == "string" and k:match("^stat_") then
                local n = tonumber(v)
                if n then lvl = lvl + math.abs(n) end
            end
        end
    end

    local minD, maxD = tonumber(values.minDamage), tonumber(values.maxDamage)
    if minD and maxD and maxD >= minD then
        lvl = lvl + math.floor((minD + maxD) / 4)
    end

    return math.max(1, math.floor(lvl + 0.5))
end

-- itemData may be nil (for new entry) -> guard every field
local function _buildItemSchema(entryId, itemData, isEdit)
    itemData = itemData or {}
    local iconDefaultId = tonumber(itemData.icon) or _iconIdFromAny(itemData.icon) or 134400
    return {
        title = isEdit and ("Edit Item: " .. entryId) or "New Item",
        pages = {
            {
                title = "Basics",
                elements = {
                    { id="name",       label="Name",        type="input",    default = itemData.name or "", required = true },
                    { id="category",   label="Category",    type="select",   choices = ITEM_CATEGORIES, default = itemData.category or "MISC" },
                    { id="rarity",     label="Rarity",      type="select",   choices = RARITY_CHOICES,  default = itemData.rarity or "common" },
                    { id="icon",       label="Icon",        type="icon",     default = iconDefaultId, required = true },
                    { id="description",label="Description", type="input",    default = itemData.description or "" },
                    { id="tags", label="Tags", type="input", default = table.concat(itemData.tags or {}, ", ") },
                }
            },
            {
                title = "Stacking",
                elements = {
                    { id="stackable",  label="Stackable",   type="checkbox", default = (itemData.stackable and true) or false },
                    { id="maxStack",   label="Max Stack",   type="number",   min = 1, max = 200, step = 1, default = tonumber(itemData.maxStack) or 1 },
                    { id="economyHeader",     label="Economy",     type="label" },
                    {
                        id = "basePriceU",
                        label = "Base Price (u)",
                        type = "number",
                        min = 0, step = 0.25,
                        tooltip = "Base value in units (1u = 4 copper)",
                        default = tonumber(itemData.basePriceU) or 0,
                    },
                    {
                        id = "vendorSellable",
                        label = "Buy @ Vendors",
                        type = "checkbox",
                        default = (itemData.vendorSellable and true) or false,
                    },
                    {
                        id = "priceOverrideC",
                        label = "Price Override (c)",
                        type = "number",
                        min = 0, step = 1,
                        tooltip = "If >0, overrides base price (in copper)",
                        default = tonumber(itemData.priceOverrideC) or 0,
                    },
                }
            },
            {
                title = "Data",
                elements = {
                    { id = "data", label = "Properties", type = "editor_table", default = itemData.data or {} },
                }
            },
            {
                title = "Consumable",
                elements = {
                    {
                        id = "spellId",
                        label = "Spell ID",
                        type = "lookup",
                        pattern = "^[0-9a-zA-Z-]+$",
                        tooltip = "Spell ID or spell key (numeric or string)",
                        default = itemData.spellId or "",
                    },
                    {
                        id = "spellRank",
                        label = "Spell Rank",
                        type = "number",
                        min = 0, step = 1,
                        tooltip = "Rank of spell to cast (0 = max available)",
                        default = tonumber(itemData.spellRank) or 0,
                    },
                }
            }
        },
        labelWidth    = 120,
        labelAlign    = "LEFT",
        buttonAlign   = "CENTER",
        navSaveAlways = true,
    }
end

local function _saveItemValues(ds, targetId, values, isEdit, oldId)
    if not ds or not values then return nil, "No dataset or values to save." end
    ds.items = ds.items or {}

    local name   = _trim(values.name or "")
    local iconId = tonumber(values.icon) or _iconIdFromAny(values.icon)

    if name == "" then
        return nil, "Name is required."
    end
    if not iconId or iconId <= 0 then
        return nil, "Icon is required."
    end

    -- ID policy: NEW → GUID; EDIT → keep id stable
    local id = targetId
    if not id or id == "" then
        id = _newItemId()
        while ds.items[id] do id = _newItemId() end
    else
        if isEdit and oldId and oldId ~= id then
            id = oldId
        end
    end

    _applyNormalizeStack(values)

    -- sanitize data table
    local cleanData = {}
    if type(values.data) == "table" then
        for k, v in pairs(values.data) do
            local ks = _trim(tostring(k or ""))
            if ks ~= "" then cleanData[ks] = v end
        end
    end

    local tagsList = {}
    if type(values.tags) == "string" then
        for tag in values.tags:gmatch("[^,%s]+") do
            table.insert(tagsList, tag)
        end
    end

    -- build/overwrite the item first
    local it = ds.items[id] or {}
    it.id          = id
    it.name        = name
    it.category    = values.category or it.category or "MISC"
    it.icon        = iconId
    it.stackable   = values.stackable and true or false
    it.maxStack    = tonumber(values.maxStack) or it.maxStack or 1
    it.description = values.description or it.description
    it.rarity      = values.rarity or it.rarity or "common"
    it.data        = cleanData
    it.basePriceU      = tonumber(values.basePriceU) or it.basePriceU or 0
    it.vendorSellable  = values.vendorSellable and true or false
    it.priceOverrideC  = tonumber(values.priceOverrideC) or it.priceOverrideC or 0
    it.tags         = tagsList
    it.spellId = (values.spellId and values.spellId ~= "") and values.spellId or nil
    it.spellRank = tonumber(values.spellRank) or nil

    -- compute ilvl from the UPDATED table
    local ilvl = nil
    if ItemLevel and ItemLevel.FromItem then
        local ok, t = pcall(ItemLevel.FromItem, ItemLevel, it, false)
        if ok and type(t) == "number" then ilvl = t end
    end
    -- Fallback to local heuristic if ItemLevel.FromItem isn't available or failed
    if (not ilvl) or (type(ilvl) == "number" and ilvl == 0) then
        local ok2, t2 = pcall(_computeItemLevel, it)
        if ok2 and type(t2) == "number" then ilvl = t2 end
    end
    ilvl = tonumber(ilvl) or 1
    it.itemLevel = ilvl

    ds.items[id] = it
    return id
end

-- Paging helpers -------------------------------------------------------------
local function _updatePageText(self, totalPages)
    totalPages = math.max(1, totalPages or 1)
    local cur = math.max(1, math.min(self._page or 1, totalPages))
    if self.pageText and self.pageText.SetText then
        self.pageText:SetText(("Page %d / %d"):format(cur, totalPages))
    end
end

function ItemEditorSheet:_setPage(p)
    local total = self._items and #self._items or 0
    local totalPages = math.max(1, math.ceil(total / (self._perPage or 1)))
    local newP = math.max(1, math.min(tonumber(p) or 1, totalPages))
    if newP ~= self._page then
        self._page = newP
        self:_rebindPage()
    end
    _updatePageText(self, totalPages)

    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWin
    if DW and type(DW._resizeSoon) == "function" then
        DW:_resizeSoon(self.sheet)
    end
end

function ItemEditorSheet:_rebindPage()
    local per  = self._perPage or (#self.slots)
    local page = math.max(1, self._page or 1)
    local startIndex = (page - 1) * per + 1

    -- clear
    for _, slot in ipairs(self.slots) do
        slot._entry = nil
        if slot.SetItem then slot:SetItem(nil) end
    end

    -- bind current page
    for i = 1, per do
        local slot  = self.slots[i]
        local entry = self._items and self._items[startIndex + (i - 1)] or nil
        if not slot then break end
        slot._entry = entry
        if entry and slot.SetItem then
            slot:SetItem({
                id = entry.id,
                icon = entry.icon,
                name = entry.name,
                rarity = entry.rarity,
            })
        end
    end

    if self.sheet and self.sheet.Relayout then pcall(function() self.sheet:Relayout() end) end
end

-- ---------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------
function ItemEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.rows     = opts.rows or 6
    self.cols     = opts.cols or 8
    self.parent   = opts.parent
    self.slots    = {}
    self._page    = 1
    self._perPage = self.rows * self.cols

    -- Bind to the dataset being edited
    self:SetEditingDataset(opts and opts.editingName)

    self.sheet = VGroup:New("RPE_ItemEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV   = "TOP",
        alignH   = "CENTER",   -- match SpellEditorSheet horizontal alignment
        autoSize = true,
    })

    self.grid = VGroup:New("RPE_ItemEditor_Grid", {
        parent   = self.sheet,
        width    = 1, height = 1,
        spacingY = 8,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.grid)

    -- Build slot matrix
    local count = 1
    for _r = 1, self.rows do
        local row = HGroup:New(("RPE_ItemEditor_Row_%d"):format(_r), {
            parent  = self.grid,
            width   = 1, height = 40, spacingX = 8,
            alignV  = "CENTER", alignH = "LEFT",
            autoSize = true,
        })
        self.grid:Add(row)

        for _c = 1, self.cols do
            local slot = InventorySlot:New(("RPE_ItemEditor_Slot_%d"):format(count), {
                width = 40, height = 40, noBorder = true,
                context = "editor"
            })
            self.slots[count] = slot
            row:Add(slot)

            if slot.frame and slot.frame.HookScript then
                slot.frame:HookScript("OnMouseDown", function(_, button)
                    local entry = slot._entry  -- nil => new/empty slot

                    -- Right-click menu
                    if button == "RightButton" then
                        local Menu = RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu
                        if not Menu then return end
                        RPE_UI.Common:ContextMenu(slot.frame or UIParent, function(level)
                            if level ~= 1 then
                                -- Submenu: "Copy from..." dataset selection
                                if level == 2 then
                                    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                    if not DatasetDB then return end
                                    
                                    -- List all available datasets
                                    local allNames = DatasetDB.ListNames and DatasetDB.ListNames()
                                    if not allNames or #allNames == 0 then
                                        local info = UIDropDownMenu_CreateInfo()
                                        info.isTitle = true
                                        info.notCheckable = true
                                        info.text = "No datasets available"
                                        UIDropDownMenu_AddButton(info, level)
                                        return
                                    end
                                    
                                    table.sort(allNames)
                                    for _, dsName in ipairs(allNames) do
                                        local info = UIDropDownMenu_CreateInfo()
                                        info.notCheckable = true
                                        info.text = dsName
                                        info.hasArrow = true
                                        info.value = dsName
                                        UIDropDownMenu_AddButton(info, level)
                                    end
                                    return
                                end
                                
                                -- Submenu level 3: select item from chosen dataset
                                if level == 3 then
                                    local datasetName = UIDROPDOWNMENU_MENU_VALUE
                                    if not datasetName then return end
                                    
                                    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                    if not DatasetDB then return end
                                    
                                    local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
                                    if not sourceDs or not sourceDs.items then
                                        local info = UIDropDownMenu_CreateInfo()
                                        info.isTitle = true
                                        info.notCheckable = true
                                        info.text = "No items in dataset"
                                        UIDropDownMenu_AddButton(info, level)
                                        return
                                    end
                                    
                                    -- Collect and sort items from source dataset
                                    local items = {}
                                    for itemId, itemDef in pairs(sourceDs.items) do
                                        table.insert(items, { id = itemId, def = itemDef })
                                    end
                                    table.sort(items, function(a, b)
                                        local anName = (a.def and a.def.name) or a.id
                                        local bnName = (b.def and b.def.name) or b.id
                                        return tostring(anName):lower() < tostring(bnName):lower()
                                    end)
                                    
                                    -- Group items into chunks of 20 for submenu display
                                    local itemsPerGroup = 20
                                    local groups = {}
                                    for i = 1, #items, itemsPerGroup do
                                        local groupItems = {}
                                        for j = i, math.min(i + itemsPerGroup - 1, #items) do
                                            table.insert(groupItems, items[j])
                                        end
                                        table.insert(groups, groupItems)
                                    end
                                    
                                    -- Create submenu buttons for each group with letter ranges
                                    for groupIdx, groupItems in ipairs(groups) do
                                        if #groupItems > 0 then
                                            -- Get first and last item names for the range label
                                            local firstName = (groupItems[1].def and groupItems[1].def.name) or groupItems[1].id
                                            local lastName = (groupItems[#groupItems].def and groupItems[#groupItems].def.name) or groupItems[#groupItems].id
                                            firstName = tostring(firstName):sub(1, 1):upper()
                                            lastName = tostring(lastName):sub(1, 2):upper()
                                            local rangeLabel = (firstName == lastName) and firstName or (firstName .. "-" .. lastName)
                                            
                                            local info = UIDropDownMenu_CreateInfo()
                                            info.notCheckable = true
                                            info.text = rangeLabel
                                            info.hasArrow = true
                                            -- Encode dataset name and group index in the value
                                            info.value = datasetName .. "|" .. tostring(groupIdx)
                                            UIDropDownMenu_AddButton(info, level)
                                        end
                                    end
                                    return
                                end
                                
                                -- Submenu level 4: show items in selected group
                                if level == 4 then
                                    local encodedValue = UIDROPDOWNMENU_MENU_VALUE
                                    if not encodedValue then return end
                                    
                                    -- Decode: "datasetName|groupIdx"
                                    local pipeIdx = encodedValue:find("|", 1, true)
                                    if not pipeIdx then return end
                                    local datasetName = encodedValue:sub(1, pipeIdx - 1)
                                    local groupIdx = tonumber(encodedValue:sub(pipeIdx + 1))
                                    
                                    if not datasetName or not groupIdx then return end
                                    
                                    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                    if not DatasetDB then return end
                                    
                                    local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
                                    if not sourceDs or not sourceDs.items then
                                        return
                                    end
                                    
                                    -- Collect and sort items from source dataset (same as level 3)
                                    local items = {}
                                    for itemId, itemDef in pairs(sourceDs.items) do
                                        table.insert(items, { id = itemId, def = itemDef })
                                    end
                                    table.sort(items, function(a, b)
                                        local anName = (a.def and a.def.name) or a.id
                                        local bnName = (b.def and b.def.name) or b.id
                                        return tostring(anName):lower() < tostring(bnName):lower()
                                    end)
                                    
                                    -- Reconstruct the groups to find the selected one
                                    local itemsPerGroup = 20
                                    local selectedGroupItems = {}
                                    local currentGroupIdx = 0
                                    for i = 1, #items, itemsPerGroup do
                                        currentGroupIdx = currentGroupIdx + 1
                                        if currentGroupIdx == groupIdx then
                                            for j = i, math.min(i + itemsPerGroup - 1, #items) do
                                                table.insert(selectedGroupItems, items[j])
                                            end
                                            break
                                        end
                                    end
                                    
                                    if #selectedGroupItems == 0 then
                                        return
                                    end
                                    
                                    for _, item in ipairs(selectedGroupItems) do
                                        local info = UIDropDownMenu_CreateInfo()
                                        info.notCheckable = true
                                        info.text = (item.def and item.def.name) or item.id
                                        info.func = function()
                                            -- Copy the item
                                            local targetDs = self:GetEditingDataset()
                                            if not targetDs then return end
                                            
                                            targetDs.items = targetDs.items or {}
                                            
                                            -- Generate new ID for the copy
                                            local newId = _newItemId()
                                            while targetDs.items[newId] do
                                                newId = _newItemId()
                                            end
                                            
                                            -- Deep copy the item definition
                                            local itemCopy = {}
                                            if type(item.def) == "table" then
                                                for k, v in pairs(item.def) do
                                                    if type(v) == "table" then
                                                        -- Shallow copy for nested tables
                                                        local tblCopy = {}
                                                        for tk, tv in pairs(v) do
                                                            tblCopy[tk] = tv
                                                        end
                                                        itemCopy[k] = tblCopy
                                                    else
                                                        itemCopy[k] = v
                                                    end
                                                end
                                            end
                                            itemCopy.id = newId
                                            
                                            targetDs.items[newId] = itemCopy
                                            
                                            -- Persist the dataset
                                            local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                            if DB and DB.Save then pcall(DB.Save, targetDs) end
                                            
                                            -- Rebuild runtime registry
                                            local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                                            if reg and reg.RefreshFromActiveDatasets then
                                                reg:RefreshFromActiveDatasets()
                                            elseif reg and reg.RefreshFromActiveDataset then
                                                reg:RefreshFromActiveDataset()
                                            end
                                            
                                            -- Refresh grid + resize
                                            self:Refresh()
                                            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                                            if DW and DW._recalcSizeForContent then
                                                DW:_recalcSizeForContent(self.sheet)
                                                if DW._resizeSoon then DW:_resizeSoon(self.sheet) end
                                            end
                                            
                                            if RPE and RPE.Debug and RPE.Debug.Internal then
                                                RPE.Debug:Internal(string.format("Copied item '%s' from dataset '%s' (new ID: %s)", 
                                                    (item.def and item.def.name) or item.id, datasetName, newId))
                                            end
                                        end
                                        UIDropDownMenu_AddButton(info, level)
                                    end
                                    return
                                end
                                return
                            end

                            if level ~= 1 then return end

                            -- Title
                            local info = UIDropDownMenu_CreateInfo()
                            info.isTitle = true
                            info.notCheckable = true
                            info.text = entry and (tostring(entry.name or entry.id)) or "Empty Slot"
                            UIDropDownMenu_AddButton(info, level)

                            -- Copy from... (empty slot only)
                            local copyFrom = UIDropDownMenu_CreateInfo()
                            copyFrom.notCheckable = true
                            copyFrom.text = "Copy from..."
                            if entry then
                                copyFrom.disabled = true
                            else
                                copyFrom.hasArrow = true
                                copyFrom.func = function()
                                    -- No-op; submenu will handle it
                                end
                            end
                            UIDropDownMenu_AddButton(copyFrom, level)

                            -- Add to Inventory
                            local add = UIDropDownMenu_CreateInfo()
                            add.notCheckable = true
                            add.text = "Add to Inventory"
                            if not entry then
                                add.disabled = true
                            else
                                add.func = function()
                                    local PDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB
                                    local profile = PDB and PDB.GetOrCreateActive and PDB.GetOrCreateActive()
                                    if not profile then
                                        return
                                    end
                                    profile:AddItem(entry.id, 1)
                                end
                            end
                            UIDropDownMenu_AddButton(add, level)

                            -- Copy Item ID
                            local copyId = UIDropDownMenu_CreateInfo()
                            copyId.notCheckable = true
                            copyId.text = "Copy Item ID"
                            if not entry then
                                copyId.disabled = true
                            else
                                copyId.func = function()
                                    local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
                                    if Clipboard then
                                        Clipboard:SetContent(entry.id)
                                        Clipboard:Show()
                                        RPE.Debug:Internal("Item ID copied to clipboard: " .. entry.id)
                                    else
                                        RPE.Debug:Internal("Clipboard widget not available")
                                    end
                                end
                            end
                            UIDropDownMenu_AddButton(copyId, level)

                            -- Delete Entry
                            local del = UIDropDownMenu_CreateInfo()
                            del.notCheckable = true
                            del.text = "|cffff4040Delete Entry|r"
                            if not entry then
                                del.disabled = true
                            else
                                del.func = function()
                                    local ds = self:GetEditingDataset()
                                    if not (ds and ds.items and ds.items[entry.id]) then return end
                                    ds.items[entry.id] = nil

                                    -- Refresh registry
                                    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                                    if reg and reg.RefreshFromActiveDatasets then
                                        reg:RefreshFromActiveDatasets()
                                    elseif reg and reg.RefreshFromActiveDataset then
                                        reg:RefreshFromActiveDataset()
                                    end

                                    -- Refresh grid + resize
                                    self:Refresh()
                                    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                                    if DW and DW._recalcSizeForContent then
                                        DW:_recalcSizeForContent(self.sheet)
                                        if DW._resizeSoon then DW:_resizeSoon(self.sheet) end
                                    end
                                end
                            end
                            UIDropDownMenu_AddButton(del, level)
                            
                            -- Export Item (compact, wrapped with key)
                            local exportItem = UIDropDownMenu_CreateInfo()
                            exportItem.notCheckable = true
                            exportItem.text = "Export Item"
                            if not entry then
                                exportItem.disabled = true
                            else
                                exportItem.func = function()
                                    local ds = self:GetEditingDataset()
                                    if ds and ds.items and entry.id and ds.items[entry.id] then
                                        local Export = _G.RPE and _G.RPE.Data and _G.RPE.Data.Export
                                        if Export and Export.ToClipboard then
                                            Export.ToClipboard(ds.items[entry.id], { format = "compact", key = entry.id })
                                            if RPE and RPE.Debug and RPE.Debug.Internal then
                                                RPE.Debug:Internal("Item exported to clipboard (compact, wrapped): " .. entry.id)
                                            end
                                        else
                                            print("Export utility not available.")
                                        end
                                    end
                                end
                            end
                            UIDropDownMenu_AddButton(exportItem, level)
                        end)
                        return
                    end

                    if button ~= "LeftButton" then return end

                    -- Left-click: open the wizard via DatasetWindow
                    local ds       = self:GetEditingDataset()
                    local entryId  = entry and entry.id or "(new)"
                    local itemData = (entry and ds and ds.items and ds.items[entry.id]) or nil
                    local isEdit   = entry and true or false
                    local schema   = _buildItemSchema(entryId, itemData, isEdit)

                    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                    if not (DW and DW.ShowWizard) then
                        return
                    end

                    DW:ShowWizard({
                        schema  = schema,
                        isEdit  = isEdit,
                        onCancel = function()
                            self:Refresh()
                        end,
                        onSave = function(values)
                            local ds2 = self:GetEditingDataset()
                            if not ds2 then
                                return
                            end

                            if type(values.data) ~= "table" then values.data = {} end

                            local newId, err = _saveItemValues(ds2, entry and entry.id or nil, values, isEdit, entry and entry.id or nil)
                            if not newId then
                                return
                            end

                            -- Persist the dataset
                            local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                            if DB and DB.Save then pcall(DB.Save, ds2) end

                            -- Rebuild runtime registry (if active)
                            local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                            if reg and reg.RefreshFromActiveDatasets then
                                reg:RefreshFromActiveDatasets()
                            elseif reg and reg.RefreshFromActiveDataset then
                                reg:RefreshFromActiveDataset()
                            end

                            -- Refresh grid + resize
                            self:Refresh()
                            local DW2 = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                            if DW2 and DW2._recalcSizeForContent then
                                DW2:_recalcSizeForContent(self.sheet)
                                if DW2._resizeSoon then DW2:_resizeSoon(self.sheet) end
                            end

                        end,
                    })
                end)
            end

            count = count + 1
        end
    end

    -- Centered pagination row (matches SpellEditorSheet)
    local navWrap = VGroup:New("RPE_ItemEditor_NavWrap", {
        parent   = self.sheet,
        width    = 1, height = 1,
        alignH   = "CENTER",
        alignV   = "CENTER",
        autoSize = true,
    })

    local nav = HGroup:New("RPE_ItemEditor_Nav", {
        parent   = navWrap,
        width    = 1, height = 1,
        spacingX = 10,
        alignV   = "CENTER",
        autoSize = true,
    })

    local prevBtn = TextBtn:New("RPE_ItemEditor_Prev", {
        parent = nav, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) - 1) end,
    })
    nav:Add(prevBtn)

    self.pageText = Text:New("RPE_ItemEditor_PageText", {
        parent = nav, text = "Page 1 / 1",
        fontTemplate = "GameFontNormalSmall",
    })
    nav:Add(self.pageText)

    local nextBtn = TextBtn:New("RPE_ItemEditor_Next", {
        parent = nav, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) + 1) end,
    })
    nav:Add(nextBtn)

    navWrap:Add(nav)
    self.sheet:Add(navWrap)

    self:Refresh()
end

function ItemEditorSheet:Refresh()
    local ds = self:GetEditingDataset()
    self._items = _collectItemsSorted(ds)

    local totalPages = math.max(1, math.ceil((#self._items) / (self._perPage or 1)))
    if (self._page or 1) > totalPages then self._page = totalPages end
    if (self._page or 0) < 1 then self._page = 1 end

    self:_rebindPage()
    _updatePageText(self, totalPages)

    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWin
    if DW and type(DW._resizeSoon) == "function" then
        DW:_resizeSoon(self.sheet)
    end
end

function ItemEditorSheet.New(opts)
    local self = setmetatable({}, ItemEditorSheet)
    self:BuildUI(opts or {})
    return self
end

return ItemEditorSheet
