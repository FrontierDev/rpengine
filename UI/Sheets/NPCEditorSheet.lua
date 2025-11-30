-- RPE_UI/Sheets/NPCEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE.ActiveRules = RPE.ActiveRules

local VGroup          = RPE_UI.Elements.VerticalLayoutGroup
local HGroup          = RPE_UI.Elements.HorizontalLayoutGroup
local Text            = RPE_UI.Elements.Text
local TextBtn         = RPE_UI.Elements.TextButton
local Input           = RPE_UI.Elements.Input
local ModelEditPrefab = RPE_UI.Prefabs and RPE_UI.Prefabs.ModelEditPrefab

local Common          = _G.RPE_UI and _G.RPE_UI.Common

---@class NPCEditorSheet
local NPCEditorSheet = {}
_G.RPE_UI.Windows.NPCEditorSheet = NPCEditorSheet
NPCEditorSheet.__index = NPCEditorSheet
NPCEditorSheet.Name = "NPCEditorSheet"

-- Dataset helpers ------------------------------------------------------------
function NPCEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then
        self.editingName = name
    else
        self.editingName = nil
    end
end

function NPCEditorSheet:GetEditingDataset()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
    if not (DB and self.editingName) then return nil end
    for _, fname in ipairs({ "GetByName", "GetByKey", "Get" }) do
        local fn = DB[fname]
        if type(fn) == "function" then
            local ok1, ds1 = pcall(fn, DB, self.editingName); if ok1 and ds1 then return ds1 end
            local ok2, ds2 = pcall(fn, self.editingName);      if ok2 and ds2 then return ds2 end
        end
    end
    return nil
end

function NPCEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- Helpers --------------------------------------------------------------------
local function _trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end

-- Use Common:GenerateGUID for new ids
local function _newGUID(prefix)
    if Common and Common.GenerateGUID then
        return Common:GenerateGUID(prefix or "NPC")
    end
    local hi = math.random(0, 0xFFFF)
    local lo = math.random(0, 0xFFFF)
    return string.format("%s-%04x%04x", prefix or "NPC", hi, lo)
end

