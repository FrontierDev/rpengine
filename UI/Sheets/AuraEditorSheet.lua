-- RPE_UI/Sheets/AuraEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE.ActiveRules = RPE.ActiveRules

local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton

-- Prefab
local AuraSlot = RPE_UI.Prefabs and RPE_UI.Prefabs.AuraSlot

local AuraEditorSheet = {}
_G.RPE_UI.Windows.AuraEditorSheet = AuraEditorSheet
AuraEditorSheet.__index = AuraEditorSheet
AuraEditorSheet.Name = "AuraEditorSheet"

-- Dataset binding ------------------------------------------------------------
function AuraEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then self.editingName = name else self.editingName = nil end
end

function AuraEditorSheet:GetEditingDataset()
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

function AuraEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- Helpers --------------------------------------------------------------------
local function _collectAurasSorted(ds)
    local auras = (ds and ds.auras) or {}
    local list = {}
    for id, t in pairs(auras) do
        t = t or {}
        list[#list+1] = {
            id   = id,
            icon = t.icon or t.iconId or nil,
            name = t.name or id,
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

local function _updatePageText(self, totalPages)
    totalPages = math.max(1, totalPages or 1)
    local cur = math.max(1, math.min(self._page or 1, totalPages))
    if self.pageText and self.pageText.SetText then
        self.pageText:SetText(("Page %d / %d"):format(cur, totalPages))
    end
end

local function _parseCSV(s)
    local out = {}
    if type(s) ~= "string" then return out end
    for token in string.gmatch(s, "[^,]+") do
        local t = token:gsub("^%s+",""):gsub("%s+$","")
        if t ~= "" then table.insert(out, t) end
    end
    return out
end

local function _toCSV(tbl)
    if not tbl or type(tbl) ~= "table" then return "" end
    return table.concat(tbl, ", ")
end

-- === Aura schema & save =====================================================
local Common = _G.RPE and _G.RPE.Common

local function _newAuraId()
    if Common and Common.GenerateGUID then return Common:GenerateGUID("aura") end
    return "aura-" .. tostring(math.random(0x1000, 0xFFFF)) .. tostring(math.random(0x1000, 0xFFFF))
end

local _STACKING_CHOICES = { "ADD_MAGNITUDE", "REFRESH_DURATION", "EXTEND_DURATION", "REPLACE" }
local _CONFLICT_CHOICES = { "NONE", "KEEP_HIGHER", "KEEP_LATEST", "BLOCK_IF_PRESENT" }
local _EXPIRE_CHOICES   = { "ON_OWNER_TURN_START", "ON_OWNER_TURN_END" }

local function _buildAuraSchema(entryId, auraData, isEdit)
    auraData = auraData or {}
    local defaults = {
        name        = auraData.name or "",
        icon        = tonumber(auraData.icon) or 134400,
        description = auraData.description or "",

        isHelpful   = auraData.isHelpful or false,
        dispelType  = auraData.dispelType or "",
        tags        = _toCSV(auraData.tags),

        durationTurns  = (auraData.duration and auraData.duration.turns) or 0,
        durationExpire = (auraData.duration and auraData.duration.expires) or "ON_OWNER_TURN_END",

        tickPeriod  = (auraData.tick and auraData.tick.period) or 0,
        tickActions = (auraData.tick and auraData.tick.actions) or {},

        maxStacks   = auraData.maxStacks or 1,
        stacking    = auraData.stackingPolicy or "ADD_MAGNITUDE",
        uniqueGroup = auraData.uniqueGroup or "",
        conflict    = auraData.conflictPolicy or "NONE",

        modifiers   = auraData.modifiers or {},

        immunity = {
            dispelTypes = _toCSV(auraData.immunity and auraData.immunity.dispelTypes),
            tags        = _toCSV(auraData.immunity and auraData.immunity.tags),
            ids         = _toCSV(auraData.immunity and auraData.immunity.ids),
            helpful     = auraData.immunity and auraData.immunity.helpful or false,
            harmful     = auraData.immunity and auraData.immunity.harmful or false,
        },

        triggers = (function()
            local rows = {}
            for _, t in ipairs(auraData.triggers or {}) do
                local row = {
                    event  = t.event,
                    key    = t.action and t.action.key or nil,
                    ref    = t.action and t.action.targets
                            and t.action.targets.ref
                            and t.action.targets.ref:upper()
                            or "TARGET",
                }

                if t.action and t.action.args then
                    row.amount = t.action.args.amount
                    row.auraId = t.action.args.auraId
                end
                table.insert(rows, row)
            end
            return rows
        end)(),
    }

    return {
        title = isEdit and ("Edit Aura: " .. tostring(entryId)) or "New Aura",
        pages = {
            {
                title = "Basics",
                elements = {
                    { id="name",        label="Name",        type="input",  default = defaults.name,  required = true },
                    { id="icon",        label="Icon",        type="icon",   default = defaults.icon,  required = true },
                    { id="description", label="Description", type="input",  default = defaults.description },
                }
            },
            {
                title = "Type & Flags",
                elements = {
                    { id="isHelpful",   label="Helpful",      type="checkbox", default = defaults.isHelpful },
                    { id="dispelType",  label="Dispel Type",  type="input",    default = defaults.dispelType },
                    { id="tags",        label="Tags (CSV)",   type="input",    default = defaults.tags },
                    { id="hidden",      label="Hidden",       type="checkbox", default = auraData.hidden or false },
                    { id="unpurgable",  label="Unpurgable",   type="checkbox", default = auraData.unpurgable or false },
                    { id="uniqueByCaster", label="Unique Per Caster", type="checkbox", default = auraData.uniqueByCaster or false },
                }
            },
            {
                title = "Duration & Ticking",
                elements = {
                    { id="durationTurns",  label="Duration (turns)", type="number", default = defaults.durationTurns, min=0, max=100, step=1 },
                    { id="durationExpire", label="Expire At", type="select", choices=_EXPIRE_CHOICES, default = defaults.durationExpire },
                    { id="tickPeriod",     label="Tick Period", type="number", default = defaults.tickPeriod, min=0, max=20, step=1 },
                    { id="tickActions",    label="Tick Actions", type="spell_groups", default = defaults.tickActions },
                }
            },
            {
                title = "Stacks & Conflicts",
                elements = {
                    { id="maxStacks",    label="Max Stacks",     type="number", default = defaults.maxStacks, min=1, max=99, step=1 },
                    { id="stacking",     label="Stacking Policy", type="select", choices=_STACKING_CHOICES, default = defaults.stacking },
                    { id="uniqueGroup",  label="Unique Group",   type="input",  default = defaults.uniqueGroup },
                    { id="conflict",     label="Conflict Policy", type="select", choices=_CONFLICT_CHOICES, default = defaults.conflict },
                }
            },
            {
                title = "Stat Modifiers",
                elements = {
                    {
                        id = "modifiers",
                        label = "Modifiers",
                        type = "editor_table",
                        mode = "rows",
                        columns = {
                            { id="stat",     header="Stat",   type="input" },
                            { id="mode",     header="Mode",   type="select", choices={"ADD","PCT_ADD","MULT","FINAL_ADD"} },
                            { id="value",    header="Value",  type="number" },
                            { id="scaleWithStacks", header="Scale", type="checkbox" },
                            { id="source",   header="Source", type="select", choices={"CASTER","TARGET"} },
                            { id="snapshot", header="Snapshot", type="select", choices={"DYNAMIC","STATIC"} },
                        },
                        default = defaults.modifiers,
                    }
                }
            },
            {
                title = "Immunity",
                elements = {
                    { id="immunity.dispelTypes", label="Dispel Types (CSV)", type="input", default = defaults.immunity.dispelTypes },
                    { id="immunity.tags",        label="Tags (CSV)",         type="input", default = defaults.immunity.tags },
                    { id="immunity.ids",         label="IDs (CSV)",          type="input", default = defaults.immunity.ids },
                    { id="immunity.helpful",     label="Block Helpful", type="checkbox", default = defaults.immunity.helpful },
                    { id="immunity.harmful",     label="Block Harmful", type="checkbox", default = defaults.immunity.harmful },
                }
            },
            {
                title = "Triggers",
                elements = {
                    {
                        id = "triggers",
                        label = "Trigger Events",
                        type = "editor_table",
                        mode = "rows",
                        columns = {
                            { id = "event",   header = "Event",   type = "select", choices = { "ON_HIT", "ON_HIT_TAKEN", "ON_CRIT", "ON_CRIT_TAKEN", "ON_CAST_RESOLVE", "ON_KILL", "ON_DEATH" } },
                            { id = "key",     header = "Action",  type = "select", choices = { "DAMAGE", "HEAL", "APPLY_AURA", "GAIN_RESOURCE" } },
                            { id = "amount",  header = "Amount",  type = "input" },
                            { id = "auraId",  header = "Aura ID", type = "input" },
                            { id = "ref",     header = "Target",  type = "select", choices = { "TARGET", "SOURCE", "BOTH" } },
                        },
                        default = defaults.triggers,
                    }
                }
            }
        },
        labelWidth    = 150,
        labelAlign    = "LEFT",
        buttonAlign   = "CENTER",
        navSaveAlways = true,
    }
end


local function _saveAuraValues(ds, targetId, v, isEdit, oldId)
    if not ds or type(v) ~= "table" then return nil, "no dataset/values" end
    ds.auras = ds.auras or {}

    local name = tostring(v.name or ""):gsub("^%s+",""):gsub("%s+$","")
    local icon = tonumber(v.icon) or 134400
    if name == "" then return nil, "Name is required." end
    if not icon or icon <= 0 then return nil, "Icon is required." end

    local id = targetId
    if not id or id == "" then
        id = _newAuraId()
        while ds.auras[id] do id = _newAuraId() end
    else
        if isEdit and oldId and oldId ~= id then id = oldId end
    end

    local duration
    if tonumber(v.durationTurns) and tonumber(v.durationTurns) > 0 then
        duration = { turns = tonumber(v.durationTurns), expires = v.durationExpire }
    end

    local tick
    if tonumber(v.tickPeriod) and tonumber(v.tickPeriod) > 0 then
        tick = { period = tonumber(v.tickPeriod), actions = v.tickActions or {} }
    end

    local def = {
        id          = id,
        name        = name,
        icon        = icon,
        description = v.description or "",

        isHelpful   = not not v.isHelpful,
        dispelType  = v.dispelType ~= "" and v.dispelType or nil,
        tags        = _parseCSV(v.tags),

        hidden      = not not v.hidden,
        unpurgable  = not not v.unpurgable,
        uniqueByCaster = not not v.uniqueByCaster,

        duration    = duration,
        tick        = tick,

        maxStacks   = tonumber(v.maxStacks) or 1,
        stackingPolicy = v.stacking,
        uniqueGroup = (v.uniqueGroup ~= "" and v.uniqueGroup) or nil,
        conflictPolicy = v.conflict,

        modifiers   = v.modifiers or {},

        immunity    = {
            dispelTypes = _parseCSV(v["immunity.dispelTypes"]),
            tags        = _parseCSV(v["immunity.tags"]),
            ids         = _parseCSV(v["immunity.ids"]),
            helpful     = v["immunity.helpful"] or false,
            harmful     = v["immunity.harmful"] or false,
        },

        triggers    = (function()
            local out = {}
            for _, row in ipairs(v.triggers or {}) do
                if row.event and row.key then
                    local ref = (row.ref or "target"):lower()
                    local action = { key = row.key, args = {}, targets = { ref = ref } }

                    if row.key == "DAMAGE" or row.key == "HEAL" then
                        if row.amount then 
                            action.args.amount = row.amount 
                        end
                    elseif row.key == "APPLY_AURA" then
                        if row.auraId then 
                            action.args.auraId = row.auraId 
                        end
                    elseif row.key == "GAIN_RESOURCE" then
                        if row.auraId then 
                            action.args.resourceId = row.auraId 
                        end
                        if row.amount then 
                            action.args.amount = row.amount 
                        end
                    end

                    table.insert(out, { event = row.event, action = action })
                end
            end
            return out
        end)(),
    }

    ds.auras[id] = def
    return id
end

-- UI -------------------------------------------------------------------------
function AuraEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.rows     = opts.rows or 6
    self.cols     = opts.cols or 8
    self.parent   = opts.parent
    self.slots    = {}
    self._page    = 1
    self._perPage = self.rows * self.cols

    self:SetEditingDataset(opts and opts.editingName)

    self.sheet = VGroup:New("RPE_AuraEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV   = "TOP",
        alignH   = "CENTER",
        autoSize = true,
    })

    self.grid = VGroup:New("RPE_AuraEditor_Grid", {
        parent   = self.sheet,
        width    = 1, height = 1,
        spacingY = 8,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.grid)

    local idx = 1
    for r = 1, self.rows do
        local row = HGroup:New(("RPE_AuraEditor_Row_%d"):format(r), {
            parent  = self.grid, width = 1, height = 40,
            spacingX = 8, alignV = "CENTER", alignH = "LEFT",
            autoSize = true,
        })
        self.grid:Add(row)

        for _ = 1, self.cols do
            local slot = AuraSlot:New(("RPE_AuraEditor_Slot_%d"):format(idx), {
                width = 40, height = 40, noBorder = true,
            })
            self.slots[idx] = slot
            row:Add(slot)

            if slot.frame and slot.frame.HookScript then
                slot.frame:HookScript("OnMouseDown", function(_, button)
                    local entry = slot._entry

                    if button == "RightButton" then
                        local Menu = RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu
                        if not Menu then return end
                        RPE_UI.Common:ContextMenu(slot.frame or UIParent, function(level, menuList)
                            if level == 1 then
                                local info = UIDropDownMenu_CreateInfo()
                                info.isTitle = true; info.notCheckable = true
                                info.text = entry and (tostring(entry.name or entry.id)) or "Empty Slot"
                                UIDropDownMenu_AddButton(info, level)

                                -- Copy Aura ID
                                local copyId = UIDropDownMenu_CreateInfo()
                                copyId.notCheckable = true
                                copyId.text = "Copy Aura ID"
                                if not entry then
                                    copyId.disabled = true
                                else
                                    copyId.func = function()
                                        local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
                                        if Clipboard then
                                            Clipboard:SetContent(entry.id)
                                            Clipboard:Show()
                                            RPE.Debug:Internal("Aura ID copied to clipboard: " .. entry.id)
                                        else
                                            RPE.Debug:Internal("Clipboard widget not available")
                                        end
                                    end
                                end
                                UIDropDownMenu_AddButton(copyId, level)

                                local del = UIDropDownMenu_CreateInfo()
                                del.notCheckable = true
                                del.text = "|cffff4040Delete Entry|r"
                                if not entry then
                                    del.disabled = true
                                else
                                    del.func = function()
                                        local ds = self:GetEditingDataset()
                                        if not (ds and ds.auras and ds.auras[entry.id]) then return end
                                        ds.auras[entry.id] = nil

                                        local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
                                        if reg and reg.RefreshFromActiveDatasets then
                                            reg:RefreshFromActiveDatasets()
                                        elseif reg and reg.Init then
                                            reg:Init()
                                        end

                                        self:Refresh()
                                        local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                                        if DW and DW._recalcSizeForContent then
                                            DW:_recalcSizeForContent(self.sheet)
                                            if DW._resizeSoon then DW:_resizeSoon(self.sheet) end
                                        end
                                    end
                                end
                                UIDropDownMenu_AddButton(del, level)
                            end
                        end)
                        return
                    end

                    if button ~= "LeftButton" then return end

                    local ds       = self:GetEditingDataset()
                    local auraId   = entry and entry.id or "(new)"
                    local auraDef  = (entry and ds and ds.auras and ds.auras[entry.id]) or nil
                    local isEdit   = entry and true or false
                    local schema   = _buildAuraSchema(auraId, auraDef, isEdit)

                    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                    if not (DW and DW.ShowWizard) then
                        return
                    end

                    DW:ShowWizard({
                        schema  = schema,
                        isEdit  = isEdit,
                        onCancel = function() self:Refresh() end,
                        onSave = function(values)
                            local ds2 = self:GetEditingDataset()
                            if not ds2 then
                                return
                            end

                            local newId, err = _saveAuraValues(ds2, entry and entry.id or nil, values, isEdit, entry and entry.id or nil)
                            if not newId then
                                return
                            end

                            local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                            if DB and DB.Save then pcall(DB.Save, ds2) end

                            local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
                            if reg and reg.RefreshFromActiveDatasets then
                                reg:RefreshFromActiveDatasets()
                            elseif reg and reg.Init then
                                reg:Init()
                            end

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

            idx = idx + 1
        end
    end

    -- Pager
    local navWrap = VGroup:New("RPE_AuraEditor_NavWrap", {
        parent   = self.sheet,
        width    = 1, height = 1,
        alignH   = "CENTER",
        alignV   = "CENTER",
        autoSize = true,
    })

    local nav = HGroup:New("RPE_AuraEditor_Nav", {
        parent   = navWrap,
        width    = 1, height = 1,
        spacingX = 10,
        alignV   = "CENTER",
        autoSize = true,
    })

    local prevBtn = TextBtn:New("RPE_AuraEditor_Prev", {
        parent = nav, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) - 1) end,
    })
    nav:Add(prevBtn)

    self.pageText = Text:New("RPE_AuraEditor_PageText", {
        parent = nav, text = "Page 1 / 1",
        fontTemplate = "GameFontNormalSmall",
    })
    nav:Add(self.pageText)

    local nextBtn = TextBtn:New("RPE_AuraEditor_Next", {
        parent = nav, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) + 1) end,
    })
    nav:Add(nextBtn)

    navWrap:Add(nav)
    self.sheet:Add(navWrap)

    self:Refresh()
    return self.sheet
