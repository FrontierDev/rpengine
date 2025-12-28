-- RPE_UI/Sheets/SpellEditorSheet.lua
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
local SpellbookSlot = RPE_UI.Prefabs and RPE_UI.Prefabs.SpellbookSlot

local SpellEditorSheet = {}
_G.RPE_UI.Windows.SpellEditorSheet = SpellEditorSheet
SpellEditorSheet.__index = SpellEditorSheet
SpellEditorSheet.Name = "SpellEditorSheet"

-- Dataset binding ------------------------------------------------------------
function SpellEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then self.editingName = name else self.editingName = nil end
end

function SpellEditorSheet:GetEditingDataset()
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

function SpellEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- Get spell from registry if available, or reconstruct from editing dataset if not
function SpellEditorSheet:GetOrReconstructSpell(spellId)
    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    local spell = reg and reg.Get and reg:Get(spellId)
    
    -- If spell is in the active registry, return it
    if spell then return spell end
    
    -- Fallback: reconstruct from the editing dataset
    local ds = self:GetEditingDataset()
    if not (ds and ds.spells and ds.spells[spellId]) then return nil end
    
    local spellDef = ds.spells[spellId]
    local SpellCore = _G.RPE and _G.RPE.Core and _G.RPE.Core.Spell
    if not SpellCore or not SpellCore.FromTable then return nil end
    
    -- Reconstruct spell object from the dataset definition
    return SpellCore.FromTable(spellDef)
end

