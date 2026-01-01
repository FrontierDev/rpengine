-- RPE_UI/Windows/DatasetWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local HBorder  = RPE_UI.Elements.HorizontalBorder
local Popup    = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
local C        = RPE_UI.Colors

---@class DatasetWindow
---@field root Window
---@field header Panel
---@field footer Panel
---@field content Panel
---@field tabs table<string, TextBtn>
---@field pages table<string, any>
---@field _colHeights table<integer, number>
---@field headerName Text
---@field btnLoad TextBtn
---@field btnSave TextBtn
---@field btnNew  TextBtn
---@field btnActivate TextBtn
---@field btnDelete TextBtn
---@field wizard any|nil
---@field activeKey string|nil
---@field editingName string|nil
local DatasetWindow = {}
_G.RPE_UI.Windows.DatasetWindow = DatasetWindow
DatasetWindow.__index = DatasetWindow
DatasetWindow.Name = "DatasetWindow"

local FOOTER_COLS       = 3
local BUTTON_HEIGHT     = 26
local BUTTON_SPACING    = 4
local FOOTER_PADDING_Y  = 7
local HEADER_HEIGHT     = 70
local HEADER_PAD_X      = 8

-- ---------- helpers ---------------------------------------------------------
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.DatasetWindow = self
end

local function _dprint(...)
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(table.concat({...}, " "))
    end
end

local function _trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _DB()
    return _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
end

local function _activeDataset()
    local DB = _DB()
    if not DB then return nil end
    local ds = (DB.LoadActiveForCurrentCharacter and DB.LoadActiveForCurrentCharacter()) or
               (DB.GetOrCreateActive and DB.GetOrCreateActive()) or nil
    return ds
end

local function _activeDatasetName()
    local ds = _activeDataset()
    return (ds and ds.name) or "No Dataset"
end

local function _applyAndReport(ds, verb)
    if not ds then return end
    local ok = pcall(function()
        if ds.ApplyToRegistries then ds:ApplyToRegistries() end
    end)
    local counts = (ds.Counts and ds:Counts()) or { items=0, spells=0, auras=0, npcs=0, extra=0 }
    _dprint(string.format("%s dataset '%s' v%s (items=%d, spells=%d, auras=%d, npcs=%d, extra=%d)%s",
        verb or "Loaded",
        tostring(ds.name), tostring(ds.version or "?"),
        counts.items or 0, counts.spells or 0, counts.auras or 0, counts.npcs or 0, counts.extra or 0,
        ok and "" or " (apply failed)"))
end

local function _window()
    local w = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    return w
end

local function _loadDatasetByName(name)
    local DB = _DB()
    if not DB then _dprint("DatasetDB missing."); return end
    name = _trim(name or "")
    if name == "" then return end
    local ds = DB.GetByName and DB.GetByName(name) or nil
    if not ds then
        _dprint("Dataset '" .. name .. "' not found.")
        return
    end
    if DB.SetActiveForCurrentCharacter then
        DB.SetActiveForCurrentCharacter(name)
    end
    _applyAndReport(ds, "Loaded")
    local w = _window()
    if w and w.UpdateHeader then w:UpdateHeader() end
    if w and w.HideWizard then w:HideWizard() end
    if w and w.ShowTab then w:ShowTab("items") end
end

local function _isDatasetActive(name)
    local DB = _DB()
    if not DB then return false end
    local active = DB.GetActiveNamesForCurrentCharacter and DB.GetActiveNamesForCurrentCharacter() or {}
    for _, n in ipairs(active) do if n == name then return true end end
    return false
end

