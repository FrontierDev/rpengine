-- RPE_UI/Sheets/StatEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local VGroup  = RPE_UI.Elements.VerticalLayoutGroup
local HGroup  = RPE_UI.Elements.HorizontalLayoutGroup
local Text    = RPE_UI.Elements.Text
local TextBtn = RPE_UI.Elements.TextButton
local Input   = RPE_UI.Elements.Input

local Common  = _G.RPE_UI and _G.RPE_UI.Common

---@class StatEditorSheet
local StatEditorSheet = {}
_G.RPE_UI.Windows.StatEditorSheet = StatEditorSheet
StatEditorSheet.__index = StatEditorSheet
StatEditorSheet.Name = "StatEditorSheet"

-- ==== Dataset helpers =======================================================

function StatEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then self.editingName = name else self.editingName = nil end
end

function StatEditorSheet:GetEditingDataset()
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

function StatEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- ==== Helpers ===============================================================
local function _trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end

local function _generateStatId(name)
    -- Convert name to ID: capitalize, replace spaces with underscores
    if type(name) ~= "string" or name == "" then return "" end
    return name:upper():gsub(" ", "_")
end

local function _statsBucket(ds) return (ds and ds.extra and ds.extra.stats) or {} end

local function _collectStatsSorted(ds)
    local list = {}
    for id, t in pairs(_statsBucket(ds)) do
        t = t or {}
        list[#list+1] = {
            id              = id,
            name            = t.name or id,
            category        = t.category or "PRIMARY",
            sourceDataset   = t.sourceDataset or "(none)",
            base            = tostring(t.base or 0),
            visible         = t.visible and "Yes" or "No",
        }
    end
    table.sort(list, function(a,b)
        local an, bn = tostring(a.name or ""):lower(), tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function _updatePageText(self, totalPages, totalFiltered)
    totalPages = math.max(1,totalPages or 1)
    local cur  = math.max(1,math.min(self._page or 1,totalPages))
    if self.pageText and self.pageText.SetText then
        local count = tonumber(totalFiltered or 0) or 0
        self.pageText:SetText(("Page %d / %d  ·  %d result%s"):format(cur,totalPages,count,(count==1) and "" or "s"))
    end
end

-- ==== Save helper ===========================================================
local function _parseRecovery(v)
    -- Recovery can be: table with { ruleKey, default }, or a simple number/string
    if type(v) == "table" then
        local ruleKey = (type(v.ruleKey) == "string" and v.ruleKey ~= "") and v.ruleKey or nil
        local default = tonumber(v.default) or 0
        if ruleKey then
            return { ruleKey = ruleKey, default = default }
        end
    end
    return nil
end

local function _valueToDisplay(val)
    -- Convert value (number or reference) to display string
    if type(val) == "table" then
        if val.ref then
            return "$" .. val.ref
        end
        return ""
    elseif val == math.huge then
        return "inf"
    else
        return tostring(val or 0)
    end
end

local function _displayToValue(str)
    -- Convert display string back to value (number, reference, or formula)
    -- BUT: if it's already a table (rule table), return it as-is
    if type(str) == "table" then
        if str.ruleKey then
            -- It's already a rule table, preserve it
            return str
        elseif str.ref then
            -- It's a reference table, preserve it
            return str
        end
        return 0
    end
    if not str or str == "" then
        return 0
    end
    str = _trim(str)
    
    -- Check if it's a formula expression (contains $value$)
    if str:find("%$value%$") then
        -- It's a formula expression like "$value$*0.5", keep it as a string
        return str
    end
    
    if str:sub(1, 1) == "$" then
        -- It's a reference like "$STAT_ID"
        local refName = str:sub(2)
        if refName ~= "" then
            return { ref = refName }
        end
    elseif str:lower() == "inf" then
        return math.huge
    end
    return tonumber(str) or 0
end

local function _parseMitigation(v)
    -- Mitigation can be: table with { normal, critical, fail, combatText } where each is an expression (literal, stat ref, or formula)
    -- Or nil/empty
    if type(v) == "table" then
        local normal = v.normal or 0
        local critical = v.critical or 0
        local fail = v.fail or 0
        local combatText = v.combatText or "Defend"
        return { normal = normal, critical = critical, fail = fail, combatText = combatText }
    end
    return nil
end

local function _syncStatToProfile(statId, statDef)
    if not (statId and statDef) then return end
    local profile = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB and _G.RPE.Profile.DB.GetOrCreateActive and _G.RPE.Profile.DB:GetOrCreateActive()
    if not profile then return end
    local stat = profile:GetStat(statId, statDef.category or "PRIMARY", statDef.sourceDataset)
    if not stat then return end
    stat:SetData({
        id=statId, name=statDef.name, category=statDef.category, base=statDef.base, min=statDef.min, max=statDef.max,
        icon=statDef.icon, tooltip=statDef.tooltip, visible=statDef.visible, pct=statDef.pct, recovery=statDef.recovery,
        mitigation=statDef.mitigation,
        itemTooltipFormat=statDef.itemTooltipFormat, itemTooltipColor=statDef.itemTooltipColor,
        itemTooltipPriority=statDef.itemTooltipPriority, itemLevelWeight=statDef.itemLevelWeight,
    })
    if statDef.sourceDataset then stat.sourceDataset=statDef.sourceDataset end
    if _G.RPE.Profile.DB.SaveProfile then _G.RPE.Profile.DB.SaveProfile(profile) end
end

local function _saveStat(ds, statId, v)
    if not (ds and statId and v) then return nil end
    ds.extra = ds.extra or {}; ds.extra.stats = ds.extra.stats or {}
    local ds_name = ds.name or ""
    local mitigationTable = _parseMitigation(v.mitigation)
    if mitigationTable then
        mitigationTable.combatText = (v.mitigationCombatText and v.mitigationCombatText ~= "") and v.mitigationCombatText or "Defend"
    end
    ds.extra.stats[statId] = {
        id              = statId,
        name            = _trim(v.name or statId),
        category        = v.category or "PRIMARY",
        base            = _displayToValue(v.base),
        min             = _displayToValue(v.min),
        max             = _displayToValue(v.max),
        visible         = (v.visible == 1 or v.visible == true or v.visible == "1") and 1 or 0,
        icon            = v.icon or "",
        description     = v.description or "",
        tooltip         = v.tooltip or "",
        recovery        = _parseRecovery(v.recovery),
        pct             = (v.pct == 1 or v.pct == true or v.pct == "1") and 1 or 0,
        mitigation      = mitigationTable,
        defenceName     = v.defenceName or "",
        data            = v.data or {},
        sourceDataset   = ds_name,
        itemTooltipFormat = v.itemTooltipFormat or "",
        itemTooltipColor = v.itemTooltipColor or {1, 1, 1},
        itemTooltipPriority = tonumber(v.itemTooltipPriority) or 0,
        itemLevelWeight = tonumber(v.itemLevelWeight) or 0,
    }
    return statId
end

-- ==== Wizard schema =========================================================
local function _buildEditSchema(statId, def)
    def = def or {}
    
    -- Debug: log the ACTUAL values coming in before any processing
    if _G.RPE and _G.RPE.Debug then
        _G.RPE.Debug:Internal(string.format("StatEditor RAW input for %s: visible_raw=%s (type=%s), pct_raw=%s (type=%s)", 
            statId, tostring(def.visible), type(def.visible), tostring(def.pct), type(def.pct)))
    end
    
    -- CRITICAL: Default checkbox values to 0 (false) unless explicitly truthy (1, true, "1")
    local visibleDefault
    if def.visible == 1 or def.visible == true or def.visible == "1" then
        visibleDefault = 1
    else
        visibleDefault = 0
    end
    
    local pctDefault
    if def.pct == 1 or def.pct == true or def.pct == "1" then
        pctDefault = 1
    else
        pctDefault = 0
    end
    
    local recoveryRuleKey = (type(def.recovery) == "table" and def.recovery.ruleKey) or ""
    local recoveryDefault = (type(def.recovery) == "table" and def.recovery.default) or 0
    
    -- Mitigation values
    local mitigationNormalValue = ""
    local mitigationCriticalValue = ""
    local mitigationFailValue = ""
    local mitigationCombatText = "Defend"
    if type(def.mitigation) == "table" then
        mitigationNormalValue = _valueToDisplay(def.mitigation.normal)
        mitigationCriticalValue = _valueToDisplay(def.mitigation.critical)
        mitigationFailValue = _valueToDisplay(def.mitigation.fail)
        mitigationCombatText = def.mitigation.combatText or "Defend"
    end
    
    -- Determine base value type and values
    local baseKey = ""
    local baseDefault = 0
    
    if type(def.base) == "table" then
        baseKey = def.base.ruleKey or def.base.expr or def.base.ref or ""
        baseDefault = def.base.default or 0
    else
        baseDefault = tonumber(def.base) or 0
    end
    
    -- Debug: log after processing
    if _G.RPE and _G.RPE.Debug then
        _G.RPE.Debug:Internal(string.format("StatEditor schema for %s: visible=%d, pct=%d", 
            statId, visibleDefault, pctDefault))
    end
    
    return {
        title="Edit Stat: "..tostring(statId),
        pages={
            { title="Basics", elements={
                { id="id",        label="Stat Key",     type="input",  default=statId or "", required=true, hint="Leave blank to auto-generate from name" },
                { id="name",       label="Name",        type="input",  default=def.name or statId, required=true },
                { id="category",   label="Category",    type="select",
                  choices={"PRIMARY","SECONDARY","DEFENSE","RESISTANCE","SKILL","RESOURCE"},
                  default=def.category or "PRIMARY" },
                { id="visible",    label="Visible",     type="checkbox", default=visibleDefault },
                { id="baseHeader",     label="Value Calculation",     type="label" },
                { id="baseKey", label="Rule Key / Expression", type="input", default=baseKey, hint="Rule key (e.g., 'max_health'), expression (e.g., 'stats.STR.value'), or stat reference (e.g., 'MAX_HEALTH')" },
                { id="baseDefault", label="Default Value", type="number", default=baseDefault, hint="Fallback value if rule/expression fails or when literal" },
                { id="minmaxHeader",     label="Bounds",     type="label" },
                { id="min",        label="Min Value",   type="input", default=_valueToDisplay(def.min), hint="Leave empty for -inf (unbounded lower)" },
                { id="max",        label="Max Value",   type="input", default=_valueToDisplay(def.max), hint='Leave empty for +inf (unbounded upper), or use "inf", "$STAT_ID" for reference' },

            }},
            { title="Display", elements={
                { id="icon",       label="Icon",        type="icon", default=def.icon or "" },
                { id="description", label="Description", type="input", default=def.description or "" },
                { id="tooltip",    label="Tooltip",     type="input", default=def.tooltip or "" },
                { id="pct",        label="Percentage",  type="checkbox", default=pctDefault },
            }},
            { title="Recovery", elements={
                { id="ruleKey",    label="Rule Key",    type="input", default=recoveryRuleKey, hint="e.g., 'health_regen'" },
                { id="recoveryDefault", label="Default Value", type="number", default=recoveryDefault },
            }},
            { title="Mitigation", elements={
                { id="mitigationHeader", label="Damage Reduction (only applies to DEFENSE/RESISTANCE stats)", type="label" },
                { id="defenceName", label="Defence Name", type="input", default=def.defenceName or "", 
                  hint="Name shown on player reaction widget (e.g., 'Fire Resistance'). If empty, uses stat name." },
                { id="mitigationCombatText", label="Combat Text", type="input", default=mitigationCombatText, 
                  hint="Text displayed when this defense is successful (e.g., 'Fire Resistance', 'Parry'). Default: 'Defend'" },
                { id="mitigationNormalValue", label="Mitigation", type="input", default=mitigationNormalValue, 
                  hint="Expression that modifies incoming damage. $value$ is the damage amount (e.g., $value$*0.5 reduces by 50%, $value$-$stat.ARMOR$ for flat reduction)" },
                { id="mitigationCriticalValue", label="Crit. Mitigation", type="input", default=mitigationCriticalValue, 
                  hint="Expression that modifies incoming critical damage. $value$ is the damage amount (e.g., $value$*0.75 reduces by 25%, $value$-($stat.ARMOR$*2) for stat-based reduction)" },
                { id="mitigationFailValue", label="Fail Mitigation", type="input", default=mitigationFailValue, 
                  hint="Expression that modifies incoming damage when defense fails. $value$ is the damage amount (e.g., $value$*0.25 reduces by 75%, $value$-$stat.AC$ for stat-based reduction)" },
            }},
            { title="Item Bonuses", elements={
                { id="itemTooltipFormat", label="Tooltip Format", type="input", 
                  default=def.itemTooltipFormat or "", hint="e.g., '$value$ Strength'" },
                { id="itemTooltipPriority", label="Priority", type="number", 
                  default=tonumber(def.itemTooltipPriority) or 0 },
                { id="itemLevelWeight", label="Level Weight", type="number",
                  default=tonumber(def.itemLevelWeight) or 0 },
            }},
        },
        labelWidth=150, navSaveAlways=true,
    }
end

-- ==== Row binding ===========================================================
local function _bindRow(self,row,entry)
    row._entry=entry
    if not row.frame then return end
    if not entry then if row.frame.Hide then row.frame:Hide() end return end
    if row.frame.Show then row.frame:Show() end
    if row._nameText and row._nameText.SetText then row._nameText:SetText(entry.name or entry.id) end
    if row._categoryText and row._categoryText.SetText then row._categoryText:SetText(entry.category or "") end
    if row._sourceText and row._sourceText.SetText then row._sourceText:SetText(entry.sourceDataset or "") end
end

local function _buildRow(self, idx)
    local row = HGroup:New(("RPE_StatEditor_Row_%d"):format(idx), {
        parent  = self.list, width = 1, height = 24,
        spacingX = 10, alignV = "CENTER", alignH = "LEFT",
        autoSize = true,
    })
    self.list:Add(row)

    local nameText = Text:New(("RPE_StatEditor_RowName_%d"):format(idx), {
        parent = row, text = "—", fontTemplate = "GameFontNormal", width = 150,
    })
    row:Add(nameText)
    row._nameText = nameText

    local categoryText = Text:New(("RPE_StatEditor_RowCategory_%d"):format(idx), {
        parent = row, text = "—", fontTemplate = "GameFontNormalSmall", width = 120,
    })
    row:Add(categoryText)
    row._categoryText = categoryText

    local sourceText = Text:New(("RPE_StatEditor_RowSource_%d"):format(idx), {
        parent = row, text = "—", fontTemplate = "GameFontNormalSmall", width = 180,
    })
    row:Add(sourceText)
    row._sourceText = sourceText

    -- ... button (context menu trigger)
    local moreBtn = TextBtn:New(("RPE_StatEditor_RowMenu_%d"):format(idx), {
        parent = row, width = 28, height = 22, text = "...",
        hasBorder = false, noBorder = true,
        onClick = function()
            local entry = row._entry
            if not entry or not (Common and Common.ContextMenu) then return end

            Common:ContextMenu(row.frame or UIParent, function(level)
                if level ~= 1 then return end

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
                            local full = (ds and ds.extra and ds.extra.stats and ds.extra.stats[entry.id]) or entry
                            -- Normalize pct/visible fields: ensure they are ALWAYS 0 unless explicitly 1
                            if full then
                                full.pct = (full.pct == 1 or full.pct == true or full.pct == "1") and 1 or 0
                                full.visible = (full.visible == 1 or full.visible == true or full.visible == "1") and 1 or 0
                            end
                            DW:ShowWizard({
                                schema = _buildEditSchema(entry.id, full),
                                isEdit = true,
                                onSave = function(values)
                                    -- Normalize checkbox values from form to numeric 1 or 0 (never true/false/nil)
                                    -- Explicitly convert anything that's not 1/true/"1" to 0
                                    if values.visible == 1 or values.visible == true or values.visible == "1" then
                                        values.visible = 1
                                    else
                                        values.visible = 0
                                    end
                                    if values.pct == 1 or values.pct == true or values.pct == "1" then
                                        values.pct = 1
                                    else
                                        values.pct = 0
                                    end
                                    
                                    -- Handle stat ID: auto-generate from name if blank
                                    local newStatId = _trim(values.id or "")
                                    if newStatId == "" then
                                        newStatId = _generateStatId(values.name)
                                    end
                                    if newStatId == "" then
                                        return  -- Can't save without a valid ID
                                    end
                                    values.id = nil  -- Remove from values, we'll use newStatId
                                    
                                    -- Handle empty min/max: empty min becomes -inf, empty max becomes +inf
                                    if not values.min or values.min == "" then
                                        values.min = -math.huge
                                    else
                                        values.min = _displayToValue(values.min)  -- Convert display string to value (handles $REF)
                                    end
                                    if not values.max or values.max == "" then
                                        values.max = math.huge
                                    else
                                        values.max = _displayToValue(values.max)  -- Convert display string to value (handles $REF)
                                    end
                                    
                                    -- Reconstruct base: if baseKey is empty, it's a literal number; otherwise it's a rule/expr/ref
                                    if values.baseKey and values.baseKey ~= "" then
                                        values.base = { ruleKey = values.baseKey, default = tonumber(values.baseDefault) or 0 }
                                    else
                                        values.base = tonumber(values.baseDefault) or 0
                                    end
                                    values.baseKey = nil
                                    values.baseDefault = nil
                                    
                                    -- Reconstruct recovery from separate fields
                                    if values.ruleKey and values.ruleKey ~= "" then
                                        values.recovery = { ruleKey = values.ruleKey, default = tonumber(values.recoveryDefault) or 0 }
                                    else
                                        values.recovery = nil
                                    end
                                    values.ruleKey = nil
                                    values.recoveryDefault = nil
                                    
                                    -- Reconstruct mitigation from separate fields
                                    local mitigationNormalValue = _displayToValue(values.mitigationNormalValue or "")
                                    local mitigationCriticalValue = _displayToValue(values.mitigationCriticalValue or "")
                                    if mitigationNormalValue ~= 0 or mitigationCriticalValue ~= 0 then
                                        values.mitigation = {
                                            normal = mitigationNormalValue,
                                            critical = mitigationCriticalValue,
                                            fail = _displayToValue(values.mitigationFailValue or ""),
                                            combatText = (values.mitigationCombatText and values.mitigationCombatText ~= "") and values.mitigationCombatText or "Defend"
                                        }
                                    else
                                        values.mitigation = nil
                                    end
                                    values.mitigationNormalValue = nil
                                    values.mitigationCriticalValue = nil
                                    values.mitigationFailValue = nil
                                    values.mitigationCombatText = nil
                                    values.mitigationHeader = nil
                                    
                                    local ds2 = self:GetEditingDataset()
                                    -- If ID changed, delete the old entry and save with new ID
                                    if newStatId ~= entry.id and ds2 and ds2.extra and ds2.extra.stats then
                                        ds2.extra.stats[entry.id] = nil
                                    end
                                    local okId = _saveStat(ds2, newStatId, values)
                                    if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                        pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                        _syncStatToProfile(newStatId, ds2.extra.stats[newStatId])
                                    end
                                    -- Refresh stat registry
                                    if _G.RPE.Core and _G.RPE.Core.StatRegistry then
                                        pcall(function() _G.RPE.Core.StatRegistry:RefreshFromActiveDatasets() end)
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
                        if not (ds and ds.extra and ds.extra.stats and ds.extra.stats[entry.id]) then return end
                        ds.extra.stats[entry.id] = nil
                        if _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                            pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                        end
                        -- Refresh stat registry
                        if _G.RPE.Core and _G.RPE.Core.StatRegistry then
                            pcall(function() _G.RPE.Core.StatRegistry:RefreshFromActiveDatasets() end)
                        end
                        self:Refresh()
                    end,
                }, level)
            end)
        end,
    })
    row:Add(moreBtn)
    row._moreBtn = moreBtn

    -- Right-click menu on entire row
    if row and row.frame and row.frame.HookScript then
        row.frame:HookScript("OnMouseDown", function(_, button)
            if button == "RightButton" and moreBtn and moreBtn.onClick then
                moreBtn.onClick()
            end
        end)
    end

    if row.frame and row.frame.Hide then row.frame:Hide() end
    return row
end


-- ==== Build UI ==============================================================
function StatEditorSheet:BuildUI(opts)
    opts=opts or {}
    self.parent=opts.parent; self.rowsPerPage=12; self._page=1; self._perPage=self.rowsPerPage; self._query=""
    self:SetEditingDataset(opts and opts.editingName)

    self.sheet=VGroup:New("RPE_StatEditor_Sheet",{parent=self.parent,width=1,height=1,point="TOP",relativePoint="TOP",x=0,y=0,padding={left=12,right=12,top=12,bottom=12},spacingY=10,alignV="TOP",alignH="CENTER",autoSize=true})

    -- Search bar
    self.searchBar=HGroup:New("RPE_StatEditor_SearchBar",{parent=self.sheet,width=1,spacingX=8,alignH="LEFT",alignV="CENTER",autoSize=true})
    self.searchBar:Add(Text:New("RPE_StatEditor_SearchLabel",{parent=self.searchBar,text="Search:",fontTemplate="GameFontNormalSmall"}))
    self.searchInput=Input:New("RPE_StatEditor_SearchInput",{parent=self.searchBar,width=220,placeholder="name, category, source dataset...",onEnterPressed=function(value) self._query=_trim(value or ""); self._page=1; self:Refresh() end})
    self.searchBar:Add(self.searchInput)
    self.resultsText=Text:New("RPE_StatEditor_ResultsText",{parent=self.searchBar,text="",fontTemplate="GameFontNormalSmall"})
    local spacer=Text:New("RPE_StatEditor_SearchSpacer",{parent=self.searchBar,text="",width=1,height=1}); spacer.flex=1; self.searchBar:Add(spacer); self.searchBar:Add(self.resultsText)
    self.sheet:Add(self.searchBar)

    -- Headers
    self.headerBar=HGroup:New("RPE_StatEditor_HeaderBar",{parent=self.sheet,width=1,spacingX=10,alignV="CENTER",alignH="LEFT",autoSize=true})
    self.headerBar:Add(Text:New("RPE_StatEditor_HeaderName",{parent=self.headerBar,text="Name",fontTemplate="GameFontNormalSmall",width=150}))
    self.headerBar:Add(Text:New("RPE_StatEditor_HeaderCategory",{parent=self.headerBar,text="Category",fontTemplate="GameFontNormalSmall",width=120}))
    self.headerBar:Add(Text:New("RPE_StatEditor_HeaderSource",{parent=self.headerBar,text="Source Dataset",fontTemplate="GameFontNormalSmall",width=180}))
    self.sheet:Add(self.headerBar)

    -- Nav (New + Pager)
    self.navWrap=HGroup:New("RPE_StatEditor_NavWrap",{parent=self.sheet,width=1,spacingX=10,alignV="CENTER",alignH="CENTER",autoSize=true})
    self.newBtn=TextBtn:New("RPE_StatEditor_New",{parent=self.navWrap,width=80,height=22,text="New Stat",onClick=function()
        local DW=_G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
        if DW and DW.ShowWizard then
            local newId=_generateStatId("New Stat")
            DW:ShowWizard({schema=_buildEditSchema(newId,{}),isEdit=false,onSave=function(values)
                local ds=self:GetEditingDataset()
                if not ds then return end
                -- Normalize checkbox values from form to numeric 1 or 0 (never true/false/nil)
                -- Explicitly convert anything that's not 1/true/"1" to 0
                if values.visible == 1 or values.visible == true or values.visible == "1" then
                    values.visible = 1
                else
                    values.visible = 0
                end
                if values.pct == 1 or values.pct == true or values.pct == "1" then
                    values.pct = 1
                else
                    values.pct = 0
                end
                
                -- Handle stat ID: auto-generate from name if blank
                local newStatId = _trim(values.id or "")
                if newStatId == "" then
                    newStatId = _generateStatId(values.name)
                end
                if newStatId == "" then
                    return  -- Can't save without a valid ID
                end
                values.id = nil  -- Remove from values, we'll use newStatId
                
                -- Reconstruct base: if baseKey is empty, it's a literal number; otherwise it's a rule/expr/ref
                if values.baseKey and values.baseKey ~= "" then
                    values.base = { ruleKey = values.baseKey, default = tonumber(values.baseDefault) or 0 }
                else
                    values.base = tonumber(values.baseDefault) or 0
                end
                values.baseKey = nil
                values.baseDefault = nil
                -- Reconstruct recovery from separate fields
                if values.ruleKey and values.ruleKey ~= "" then
                    values.recovery = { ruleKey = values.ruleKey, default = tonumber(values.recoveryDefault) or 0 }
                else
                    values.recovery = nil
                end
                values.ruleKey = nil
                values.recoveryDefault = nil
                
                -- Reconstruct mitigation from separate fields
                local mitigationNormalValue = _displayToValue(values.mitigationNormalValue or "")
                local mitigationCriticalValue = _displayToValue(values.mitigationCriticalValue or "")
                if mitigationNormalValue ~= 0 or mitigationCriticalValue ~= 0 then
                    values.mitigation = {
                        normal = mitigationNormalValue,
                        critical = mitigationCriticalValue,
                        fail = _displayToValue(values.mitigationFailValue or ""),
                        combatText = (values.mitigationCombatText and values.mitigationCombatText ~= "") and values.mitigationCombatText or "Defend"
                    }
                else
                    values.mitigation = nil
                end
                values.mitigationNormalValue = nil
                values.mitigationCriticalValue = nil
                values.mitigationFailValue = nil
                values.mitigationCombatText = nil
                values.mitigationHeader = nil
                
                local okId = _saveStat(ds, newStatId, values)
                if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                    pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                    _syncStatToProfile(newStatId, ds.extra.stats[newStatId])
                end
                -- Refresh stat registry
                if _G.RPE.Core and _G.RPE.Core.StatRegistry then
                    pcall(function() _G.RPE.Core.StatRegistry:RefreshFromActiveDatasets() end)
                end
                self:Refresh()
            end})
        end
    end}); self.navWrap:Add(self.newBtn)

    self.pager=HGroup:New("RPE_StatEditor_Nav",{parent=self.navWrap,spacingX=10,alignV="CENTER",autoSize=true})
    self.prevBtn=TextBtn:New("RPE_StatEditor_Prev",{parent=self.pager,width=70,height=22,text="Prev",noBorder=true,onClick=function() self:_setPage((self._page or 1)-1) end})
    self.pager:Add(self.prevBtn)
    self.pageText=Text:New("RPE_StatEditor_PageText",{parent=self.pager,text="Page 1 / 1",fontTemplate="GameFontNormalSmall"})
    self.pager:Add(self.pageText)
    self.nextBtn=TextBtn:New("RPE_StatEditor_Next",{parent=self.pager,width=70,height=22,text="Next",noBorder=true,onClick=function() self:_setPage((self._page or 1)+1) end})
    self.pager:Add(self.nextBtn)
    self.navWrap:Add(self.pager); self.sheet:Add(self.navWrap)

    -- List
    self.list=VGroup:New("RPE_StatEditor_List",{parent=self.sheet,width=1,spacingY=8,alignV="TOP",alignH="LEFT",autoSize=true})
    self.sheet:Add(self.list)
    self._rows={}; for i=1,self._perPage do self._rows[i]=_buildRow(self,i) end

    self:Refresh()
    return self.sheet
end

-- ==== Paging ================================================================
function StatEditorSheet:_setPage(p)
    local total=#(self._filtered or {}); local per=self._perPage or (#self._rows)
    local totalPages=math.max(1,math.ceil(math.max(0,total)/math.max(1,per)))
    local newP=math.max(1,math.min(tonumber(p) or 1,totalPages))
    if newP~=self._page then self._page=newP; self:_rebindPage() end
    _updatePageText(self,totalPages,total)
end

function StatEditorSheet:_rebindPage()
    local per=self._perPage or (#self._rows); local page=math.max(1,self._page or 1)
    local start=(page-1)*per+1; local total=#(self._filtered or {})
    for i=1,per do local row=self._rows[i]; local entry=(start+(i-1) <= total) and self._filtered[start+(i-1)] or nil; if row then _bindRow(self,row,entry) end end
end

function StatEditorSheet:Refresh()
    local ds=self:GetEditingDataset()
    self._entries=_collectStatsSorted(ds or {})
    -- filter
    local query=(self._query or ""):lower()
    if query~="" then
        local f={}; for _,e in ipairs(self._entries) do
            local s=(e.name or ""):lower()..(e.id or ""):lower()..(e.category or ""):lower()..(e.sourceDataset or ""):lower()
            if s:find(query,1,true) then f[#f+1]=e end
        end; self._filtered=f
    else self._filtered=self._entries end
    local total=#self._filtered; local per=self._perPage or (#self._rows); local totalPages=math.max(1,math.ceil(total/math.max(1,per)))
    if (self._page or 1)>totalPages then self._page=totalPages end; if (self._page or 0)<1 then self._page=1 end
    self:_rebindPage(); _updatePageText(self,totalPages,total)
    if self.resultsText and self.resultsText.SetText then self.resultsText:SetText(("%d total"):format(total)) end
end

function StatEditorSheet.New(opts) local self=setmetatable({},StatEditorSheet); self:SetEditingDataset(opts and opts.editingName); self:BuildUI(opts or {}); return self end

return StatEditorSheet
