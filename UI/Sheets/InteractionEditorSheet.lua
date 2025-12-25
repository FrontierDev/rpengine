-- RPE_UI/Sheets/InteractionEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE.ActiveRules = RPE.ActiveRules

local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Input    = RPE_UI.Elements.Input
local Common   = _G.RPE_UI and _G.RPE_UI.Common

---@class InteractionEditorSheet
local InteractionEditorSheet = {}
_G.RPE_UI.Windows.InteractionEditorSheet = InteractionEditorSheet
InteractionEditorSheet.__index = InteractionEditorSheet
InteractionEditorSheet.Name = "InteractionEditorSheet"

-- ============================================================================
-- Dataset helpers
-- ============================================================================
function InteractionEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then
        self.editingName = name
    else
        self.editingName = nil
    end
end

function InteractionEditorSheet:GetEditingDataset()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
    if not (DB and self.editingName) then return nil end
    for _, fname in ipairs({ "GetByName", "GetByKey", "Get" }) do
        local fn = DB[fname]
        if type(fn) == "function" then
            local ok1, ds1 = pcall(fn, DB, self.editingName); if ok1 and ds1 then
                ds1.extra = ds1.extra or {}
                ds1.extra.interactions = ds1.extra.interactions or {}
                return ds1
            end
            local ok2, ds2 = pcall(fn, self.editingName); if ok2 and ds2 then
                ds2.extra = ds2.extra or {}
                ds2.extra.interactions = ds2.extra.interactions or {}
                return ds2
            end
        end
    end
    return nil
end

function InteractionEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- ============================================================================
-- Helpers
-- ============================================================================
local function _trim(s)
    return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$",""))
end

local function _newGUID(prefix)
    if Common and Common.GenerateGUID then
        return Common:GenerateGUID(prefix or "ixn")
    end
    local hi, lo = math.random(0, 0xFFFF), math.random(0, 0xFFFF)
    return string.format("%s-%04x%04x", prefix or "ixn", hi, lo)
end

local function _collectInteractionsSorted(ds)
    local bucket = (ds and ds.extra and ds.extra.interactions) or {}
    local list = {}
    for id, def in pairs(bucket) do
        if type(def) == "table" then
            table.insert(list, {
                id = id,
                target = tostring(def.target or "(none)"),
                options = def.options or {},
            })
        end
    end
    table.sort(list, function(a,b)
        return tostring(a.target):lower() < tostring(b.target):lower()
    end)
    return list
end

local function _updatePageText(self, totalPages, totalCount)
    totalPages = math.max(1, totalPages or 1)
    local cur = math.max(1, math.min(self._page or 1, totalPages))
    local count = tonumber(totalCount or 0) or 0
    if self.pageText and self.pageText.SetText then
        self.pageText:SetText(("Page %d / %d  ·  %d result%s"):format(
            cur, totalPages, count, (count == 1) and "" or "s"))
    end
end

-- ============================================================================
-- Save + Schema
-- ============================================================================
local function _buildInteractionSchema(id, def, isEdit)
    def = def or {}
    return {
        title = (isEdit and ("Edit Interaction: " .. tostring(id))) or "New Interaction",
        pages = {
            {
                title = "Basics",
                elements = {
                    { id="target", label="Target (NPC ID or type)", type="input",
                      required=true, default = def.target or "" },
                }
            },
            {
                title = "Options",
                elements = {
                    { id="options", label="Options", type="interaction_options",
                      default = type(def.options) == "table" and def.options or {} },
                }
            },
        },
        labelWidth = 160,
        navSaveAlways = true,
    }
end

local function _saveInteraction(ds, id, v)
    if not ds then return nil, "No dataset" end
    ds.extra = ds.extra or {}
    ds.extra.interactions = ds.extra.interactions or {}

    local target = _trim(v.target or "")
    if target == "" then return nil, "Target is required" end
    
    local options = type(v.options) == "table" and v.options or {}
    if #options == 0 then return nil, "At least one option required" end

    ds.extra.interactions[id] = { id = id, target = target, options = options }
    return id