local function _toggleDatasetActive(name)
    local DB = _DB()
    if not DB then _dprint("DatasetDB missing."); return end
    if not name or name == "" then return end
    if DB.ToggleActive then
        DB.ToggleActive(name)
        local isActive = _isDatasetActive(name)
        _dprint((isActive and "Activated" or "Deactivated") .. " dataset: " .. name)
        
        -- Rebuild registries from all active datasets (not just the one toggled)
        if RPE.Core then
            local function _refreshRegistry(reg, method)
                if reg and type(reg[method]) == "function" then
                    pcall(function() reg[method](reg) end)
                end
            end
            _refreshRegistry(RPE.Core.ItemRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.SpellRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.AuraRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.NPCRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.RecipeRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.InteractionRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.StatRegistry, "RefreshFromActiveDatasets")
        end
        
        -- Sync stats to profile from ALL active datasets merged together
        local profile = (RPE.Profile and RPE.Profile.ProfileDB and RPE.Profile.ProfileDB.GetOrCreateActive and RPE.Profile.ProfileDB.GetOrCreateActive()) or nil
        if profile and DB then
            -- Get the merged active dataset (combines all active datasets' stats)
            local mergedDS = DB.LoadActiveForCurrentCharacter and DB.LoadActiveForCurrentCharacter() or nil
            if mergedDS and mergedDS.extra and mergedDS.extra.stats then
                local synced = 0
                local datasetName = mergedDS.name or "_unknown"
                for statId, statDef in pairs(mergedDS.extra.stats) do
                    if statDef then
                        -- Get or create stat on profile with proper category, per dataset
                        local stat = profile:GetStat(statId, statDef.category or "PRIMARY", datasetName)
                        if stat then
                            synced = synced + 1
                            -- Prepare data to set (will preserve setupBonus automatically since SetData doesn't touch it)
                            local dataToSet = {
                                id              = statId,
                                name            = statDef.name,
                                category        = statDef.category,
                                base            = statDef.base,
                                min             = statDef.min,
                                max             = statDef.max,
                                icon            = statDef.icon,
                                tooltip         = statDef.tooltip,
                                visible         = statDef.visible,
                                pct             = statDef.pct,
                                recovery        = statDef.recovery,
                                itemTooltipFormat   = statDef.itemTooltipFormat,
                                itemTooltipColor    = statDef.itemTooltipColor,
                                itemTooltipPriority = statDef.itemTooltipPriority,
                                itemLevelWeight     = statDef.itemLevelWeight,
                            }
                            stat:SetData(dataToSet)
                            -- Set sourceDataset directly (not in SetData)
                            stat.sourceDataset = datasetName
                        end
                    end
                end
                -- Remove stats that are no longer in active datasets (deactivated stat cleanup)
                if not isActive then
                    -- Remove all stats that have sourceDataset == datasetName
                    if profile and profile.stats then
                        for k, s in pairs(profile.stats) do
                            if s and s.sourceDataset == datasetName then
                                profile.stats[k] = nil
                            end
                        end
                    end
                end
                if RPE.Profile.ProfileDB.SaveProfile then
                    pcall(function() RPE.Profile.ProfileDB.SaveProfile(profile) end)
                end
                _dprint(string.format("_toggleDatasetActive: synced %d stats from merged active datasets", synced))
            end
        end
        
        -- Refresh both statistics and character sheets
        if _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.StatisticSheetInstance then
            local ss = _G.RPE_UI.Windows.StatisticSheetInstance
            if ss and ss.Refresh then
                pcall(function() ss:Refresh() end)
            end
        end
        if _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.CharacterSheetInstance then
            local cs = _G.RPE_UI.Windows.CharacterSheetInstance
            if cs and cs.Refresh then
                pcall(function() cs:Refresh() end)
            end
        end
        
        -- Update UI
        local w = _window()
        if w then
            if w.UpdateActiveButtonText then w:UpdateActiveButtonText() end
        end
    end
end

local function _deleteDataset(name)
    local DB = _DB()
    if not DB then _dprint("DatasetDB missing."); return end
    if not name or name == "" then _dprint("No name provided to delete."); return end
    
    -- Check if this is a default dataset
    if name == "DefaultClassic" or name == "Default5e" or name == "DefaultWarcraft" then
        RPE.Debug:Warning("Cannot delete default dataset: " .. name)
        _dprint("Cannot delete default dataset: " .. name)
        return
    end
    
    -- Use Popup.Confirm for deletion confirmation
    if not Popup or not Popup.Confirm then
        _dprint("Popup.Confirm not available.")
        return
    end
    
    RPE.Debug:Print("Showing confirmation popup for deletion")
    Popup.Confirm(
        "Delete Dataset",
        "Really delete '" .. name .. "'?\n\nThis cannot be undone.",
        function()
            RPE.Debug:Internal("Delete confirmed for: " .. tostring(name))
            local DB = _DB()
            if DB and DB.Delete then
                RPE.Debug:Internal("Calling DB.Delete for: " .. tostring(name))
                DB.Delete(name)
                _dprint("Deleted dataset: " .. name)
                -- Switch to a different dataset
                local newNames = DB.ListNames and DB.ListNames() or {}
                local w = _window()
                if w then
                    if #newNames > 0 then
                        w.editingName = newNames[1]
                    else
                        w.editingName = nil
                    end
                    w:UpdateHeader()
                    -- Refresh all pages
                    for _, page in pairs(w.pages or {}) do
                        if page and page.SetEditingDataset then pcall(function() page:SetEditingDataset(w.editingName) end) end
                        if page and page.Refresh then pcall(function() page:Refresh() end) end
                    end
                end
            end
        end,
        function()
            RPE.Debug:Internal("Delete cancelled")
        end
    )
end
-- ---------- end helpers -----------------------------------------------------

-- Get the natural/intrinsic size of a sheet by measuring its content
function DatasetWindow:_getSheetSize(pageSheet)
    if not pageSheet or not pageSheet.frame then return nil, nil end
    
    -- Force a layout pass
    if pageSheet.Relayout then
        pcall(function() pageSheet:Relayout() end)
    end
    
    -- Try to measure the frame
    local frame = pageSheet.frame
    local w = frame:GetWidth()
    local h = frame:GetHeight()
    
    -- If we got 0 or nil, try to calculate from children
    if not w or w == 0 or not h or h == 0 then
        local minW, minH = 0, 0
        for i = 1, frame:GetNumChildren() do
            local child = select(i, frame:GetChildren())
            if child and child:IsShown() then
                local cw = child:GetWidth() or 0
                local ch = child:GetHeight() or 0
                minW = math.max(minW, cw)
                minH = minH + ch
            end
        end
        w = (minW > 0 and minW) or w or 480
        h = (minH > 0 and minH) or h or 400
    end
    
    return w or 480, h or 400
end

-- Ensure sizing happens after layout settles
function DatasetWindow:_resizeSoon(targetSheet)
    if C_Timer and C_Timer.After then
        -- Defer sizing to allow multiple layout passes
        C_Timer.After(0.01, function()
            if self.root and self.root.frame and self.root.frame:IsVisible() then
                self:_recalcSizeForContent(targetSheet or self:GetActiveSheet())
            end
        end)
    end
end

-- When a specific sheet is visible, compute window size to match it.
function DatasetWindow:_recalcSizeForContent(pageSheet)
    if not (self.content and self.content.SetSize and pageSheet and pageSheet.frame) then return end
    
    local w, h = self:_getSheetSize(pageSheet)
    if not (w and h) then return end
    
    -- Add padding
    w = w + 12
    h = h + 12

    local padX = self.content.autoSizePadX or 0
    local padY = self.content.autoSizePadY or 0

    -- Use baseline mins, not the *current* footer width (which might be stretched)
    local baselineFooter = self._footerMinWidth or 0
    local baselineHeader = self._headerMinWidth or 0
    local minW = math.max(baselineFooter, baselineHeader)

    local cw = math.max(w + padX, minW)
    local ch = h + padY

    self.content:SetSize(cw, ch)
    local hdrH = (self.header and self.header.frame:GetHeight()) or 0
    local ftrH = (self.footer and self.footer.frame:GetHeight()) or 0
    self.root:SetSize(cw, ch + ftrH + hdrH)

    if self.content and self.header and self.footer then
        self.content.frame:ClearAllPoints()
        self.content.frame:SetPoint("TOPLEFT",  self.header.frame, "BOTTOMLEFT", 0, 0)
        self.content.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)
        self.content.frame:SetPoint("BOTTOMLEFT",  self.footer.frame, "TOPLEFT", 0, 0)
        self.content.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)
    end