-- Collect & sort; surfaces tags for searching
local function _collectNPCsSorted(ds)
    local npcs = (ds and ds.npcs) or {}
    local list = {}
    for id, t in pairs(npcs) do
        t = t or {}

        local tagsStr = nil
        if type(t.tags) == "string" then
            tagsStr = t.tags
        elseif type(t.tags) == "table" then
            local parts = {}
            for _, v in ipairs(t.tags) do parts[#parts+1] = tostring(v) end
            tagsStr = table.concat(parts, ",")
        end

        list[#list+1] = {
            id   = id,
            name = t.name or id,
            team = tonumber(t.team) or 1,
            raidMarker = tonumber(t.raidMarker),
            fileDataId = t.fileDataId or 124578,
            displayId  = t.displayId or 21,
            cam = t.cam, rot = t.rot, z = t.z,
            tags = tagsStr,
            isNPC = true,
            spells = (type(t.spells) == "table") and t.spells or {}, -- ✅ enforce array
        }
    end
    table.sort(list, function(a,b)
        local an = tostring(a.name or ""):lower()
        local bn = tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function _updatePageText(self, totalPages, totalFiltered)
    totalPages = math.max(1, totalPages or 1)
    local cur = math.max(1, math.min(self._page or 1, totalPages))
    if self.pageText and self.pageText.SetText then
        local count = tonumber(totalFiltered or 0) or 0
        self.pageText:SetText(("Page %d / %d  ·  %d result%s"):format(cur, totalPages, count, (count==1) and "" or "s"))
    end
end

-- Save helper ----------------------------------------------------------------
local function _saveNPCValues(ds, npcId, v)
    if not (ds and npcId and v) then return nil, "No dataset or values." end
    ds.npcs = ds.npcs or {}

    local name = _trim(v.name or "")
    if name == "" then return nil, "Name is required." end

    local def = {
        id   = npcId,
        name = name,
        team = tonumber(v.team) or 1,
        raidMarker = tonumber(v.raidMarker) or nil,
        unitType = v.unitType or "Humanoid",
        unitSize = v.unitSize or "Medium",
        fileDataId = tonumber(v.modelEdit and v.modelEdit.fileDataId) or tonumber(v.fileDataId),
        displayId  = tonumber(v.modelEdit and v.modelEdit.displayId)  or tonumber(v.displayId),
        cam        = tonumber(v.modelEdit and v.modelEdit.cam) or 1.0,
        rot        = tonumber(v.modelEdit and v.modelEdit.rot) or 0.0,
        z          = tonumber(v.modelEdit and v.modelEdit.z)   or -0.35,
        tags = v.tags,
    }

    -- Hitpoints
    local hpBase      = tonumber(v.hpBase or (v.hp and v.hp.base)) or 0
    local hpPerPlayer = tonumber(v.hpPerPlayer or (v.hp and v.hp.perPlayer)) or 0
    def.hp = { base = hpBase, perPlayer = hpPerPlayer }

    -- Stats from editor table (rows -> map)
    local stats = {}
    if type(v.stats) == "table" then
        if #v.stats > 0 then
            for _, row in ipairs(v.stats) do
                local key = tostring(row.stat or row.key or ""):gsub("^%s+",""):gsub("%s+$","")
                if key ~= "" then
                    local n = tonumber(row.value or row.val or row[2])
                    stats[key] = n or 0
                end
            end
        else
            for k, val in pairs(v.stats) do
                local key = tostring(k or ""):gsub("^%s+",""):gsub("%s+$","")
                if key ~= "" then
                    stats[key] = tonumber(val) or 0
                end
            end
        end
    end
    def.stats = stats

    -- Spells
    local spells = {}
    if type(v.spells) == "table" then
        for _, id in ipairs(v.spells) do
            local sid = tostring(id or ""):match("^%s*(.-)%s*$")
            if sid ~= "" then table.insert(spells, sid) end
        end
    else
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("NPCEditorSheet: expected v.spells as array, got " .. type(v.spells))
        end
    end
    def.spells = spells

    -- Debug: print what we just saved
    if RPE and RPE.Debug and RPE.Debug.Print then
        local joined = (#def.spells > 0) and table.concat(def.spells, ", ") or "(none)"
        RPE.Debug:Internal(("Saving NPC %s, spells: %s"):format(tostring(npcId), joined))
    end

    ds.npcs[npcId] = def
    return npcId
end


-- Schema ---------------------------------------------------------------------
local function _buildEditSchema(npcId, def)
    def = def or {}

    -- Build stat rows from active rule "npc_stats"
    local ruleList = (RPE and RPE.ActiveRules and RPE.ActiveRules.Get and RPE.ActiveRules:Get("npc_stats")) or {}
    local statKeys = {}
    if type(ruleList) == "table" then
        local isArray = (ruleList[1] ~= nil)
        if isArray then
            for i = 1, #ruleList do statKeys[#statKeys+1] = tostring(ruleList[i]) end
        else
            for k, v in pairs(ruleList) do if v then statKeys[#statKeys+1] = tostring(k) end end
            table.sort(statKeys)
        end
    end

    local statsRows = {}
    local defStats  = (type(def.stats) == "table") and def.stats or {}
    for _, k in ipairs(statKeys) do
        statsRows[#statsRows+1] = { stat = k, value = tonumber(defStats[k]) or 0 }
    end

    -- HP defaults (support nested hp and legacy)
    local hpBase      = tonumber(def.hp and def.hp.base) or tonumber(def.hpBase) or 0
    local hpPerPlayer = tonumber(def.hp and def.hp.perPlayer) or tonumber(def.hpPerPlayer) or 0

    -- Sanitize spells
    if type(def.spells) ~= "table" then
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("NPCEditorSheet: invalid spells format for " .. tostring(npcId) .. ", resetting.")
        end
        def.spells = {}
    else
        local cleaned = {}
        for _, id in ipairs(def.spells) do
            local sid = tostring(id or ""):match("^%s*(.-)%s*$")
            if sid ~= "" then table.insert(cleaned, sid) end
        end
        def.spells = cleaned
    end

    -- Debug: show spells loaded
    if RPE and RPE.Debug and RPE.Debug.Print then
        local joined = (#def.spells > 0) and table.concat(def.spells, ", ") or "(none)"
        RPE.Debug:Internal(("Editing NPC %s, spells loaded: %s"):format(tostring(npcId), joined))
    end

    if RPE and RPE.Debug and RPE.Debug.Print then
    RPE.Debug:Internal(("Schema for %s: def.spells = %s")
        :format(npcId, (def.spells and #def.spells > 0) and table.concat(def.spells, ", ") or "(none)"))
    end

    return {
        title  = "Edit NPC: " .. tostring(npcId),
        pages  = {
            {
                title    = "Defaults",
                elements = {
                    { id="name",       label="Name",         type="input",  default = def.name or npcId, required = true },
                    { id="team",       label="Default Team", type="number", default = tonumber(def.team) or 1 },

                    -- Unit Type and Size
                    { id="typeSizeHeader", label="Type and Size", type="label" },

                    { id="unitType", label="Unit Type", type="select",
                    choices = { "Aberration","Beast","Demon","Dragonkin","Elemental","Giant","Humanoid","Mechanical","Undead" },
                    default = def.unitType or "Humanoid" },

                    { id="unitSize", label="Unit Size", type="select",
                    choices = { "Tiny","Small","Medium","Large","Huge","Gargantuan" },
                    default = def.unitSize or "Medium" },

                    -- Hitpoints
                    { id="hpHeader",     label="Hitpoints",     type="label" },
                    { id="hpBase",       label="Base HP",       type="number", default = hpBase },
                    { id="hpPerPlayer",  label="HP per Player", type="number", default = hpPerPlayer },
                }
            },
            {
                title    = "Model",
                elements = {
                    {
                        id="modelEdit",
                        label="Model",
                        type="custom",
                        prefab=ModelEditPrefab,
                        default = {
                            fileDataId = tonumber(def.fileDataId) or nil,
                            displayId  = tonumber(def.displayId)  or nil,
                            cam  = tonumber(def.cam) or 1.0,
                            rot  = tonumber(def.rot) or 0.0,
                            z    = tonumber(def.z) or -0.35,
                        },
                    },
                }
            },
            {
                title    = "Stats (must include a row for each stat in the 'npc_stats' rule!)",
                elements = {
                    {
                        id     = "stats",
                        label  = "Stats",
                        type   = "editor_table",
                        columns = {
                            { id = "stat",  header = "Stat",  type = "label",  width = 180 },
                            { id = "value", header = "Value", type = "number", width = 90  },
                        },
                        default = statsRows,
                        minRows = #statsRows,
                    },
                },
            },
            {
                title = "NPC Spellbook",
                elements = {
                    {
                        id     = "spells",
                        label  = "",
                        type   = "spellbook",
                        default = def.spells or {},
                    }                
                }
            },
            {
                title    = ("%s NYI: Behaviours.\n|cff9d9d9dThese define how the NPC acts when AI mode is enabled.|r"):format(RPE.Common.InlineIcons.Warning),
                elements = { },
            },
            {
                title    = ("%s NYI: Bestiary Entry"):format(RPE.Common.InlineIcons.Warning),
                elements = { },
            }
        },
        labelWidth    = 150,
        navSaveAlways = true,
    }
end



-- Row binding ----------------------------------------------------------------
local function _bindRow(self, row, entry)
    row._entry = entry
    if not row.frame then return end
    if not entry then
        if row.frame.Hide then row.frame:Hide() end
        return
    end
    if row.frame.Show then row.frame:Show() end

    if row._nameText and row._nameText.SetText then
        row._nameText:SetText(entry.name or entry.id)
    end
    if row._portrait then
        row._portrait:SetUnit(entry)
        if row._portrait.hp and row._portrait.hp.Hide then row._portrait.hp:Hide() end
    end
end

local function _buildRow(self, idx)
    local row = HGroup:New(("RPE_NPCEditor_Row_%d"):format(idx), {
        parent  = self.list, width = 1, height = 32,
        spacingX = 10, alignV = "CENTER", alignH = "LEFT",
        autoSize = true,
    })
    self.list:Add(row)

    --[[
    local portrait = UnitPortrait and UnitPortrait:New(("RPE_NPCEditor_RowPortrait_%d"):format(idx), {
        parent = row, size = 32, unit = { isNPC = true, team = 1 },
    })
    if portrait and portrait.hp and portrait.hp.Hide then portrait.hp:Hide() end
    row._portrait = portrait
    if portrait and row.Add then row:Add(portrait) end
    --]]

    local nameText = Text:New(("RPE_NPCEditor_RowName_%d"):format(idx), {
        parent = row, text = "—", fontTemplate = "GameFontNormal",
        point = "LEFT", pointRelative = "LEFT", y = 0
    })
    row:Add(nameText)
    row._nameText = nameText

    -- ... button (context menu trigger)
    local moreBtn = TextBtn:New(("RPE_NPCEditor_RowMenu_%d"):format(idx), {
        parent = row, width = 28, height = 22, text = "...", hasBorder = false, noBorder = true,
        onClick = function()
            local entry = row._entry
            if not entry then return end
            if not (Common and Common.ContextMenu) then return end

            Common:ContextMenu(row.frame or UIParent, function(level, menuList)
                if level == 1 then
                    -- Title
                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle = true; info.notCheckable = true
                    info.text = entry.name or entry.id
                    UIDropDownMenu_AddButton(info, level)

                    -- Edit
                    UIDropDownMenu_AddButton({
                        text = "Edit",
                        notCheckable = true,
                        func = function()
                            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                            if DW and DW.ShowWizard then
                                local ds   = self:GetEditingDataset()
                                local full = (ds and ds.npcs and ds.npcs[entry.id]) or entry
                                local wiz = DW:ShowWizard({
                                    schema = _buildEditSchema(entry.id, full),
                                    isEdit = true,
                                    onSave = function(values)
                                        local ds2 = self:GetEditingDataset()
                                        local okId = _saveNPCValues(ds2, entry.id, values)
                                        if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                            pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                        end
                                        self:Refresh()
                                    end,
                                })
                            end
                        end,
                    }, level)

                    -- Clone (fresh GUID)
                    UIDropDownMenu_AddButton({
                        text = "Clone",
                        notCheckable = true,
                        func = function()
                            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                            if DW and DW.ShowWizard then
                                local ds   = self:GetEditingDataset()
                                local full = (ds and ds.npcs and ds.npcs[entry.id]) or entry
                                local newId = _newGUID("NPC")
                                local wiz = DW:ShowWizard({
                                    schema = _buildEditSchema(newId, full),
                                    isEdit = false,
                                    onSave = function(values)
                                        local ds2 = self:GetEditingDataset()
                                        local okId = _saveNPCValues(ds2, newId, values)
                                        if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                            pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                        end
                                        self:Refresh()
                                    end,
                                })
                            end
                        end,
                    }, level)

                    -- Delete
                    UIDropDownMenu_AddButton({
                        text = "|cffff4040Delete Entry|r",
                        notCheckable = true,
                        func = function()
                            local ds = self:GetEditingDataset()
                            if not (ds and ds.npcs and ds.npcs[entry.id]) then return end
                            ds.npcs[entry.id] = nil
                            if _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                            end
                            self:Refresh()
                        end,
                    }, level)
                end
            end)
        end,
    })
    row:Add(moreBtn)
    row._moreBtn = moreBtn

    -- Right-click menu on entire row
    if row then
        row.frame:HookScript("OnMouseDown", function(_, button)
            if button ~= "RightButton" then return end
            local entry = row._entry
            if not entry then return end
            if not (Common and Common.ContextMenu) then return end

            Common:ContextMenu(row.frame or UIParent, function(level, menuList)
                if level == 1 then
                    local info = UIDropDownMenu_CreateInfo()
                    info.isTitle = true; info.notCheckable = true
                    info.text = entry.name or entry.id
                    UIDropDownMenu_AddButton(info, level)

                    UIDropDownMenu_AddButton({
                        text = "Edit", notCheckable = true, func = function() moreBtn.onClick() end
                    }, level)
                end
            end)
        end)
    end

    if row.frame and row.frame.Hide then row.frame:Hide() end
    return row
end

-- Find a real EditBox inside the Input wrapper -------------------------------
local function _findEditBoxFromInput(inputElem)
    if not inputElem then return nil end
    local cand = inputElem.edit or inputElem.input or inputElem.frame
    if cand and cand.GetObjectType and cand:GetObjectType() == "EditBox" then
        return cand
    end
    local root = inputElem.frame or cand
    if root and root.GetChildren then
        local n = select("#", root:GetChildren())
        for i = 1, n do
            local ch = select(i, root:GetChildren())
            if ch and ch.GetObjectType and ch:GetObjectType() == "EditBox" then
                return ch
            end
        end
    end
    return nil
end

-- Apply search from current input value
local function _applySearch(self)
    local value = ""
    local eb = _findEditBoxFromInput(self.searchInput)
    if eb and eb.GetText then
        value = eb:GetText() or ""
    elseif self.searchInput and self.searchInput.GetText then
        value = self.searchInput:GetText() or ""
    end
    self._query = _trim(value)
    self._page  = 1
    self:Refresh()
end

-- Build & Refresh ------------------------------------------------------------
function NPCEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.parent      = opts.parent
    self.rowsPerPage = 10
    self._page       = 1
    self._perPage    = self.rowsPerPage
    self._query      = ""

    self:SetEditingDataset(opts and opts.editingName)

    self.sheet = VGroup:New("RPE_NPCEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 10,
        alignV   = "TOP", alignH   = "CENTER",
        autoSize = true,
    })

    -- Search bar
    self.searchBar = HGroup:New("RPE_NPCEditor_SearchBar", {
        parent   = self.sheet, width = 1, height = 1,
        spacingX = 8, alignH = "LEFT", alignV = "CENTER", autoSize = true,
    })
    local searchLabel = Text:New("RPE_NPCEditor_SearchLabel", {
        parent = self.searchBar, text = "Search:", fontTemplate="GameFontNormalSmall",
    })
    self.searchBar:Add(searchLabel)

    self.searchInput = Input:New("RPE_NPCEditor_SearchInput", {
        parent = self.searchBar,
        width  = 200,
        placeholder = "name or tag...",
        onEnterPressed = function(value)
            self._query = _trim(value or "")
            self._page  = 1
            self:Refresh()
        end,
    })
    self.searchBar:Add(self.searchInput)

    -- Hook real editbox if present
    local eb = _findEditBoxFromInput(self.searchInput)
    if eb and eb.SetScript then
        if not eb.HasScript or eb:HasScript("OnEnterPressed") then
            eb:SetScript("OnEnterPressed", function() _applySearch(self) end)
        end
        if not eb.HasScript or eb:HasScript("OnEscapePressed") then
            eb:SetScript("OnEscapePressed", function()
                if eb.SetText then eb:SetText("") end
                self._query = ""
                self._page  = 1
                self:Refresh()
            end)
        end
    end

    self.resultsText = Text:New("RPE_NPCEditor_ResultsText", {
        parent = self.searchBar, text = "", fontTemplate="GameFontNormalSmall",
    })
    local spacerSB = Text:New("RPE_NPCEditor_SearchSpacer", { parent = self.searchBar, text = "", width = 1, height = 1 })
    spacerSB.flex = 1; self.searchBar:Add(spacerSB)
    self.searchBar:Add(self.resultsText)
    self.sheet:Add(self.searchBar)

    -- Top nav (New + Pager)
    self.navWrap = HGroup:New("RPE_NPCEditor_NavWrap", {
        parent   = self.sheet, width = 1, height = 1,
        spacingX = 10, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })

    -- New NPC (fresh GUID) + immediate resize to wizard
    self.newBtn = TextBtn:New("RPE_NPCEditor_NewNPC", {
        parent = self.navWrap, width = 96, height = 22, text = "New NPC",
        onClick = function()
            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
            if DW and DW.ShowWizard then
                local newId = _newGUID("NPC")
                local wiz = DW:ShowWizard({
                    schema = _buildEditSchema(newId, {}),
                    isEdit = false,
                    onSave = function(values)
                        local ds = self:GetEditingDataset()
                        local okId = _saveNPCValues(ds, newId, values)
                        if okId and _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                            pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                        end
                        self:Refresh()
                    end,
                })
            end
        end,
    })
    self.navWrap:Add(self.newBtn)

    self.pager = HGroup:New("RPE_NPCEditor_Nav", {
        parent   = self.navWrap, width = 1, height = 1,
        spacingX = 10, alignV = "CENTER", autoSize = true,
    })
    local prevBtn = TextBtn:New("RPE_NPCEditor_Prev", {
        parent = self.pager, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) - 1) end,
    })
    self.pager:Add(prevBtn)
    self.pageText = Text:New("RPE_NPCEditor_PageText", {
        parent = self.pager, text = "Page 1 / 1", fontTemplate = "GameFontNormalSmall",
    })
    self.pager:Add(self.pageText)
    local nextBtn = TextBtn:New("RPE_NPCEditor_Next", {
        parent = self.pager, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) + 1) end,
    })
    self.pager:Add(nextBtn)
    self.navWrap:Add(self.pager)
    self.sheet:Add(self.navWrap)

    -- List
    self.list = VGroup:New("RPE_NPCEditor_List", {
        parent   = self.sheet, width = 1, height = 1,
        spacingY = 8, alignV = "TOP", alignH = "LEFT", autoSize = true,
    })
    self.sheet:Add(self.list)

    self._rows = {}
    for i = 1, self._perPage do self._rows[i] = _buildRow(self, i) end

    self:Refresh()
    return self.sheet
end

-- Paging ---------------------------------------------------------------------
function NPCEditorSheet:_setPage(p)
    local total = self._filtered and #self._filtered or 0
    local per   = self._perPage or (#self._rows)
    local totalPages = math.max(1, math.ceil(math.max(0, total) / math.max(1, per)))
    local newP = math.max(1, math.min(tonumber(p) or 1, totalPages))
    if newP ~= self._page then
        self._page = newP
        self:_rebindPage()
    end
    _updatePageText(self, totalPages, total)
end

function NPCEditorSheet:_rebindPage()
    local per  = self._perPage or (#self._rows)
    local page = math.max(1, self._page or 1)
    local startIndex = (page - 1) * per + 1
    local total = self._filtered and #self._filtered or 0

    for i = 1, per do
        local row    = self._rows[i]
        local entry  = (startIndex + (i - 1) <= total) and (self._filtered[startIndex + (i - 1)]) or nil
        if row then _bindRow(self, row, entry) end
    end
end

function NPCEditorSheet:Refresh()
    local ds = self:GetEditingDataset()
    self._entries = _collectNPCsSorted(ds)

    -- Apply search filter (name, id, tags)
    local query = (self._query or ""):lower()
    if query ~= "" then
        local filtered = {}
        for _, e in ipairs(self._entries) do
            local name = tostring(e.name or ""):lower()
            local id   = tostring(e.id or ""):lower()
            local tags = type(e.tags) == "string" and e.tags:lower() or ""
            if name:find(query, 1, true) or id:find(query, 1, true) or tags:find(query, 1, true) then
                filtered[#filtered+1] = e
            end
        end
        self._filtered = filtered
    else
        self._filtered = self._entries
    end

    if self.resultsText and self.resultsText.SetText then
        local n = #self._filtered
        self.resultsText:SetText(("%d total"):format(n))
    end

    local total      = #self._filtered
    local per        = self._perPage or (#self._rows)
    local totalPages = math.max(1, math.ceil(math.max(0, total) / math.max(1, per)))
    if (self._page or 1) > totalPages then self._page = totalPages end
    if (self._page or 0) < 1 then self._page = 1 end

    self:_rebindPage()
    _updatePageText(self, totalPages, total)
end

function NPCEditorSheet.New(opts)
    local self = setmetatable({}, NPCEditorSheet)
    self:SetEditingDataset(opts and opts.editingName)
    self:BuildUI(opts or {})
    return self
end

return NPCEditorSheet