-- Helpers --------------------------------------------------------------------
-- Accepts either the 3-column EditorTable rows or already-formed list.
local function _normalizeCosts(costs)
    if type(costs) ~= "table" then return nil end
    local out = {}
    for _, row in ipairs(costs) do
        if type(row) == "table" then
            local resource = row.resource or row[1]
            local amount   = row.amount   or row[2]
            local perRank  = row.perRank  or row[3]
            local when     = row.when     or row[4]
            if type(resource) == "string" and resource ~= "" then
                table.insert(out, {
                    resource = resource,
                    amount   = amount,   -- formula string
                    perRank  = tostring(perRank or ""),  -- formula string
                    when     = (when == "onStart" or when == "onResolve" or when == "perTick") and when or nil,
                })
            end
        end
    end
    return (#out > 0) and out or nil
end


-- Action bar helpers (match InventorySlot/SpellbookSlot style) ---------------
local function _getNumActionBarSlots()
    local slots = _G.RPE and _G.RPE.ActiveRules and _G.RPE.ActiveRules.Get
        and _G.RPE.ActiveRules:Get("action_bar_slots") or 5
    return tonumber(slots) or 12
end

local function _getAvailableResources()
    -- Get all RESOURCE category stats from the active profile
    local profile = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB and _G.RPE.Profile.DB.GetOrCreateActive and _G.RPE.Profile.DB:GetOrCreateActive()
    local resources = {}
    
    -- Always include these base resources
    local alwaysInclude = {
        HEALTH = true,
        ACTION = true,
        BONUS_ACTION = true,
        REACTION = true,
    }
    
    -- Add always-included resources first
    for _, resId in ipairs({"HEALTH", "ACTION", "BONUS_ACTION", "REACTION"}) do
        table.insert(resources, resId)
    end
    
    -- Add all other RESOURCE category stats from the active profile
    if profile and profile.stats then
        for _, stat in pairs(profile.stats) do
            if stat and stat.category == "RESOURCE" then
                local sid = stat.id and tostring(stat.id) or nil
                if sid and not sid:match("^MAX_") and not alwaysInclude[sid] then
                    table.insert(resources, sid)
                end
            end
        end
    end
    
    -- Sort the non-always-included ones
    if #resources > 4 then
        local alwaysFirst = {}
        local rest = {}
        for i, resId in ipairs(resources) do
            if i <= 4 then
                table.insert(alwaysFirst, resId)
            else
                table.insert(rest, resId)
            end
        end
        table.sort(rest)
        resources = {}
        for _, resId in ipairs(alwaysFirst) do
            table.insert(resources, resId)
        end
        for _, resId in ipairs(rest) do
            table.insert(resources, resId)
        end
    end
    
    return resources
end

local function _ensureActionBar()
    local coreWindows = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows
    local existing    = coreWindows and coreWindows.ActionBarWidget
    if existing and existing.root then
        return existing
    end
    if RPE_UI and RPE_UI.Windows and RPE_UI.Windows.ActionBarWidget
       and RPE_UI.Windows.ActionBarWidget.New then
        local bar = RPE_UI.Windows.ActionBarWidget.New({
            numSlots = _getNumActionBarSlots(),
            slotSize = 32,
            spacing  = 4,
            point    = "BOTTOM", rel = "BOTTOM", y = 60,
        })
        if bar and bar.Hide then bar:Hide() end
        return bar
    end
    return nil
end

local function _spellDisplay(spellId, fallbackName, fallbackIcon)
    local reg   = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    local def   = reg and reg.Get and reg:Get(spellId) or nil
    local name  = (def and (def.name or def.displayName)) or fallbackName or tostring(spellId)
    local icon  = (def and def.icon) or fallbackIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    return name, icon, def
end

local function _collectSpellsSorted(ds)
    local spells = (ds and ds.spells) or {}
    local list = {}
    for id, t in pairs(spells) do
        t = t or {}
        list[#list+1] = {
            id     = id,
            icon   = t.icon or t.iconId or nil, -- nil => empty slot
            name   = t.name or id,
            school = t.school or "Physical",
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

-- === Spell schema & save ====================================================

local Common = _G.RPE and _G.RPE.Common
local SpellCore = _G.RPE and _G.RPE.Core and _G.RPE.Core.Spell

local function _newSpellId()
    if Common and Common.GenerateGUID then
        return Common:GenerateGUID("spell")
    end
    return "spell-" .. tostring(math.random(0x1000, 0xFFFF)) .. tostring(math.random(0x1000, 0xFFFF))
end

-- Build a multi-page wizard schema for new/edit spell
local _TARGETER_CHOICES = { "PRECAST", "CASTER", "ALLY_SINGLE_OR_SELF" }
local _CAST_TYPES       = { "INSTANT", "CAST_TURNS", "CHANNEL" }
local _CD_STARTS        = { "onStart", "onResolve" }
local _SCHOOLS          = { "Physical","Fire","Frost","Arcane","Shadow","Nature","Holy" }
local _SUMMON_TYPES     = { "None", "Pet", "Totem" }
local function _trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end

local function _buildSpellSchema(entryId, spellData, isEdit)
    spellData = spellData or {}

    -- Pull out simple fields; keep groups/costs for dedicated editors
    local defaults = {
        name        = spellData.name or "",
        icon        = tonumber(spellData.icon) or 134400,
        description = spellData.description or "",
        npcOnly     = spellData.npcOnly or false,
        alwaysKnown = spellData.alwaysKnown or false,
        canCrit     = spellData.canCrit ~= false,

        castType     = (spellData.cast and spellData.cast.type) or "INSTANT",
        castTurns    = tonumber(spellData.cast and spellData.cast.turns) or 1,
        tickInterval = tonumber(spellData.cast and spellData.cast.tickIntervalTurns) or 1,
        concentration= (spellData.cast and spellData.cast.concentration) and true or false,
        moveAllowed  = (spellData.cast and spellData.cast.moveAllowed) and true or false,

        cdTurns      = tonumber(spellData.cooldown and spellData.cooldown.turns) or 0,
        cdStarts     = (spellData.cooldown and spellData.cooldown.starts) or "onResolve",
        cdSharedGroup= _trim(spellData.cooldown and spellData.cooldown.sharedGroup),
        cdCharges    = tonumber(spellData.cooldown and spellData.cooldown.charges) or 0,
        cdRecharge   = tonumber(spellData.cooldown and spellData.cooldown.rechargeTurns) or 0,

        targeterDefault = (spellData.targeter and spellData.targeter.default) or "PRECAST",

        costs  = spellData.costs or {},
        requirements = spellData.requirements or {},
        groups = spellData.groups or {
            { phase = "onResolve", logic="ALL", requirements = {}, actions = {} }
        },
    }

    return {
        title = isEdit and ("Edit Spell: " .. tostring(entryId)) or "New Spell",
        pages = {
            {
                title    = "Basics",
                elements = {
                    { id="name",        label="Name",        type="input",  default = defaults.name,  required = true },
                    { id="icon",        label="Icon",        type="icon",   default = defaults.icon,  required = true },
                    { id="description", label="Description", type="input",  default = defaults.description },
                    { id="npcOnly", label="NPCOnly", type="checkbox",  default = defaults.npcOnly or false },
                    { id="alwaysKnown", label="Always Known", type="checkbox",  default = defaults.alwaysKnown or false },
                    { id="canCrit", label="Can Crit", type="checkbox",  default = defaults.canCrit or true },
                    { id="ranksHeader",     label="Spell Ranks",     type="label" },
                    { id="maxRanks",     label="Max Ranks",     type="number", default = tonumber(spellData.maxRanks) or 1, min=1, max=20, step=1 },
                    { id="unlockLevel",  label="Unlock Level",  type="number", default = tonumber(spellData.unlockLevel) or 1, min=1, max=100, step=1 },
                    { id="rankInterval", label="Rank Interval", type="number", default = tonumber(spellData.rankInterval) or 1, min=1, max=20, step=1 },
                    { id="reqHeader",    label="Requirements",   type="label" },
                    {
                        id   = "requirements",
                        label= "Spell Requirements",
                        type = "input",
                        placeholder = "e.g., equip.mainhand, inventory.12345, equip.sword OR equip.dagger",
                        multiline = true,
                        default = (function()
                            if type(defaults.requirements) == "table" and #defaults.requirements > 0 then
                                return table.concat(defaults.requirements, ", ")
                            end
                            return ""
                        end)(),
                    }
                }
            },
            {
                title    = "Casting",
                elements = {
                    { id="castType",     label="Cast Type",     type="select",  choices=_CAST_TYPES,     default = defaults.castType },
                    { id="castTurns",    label="Turns",         type="number",  default = defaults.castTurns, min=1, max=20, step=1 },
                    { id="tickInterval", label="Tick Interval", type="number",  default = defaults.tickInterval, min=1, max=20, step=1 },
                    { id="concentration",label="Concentration", type="checkbox",default = defaults.concentration },
                }
            },
            {
                title    = "Cooldown & Targeting",
                elements = {
                    { id="cdTurns",       label="Cooldown (turns)", type="number", default = defaults.cdTurns, min=0, max=30, step=1 },
                    { id="cdStarts",      label="Cooldown Starts",   type="select", choices=_CD_STARTS, default = defaults.cdStarts },
                    { id="cdSharedGroup", label="Shared Group",      type="input",  default = defaults.cdSharedGroup },
                    { id="cdCharges",     label="Charges",           type="number", default = defaults.cdCharges, min=0, max=10, step=1 },
                    { id="cdRecharge",    label="Recharge (turns)",  type="number", default = defaults.cdRecharge, min=0, max=60, step=1 },
                    { id="targeterDefault",label="Default Targeter", type="select", choices=_TARGETER_CHOICES, default = defaults.targeterDefault },
                }
            },
            {
                -- Costs as a 3-column table (Resource / Amount / When)
                title    = "Costs",
                elements = {
                    {
                        id   = "costs",
                        label= "Resource Costs",
                        type = "editor_table",
                        mode = "rows",
                        columns = {
                            { id="resource", header="Resource", type="select", choices=_getAvailableResources() },
                            { id="amount",   header="Amount",   type="input",  placeholder="e.g. 10 or 1d6", width = 100 },
                            { id="perRank",  header="Per Rank", type="input",  placeholder="e.g. 2 or 1d4", width = 100 },
                            { id="when",     header="When",     type="select", choices={"onStart","onResolve"} },
                        },
                        default = defaults.costs,
                    }
                }
            },
            {
                -- Dedicated prefab editor, returns a groups array
                title    = "Groups & Actions",
                elements = {
                    { id="groups", label="Groups", type="spell_groups", default = defaults.groups },
                }
            },
            {
                -- Tags editor
                title    = "Tags",
                elements = {
                    {
                        id   = "tags",
                        label= "Spell Tags",
                        type = "editor_table",
                        columns = {
                            { id="tag", header="Tag", type="string", width=180 },
                        },
                        default = (function()
                            local t = {}
                            if spellData.tags then
                                -- support both array-like and keyed tables
                                if #spellData.tags > 0 then
                                    for _, v in ipairs(spellData.tags) do
                                        table.insert(t, { tag = tostring(v) })
                                    end
                                else
                                    for k, v in pairs(spellData.tags) do
                                        if v then table.insert(t, { tag = tostring(k) }) end
                                    end
                                end
                            end
                            return t
                        end)(),
                    },
                },
            },
        },
        labelWidth    = 150,
        labelAlign    = "LEFT",
        buttonAlign   = "CENTER",
        navSaveAlways = true,
    }
end

-- Turn wizard values into a proper Spell table and save into the dataset
local function _newSpellId()
    if Common and Common.GenerateGUID then return Common:GenerateGUID("spell") end
    return "spell-" .. tostring(math.random(0x1000, 0xFFFF)) .. tostring(math.random(0x1000, 0xFFFF))
end

local function _saveSpellValues(ds, targetId, v, isEdit, oldId)
    if not ds or type(v) ~= "table" then return nil, "no dataset/values" end
    ds.spells = ds.spells or {}

    local name = _trim(v.name)
    local icon = tonumber(v.icon) or 134400
    if name == "" then return nil, "Name is required." end
    if not icon or icon <= 0 then return nil, "Icon is required." end

    -- id policy
    local id = targetId
    if not id or id == "" then
        id = _newSpellId()
        while ds.spells[id] do id = _newSpellId() end
    else
        if isEdit and oldId and oldId ~= id then id = oldId end
    end

    -- Costs (validate 3-column rows)
    local costs = _normalizeCosts(v.costs)

    -- Cast
    local cast = { type = v.castType or "INSTANT" }
    if cast.type == "CAST_TURNS" or cast.type == "CHANNEL" then
        cast.turns = tonumber(v.castTurns) or 1
    end
    if cast.type == "CHANNEL" then cast.tickIntervalTurns = tonumber(v.tickInterval) or 1 end
    cast.concentration = not not v.concentration
    cast.moveAllowed   = not not v.moveAllowed

    -- Cooldown
    local cd = {}
    local cdTurns = tonumber(v.cdTurns) or 0
    if cdTurns > 0 then cd.turns = cdTurns end
    local starts = _trim(v.cdStarts); if starts ~= "" then cd.starts = starts end
    local sg = _trim(v.cdSharedGroup); if sg ~= "" then cd.sharedGroup = sg end
    local charges = tonumber(v.cdCharges) or 0; if charges > 0 then cd.charges = charges end
    local rech = tonumber(v.cdRecharge) or 0; if rech > 0 then cd.rechargeTurns = rech end
    if not next(cd) then cd = nil end

    -- Targeter
    local targeter = { default = v.targeterDefault or "PRECAST" }

    -- Groups (from prefab)
    local groups = (type(v.groups) == "table" and v.groups) or nil

    -- Requirements (from comma-separated input)
    local requirements = nil
    if type(v.requirements) == "string" and v.requirements ~= "" then
        requirements = {}
        for req in v.requirements:gmatch("[^,]+") do
            local trimmed = _trim(req)
            if trimmed ~= "" then
                table.insert(requirements, trimmed)
            end
        end
        if #requirements == 0 then requirements = nil end
    end

    -- Tags (from editor table)
    local tags = nil
    if type(v.tags) == "table" then
        tags = {}
        for _, row in ipairs(v.tags) do
            if type(row) == "table" and row.tag and row.tag ~= "" then
                table.insert(tags, row.tag)
            end
        end
        if #tags == 0 then tags = nil end
    end

    -- Normalize via Spell core when available
    local def
    local SpellCore = _G.RPE and _G.RPE.Core and _G.RPE.Core.Spell
    local def
    if SpellCore and SpellCore.New and SpellCore.Serialize then
        local obj = SpellCore:New(id, name, {
            icon = icon, description = v.description or "",
            costs = costs, cast = cast, cooldown = cd,
            targeter = targeter, groups = groups, requirements = requirements,
            npcOnly  = v.npcOnly or false,
            alwaysKnown = v.alwaysKnown or false,
            canCrit = v.canCrit ~= false,
            rank        = tonumber(v.rank) or 1,
            maxRanks    = tonumber(v.maxRanks) or 1,
            unlockLevel = tonumber(v.unlockLevel) or 1,
            rankInterval= tonumber(v.rankInterval) or 1,
            tags        = tags,
        })
        def = obj:Serialize()
    else
        def = {
            id = id, name = name, icon = icon, description = v.description or "",
            costs = costs, cast = cast, cooldown = cd, targeter = targeter, groups = groups, requirements = requirements,
            npcOnly     = v.npcOnly or false,
            alwaysKnown = v.alwaysKnown or false,
            canCrit     = v.canCrit ~= false,
            rank        = tonumber(v.rank) or 1,
            maxRanks    = tonumber(v.maxRanks) or 1,
            unlockLevel = tonumber(v.unlockLevel) or 1,
            rankInterval= tonumber(v.rankInterval) or 1,
            tags        = tags,
        }
    end

    ds.spells[id] = def
    return id
end

-- UI -------------------------------------------------------------------------
function SpellEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.rows     = opts.rows or 6
    self.cols     = opts.cols or 8
    self.parent   = opts.parent
    self.slots    = {}
    self._page    = 1
    self._perPage = self.rows * self.cols

    self:SetEditingDataset(opts and opts.editingName)

    self.sheet = VGroup:New("RPE_SpellEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV   = "TOP",
        alignH   = "CENTER",   -- match Item editor horizontal alignment
        autoSize = true,
    })

    self.grid = VGroup:New("RPE_SpellEditor_Grid", {
        parent   = self.sheet,
        width    = 1, height = 1,
        spacingY = 8,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.grid)

    -- Build matrix identical spacing/sizing
    local idx = 1
    for r = 1, self.rows do
        local row = HGroup:New(("RPE_SpellEditor_Row_%d"):format(r), {
            parent  = self.grid, width = 1, height = 40,
            spacingX = 8, alignV = "CENTER", alignH = "LEFT",
            autoSize = true,
        })
        self.grid:Add(row)

        for _ = 1, self.cols do
            local slot = SpellbookSlot:New(("RPE_SpellEditor_Slot_%d"):format(idx), {
                width = 40, height = 40, noBorder = true,
            })
            self.slots[idx] = slot
            row:Add(slot)

            -- Click handlers: Left = open wizard, Right = context menu
            if slot.frame and slot.frame.HookScript then
                slot.frame:HookScript("OnMouseDown", function(_, button)
                    local entry = slot._entry  -- nil => empty (new)

                    if button == "RightButton" then
                        local Menu = RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu
                        if not Menu then return end

                        RPE_UI.Common:ContextMenu(slot.frame or UIParent, function(level, menuList)
                            if level == 1 then
                                -- Title
                                local info = UIDropDownMenu_CreateInfo()
                                info.isTitle = true; info.notCheckable = true
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
                                    copyFrom.menuList = "COPY_FROM_DATASET"
                                end
                                UIDropDownMenu_AddButton(copyFrom, level)

                                -- Bind to...
                                UIDropDownMenu_AddButton({
                                    text = "Bind to...",
                                    hasArrow = true,
                                    notCheckable = true,
                                    disabled = not entry,
                                    menuList = "BIND_SLOT_LIST",
                                }, level)

                                -- Preview Tooltip submenu (Rank 1–4)
                                if entry then
                                    UIDropDownMenu_AddButton({
                                        text = "Preview Tooltip",
                                        hasArrow = true,
                                        notCheckable = true,
                                        menuList = "PREVIEW_RANK",
                                    }, level)
                                end

                                -- Copy Spell ID
                                local copyId = UIDropDownMenu_CreateInfo()
                                copyId.notCheckable = true
                                copyId.text = "Copy Spell ID"
                                if not entry then
                                    copyId.disabled = true
                                else
                                    copyId.func = function()
                                        local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
                                        if Clipboard then
                                            Clipboard:SetContent(entry.id)
                                            Clipboard:Show()
                                            RPE.Debug:Internal("Spell ID copied to clipboard: " .. entry.id)
                                        else
                                            RPE.Debug:Internal("Clipboard widget not available")
                                        end
                                    end
                                end
                                UIDropDownMenu_AddButton(copyId, level)

                                -- Export Spell (compact, wrapped with key)
                                local exportSpell = UIDropDownMenu_CreateInfo()
                                exportSpell.notCheckable = true
                                exportSpell.text = "Export Spell"
                                if not entry then
                                    exportSpell.disabled = true
                                else
                                    exportSpell.func = function()
                                        local ds = self:GetEditingDataset()
                                        if ds and ds.spells and entry.id and ds.spells[entry.id] then
                                            local Export = _G.RPE and _G.RPE.Data and _G.RPE.Data.Export
                                            if Export and Export.ToClipboard then
                                                Export.ToClipboard(ds.spells[entry.id], { format = "compact", key = entry.id })
                                                if RPE and RPE.Debug and RPE.Debug.Internal then
                                                    RPE.Debug:Internal("Spell exported to clipboard (compact, wrapped): " .. entry.id)
                                                end
                                            else
                                                print("Export utility not available.")
                                            end
                                        end
                                    end
                                end
                                UIDropDownMenu_AddButton(exportSpell, level)

                                -- Delete (moved to bottom)
                                local del = UIDropDownMenu_CreateInfo()
                                del.notCheckable = true
                                del.text = "|cffff4040Delete Entry|r"
                                if not entry then
                                    del.disabled = true
                                else
                                    del.func = function()
                                        local ds = self:GetEditingDataset()
                                        if not (ds and ds.spells and ds.spells[entry.id]) then return end
                                        ds.spells[entry.id] = nil

                                        local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
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

                            elseif level == 2 and menuList == "COPY_FROM_DATASET" then
                                -- Submenu level 2: "Copy from..." dataset selection
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
                                    info.menuList = "COPY_FROM_SPELLS"
                                    UIDropDownMenu_AddButton(info, level)
                                end
                                return

                            elseif level == 3 and menuList == "COPY_FROM_SPELLS" then
                                -- Submenu level 3: select spell from chosen dataset (grouped alphabetically)
                                local datasetName = UIDROPDOWNMENU_MENU_VALUE
                                if not datasetName then return end
                                
                                local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                if not DatasetDB then return end
                                
                                local sourceDs = DatasetDB.GetByName and DatasetDB.GetByName(datasetName)
                                if not sourceDs or not sourceDs.spells then
                                    local info = UIDropDownMenu_CreateInfo()
                                    info.isTitle = true
                                    info.notCheckable = true
                                    info.text = "No spells in dataset"
                                    UIDropDownMenu_AddButton(info, level)
                                    return
                                end
                                
                                -- Collect and sort spells from source dataset
                                local spells = {}
                                for spellId, spellDef in pairs(sourceDs.spells) do
                                    table.insert(spells, { id = spellId, def = spellDef })
                                end
                                table.sort(spells, function(a, b)
                                    local anName = (a.def and a.def.name) or a.id
                                    local bnName = (b.def and b.def.name) or b.id
                                    return tostring(anName):lower() < tostring(bnName):lower()
                                end)
                                
                                -- Group spells into chunks of 20 for submenu display
                                local spellsPerGroup = 20
                                local groups = {}
                                for i = 1, #spells, spellsPerGroup do
                                    local groupSpells = {}
                                    for j = i, math.min(i + spellsPerGroup - 1, #spells) do
                                        table.insert(groupSpells, spells[j])
                                    end
                                    table.insert(groups, groupSpells)
                                end
                                
                                -- Create submenu buttons for each group with letter ranges
                                for groupIdx, groupSpells in ipairs(groups) do
                                    if #groupSpells > 0 then
                                        -- Get first and last spell names for the range label
                                        local firstName = (groupSpells[1].def and groupSpells[1].def.name) or groupSpells[1].id
                                        local lastName = (groupSpells[#groupSpells].def and groupSpells[#groupSpells].def.name) or groupSpells[#groupSpells].id
                                        firstName = tostring(firstName):sub(1, 1):upper()
                                        lastName = tostring(lastName):sub(1, 2):upper()
                                        local rangeLabel = (firstName == lastName) and firstName or (firstName .. "-" .. lastName)
                                        
                                        local info = UIDropDownMenu_CreateInfo()
                                        info.notCheckable = true
                                        info.text = rangeLabel
                                        info.hasArrow = true
                                        -- Encode dataset name and group index in the value
                                        info.value = datasetName .. "|" .. tostring(groupIdx)
                                        info.menuList = "COPY_FROM_SPELL_GROUP"
                                        UIDropDownMenu_AddButton(info, level)
                                    end
                                end
                                return

                            elseif level == 4 and menuList == "COPY_FROM_SPELL_GROUP" then
                                -- Submenu level 4: show spells in selected group
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
                                if not sourceDs or not sourceDs.spells then
                                    return
                                end
                                
                                -- Collect and sort spells from source dataset (same as level 3)
                                local spells = {}
                                for spellId, spellDef in pairs(sourceDs.spells) do
                                    table.insert(spells, { id = spellId, def = spellDef })
                                end
                                table.sort(spells, function(a, b)
                                    local anName = (a.def and a.def.name) or a.id
                                    local bnName = (b.def and b.def.name) or b.id
                                    return tostring(anName):lower() < tostring(bnName):lower()
                                end)
                                
                                -- Reconstruct the groups to find the selected one
                                local spellsPerGroup = 20
                                local selectedGroupSpells = {}
                                local currentGroupIdx = 0
                                for i = 1, #spells, spellsPerGroup do
                                    currentGroupIdx = currentGroupIdx + 1
                                    if currentGroupIdx == groupIdx then
                                        for j = i, math.min(i + spellsPerGroup - 1, #spells) do
                                            table.insert(selectedGroupSpells, spells[j])
                                        end
                                        break
                                    end
                                end
                                
                                if #selectedGroupSpells == 0 then
                                    return
                                end
                                
                                for _, spell in ipairs(selectedGroupSpells) do
                                    local info = UIDropDownMenu_CreateInfo()
                                    info.notCheckable = true
                                    info.text = (spell.def and spell.def.name) or spell.id
                                    info.func = function()
                                        -- Copy the spell
                                        local targetDs = self:GetEditingDataset()
                                        if not targetDs then return end
                                        
                                        targetDs.spells = targetDs.spells or {}
                                        
                                        -- Generate new ID for the copy
                                        local newId = _newSpellId()
                                        while targetDs.spells[newId] do
                                            newId = _newSpellId()
                                        end
                                        
                                        -- Deep copy the spell definition
                                        local spellCopy = {}
                                        if type(spell.def) == "table" then
                                            for k, v in pairs(spell.def) do
                                                if type(v) == "table" then
                                                    -- Shallow copy for nested tables
                                                    local tblCopy = {}
                                                    for tk, tv in pairs(v) do
                                                        tblCopy[tk] = tv
                                                    end
                                                    spellCopy[k] = tblCopy
                                                else
                                                    spellCopy[k] = v
                                                end
                                            end
                                        end
                                        spellCopy.id = newId
                                        
                                        targetDs.spells[newId] = spellCopy
                                        
                                        -- Persist the dataset
                                        local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                                        if DB and DB.Save then pcall(DB.Save, targetDs) end
                                        
                                        -- Rebuild runtime registry
                                        local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
                                        if reg and reg.RefreshFromActiveDatasets then
                                            reg:RefreshFromActiveDatasets()
                                        elseif reg and reg.Init then
                                            reg:Init()
                                        end
                                        
                                        -- Refresh grid + resize
                                        self:Refresh()
                                        local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                                        if DW and DW._recalcSizeForContent then
                                            DW:_recalcSizeForContent(self.sheet)
                                            if DW._resizeSoon then DW:_resizeSoon(self.sheet) end
                                        end
                                        
                                        if RPE and RPE.Debug and RPE.Debug.Internal then
                                            RPE.Debug:Internal(string.format("Copied spell '%s' from dataset '%s' (new ID: %s)", 
                                                (spell.def and spell.def.name) or spell.id, datasetName, newId))
                                        end
                                    end
                                    UIDropDownMenu_AddButton(info, level)
                                end
                                return

                            elseif level == 2 and menuList == "BIND_SLOT_LIST" then
                                -- existing bind logic...
                                if not entry then
                                    UIDropDownMenu_AddButton({ text = "No spell selected", isTitle = true, notCheckable = true }, level)
                                else
                                    for i = 1, _getNumActionBarSlots() do
                                        UIDropDownMenu_AddButton({
                                            text = ("Slot %d"):format(i),
                                            notCheckable = true,
                                            func = function()
                                                -- Check if event is running
                                                local Event = RPE.Core and RPE.Core.Event
                                                if Event and Event.IsRunning and Event:IsRunning() then
                                                    if RPE and RPE.Debug and RPE.Debug.Warning then
                                                        RPE.Debug:Warning("Cannot bind spells during an event.")
                                                    end
                                                    return
                                                end
                                                
                                                -- Check if current player is the dataset author
                                                local ds = self:GetEditingDataset()
                                                local currentPlayer = UnitName("player")
                                                local dsAuthor = ds and ds.author
                                                if dsAuthor and currentPlayer ~= dsAuthor then
                                                    if RPE and RPE.Debug and RPE.Debug.Warning then
                                                        RPE.Debug:Warning("Only the dataset author (" .. tostring(dsAuthor) .. ") can bind spells to the action bar.")
                                                    end
                                                    return
                                                end
                                                
                                                local bar = _ensureActionBar(); if not bar then return end
                                                local name, icon = _spellDisplay(entry.id, entry.name, entry.icon)
                                                local action = { spellId = entry.id, icon = icon, name = name, isEnabled = true }
                                                if bar.SetAction then bar:SetAction(i, action) end
                                                if bar.FlashSlot then bar:FlashSlot(i, 0.35) end
                                            end,
                                        }, level)
                                    end
                                end

                            elseif level == 2 and menuList == "PREVIEW_RANK" then
                                -- Try to get spell from registry first, fallback to dataset
                                local spell = entry and self:GetOrReconstructSpell(entry.id)
                                
                                -- Get maxRanks from dataset definition using unlockLevel and rankInterval
                                local ds = self:GetEditingDataset()
                                local spellDef = (ds and ds.spells and entry and ds.spells[entry.id]) or {}
                                local unlockLevel = tonumber(spellDef.unlockLevel) or 1
                                local rankInterval = tonumber(spellDef.rankInterval) or 1
                                
                                -- If rankInterval is 0, spell doesn't rank up (only 1 rank)
                                local maxR = 1
                                if rankInterval > 0 then
                                    local maxPlayerLevels = tonumber(RPE.ActiveRules:Get("max_player_level") or 20)
                                    maxR = math.floor((maxPlayerLevels - unlockLevel) / rankInterval) + 1
                                end

                                for r = 1, maxR do
                                    UIDropDownMenu_AddButton({
                                        text = ("Rank %d"):format(r),
                                        notCheckable = true,
                                        func = function()
                                            if not spell then return end

                                            -- Pass rank directly to GetTooltip instead of modifying the spell object
                                            if spell and RPE.Common and RPE.Common.ShowTooltip then
                                                RPE.Common:ShowTooltip(slot.frame, spell:GetTooltip(r))
                                            end
                                        end,
                                    }, level)
                                end
                            end
                        end)
                        return
                    end

                    if button ~= "LeftButton" then return end

                    -- Open wizard
                    local ds       = self:GetEditingDataset()
                    local spellId  = entry and entry.id or "(new)"
                    local spellDef = (entry and ds and ds.spells and ds.spells[entry.id]) or nil
                    local isEdit   = entry and true or false
                    local schema   = _buildSpellSchema(spellId, spellDef, isEdit)

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

                            local newId, err = _saveSpellValues(ds2, entry and entry.id or nil, values, isEdit, entry and entry.id or nil)
                            if not newId then
                                return
                            end

                            -- Persist dataset
                            local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                            if DB and DB.Save then pcall(DB.Save, ds2) end

                            -- Rebuild runtime registry from active datasets
                            local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
                            if reg and reg.RefreshFromActiveDatasets then
                                reg:RefreshFromActiveDatasets()
                            elseif reg and reg.Init then
                                reg:Init()
                            end

                            -- Refresh grid and resize
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

    -- Centered pager
    local navWrap = VGroup:New("RPE_SpellEditor_NavWrap", {
        parent   = self.sheet,
        width    = 1, height = 1,
        alignH   = "CENTER",
        alignV   = "CENTER",
        autoSize = true,
    })

    local nav = HGroup:New("RPE_SpellEditor_Nav", {
        parent   = navWrap,
        width    = 1, height = 1,
        spacingX = 10,
        alignV   = "CENTER",
        autoSize = true,
    })

    local prevBtn = TextBtn:New("RPE_SpellEditor_Prev", {
        parent = nav, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) - 1) end,
    })
    nav:Add(prevBtn)

    self.pageText = Text:New("RPE_SpellEditor_PageText", {
        parent = nav, text = "Page 1 / 1",
        fontTemplate = "GameFontNormalSmall",
    })
    nav:Add(self.pageText)

    local nextBtn = TextBtn:New("RPE_SpellEditor_Next", {
        parent = nav, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function() self:_setPage((self._page or 1) + 1) end,
    })
    nav:Add(nextBtn)

    navWrap:Add(nav)
    self.sheet:Add(navWrap)

    self:Refresh()
    return self.sheet
end

function SpellEditorSheet:_setPage(p)
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

function SpellEditorSheet:_rebindPage()
    local per  = self._perPage or (#self.slots)
    local page = math.max(1, self._page or 1)
    local startIndex = (page - 1) * per + 1

    for i = 1, per do
        local slot  = self.slots[i]
        local entry = self._list and self._list[startIndex + (i - 1)] or nil
        if slot then
            slot._entry = entry
            if slot.SetSpell then slot:SetSpell(entry) end -- nil => empty slot
        end
    end

    if self.sheet and self.sheet.Relayout then pcall(function() self.sheet:Relayout() end) end
end

function SpellEditorSheet:Refresh()
    local ds = self:GetEditingDataset()
    self._list = _collectSpellsSorted(ds)

    local totalPages = math.max(1, math.ceil((#self._list) / (self._perPage or 1)))
    if (self._page or 1) > totalPages then self._page = totalPages end
    if (self._page or 0) < 1 then self._page = 1 end

    for _, slot in ipairs(self.slots) do if slot.ClearSpell then slot:ClearSpell() end end
    self:_rebindPage()
    _updatePageText(self, totalPages)

    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW and type(DW._resizeSoon) == "function" then DW:_resizeSoon(self.sheet) end
end

function SpellEditorSheet.New(opts)
    local self = setmetatable({}, SpellEditorSheet)
    self:BuildUI(opts or {})
    return self
end

return SpellEditorSheet