end


-- Return the sheet currently driving sizing (wizard has priority)
function DatasetWindow:GetActiveSheet()
    if self.wizard and self.wizard.sheet and self.wizard.sheet:IsShown() then
        return self.wizard.sheet
    end
    local activePage = self.activeKey and self.pages and self.pages[self.activeKey] or nil
    if activePage then
        return (activePage.sheet or activePage.root)
    end
    for _, p in pairs(self.pages or {}) do
        local s = (p.sheet or p.root)
        if s and s.frame and s.frame:IsShown() then return s end
    end
    return nil
end

-- Create & show the editor wizard (not a tab); size window to the wizard
-- args: { schema=table, isEdit=bool, onSave=function(values), onCancel=function() end }
function DatasetWindow:ShowWizard(args)
    -- Hide all pages while wizard is visible
    for _, page in pairs(self.pages or {}) do
        local w = (page.sheet or page.root)
        if w and w.Hide then w:Hide() end
    end

    -- Destroy previous wizard instance if any
    if self.wizard and self.wizard.sheet and self.wizard.sheet.Hide then
        self.wizard.sheet:Hide()
    end
    self.wizard = nil

    local EditorWizardSheet = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.EditorWizardSheet
    if not EditorWizardSheet then
        _dprint("EditorWizardSheet not found; cannot open wizard.")
        return
    end

    self.wizard = EditorWizardSheet.New({
        parent        = self.content,
        isEdit        = args and args.isEdit or false,
        schema        = args and args.schema or {},
        labelWidth    = 120,
        labelAlign    = "LEFT",
        buttonAlign   = "CENTER",
        navSaveAlways = true,
        onCancel = function()
            self:HideWizard()
            if args and args.onCancel then pcall(args.onCancel) end
        end,
        onSave = function(values)
            if args and args.onSave then pcall(args.onSave, values) end
            -- Hide wizard AFTER onSave callback (grid may have changed size)
            if self.wizard and self.wizard.sheet and self.wizard.sheet:IsShown() then
                self:HideWizard()
            end
        end,
    })

    if self.wizard and self.wizard.sheet then
        self:_recalcSizeForContent(self.wizard.sheet)
        self:_resizeSoon(self.wizard.sheet) -- ensure next-frame sizing too
    end
end

-- Hide the wizard and restore the active tab; size window to that content
function DatasetWindow:HideWizard()
    if self.wizard and self.wizard.sheet and self.wizard.sheet.Hide then
        self.wizard.sheet:Hide()
    end
    self.wizard = nil

    -- Restore active tab page
    local page = (self.activeKey and self.pages and self.pages[self.activeKey]) or nil
    if not page then
        -- fallbacks
        if self.pages and self.pages["items"] then
            page = self.pages["items"]
            self.activeKey = "items"
        else
            for _, p in pairs(self.pages or {}) do page = p; break end
        end
    end

    if page then
        local w = (page.sheet or page.root)
        if w and w.Show then w:Show() end
        self:_recalcSizeForContent(w)
        self:_resizeSoon(w) -- next frame resize after layout/Relayout
    end
end