end

-- ============================================================================
-- Row binding
-- ============================================================================
local function _bindRow(self, row, entry)
    if not row or not row.frame then return end
    if not entry then
        if row.frame.Hide then row.frame:Hide() end
        return
    end
    if row.frame.Show then row.frame:Show() end

    if row._targetText and row._targetText.SetText then
        local optCount = #entry.options
        local text = string.format("%s  |cff9d9d9d(%d option%s)|r",
            entry.target or entry.id,
            optCount, (optCount == 1) and "" or "s")
        row._targetText:SetText(text)
    end

    row._entry = entry
end

local function _buildRow(self, i)
    local row = HGroup:New(("RPE_InteractionEditor_Row_%d"):format(i), {
        parent = self.list, width = 1, height = 28,
        spacingX = 10, alignV = "CENTER", alignH = "LEFT",
        autoSize = true,
    })
    self.list:Add(row)

    local t = Text:New(("RPE_InteractionEditor_Target_%d"):format(i), {
        parent = row,
        text = "—",
        fontTemplate = "GameFontNormal",
    })
    row:Add(t)
    row._targetText = t

    local menuBtn = TextBtn:New(("RPE_InteractionEditor_Menu_%d"):format(i), {
        parent = row, width = 28, height = 22, text = "...",
        hasBorder = false, noBorder = true,
        onClick = function()
            local e = row._entry
            if not e or not Common or not Common.ContextMenu then return end

            Common:ContextMenu(row.frame or UIParent, function(level, menuList)
                if level == 1 then
                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle, info.notCheckable = true, true
                    info.text = e.target or e.id
                    UIDropDownMenu_AddButton(info, level)

                    -- Copy from other datasets
                    local copyFrom = UIDropDownMenu_CreateInfo()
                    copyFrom.notCheckable = true
                    copyFrom.text = "Copy from..."
                    copyFrom.hasArrow = true
                    copyFrom.menuList = "COPY_FROM_DATASET"
                    UIDropDownMenu_AddButton(copyFrom, level)

                    UIDropDownMenu_AddButton({
                        text = "Edit", notCheckable = true,
                        func = function()
                            local ds = self:GetEditingDataset()
                            local full = (ds and ds.extra and ds.extra.interactions and ds.extra.interactions[e.id]) or e
                            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                            if DW and DW.ShowWizard then
                                DW:ShowWizard({
                                    schema = _buildInteractionSchema(e.id, full, true),
                                    isEdit = true,
                                    onSave = function(values)
                                        local ds2 = self:GetEditingDataset()
                                        local okId = _saveInteraction(ds2, e.id, values)
                                        if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                            pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                        end
                                        self:Refresh()
                                    end,
                                })
                            end
                        end,
                    }, level)

                    UIDropDownMenu_AddButton({
                        text = "Clone", notCheckable = true,
                        func = function()
                            local ds = self:GetEditingDataset()
                            if not ds then return end
                            local copy = {}
                            for k,v in pairs(e) do copy[k] = v end
                            local newId = _newGUID("ixn")
                            ds.extra.interactions[newId] = copy
                            if _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                            end
                            self:Refresh()
                        end,
                    }, level)

                    UIDropDownMenu_AddButton({
                        text = "|cffff4040Delete Entry|r", notCheckable = true,
                        func = function()
                            local ds = self:GetEditingDataset()
                            if not (ds and ds.extra and ds.extra.interactions and ds.extra.interactions[e.id]) then return end
                            ds.extra.interactions[e.id] = nil
                            if _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                            end
                            self:Refresh()
                        end,
                    }, level)
                elseif level == 2 and menuList == "COPY_FROM_DATASET" then
                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle = true; info.notCheckable = true
                    info.text = "Select Dataset"
                    UIDropDownMenu_AddButton(info, level)

                    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                    if DB and DB.ListNames then
                        local names = DB:ListNames()
                        table.sort(names)
                        for _, dsName in ipairs(names) do
                            local btn = UIDropDownMenu_CreateInfo()
                            btn.notCheckable = true
                            btn.text = dsName
                            btn.value = dsName
                            btn.menuList = "COPY_FROM_INTERACTIONS"
                            btn.hasArrow = true
                            UIDropDownMenu_AddButton(btn, level)
                        end
                    end
                elseif level == 3 and menuList == "COPY_FROM_INTERACTIONS" then
                    local sourceDatasetName = UIDROPDOWNMENU_MENU_VALUE
                    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                    if not (DB and sourceDatasetName) then return end

                    local sourceDataset
                    for _, fn in ipairs({ "GetByName", "GetByKey", "Get" }) do
                        local func = DB[fn]
                        if type(func) == "function" then
                            local ok, ds = pcall(func, DB, sourceDatasetName)
                            if ok and ds then sourceDataset = ds; break end
                            local ok2, ds2 = pcall(func, sourceDatasetName)
                            if ok2 and ds2 then sourceDataset = ds2; break end
                        end
                    end

                    if not (sourceDataset and sourceDataset.extra and sourceDataset.extra.interactions) then return end

                    local interactionList = {}
                    for interactionId, interactionDef in pairs(sourceDataset.extra.interactions) do
                        table.insert(interactionList, {
                            id = interactionId,
                            target = interactionDef.target or interactionId,
                        })
                    end

                    table.sort(interactionList, function(a, b)
                        local an = tostring(a.target or ""):lower()
                        local bn = tostring(b.target or ""):lower()
                        if an ~= bn then return an < bn end
                        return tostring(a.id) < tostring(b.id)
                    end)

                    local groupSize = 20
                    local groups = {}
                    for i = 1, #interactionList, groupSize do
                        local group = {}
                        for j = 0, groupSize - 1 do
                            if interactionList[i + j] then
                                table.insert(group, interactionList[i + j])
                            end
                        end
                        if #group > 0 then
                            table.insert(groups, group)
                        end
                    end

                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle = true; info.notCheckable = true
                    info.text = "Select Group"
                    UIDropDownMenu_AddButton(info, level)

                    for groupIdx, group in ipairs(groups) do
                        local firstInt = group[1]
                        local lastInt = group[#group]
                        local firstName = (tostring(firstInt.target or "")):sub(1, 1):upper()
                        local lastName = (tostring(lastInt.target or "")):sub(1, 2):upper()
                        local rangeLabel = firstName .. "-" .. lastName

                        local btn = UIDropDownMenu_CreateInfo()
                        btn.notCheckable = true
                        btn.text = rangeLabel
                        btn.value = sourceDatasetName .. "|" .. groupIdx
                        btn.menuList = "COPY_FROM_INTERACTION_GROUP"
                        btn.hasArrow = true
                        UIDropDownMenu_AddButton(btn, level)
                    end
                elseif level == 4 and menuList == "COPY_FROM_INTERACTION_GROUP" then
                    local encodedValue = UIDROPDOWNMENU_MENU_VALUE
                    local sourceDatasetName, groupIdxStr = encodedValue:match("^(.+)|(.+)$")
                    local groupIdx = tonumber(groupIdxStr)

                    if not (sourceDatasetName and groupIdx) then return end

                    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                    if not DB then return end

                    local sourceDataset
                    for _, fn in ipairs({ "GetByName", "GetByKey", "Get" }) do
                        local func = DB[fn]
                        if type(func) == "function" then
                            local ok, ds = pcall(func, DB, sourceDatasetName)
                            if ok and ds then sourceDataset = ds; break end
                            local ok2, ds2 = pcall(func, sourceDatasetName)
                            if ok2 and ds2 then sourceDataset = ds2; break end
                        end
                    end

                    if not (sourceDataset and sourceDataset.extra and sourceDataset.extra.interactions) then return end

                    local interactionList = {}
                    for interactionId, interactionDef in pairs(sourceDataset.extra.interactions) do
                        table.insert(interactionList, {
                            id = interactionId,
                            target = interactionDef.target or interactionId,
                        })
                    end

                    table.sort(interactionList, function(a, b)
                        local an = tostring(a.target or ""):lower()
                        local bn = tostring(b.target or ""):lower()
                        if an ~= bn then return an < bn end
                        return tostring(a.id) < tostring(b.id)
                    end)

                    local groupSize = 20
                    local groups = {}
                    for i = 1, #interactionList, groupSize do
                        local group = {}
                        for j = 0, groupSize - 1 do
                            if interactionList[i + j] then
                                table.insert(group, interactionList[i + j])
                            end
                        end
                        if #group > 0 then
                            table.insert(groups, group)
                        end
                    end

                    local selectedGroup = groups[groupIdx]
                    if not selectedGroup then return end

                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle = true; info.notCheckable = true
                    info.text = "Select Interaction"
                    UIDropDownMenu_AddButton(info, level)

                    for _, intRef in ipairs(selectedGroup) do
                        local btn = UIDropDownMenu_CreateInfo()
                        btn.notCheckable = true
                        btn.text = intRef.target
                        btn.func = function()
                            local targetDs = self:GetEditingDataset()
                            if not (targetDs and sourceDataset and sourceDataset.extra and sourceDataset.extra.interactions and sourceDataset.extra.interactions[intRef.id]) then
                                return
                            end

                            local sourceInteractionDef = sourceDataset.extra.interactions[intRef.id]

                            -- Replace the current interaction entry's data
                            targetDs.extra = targetDs.extra or {}
                            targetDs.extra.interactions = targetDs.extra.interactions or {}
                            targetDs.extra.interactions[e.id] = {}
                            for k, v in pairs(sourceInteractionDef) do
                                if type(v) == "table" then
                                    targetDs.extra.interactions[e.id][k] = {}
                                    for k2, v2 in pairs(v) do
                                        targetDs.extra.interactions[e.id][k][k2] = v2
                                    end
                                else
                                    targetDs.extra.interactions[e.id][k] = v
                                end
                            end
                            targetDs.extra.interactions[e.id].id = e.id

                            local DB2 = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                            if DB2 and DB2.Save then pcall(DB2.Save, targetDs) end

                            self:Refresh()

                            if RPE and RPE.Debug and RPE.Debug.Internal then
                                RPE.Debug:Internal("Interaction replaced: " .. intRef.target .. " -> " .. e.id)
                            end
                        end
                        UIDropDownMenu_AddButton(btn, level)
                    end
                end
            end)
        end,
    })
    row:Add(menuBtn)
    row._menuBtn = menuBtn

    if row.frame and row.frame.Hide then row.frame:Hide() end
    return row
end

-- ============================================================================
-- Build UI
-- ============================================================================
function InteractionEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.parent   = opts.parent
    self._page    = 1
    self._perPage = 10
    self._query   = ""

    self:SetEditingDataset(opts and opts.editingName)

    self.sheet = VGroup:New("RPE_InteractionEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 10,
        alignV   = "TOP", alignH = "CENTER",
        autoSize = true,
    })

    self.searchBar = HGroup:New("RPE_InteractionEditor_SearchBar", {
        parent = self.sheet, width = 1, height = 1,
        spacingX = 8, alignH = "LEFT", alignV = "CENTER", autoSize = true,
    })
    local searchLbl = Text:New("RPE_InteractionEditor_SearchLbl", {
        parent = self.searchBar, text = "Search:", fontTemplate="GameFontNormalSmall",
    })
    self.searchBar:Add(searchLbl)

    self.searchInput = Input:New("RPE_InteractionEditor_SearchInput", {
        parent = self.searchBar,
        width = 200,
        placeholder = "target...",
        onEnterPressed = function(value)
            self._query = _trim(value or "")
            self._page = 1
            self:Refresh()
        end,
    })
    self.searchBar:Add(self.searchInput)

    self.resultsText = Text:New("RPE_InteractionEditor_ResultsText", {
        parent = self.searchBar, text = "", fontTemplate="GameFontNormalSmall",
    })
    local spacer = Text:New(nil, { parent = self.searchBar, text = "", width = 1, height = 1 }); spacer.flex = 1
    self.searchBar:Add(spacer)
    self.searchBar:Add(self.resultsText)
    self.sheet:Add(self.searchBar)

    self.navRow = HGroup:New("RPE_InteractionEditor_NavRow", {
        parent = self.sheet, width = 1, height = 1,
        spacingX = 10, alignH = "CENTER", alignV = "CENTER", autoSize = true,
    })
    self.newBtn = TextBtn:New("RPE_InteractionEditor_New", {
        parent = self.navRow, width = 120, height = 22, text = "New Interaction",
        onClick = function()
            local ds = self:GetEditingDataset()
            if not ds then return end
            local newId = _newGUID("ixn")
            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
            if DW and DW.ShowWizard then
                DW:ShowWizard({
                    schema = _buildInteractionSchema(newId, {}, false),
                    isEdit = false,
                    onSave = function(values)
                        local okId = _saveInteraction(ds, newId, values)
                        if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                            pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                        end
                        self:Refresh()
                    end,
                })
            end
        end,
    })
    self.navRow:Add(self.newBtn)

    local prev = TextBtn:New("RPE_InteractionEditor_Prev", {
        parent = self.navRow, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) - 1) end,
    })
    self.navRow:Add(prev)

    self.pageText = Text:New("RPE_InteractionEditor_PageText", {
        parent = self.navRow, text = "Page 1 / 1", fontTemplate = "GameFontNormalSmall",
    })
    self.navRow:Add(self.pageText)

    local next = TextBtn:New("RPE_InteractionEditor_Next", {
        parent = self.navRow, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) + 1) end,
    })
    self.navRow:Add(next)
    self.sheet:Add(self.navRow)

    self.list = VGroup:New("RPE_InteractionEditor_List", {
        parent   = self.sheet,
        width    = 1, height = 1,
        spacingY = 8,
        alignV   = "TOP", alignH = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.list)

    self._rows = {}
    for i = 1, self._perPage do
        self._rows[i] = _buildRow(self, i)
    end

    self:Refresh()
    return self.sheet
end

-- ============================================================================
-- Paging + Refresh
-- ============================================================================
function InteractionEditorSheet:_setPage(p)
    local total = self._filtered and #self._filtered or 0
    local per = self._perPage or (#self._rows)
    local totalPages = math.max(1, math.ceil(total / per))
    local newP = math.max(1, math.min(tonumber(p) or 1, totalPages))
    if newP ~= self._page then
        self._page = newP
        self:_rebindPage()
    end
    _updatePageText(self, totalPages, total)
end

function InteractionEditorSheet:_rebindPage()
    local per = self._perPage or (#self._rows)
    local page = math.max(1, self._page or 1)
    local start = (page - 1) * per + 1
    local total = self._filtered and #self._filtered or 0
    for i = 1, per do
        local row = self._rows[i]
        local entry = (start + (i - 1) <= total) and self._filtered[start + (i - 1)] or nil
        if row then _bindRow(self, row, entry) end
    end
end

function InteractionEditorSheet:Refresh()
    local ds = self:GetEditingDataset()
    local list = _collectInteractionsSorted(ds)

    local query = (self._query or ""):lower()
    if query ~= "" then
        local filtered = {}
        for _, e in ipairs(list) do
            if e.target:lower():find(query, 1, true) or tostring(e.id):lower():find(query, 1, true) then
                table.insert(filtered, e)
            end
        end
        self._filtered = filtered
    else
        self._filtered = list
    end

    local n = #self._filtered
    if self.resultsText and self.resultsText.SetText then
        self.resultsText:SetText(("%d total"):format(n))
    end

    local totalPages = math.max(1, math.ceil(n / (self._perPage or 1)))
    if (self._page or 1) > totalPages then self._page = totalPages end
    self:_rebindPage()
    _updatePageText(self, totalPages, n)
end

function InteractionEditorSheet.New(opts)
    local self = setmetatable({}, InteractionEditorSheet)
    self:SetEditingDataset(opts and opts.editingName)
    self:BuildUI(opts or {})
    return self
end

return InteractionEditorSheet
