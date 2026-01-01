-- RPE_UI/Elements/EditorTable.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local Input    = RPE_UI.Elements.Input
local Button   = RPE_UI.Elements.TextButton
local IconBtn  = RPE_UI.Elements.IconButton
local Dropdown = RPE_UI.Elements.Dropdown   -- NEW: for select columns

---@class EditorTable
---@field root any
---@field header any
---@field body any
---@field rows table[]
---@field onChange fun()|nil
---@field _baseName string
---@field _uid integer
---@field KEY_W number
---@field VALUE_W number
---@field mode "kv"|"rows"
---@field columns table[]|nil
---@field minRows integer
local EditorTable = {}
EditorTable.__index = EditorTable
RPE_UI.Elements.EditorTable = EditorTable

-- =========================
-- Constants / helpers
-- =========================
local REMOVE_W = 28
local GAP_X    = 8

local function _fireChange(self)
    if type(self.onChange) == "function" then
        pcall(self.onChange)
    end
end

-- per-instance unique name generator
local function _uname(self, suffix)
    self._uid = (self._uid or 0) + 1
    return string.format("%s_%s_%04d", self._baseName or "RPE_ET2", suffix or "Node", self._uid)
end

local function _dw_resize_now()
    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW then
        local target = (DW.wizard and DW.wizard.sheet) or (DW.GetActiveSheet and DW:GetActiveSheet()) or nil
        if DW._recalcSizeForContent then DW:_recalcSizeForContent(target or DW.content or DW.root) end
        if DW._resizeSoon then DW:_resizeSoon(target or DW.GetActiveSheet and DW:GetActiveSheet() or nil) end
    end
end

local function _colWidth(col)
    if not col then return 140 end
    if tonumber(col.width) then return tonumber(col.width) end
    local t = (col.type or "input")
    if t == "number" then return 90 end
    if t == "select" then return 140 end
    if t == "lookup" then return 200 end
    return 160
end

-- =========================
-- Public API
-- =========================