function DatasetWindow:BuildUI()
    -- Root window
    self.root = Window:New("RPE_DataManager_Window", {
        width  = 480,
        height = 680,
        point  = "CENTER",
        autoSize = false,
    })

    -- Decide initial dataset to edit (first active, else first saved)
    do
        local DB = _DB()
        if DB then
            local act = DB.GetActiveNamesForCurrentCharacter and DB.GetActiveNamesForCurrentCharacter() or {}
            if act and #act > 0 then
                self.editingName = act[1]
            else
                local names = DB.ListNames and DB.ListNames() or {}
                self.editingName = names and names[1] or nil
            end
        end
    end

    -- Top border
    self.topBorder = HBorder:New("RPE_DataManager_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT",  self.root.frame, "TOPLEFT",  0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    if _G.RPE_UI and _G.RPE_UI.Colors and _G.RPE_UI.Colors.ApplyHighlight then
        _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)
    end

    -- Header panel
    self.header = Panel:New("RPE_DataManager_Header", {
        parent   = self.root,
        autoSize = false,
    })
    self.header.frame:ClearAllPoints()
    self.header.frame:SetPoint("TOPLEFT",  self.topBorder.frame, "BOTTOMLEFT", 0, 0)
    self.header.frame:SetPoint("TOPRIGHT", self.topBorder.frame, "BOTTOMRIGHT", 0, 0)
    self.header.frame:SetHeight(HEADER_HEIGHT)

    -- Header: dataset being edited (below buttons)
    self.headerName = Text:New("RPE_DataManager_HeaderName", {
        parent = self.header,
        text   = "Dataset: " .. (self.editingName or "None"),
    })
    self.headerName.frame:ClearAllPoints()
    self.headerName.frame:SetPoint("BOTTOMLEFT", self.header.frame, "BOTTOMLEFT", HEADER_PAD_X, 6)

    -- Close button (top-right)
    self.closeBtn = CreateFrame("Button", "RPE_DataManager_CloseBtn", self.root.frame)
    self.closeBtn:SetSize(24, 24)
    self.closeBtn:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", -8, -8)
    self.closeBtn:SetFrameStrata("DIALOG")
    self.closeBtn:SetFrameLevel(100)
    self.closeBtn:SetText("×")
    self.closeBtn:SetNormalFontObject("GameFontHighlightLarge")
    self.closeBtn:GetFontString():SetTextColor(0.9, 0.9, 0.95, 1.0)
    
    -- Background texture (uses palette color)
    local closeBg = self.closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    self.closeBtn._bgTex = closeBg
    
    -- Hover texture
    local closeHover = self.closeBtn:CreateTexture(nil, "BORDER")
    closeHover:SetAllPoints()
    closeHover:SetColorTexture(0.3, 0.3, 0.35, 0)
    self.closeBtn._hoverTex = closeHover
    
    -- Apply initial palette colors
    if C and C.Get then
        local bgR, bgG, bgB, bgA = C.Get("background")
        if bgR then
            closeBg:SetColorTexture(bgR, bgG, bgB, bgA or 0.9)
        else
            closeBg:SetColorTexture(0.15, 0.15, 0.2, 0.8)
        end
    else
        closeBg:SetColorTexture(0.15, 0.15, 0.2, 0.8)
    end
    
    self.closeBtn:SetScript("OnEnter", function(btn)
        btn._hoverTex:SetColorTexture(0.3, 0.3, 0.35, 0.5)
    end)
    self.closeBtn:SetScript("OnLeave", function(btn)
        btn._hoverTex:SetColorTexture(0.3, 0.3, 0.35, 0)
    end)
    self.closeBtn:SetScript("OnClick", function()
        self:Hide()
    end)

    -- Header: buttons (right) - Edit | Save | New | Sync | Activate | Delete
    local btnWidth = 65
    local pad = 4

    self.btnNew = TextBtn:New("RPE_DataManager_BtnNewDataset", {
        parent  = self.header,
        width   = btnWidth,
        height  = BUTTON_HEIGHT,
        text    = "New",
        noBorder = true,
        onClick = function()
            if not Popup or not Popup.Prompt then
                _dprint("Popup prefab missing; cannot prompt for name.")
                return
            end
            Popup.Prompt("New Dataset", "Enter a unique dataset name:", "", function(name)
                name = _trim(name or "")
                local DB = _DB()
                if not DB then _dprint("DatasetDB missing."); return end
                if name == "" then _dprint("Please enter a dataset name."); return end
                local ok, dsOrErr = pcall(function()
                    return DB.CreateNew(name, { author = UnitName and UnitName("player") or nil })
                end)
                if not ok then
                    _dprint("Create failed:", tostring(dsOrErr))
                    return
                end
                local ds = dsOrErr
                self.editingName = name
                self:UpdateHeader()
                -- notify sheets about the new selection
                for _, page in pairs(self.pages or {}) do
                    if page and page.SetEditingDataset then pcall(function() page:SetEditingDataset(name) end) end
                    if page and page.Refresh then pcall(function() page:Refresh() end) end
                end
                _applyAndReport(ds, "Created")
                local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
                if reg and reg.RefreshFromDataset then reg:RefreshFromDataset(ds) end
                self:ShowTab("items")
            end)
        end,
    })
    self.btnNew.frame:ClearAllPoints()
    self.btnNew.frame:SetPoint("TOP", self.header.frame, "TOP", -147, -8)

    self.btnSave = TextBtn:New("RPE_DataManager_BtnSave", {
        parent  = self.header,
        width   = 60,
        height  = BUTTON_HEIGHT,
        text    = "Save",
        noBorder = true,
        onClick = function()
            local DB = _DB()
            if not DB then _dprint("DatasetDB missing."); return end
            local name = self.editingName
            if not name or name == "" then _dprint("No editing dataset selected."); return end
            local ds = DB.GetByName and DB.GetByName(name)
            if not ds then _dprint("Dataset not found: " .. tostring(name)); return end
            
            -- Check if non-author is trying to save a restricted dataset
            local playerName = UnitName("player")
            local isAuthor = (ds.author == playerName)
            if not isAuthor and (ds.securityLevel == "Viewable" or ds.securityLevel == "Locked") then
                _dprint("Cannot save: non-author trying to save restricted dataset")
                return
            end
            
            -- Sync metadata from the editor sheet before saving
            local metaSheet = self.pages and self.pages["metadata"]
            if metaSheet and metaSheet.inputs and metaSheet.inputs.description then
                local descInput = metaSheet.inputs.description
                if descInput.GetText then
                    ds.description = descInput:GetText() or ""
                end
            end
            
            DB.Save(ds)
            _dprint("Saved dataset:", ds.name)
        end,
    })
    self.btnSave.frame:ClearAllPoints()
    self.btnSave.frame:SetPoint("LEFT", self.btnNew.frame, "RIGHT", -pad, 0)

    self.btnLoad = TextBtn:New("RPE_DataManager_BtnLoad", {
        parent  = self.header,
        width   = 60,
        height  = BUTTON_HEIGHT,
        text    = "Edit",
        noBorder = true,
        onClick = function(btn)
            local DB = _DB()
            if not DB then _dprint("DatasetDB missing."); return end
            if not (RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu) then
                _dprint("ContextMenu helper not available.")
                return
            end

            local names = DB.ListNames and DB.ListNames() or {}
            RPE_UI.Common:ContextMenu(btn.frame or self.header.frame or UIParent, function(level)
                if level ~= 1 then return end
                local current = self.editingName or "None"
                local activeNames = DB.GetActiveNamesForCurrentCharacter and DB.GetActiveNamesForCurrentCharacter() or {}
                local activeSet = {}
                for _, n in ipairs(activeNames) do activeSet[n] = true end

                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "Edit Dataset"
                UIDropDownMenu_AddButton(info, level)

                if not names or #names == 0 then
                    local nfo = UIDropDownMenu_CreateInfo()
                    nfo.notCheckable = true
                    nfo.disabled = true
                    nfo.text = "No datasets saved"
                    UIDropDownMenu_AddButton(nfo, level)
                    return
                end

                -- Separate default datasets from custom ones
                local defaultDatasets = { "DefaultClassic", "Default5e", "DefaultWarcraft" }
                local customDatasets = {}
                local defaultSet = {}
                for _, dn in ipairs(defaultDatasets) do defaultSet[dn] = true end
                for _, n in ipairs(names) do
                    if not defaultSet[n] then table.insert(customDatasets, n) end
                end

                -- Add default datasets at top
                for _, name in ipairs(defaultDatasets) do
                    if defaultSet[name] then
                        local nfo = UIDropDownMenu_CreateInfo()
                        local activeMarker = activeSet[name] and RPE.Common.InlineIcons["Check"] or ""
                        nfo.text = name .. activeMarker
                        nfo.func = function()
                            -- Switch which dataset we're editing (does NOT change active list)
                            self.editingName = name
                            self:UpdateHeader()

                            -- Broadcast to pages so they rebind to this dataset and refresh
                            for _, page in pairs(self.pages or {}) do
                                if page and page.SetEditingDataset then pcall(function() page:SetEditingDataset(name) end) end
                                if page and page.Refresh then pcall(function() page:Refresh() end) end
                            end

                            if self.wizard and self.wizard.sheet and self.wizard.sheet:IsShown() then
                                self:HideWizard()
                            end
                            self:ShowTab("items")
                            
                            -- Resize window for new dataset content
                            local itemsPage = self.pages and self.pages["items"]
                            if itemsPage then
                                local itemsSheet = itemsPage.sheet or itemsPage.root
                                if itemsSheet then
                                    self:_recalcSizeForContent(itemsSheet)
                                    self:_resizeSoon(itemsSheet)
                                end
                            end
                        end
                        nfo.checked = (name == current)
                        UIDropDownMenu_AddButton(nfo, level)
                    end
                end

                -- Add separator if there are custom datasets
                if #customDatasets > 0 then
                    UIDropDownMenu_AddSeparator(level)
                end

                -- Add custom datasets
                for _, name in ipairs(customDatasets) do
                    local nfo = UIDropDownMenu_CreateInfo()
                    local activeMarker = activeSet[name] and RPE.Common.InlineIcons["Check"] or ""
                    nfo.text = name .. activeMarker
                    nfo.func = function()
                        -- Switch which dataset we're editing (does NOT change active list)
                        self.editingName = name
                        self:UpdateHeader()

                        -- Broadcast to pages so they rebind to this dataset and refresh
                        for _, page in pairs(self.pages or {}) do
                            if page and page.SetEditingDataset then pcall(function() page:SetEditingDataset(name) end) end
                            if page and page.Refresh then pcall(function() page:Refresh() end) end
                        end

                        if self.wizard and self.wizard.sheet and self.wizard.sheet:IsShown() then
                            self:HideWizard()
                        end
                        self:ShowTab("items")
                        
                        -- Resize window for new dataset content
                        local itemsPage = self.pages and self.pages["items"]
                        if itemsPage then
                            local itemsSheet = itemsPage.sheet or itemsPage.root
                            if itemsSheet then
                                self:_recalcSizeForContent(itemsSheet)
                                self:_resizeSoon(itemsSheet)
                            end
                        end
                    end
                    nfo.checked = (name == current)
                    UIDropDownMenu_AddButton(nfo, level)
                end
            end)
        end,
    })
    self.btnLoad.frame:ClearAllPoints()
    self.btnLoad.frame:SetPoint("LEFT", self.btnSave.frame, "RIGHT", -pad, 0)

    self.btnActivate = TextBtn:New("RPE_DataManager_BtnActivate", {
        parent  = self.header,
        width   = 65,
        height  = BUTTON_HEIGHT,
        text    = "Activate",
        noBorder = true,
        onClick = function()
            local name = self.editingName
            if not name or name == "" then _dprint("No dataset selected to toggle."); return end
            _toggleDatasetActive(name)
        end,
    })
    self.btnActivate.frame:ClearAllPoints()
    self.btnActivate.frame:SetPoint("LEFT", self.btnLoad.frame, "RIGHT", -pad, 0)

    -- Delete button
    self.btnDelete = TextBtn:New("RPE_DataManager_BtnDelete", {
        parent  = self.header,
        width   = 60,
        height  = BUTTON_HEIGHT,
        text    = "Delete",
        noBorder = true,
        onClick = function()
            local name = self.editingName
            if not name or name == "" then _dprint("No dataset selected to delete."); return end
            _deleteDataset(name)
        end,
    })
    self.btnDelete.frame:ClearAllPoints()
    self.btnDelete.frame:SetPoint("LEFT", self.btnActivate.frame, "RIGHT", -pad, 0)

    -- Sync button
    self.btnSync = TextBtn:New("RPE_DataManager_BtnSync", {
        parent  = self.header,
        width   = 60,
        height  = BUTTON_HEIGHT,
        text    = "Sync",
        noBorder = true,
        onClick = function()
            local name = self.editingName
            if not name or name == "" then _dprint("No dataset selected to sync."); return end
            local DB = _DB()
            if not DB then _dprint("DatasetDB missing."); return end
            local ds = DB.GetByName and DB.GetByName(name)
            if not ds then _dprint("Dataset not found: " .. tostring(name)); return end
            
            local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
            if not Broadcast then _dprint("Broadcast module not available."); return end
            
            if not Broadcast._StreamDataset then _dprint("Broadcast._StreamDataset not available."); return end
            Broadcast:_StreamDataset(ds)
            _dprint("Syncing dataset: " .. name)
        end,
    })
    self.btnSync.frame:ClearAllPoints()
    self.btnSync.frame:SetPoint("LEFT", self.btnDelete.frame, "RIGHT", -pad, 0)

    -- Bottom border
    self.bottomBorder = HBorder:New("RPE_DataManager_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = -2,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT",  self.root.frame, "BOTTOMLEFT",  0, -32)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, -32)
    if _G.RPE_UI and _G.RPE_UI.Colors and _G.RPE_UI.Colors.ApplyHighlight then
        _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)
    end

    -- Content panel (between header and footer)
    self.content = Panel:New("RPE_DataManager_Content", {
        parent   = self.root,
        autoSize = true,
    })
    self.root:Add(self.content)
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT",  self.header.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT",  self.root.frame, "BOTTOMLEFT",  0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)


    -- Footer panel
    self.footer = Panel:New("RPE_DataManager_Footer", {
        parent   = self.root,
        autoSize = false,
    })
    self.root:Add(self.footer)
    self.footer.frame:ClearAllPoints()
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    self.footer.frame:SetHeight(40)

    -- Baseline widths used for tab/header layout
    self._footerMinWidth = self.root.frame:GetWidth() or 480
    self._headerMinWidth = self.root.frame:GetWidth() or 480

    self.tabs = {}
    self.pages = {}
    self._colHeights = { [1] = 0, [2] = 0, [3] = 0 }
    self.wizard = nil
    self.activeKey = nil

    -- ...existing code...

    -- Draw Metadata and Setup Wizard button group after paginator (footer tabs)
    local metaSetupGroup = Panel:New("RPE_DataManager_MetaSetupGroup", {
        parent = self.footer,
        autoSize = false,
    })
    metaSetupGroup.frame:ClearAllPoints()
    metaSetupGroup.frame:SetPoint("TOPLEFT", self.footer.frame, "BOTTOMLEFT", 0, 0)
    metaSetupGroup.frame:SetPoint("TOPRIGHT", self.footer.frame, "BOTTOMRIGHT", 0, 0)
    metaSetupGroup.frame:SetHeight(BUTTON_HEIGHT + 4)

    local groupBtnWidth = 120
    local groupPad = 12

    self.btnMetadata = TextBtn:New("RPE_DataManager_BtnMetadata", {
        parent = metaSetupGroup,
        width = groupBtnWidth,
        height = BUTTON_HEIGHT,
        text = "Metadata",
        noBorder = true,
        onClick = function()
            if self.pages and self.pages["metadata"] then
                self:ShowTab("metadata")
                
                -- Resize window for metadata content
                local metaPage = self.pages["metadata"]
                if metaPage then
                    local metaSheet = metaPage.sheet or metaPage.root
                    if metaSheet then
                        self:_recalcSizeForContent(metaSheet)
                        self:_resizeSoon(metaSheet)
                    end
                end
            end
        end,
    })
    self.btnMetadata.frame:ClearAllPoints()
    self.btnMetadata.frame:SetPoint("CENTER", metaSetupGroup.frame, "CENTER", -(groupBtnWidth/2 + groupPad/2), 0)

    self.btnSetupWizard = TextBtn:New("RPE_DataManager_BtnSetupWizard", {
        parent = metaSetupGroup,
        width = groupBtnWidth,
        height = BUTTON_HEIGHT,
        text = "Setup Wizard",
        noBorder = true,
        onClick = function()
            local DB = _DB()
            if not DB then _dprint("DatasetDB missing."); return end
            local ds = DB.GetByName(self.editingName)
            if not ds then _dprint("Dataset not found."); return end
            
            -- Check if non-author is trying to access setup wizard on a Locked dataset
            local playerName = UnitName("player")
            local isAuthor = (ds.author == playerName)
            if not isAuthor and ds.securityLevel == "Locked" then
                _dprint("Cannot access setup wizard: non-author trying to modify locked dataset")
                return
            end
            
            self:ShowTab("setupWizard")
            
            -- Resize window for setup wizard content
            local setupPage = self.pages and self.pages["setupWizard"]
            if setupPage then
                local setupSheet = setupPage.sheet or setupPage.root
                if setupSheet then
                    self:_recalcSizeForContent(setupSheet)
                    self:_resizeSoon(setupSheet)
                end
            end
        end,
    })
    self.btnSetupWizard.frame:ClearAllPoints()
    self.btnSetupWizard.frame:SetPoint("CENTER", metaSetupGroup.frame, "CENTER", (groupBtnWidth/2 + groupPad/2), 0)

    -- Tabs
    self:AddTabButton(1, "recipes",   "Recipes")
    self:AddTabButton(1, "items",  "Items")
    self:AddTabButton(1, "stats",   "Stats")
    self:AddTabButton(2, "spells", "Spells")
    self:AddTabButton(2, "auras",  "Auras")
    self:AddTabButton(2, "npcs",   "NPCs")
    self:AddTabButton(3, "achievements",   "Achievements")
    self:AddTabButton(3, "interactions", "Interactions")

    -- Pages
    local OverviewSheet = _G.RPE_UI.Windows.DatasetOverviewSheet
    if OverviewSheet then
        local page = OverviewSheet.New({ parent = self.content })
        self.pages["overview"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("DatasetOverviewSheet not found.")
    end

    local ItemEditorSheet = _G.RPE_UI.Windows.ItemEditorSheet
    if ItemEditorSheet then
        local page = ItemEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["items"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("ItemEditorSheet not found.")
    end

    local SpellEditorSheet = _G.RPE_UI.Windows.SpellEditorSheet
    if SpellEditorSheet then
        local page = SpellEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["spells"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("SpellEditorSheet not found.")
    end

    local AuraEditorSheet = _G.RPE_UI.Windows.AuraEditorSheet
    if AuraEditorSheet then
        local page = AuraEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["auras"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("AuraEditorSheet not found.")
    end

    local NPCEditorSheet = _G.RPE_UI.Windows.NPCEditorSheet
    if NPCEditorSheet then
        local page = NPCEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["npcs"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("NPCEditorSheet not found.")
    end

    local RecipeEditorSheet = _G.RPE_UI.Windows.RecipeEditorSheet
    if RecipeEditorSheet then
        local page = RecipeEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["recipes"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("RecipeEditorSheet not found.")
    end

    local StatEditorSheet = _G.RPE_UI.Windows.StatEditorSheet
    if StatEditorSheet then
        local page = StatEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- If the sheet doesn't accept ctor arg, try calling setter (next script will add this)
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["stats"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("StatEditorSheet not found.")
    end

    local InteractionEditorSheet = _G.RPE_UI.Windows.InteractionEditorSheet
    if InteractionEditorSheet then
        local page = InteractionEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- ensure dataset binding if ctor doesn't handle it
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["interactions"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("InteractionEditorSheet not found.")
    end

    local MetadataEditorSheet = _G.RPE_UI.Windows.MetadataEditorSheet
    if MetadataEditorSheet then
        local page = MetadataEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- ensure dataset binding if ctor doesn't handle it
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["metadata"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("MetadataEditorSheet not found.")
    end

    local SetupWizardEditorSheet = _G.RPE_UI.Windows.SetupWizardEditorSheet
    if SetupWizardEditorSheet then
        local page = SetupWizardEditorSheet.New({ parent = self.content, editingName = self.editingName })
        -- ensure dataset binding if ctor doesn't handle it
        if page and page.SetEditingDataset and self.editingName then
            pcall(function() page:SetEditingDataset(self.editingName) end)
        end
        self.pages["setupWizard"] = page
        if page.sheet and page.sheet.Hide then page.sheet:Hide() end
    else
        _dprint("SetupWizardEditorSheet not found.")
    end

    -- Now size and show the initial sheet (items)
    self.activeKey = "items"
    local itemsPage = self.pages["items"]
    if itemsPage then
        local itemsSheet = itemsPage.sheet or itemsPage.root
        if itemsSheet then
            if itemsSheet.Show then itemsSheet:Show() end
            self:_recalcSizeForContent(itemsSheet)
            self:_resizeSoon(itemsSheet)
        end
    end

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function DatasetWindow:UpdateHeader()
    if self.headerName and self.headerName.SetText then
        self.headerName:SetText("Dataset: " .. (self.editingName or "None"))
    end
    self:UpdateActiveButtonText()
    self:UpdateDeleteButtonState()
    self:_updateTabLockState()
end

function DatasetWindow:UpdateActiveButtonText()
    if not self.btnActivate or not self.btnActivate.SetText then return end
    local isActive = _isDatasetActive(self.editingName or "")
    local btnText = isActive and "Deactivate" or "Activate"
    self.btnActivate:SetText(btnText)
end

function DatasetWindow:UpdateDeleteButtonState()
    if not self.btnDelete or not self.btnDelete.SetEnabled then return end
    local name = self.editingName or ""
    local isDefault = (name == "DefaultClassic" or name == "Default5e" or name == "DefaultWarcraft")
    self.btnDelete:SetEnabled(not isDefault)
    if isDefault then
        self.btnDelete:SetAlpha(0.5)
    else
        self.btnDelete:SetAlpha(1.0)
    end
end

function DatasetWindow:ShowTab(key)
    -- Close wizard when switching tabs
    if self.wizard and self.wizard.sheet and self.wizard.sheet:IsShown() then
        self:HideWizard()
    end

    -- Hide all pages
    for _, page in pairs(self.pages or {}) do
        local w = (page.sheet or page.root)
        if w and w.Hide then w:Hide() end
    end

    local page = self.pages[key]
    if not page then
        _dprint("No page registered for key:", tostring(key))
        return
    end

    self.activeKey = key

    local w = (page.sheet or page.root)
    if w and w.Show then w:Show() end

    self:_recalcSizeForContent(w)
    self:_resizeSoon(w)
end

function DatasetWindow:_updateTabLockState()
    local DB = _DB()
    if not DB then return end
    local ds = DB.GetByName(self.editingName)
    if not ds then return end
    
    local playerName = UnitName("player")
    local isAuthor = (ds.author == playerName)
    local isLocked = (ds.securityLevel == "Locked")
    
    -- If locked and not author, disable all tabs except metadata
    if isLocked and not isAuthor then
        for key, btn in pairs(self.tabs or {}) do
            if btn and btn.SetEnabled then
                if key == "metadata" then
                    btn:SetEnabled(true)
                else
                    btn:SetEnabled(false)
                end
            end
        end
        -- Force show metadata tab
        self:ShowTab("metadata")
    else
        -- Re-enable all tabs if not locked or if author (Viewable datasets show all tabs)
        for _, btn in pairs(self.tabs or {}) do
            if btn and btn.SetEnabled then
                btn:SetEnabled(true)
            end
        end
    end
end

--- Add a tab button into a footer column
---@param col integer 1..3
---@param key string
---@param title string
function DatasetWindow:AddTabButton(col, key, title)
    assert(col >= 1 and col <= FOOTER_COLS, "Column index must be 1..3")

    -- Use the baseline width recorded at build time so our tabs don't force future min width to 'stretched'
    local totalW  = self._footerMinWidth or (self.root.frame:GetWidth() or 480)
    local colWidth = totalW / FOOTER_COLS
    
    local btn = TextBtn:New("RPE_DataManager_TabBtn_" .. key, {
        parent  = self.footer,
        width   = colWidth - 12,
        height  = BUTTON_HEIGHT,
        text    = title,
        noBorder = true,
        onClick = function()
            self:ShowTab(key)
        end,
    })

    local left = (col - 1) * colWidth
    local offsetY = FOOTER_PADDING_Y + self._colHeights[col]
    btn.frame:ClearAllPoints()
    btn.frame:SetPoint("BOTTOMLEFT",  self.footer.frame, "BOTTOMLEFT", left + 6, offsetY)
    btn.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "BOTTOMLEFT", left + colWidth - 6, offsetY)

    self._colHeights[col] = self._colHeights[col] + BUTTON_HEIGHT + BUTTON_SPACING
    self.tabs[key] = btn

    local tallest = math.max(self._colHeights[1], self._colHeights[2], self._colHeights[3])
    self.footer.frame:SetHeight(tallest + FOOTER_PADDING_Y + BUTTON_HEIGHT)

    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT",  self.header.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT",  self.footer.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)

    return btn
end

function DatasetWindow:ApplyPalette()
    -- Update border colors from palette
    if self.topBorder then
        if C and C.ApplyHighlight then C.ApplyHighlight(self.topBorder) end
    end
    if self.bottomBorder then
        if C and C.ApplyHighlight then C.ApplyHighlight(self.bottomBorder) end
    end
    
    -- Update close button background color from palette
    if self.closeBtn and self.closeBtn._bgTex then
        if C and C.Get then
            local bgR, bgG, bgB, bgA = C.Get("background")
            if bgR then
                self.closeBtn._bgTex:SetColorTexture(bgR, bgG, bgB, bgA or 0.9)
            else
                self.closeBtn._bgTex:SetColorTexture(0.15, 0.15, 0.2, 0.8)
            end
        else
            self.closeBtn._bgTex:SetColorTexture(0.15, 0.15, 0.2, 0.8)
        end
    end
    
    -- TextButton elements will auto-update via their own ApplyPalette
    -- Panel and Window elements will auto-update via their own ApplyPalette
end

function DatasetWindow.New()
    local self = setmetatable({}, DatasetWindow)
    self:BuildUI()
    self:UpdateHeader()
    
    -- Register as palette consumer so UI updates when palette changes
    if C and C.RegisterConsumer then
        C.RegisterConsumer(self)
    end
    
    return self
end

function DatasetWindow:Show()
    self:UpdateHeader()
    if self.root and self.root.Show then self.root:Show() end
end

function DatasetWindow:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

return DatasetWindow