end

function AuraEditorSheet:_setPage(p)
    local total = self._list and #self._list or 0
    local totalPages = math.max(1, math.ceil(total / (self._perPage or 1)))
    local newP = math.max(1, math.min(tonumber(p) or 1, totalPages))
    if newP ~= self._page then
        self._page = newP
        self:_rebindPage()
    end
    _updatePageText(self, totalPages)

    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW and type(DW._resizeSoon) == "function" then
        DW:_resizeSoon(self.sheet)
    end
end

function AuraEditorSheet:_rebindPage()
    local per  = self._perPage or (#self.slots)
    local page = math.max(1, self._page or 1)
    local startIndex = (page - 1) * per + 1

    for i = 1, per do
        local slot  = self.slots[i]
        local entry = self._list and self._list[startIndex + (i - 1)] or nil
        if slot then
            slot._entry = entry
            if slot.SetAura then slot:SetAura(entry) end
        end
    end

    if self.sheet and self.sheet.Relayout then pcall(function() self.sheet:Relayout() end) end
end

function AuraEditorSheet:Refresh()
    local ds = self:GetEditingDataset()
    self._list = _collectAurasSorted(ds)

    local totalPages = math.max(1, math.ceil((#self._list) / (self._perPage or 1)))
    if (self._page or 1) > totalPages then self._page = totalPages end
    if (self._page or 0) < 1 then self._page = 1 end

    for _, slot in ipairs(self.slots) do if slot.ClearAura then slot:ClearAura() end end
    self:_rebindPage()
    _updatePageText(self, totalPages)

    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW and type(DW._resizeSoon) == "function" then DW:_resizeSoon(self.sheet) end
end

function AuraEditorSheet.New(opts)
    local self = setmetatable({}, AuraEditorSheet)
    self:BuildUI(opts or {})
    return self
end

return AuraEditorSheet