-- Return either:
--   mode="kv"   -> { [key]=value, ... }
--   mode="rows" -> { { [columns[i].id]=value, ... }, ... }
function EditorTable:GetData()
    if self.mode == "rows" then
        local out = {}
        for _, r in ipairs(self.rows) do
            local rec = {}
            for i, c in ipairs(self.columns or {}) do
                local cell = r.cells[i]
                if cell then
                    local t = (c.type or "input")
                    if t == "select" and cell.get then
                        rec[c.id or tostring(i)] = cell.get()
                    else
                        local s = (cell.get and cell.get()) or ""
                        if t == "number" then
                            local n = tonumber(s)
                            rec[c.id or tostring(i)] = n or s -- allow formulas/strings
                        else
                            rec[c.id or tostring(i)] = s
                        end
                    end
                end
            end
            -- keep row if any field is non-empty
            local keep = false
            for _, v in pairs(rec) do if v ~= nil and tostring(v) ~= "" then keep = true break end end
            if keep then table.insert(out, rec) end
        end
        return out
    end

    -- legacy KV map
    local out = {}
    for _, r in ipairs(self.rows) do
        local k = (r.keyInput.GetText and r.keyInput:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if k ~= "" then
            out[k] = r.valInput:GetText() or ""
        end
    end
    return out
end

-- Accepts:
--   mode="kv"   -> map
--   mode="rows" -> array of row tables OR empty/nil
function EditorTable:SetData(tbl)
    self:Clear()

    if self.mode == "rows" then
        if type(tbl) == "table" then
            local isArray = (#tbl > 0)
            if isArray then
                for _, row in ipairs(tbl) do self:_addRow_structured(row) end
            else
                self:_addRow_structured(tbl)
            end
        end
        local need = math.max(1, self.minRows or 1)
        while #self.rows < need do self:_addRow_structured({}) end
        if #self.rows == 0 then self:_addRow_structured({}) end
        _fireChange(self)
        return
    end

    -- legacy KV map mode
    if type(tbl) == "table" then
        local keys = {}
        for k in pairs(tbl) do keys[#keys+1] = tostring(k) end
        table.sort(keys)
        for _, k in ipairs(keys) do
            self:AddRow(k, tostring(tbl[k] or ""))
        end
    end
    if #self.rows == 0 then
        self:AddRow("", "")
    end
    _fireChange(self)
end

function EditorTable:SetOnChange(fn)
    self.onChange = fn
end

function EditorTable:Clear()
    for _, r in ipairs(self.rows) do
        if r.row and r.row.Destroy then r.row:Destroy() end
    end
    self.rows = {}
end

-- Legacy API for KV tables only
function EditorTable:SetColumnWidths(keyW, valueW)
    if self.mode ~= "kv" then return end
    self.KEY_W   = tonumber(keyW)   or self.KEY_W
    self.VALUE_W = tonumber(valueW) or self.VALUE_W

    if self.hdrKey and self.hdrKey.frame then self.hdrKey.frame:SetWidth(self.KEY_W) end
    if self.hdrVal and self.hdrVal.frame then self.hdrVal.frame:SetWidth(self.VALUE_W) end

    for _, r in ipairs(self.rows) do
        if r.keyInput and r.keyInput.frame then r.keyInput.frame:SetWidth(self.KEY_W) end
        if r.valInput and r.valInput.frame then r.valInput.frame:SetWidth(self.VALUE_W) end
    end
end

-- =========================
-- Lookup / Search functionality
-- =========================

--- Show lookup menu for selecting items/recipes/spells/auras/stats from datasets
--- @param inputField any - The input element to populate with selected ID
--- @param parentFrame any - The frame to anchor the menu to
--- @param allowedTypes string|table|nil - "items", "recipes", "spells", "auras", "stats", or nil for all
--- @param onSelect fun(id: string)|nil - Optional callback after selection
function EditorTable:ShowLookupMenu(inputField, parentFrame, allowedTypes, onSelect)
    if not (inputField and parentFrame) then return end
    
    -- Normalize allowedTypes to table
    local typeFilter = {}
    if allowedTypes then
        if type(allowedTypes) == "string" then
            typeFilter[allowedTypes] = true
        elseif type(allowedTypes) == "table" then
            for _, t in ipairs(allowedTypes) do
                typeFilter[t] = true
            end
        end
    else
        -- If nil, allow all types
        typeFilter.items = true
        typeFilter.recipes = true
        typeFilter.spells = true
        typeFilter.auras = true
        typeFilter.stats = true
    end
    
    local Common = _G.RPE_UI and _G.RPE_UI.Common
    if not (Common and Common.ContextMenu) then return end
    
    Common:ContextMenu(parentFrame or UIParent, function(level)
        if level == 1 then
            -- Level 1: Show datasets
            local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
            if not DatasetDB then return end
            
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
        
        if level == 2 then
            -- Level 2: Show available types based on filter
            local datasetName = UIDROPDOWNMENU_MENU_VALUE
            if not datasetName then return end
            
            local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
            if not DatasetDB then return end
            
            local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
            if not sourceDs then return end
            
            -- Check availability based on filter
            local hasItems = typeFilter.items and sourceDs.items and next(sourceDs.items)
            local hasRecipes = typeFilter.recipes and (
                (sourceDs.recipes and next(sourceDs.recipes)) or 
                (sourceDs.extra and sourceDs.extra.recipes and next(sourceDs.extra.recipes))
            )
            local hasSpells = typeFilter.spells and (
                (sourceDs.spells and next(sourceDs.spells)) or
                (sourceDs.extra and sourceDs.extra.spells and next(sourceDs.extra.spells))
            )
            local hasAuras = typeFilter.auras and (
                (sourceDs.auras and next(sourceDs.auras)) or
                (sourceDs.extra and sourceDs.extra.auras and next(sourceDs.extra.auras))
            )
            local hasStats = typeFilter.stats and (
                (sourceDs.stats and next(sourceDs.stats)) or
                (sourceDs.extra and sourceDs.extra.stats and next(sourceDs.extra.stats))
            )
            
            if not hasItems and not hasRecipes and not hasSpells and not hasAuras and not hasStats then
                local typeList = {}
                if typeFilter.items then table.insert(typeList, "items") end
                if typeFilter.recipes then table.insert(typeList, "recipes") end
                if typeFilter.spells then table.insert(typeList, "spells") end
                if typeFilter.auras then table.insert(typeList, "auras") end
                if typeFilter.stats then table.insert(typeList, "stats") end
                local typeStr = table.concat(typeList, ", ")
                
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "No " .. typeStr .. " found"
                UIDropDownMenu_AddButton(info, level)
                return
            end
            
            if hasItems then
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = "Items"
                info.hasArrow = true
                info.value = datasetName .. "|items"
                UIDropDownMenu_AddButton(info, level)
            end
            
            if hasRecipes then
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = "Recipes"
                info.hasArrow = true
                info.value = datasetName .. "|recipes"
                UIDropDownMenu_AddButton(info, level)
            end
            
            if hasSpells then
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = "Spells"
                info.hasArrow = true
                info.value = datasetName .. "|spells"
                UIDropDownMenu_AddButton(info, level)
            end
            
            if hasAuras then
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = "Auras"
                info.hasArrow = true
                info.value = datasetName .. "|auras"
                UIDropDownMenu_AddButton(info, level)
            end
            
            if hasStats then
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = "Stats"
                info.hasArrow = true
                info.value = datasetName .. "|stats"
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
        
        if level == 3 then
            -- Level 3: Show items/recipes/spells/auras/stats grouped by first letter
            local encodedValue = UIDROPDOWNMENU_MENU_VALUE
            if not encodedValue then return end
            
            local pipeIdx = encodedValue:find("|", 1, true)
            if not pipeIdx then return end
            local datasetName = encodedValue:sub(1, pipeIdx - 1)
            local itemType = encodedValue:sub(pipeIdx + 1)
            
            local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
            if not DatasetDB then return end
            
            local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
            if not sourceDs then return end
            
            -- Collect items/recipes/spells/auras/stats based on type
            local items = {}
            if itemType == "items" and sourceDs.items then
                for itemId, itemDef in pairs(sourceDs.items) do
                    table.insert(items, { id = itemId, def = itemDef })
                end
            elseif itemType == "recipes" then
                local recipesBucket = {}
                if sourceDs.recipes then
                    for id, recipe in pairs(sourceDs.recipes) do
                        recipesBucket[id] = recipe
                    end
                end
                if sourceDs.extra and sourceDs.extra.recipes then
                    for id, recipe in pairs(sourceDs.extra.recipes) do
                        recipesBucket[id] = recipe
                    end
                end
                for recipeId, recipeDef in pairs(recipesBucket) do
                    table.insert(items, { id = recipeId, def = recipeDef })
                end
            elseif itemType == "spells" then
                local spellsBucket = {}
                if sourceDs.spells then
                    for id, spell in pairs(sourceDs.spells) do
                        spellsBucket[id] = spell
                    end
                end
                if sourceDs.extra and sourceDs.extra.spells then
                    for id, spell in pairs(sourceDs.extra.spells) do
                        spellsBucket[id] = spell
                    end
                end
                for spellId, spellDef in pairs(spellsBucket) do
                    table.insert(items, { id = spellId, def = spellDef })
                end
            elseif itemType == "auras" then
                local aurasBucket = {}
                if sourceDs.auras then
                    for id, aura in pairs(sourceDs.auras) do
                        aurasBucket[id] = aura
                    end
                end
                if sourceDs.extra and sourceDs.extra.auras then
                    for id, aura in pairs(sourceDs.extra.auras) do
                        aurasBucket[id] = aura
                    end
                end
                for auraId, auraDef in pairs(aurasBucket) do
                    table.insert(items, { id = auraId, def = auraDef })
                end
            elseif itemType == "stats" then
                local statsBucket = {}
                if sourceDs.stats then
                    for id, stat in pairs(sourceDs.stats) do
                        statsBucket[id] = stat
                    end
                end
                if sourceDs.extra and sourceDs.extra.stats then
                    for id, stat in pairs(sourceDs.extra.stats) do
                        statsBucket[id] = stat
                    end
                end
                for statId, statDef in pairs(statsBucket) do
                    table.insert(items, { id = statId, def = statDef })
                end
            end
            
            if #items == 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "No " .. itemType .. " found"
                UIDropDownMenu_AddButton(info, level)
                return
            end
            
            -- Sort by name
            table.sort(items, function(a, b)
                local anName = (a.def and a.def.name) or a.id
                local bnName = (b.def and b.def.name) or b.id
                return tostring(anName):lower() < tostring(bnName):lower()
            end)
            
            -- Group into chunks of 20
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
                    local firstName = (groupItems[1].def and groupItems[1].def.name) or groupItems[1].id
                    local lastName = (groupItems[#groupItems].def and groupItems[#groupItems].def.name) or groupItems[#groupItems].id
                    firstName = tostring(firstName):sub(1, 1):upper()
                    lastName = tostring(lastName):sub(1, 2):upper()
                    local rangeLabel = (firstName == lastName) and firstName or (firstName .. "-" .. lastName)
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.notCheckable = true
                    info.text = rangeLabel
                    info.hasArrow = true
                    info.value = datasetName .. "|" .. itemType .. "|" .. tostring(groupIdx)
                    UIDropDownMenu_AddButton(info, level)
                end
            end
            return
        end
        
        if level == 4 then
            -- Level 4: Show individual items/recipes/spells/auras/stats in the selected group
            local encodedValue = UIDROPDOWNMENU_MENU_VALUE
            if not encodedValue then return end
            
            -- Parse: "datasetName|itemType|groupIdx"
            local parts = {}
            for part in encodedValue:gmatch("[^|]+") do
                table.insert(parts, part)
            end
            if #parts < 3 then return end
            
            local datasetName = parts[1]
            local itemType = parts[2]
            local groupIdx = tonumber(parts[3])
            
            local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
            if not DatasetDB then return end
            
            local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
            if not sourceDs then return end
            
            -- Reconstruct items/recipes/spells/auras/stats
            local items = {}
            if itemType == "items" and sourceDs.items then
                for itemId, itemDef in pairs(sourceDs.items) do
                    table.insert(items, { id = itemId, def = itemDef })
                end
            elseif itemType == "recipes" then
                local recipesBucket = {}
                if sourceDs.recipes then
                    for id, recipe in pairs(sourceDs.recipes) do
                        recipesBucket[id] = recipe
                    end
                end
                if sourceDs.extra and sourceDs.extra.recipes then
                    for id, recipe in pairs(sourceDs.extra.recipes) do
                        recipesBucket[id] = recipe
                    end
                end
                for recipeId, recipeDef in pairs(recipesBucket) do
                    table.insert(items, { id = recipeId, def = recipeDef })
                end
            elseif itemType == "spells" then
                local spellsBucket = {}
                if sourceDs.spells then
                    for id, spell in pairs(sourceDs.spells) do
                        spellsBucket[id] = spell
                    end
                end
                if sourceDs.extra and sourceDs.extra.spells then
                    for id, spell in pairs(sourceDs.extra.spells) do
                        spellsBucket[id] = spell
                    end
                end
                for spellId, spellDef in pairs(spellsBucket) do
                    table.insert(items, { id = spellId, def = spellDef })
                end
            elseif itemType == "auras" then
                local aurasBucket = {}
                if sourceDs.auras then
                    for id, aura in pairs(sourceDs.auras) do
                        aurasBucket[id] = aura
                    end
                end
                if sourceDs.extra and sourceDs.extra.auras then
                    for id, aura in pairs(sourceDs.extra.auras) do
                        aurasBucket[id] = aura
                    end
                end
                for auraId, auraDef in pairs(aurasBucket) do
                    table.insert(items, { id = auraId, def = auraDef })
                end
            elseif itemType == "stats" then
                local statsBucket = {}
                if sourceDs.stats then
                    for id, stat in pairs(sourceDs.stats) do
                        statsBucket[id] = stat
                    end
                end
                if sourceDs.extra and sourceDs.extra.stats then
                    for id, stat in pairs(sourceDs.extra.stats) do
                        statsBucket[id] = stat
                    end
                end
                for statId, statDef in pairs(statsBucket) do
                    table.insert(items, { id = statId, def = statDef })
                end
            end
            
            table.sort(items, function(a, b)
                local anName = (a.def and a.def.name) or a.id
                local bnName = (b.def and b.def.name) or b.id
                return tostring(anName):lower() < tostring(bnName):lower()
            end)
            
            -- Find the group
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
            
            if #selectedGroupItems == 0 then return end
            
            for _, item in ipairs(selectedGroupItems) do
                local info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = (item.def and item.def.name) or item.id
                info.func = function()
                    -- Set the lookup input to the selected ID
                    inputField:SetText(item.id)
                    _fireChange(self)
                    if onSelect then
                        pcall(onSelect, item.id)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
    end)
end

-- =========================
-- Row creation
-- =========================

-- KV mode
function EditorTable:AddRow(key, value)
    if self.mode == "rows" then
        return self:_addRow_structured(type(key)=="table" and key or nil) -- key=record
    end

    local rowName = _uname(self, "Row")
    local row = HGroup:New(rowName, {
        parent   = self.body,
        spacingX = GAP_X,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.body:Add(row)

    local keyInput = Input:New(rowName .. "_Key", {
        parent = row,
        width  = self.KEY_W, height = 20,
        text   = tostring(key or ""),
        onEnterPressed = function() _fireChange(self) end,
        onTextChanged  = function() _fireChange(self) end,
        placeholder    = "key",
    })
    row:Add(keyInput)

    local valInput = Input:New(rowName .. "_Val", {
        parent = row,
        width  = self.VALUE_W, height = 20,
        text   = tostring(value or ""),
        onEnterPressed = function() _fireChange(self) end,
        onTextChanged  = function() _fireChange(self) end,
        placeholder    = "value",
    })
    row:Add(valInput)

    local removeBtn = Button:New(rowName .. "_Remove", {
        parent = row,
        width  = REMOVE_W, height = 22,
        text   = RPE.Common.InlineIcons.Cancel,
        onClick = function()
            for i, rr in ipairs(self.rows) do
                if rr.row == row then
                    if rr.row.Destroy then rr.row:Destroy() end
                    table.remove(self.rows, i)
                    _dw_resize_now()
                    break
                end
            end
            if #self.rows == 0 then
                self:AddRow("", "")
            end
            _fireChange(self)
        end,
        noBorder = true,
    })
    row:Add(removeBtn)

    local obj = { row = row, keyInput = keyInput, valInput = valInput, removeBtn = removeBtn }
    table.insert(self.rows, obj)

    _dw_resize_now()
    return obj
end

-- Structured "rows" mode
function EditorTable:_addRow_structured(record)
    local rowName = _uname(self, "Row")
    local row = HGroup:New(rowName, {
        parent   = self.body,
        spacingX = GAP_X,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.body:Add(row)

    local cells = {}
    for i, col in ipairs(self.columns or {}) do
        local cid = col.id or tostring(i)
        local ctype = (col.type or "input"):lower()
        local width = _colWidth(col)

        if ctype == "select" and Dropdown then
            local dd = Dropdown:New(rowName .. "_Sel_"..cid, {
                parent  = row,
                width   = width, height = 22,
                value   = record and (record[cid] or record[i]) or (col.choices and col.choices[1]) or "",
                choices = col.choices or {},
            })
            row:Add(dd)
            table.insert(cells, { id=cid, type="select", get=function() return dd:GetValue() end })

        elseif ctype == "lookup" then
            -- Lookup field: input + paste button + lookup button
            local txt = record and (record[cid] or record[i]) or ""
            local lookupInput = Input:New(rowName .. "_Lookup_Inp_"..cid, {
                parent = row, width = width, height = 20,
                text   = tostring(txt or ""),
                onEnterPressed = function() _fireChange(self) end,
                onTextChanged  = function() _fireChange(self) end,
                placeholder    = col.placeholder or "",
            })
            row:Add(lookupInput)

            -- Paste button
            local pasteBtn = IconBtn:New(rowName .. "_Lookup_Paste_"..cid, {
                parent = row, width = 16, height = 16,
                icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\paste.png",
                noBackground = true, hasBackground = false,
                noBorder = true, hasBorder = false,
                tooltip = "Paste from Clipboard",
                onClick = function()
                    local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
                    if not Clipboard then
                        if RPE and RPE.Debug then
                            RPE.Debug:Warning("Clipboard widget not available")
                        end
                        return
                    end
                    
                    local pattern = col.pattern or "^item%-[a-fA-F0-9]+$"
                    local value = Clipboard:GetClipboardText(pattern)
                    if value then
                        lookupInput:SetText(value)
                        _fireChange(self)
                    else
                        if RPE and RPE.Debug then
                            RPE.Debug:Warning("Clipboard is empty or content does not match pattern")
                        end
                    end
                end,
            })
            row:Add(pasteBtn)

            -- Lookup button
            local lookupBtn = IconBtn:New(rowName .. "_Lookup_Search_"..cid, {
                parent = row, width = 16, height = 16,
                icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\lookup.png",
                noBackground = true, hasBackground = false,
                noBorder = true, hasBorder = false,
                tooltip = "Lookup",
                onClick = function()
                    -- Call the ShowLookupMenu method with optional type filter from column config
                    self:ShowLookupMenu(lookupInput, row.frame or UIParent, col.lookupTypes, nil)
                end,
            })
            row:Add(lookupBtn)

            table.insert(cells, { id=cid, type="lookup", get=function() return lookupInput:GetText() end })

        else
            -- default = "input" and also "number" uses Input
            local txt = record and (record[cid] or record[i]) or ""
            local input = Input:New(rowName .. "_Inp_"..cid, {
                parent = row, width = width, height = 20,
                text   = tostring(txt or ""),
                onEnterPressed = function() _fireChange(self) end,
                onTextChanged  = function() _fireChange(self) end,
                placeholder    = col.placeholder or "",
            })
            row:Add(input)
            table.insert(cells, { id=cid, type=ctype, get=function() return input:GetText() end })
        end
    end

    local removeBtn = Button:New(rowName .. "_Remove", {
        parent = row,
        width  = REMOVE_W, height = 22,
        text   = RPE.Common.InlineIcons.Cancel,
        onClick = function()
            for i, rr in ipairs(self.rows) do
                if rr.row == row then
                    if rr.row.Destroy then rr.row:Destroy() end
                    table.remove(self.rows, i)
                    if #self.rows < (self.minRows or 1) then
                        self:_addRow_structured({})
                    end
                    _dw_resize_now()
                    break
                end
            end
            _fireChange(self)
        end,
        noBorder = true,
    })
    row:Add(removeBtn)

    local obj = { row = row, cells = cells, removeBtn = removeBtn }
    table.insert(self.rows, obj)

    _dw_resize_now()
    return obj
end

-- =========================
-- Build
-- =========================
function EditorTable:BuildUI(name, opts)
    self.rows      = {}
    self._baseName = name or "RPE_EditorTable2"
    self._uid      = 0

    -- Mode detection
    self.columns = (type(opts.columns) == "table") and opts.columns or nil
    self.mode    = (self.columns and "rows") or (opts.mode == "rows" and "rows") or "kv"
    self.minRows = tonumber(opts.minRows or 1) or 1

    self.KEY_W     = tonumber(opts.keyWidth)   or 190
    self.VALUE_W   = tonumber(opts.valueWidth) or 190

    self.root = VGroup:New(_uname(self, "Root"), {
        parent   = opts.parent,
        width    = 1, height = 1,
        padding  = { left = 0, right = 0, top = 0, bottom = 0 },
        spacingY = 6,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })

    if self.root and self.root.frame and self.root.frame.HookScript then
        self.root.frame:HookScript("OnSizeChanged", function()
            _dw_resize_now()
        end)
    end

    -- Header
    self.header = HGroup:New(_uname(self, "Header"), {
        parent   = self.root,
        spacingX = GAP_X,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.root:Add(self.header)

    if self.mode == "rows" then
        self._hdrCols = {}
        for i, col in ipairs(self.columns or {}) do
            local hdr = Text:New(_uname(self, "HdrCol_"..(col.id or tostring(i))), {
                parent = self.header,
                text   = tostring(col.header or col.id or ("Col "..i)),
                fontTemplate = "GameFontNormal",
            })
            self.header:Add(hdr)
            if hdr.frame and hdr.frame.SetWidth then hdr.frame:SetWidth(_colWidth(col)) end
            table.insert(self._hdrCols, hdr)
        end
        local addBtn = Button:New(_uname(self, "Add"), {
            parent = self.header, width = 40, height = 22, text = "+ Add",
            onClick = function()
                self:_addRow_structured({})
                _fireChange(self)
            end,
            noBorder = true,
        })
        self.header:Add(addBtn)

    else
        -- Legacy 2-column KV header
        self.hdrKey = Text:New(_uname(self, "HdrKey"), {
            parent = self.header, text = "Key", fontTemplate = "GameFontNormal"
        })
        self.header:Add(self.hdrKey); self.hdrKey.frame:SetWidth(self.KEY_W)

        self.hdrVal = Text:New(_uname(self, "HdrValue"), {
            parent = self.header, text = "Value", fontTemplate = "GameFontNormal"
        })
        self.header:Add(self.hdrVal); self.hdrVal.frame:SetWidth(self.VALUE_W)

        local addBtn = Button:New(_uname(self, "Add"), {
            parent = self.header, width = 72, height = 22, text = "+ Add",
            onClick = function()
                self:AddRow("", "")
                _fireChange(self)
            end,
            noBorder = true,
        })
        self.header:Add(addBtn)
    end

    -- Body (rows)
    self.body = VGroup:New(_uname(self, "Body"), {
        parent   = self.root,
        spacingY = 4,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.root:Add(self.body)

    -- Seed data
    self:SetData(opts.data or {})

    return self
end

function EditorTable.New(name, opts)
    assert(opts and opts.parent, "EditorTable.New requires opts.parent")
    local o = setmetatable({}, EditorTable)
    o:BuildUI(name, opts or {})
    return o
end

return EditorTable
