-- RPE_UI/Windows/EditorWizardSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local VGroup      = RPE_UI.Elements.VerticalLayoutGroup
local HGroup      = RPE_UI.Elements.HorizontalLayoutGroup
local Text        = RPE_UI.Elements.Text
local Input       = RPE_UI.Elements.Input
local Checkbox    = RPE_UI.Elements.Checkbox
local Dropdown    = RPE_UI.Elements.Dropdown
local Slider      = RPE_UI.Elements.Slider
local TextBtn     = RPE_UI.Elements.TextButton
local IconBtn     = RPE_UI.Elements.IconButton
local EditorTable = RPE_UI.Elements.EditorTable


-- Custom prefab support
local ModelEditPrefab = RPE_UI.Prefabs and RPE_UI.Prefabs.ModelEditPrefab
local NPCSpellbookPrefab = RPE_UI.Prefabs and RPE_UI.Prefabs.NPCSpellbookPrefab

---@class EditorWizardSheet
local EditorWizardSheet = {}
_G.RPE_UI.Windows.EditorWizardSheet = EditorWizardSheet
EditorWizardSheet.__index = EditorWizardSheet
EditorWizardSheet.Name = "EditorWizardSheet"

-- ===========================================================================
-- utils
local _uid = 0
local function _name(prefix)
    _uid = _uid + 1
    return string.format("%s_%04d", prefix or "RPE_EW", _uid)
end

local function _toboolean(v) 
    -- Numeric 0, false, nil -> false; everything else -> true
    return (v == 1 or v == true or v == "1") and true or false
end
local function _tonumberOrNil(v) local n = tonumber(v); return n end
local function _text(s) return (s and tostring(s)) or "" end

local function _label(parent, text)
    local t = Text:New(_name("RPE_EW_Label"), {
        parent       = parent,
        text         = text or "",
        fontTemplate = "GameFontNormal",
        justifyH     = "RIGHT",
        width        = 1, height = 18,
    })
    if RPE_UI.Colors and RPE_UI.Colors.ApplyText then
        RPE_UI.Colors.ApplyText(t.fs, "text")
    end
    return t
end

-- ===========================================================================
-- icon picker row
local function _iconRow(parent, default)
    local row = HGroup:New(_name("RPE_EW_RowIcon"), {
        parent  = parent, spacingX = 8, alignV = "CENTER", alignH = "LEFT", autoSize = true,
    })
    parent:Add(row)

    local value = tonumber(default) or 134400

    local preview = IconBtn:New(_name("RPE_EW_IconPreview"), {
        parent = row, width = 16, height = 16,
    })
    preview:SetIcon(value)
    row:Add(preview)

    local idText = Text:New(_name("RPE_EW_IconId"), {
        parent = row, text = "ID: " .. tostring(value), fontTemplate = "GameFontHighlightSmall",
    })
    row:Add(idText)

    local btn = TextBtn:New(_name("RPE_EW_IconBtn"), {
        parent = row, width = 92, height = 22, text = "Choose...",
        onClick = function()
            local openFinder = RPE and RPE.Core and RPE.Core.OpenIconFinder
            if openFinder then
                openFinder(function(fileId, _path)
                    value = tonumber(fileId) or value
                    idText:SetText("ID: " .. tostring(value))
                    preview:SetIcon(value)
                end, { filter = "" })
            end
        end,
        noBorder = true,
    })
    row:Add(btn)

    return row, function() return value end
end

-- ===========================================================================
-- field factory
local function _buildFieldRow(sheet, body, e, labelWidth)
    local id       = e.id or ("_unnamed_" .. tostring(math.random(1, 1e6)))
    local etype    = (e.type or "input"):lower()
    local required = _toboolean(e.required)

    local row = HGroup:New(_name("RPE_EW_Row"), {
        parent = body, spacingX = 12, alignV = "CENTER", alignH = "LEFT", autoSize = true,
    })
    body:Add(row)

    local title = e.label or id
    if required then title = title .. " *" end
    local lbl = _label(row, title)
    if labelWidth and lbl and lbl.frame and lbl.frame.SetWidth then
        lbl.frame:SetWidth(labelWidth)
    end

    local control, getter

    if etype == "input" then
        local input = Input:New(_name("RPE_EW_Input_" .. id), {
            parent = row, width = 240, height = 20, text = _text(e.default)
        })
        row:Add(input)
        control = input
        getter  = function() return input:GetText() end

    elseif etype == "number" then
        local input = Input:New(_name("RPE_EW_Number_" .. id), {
            parent = row, width = 120, height = 20, text = _text(e.default)
        })
        row:Add(input)
        control = input
        getter  = function() return _tonumberOrNil(input:GetText()) end

    elseif etype == "checkbox" then
        local defaultChecked = _toboolean(e.default)
        if RPE and RPE.Debug then
            RPE.Debug:Internal(string.format("EditorWizardSheet checkbox %s: e.default=%s (type=%s), _toboolean result=%s", 
                id, tostring(e.default), type(e.default), tostring(defaultChecked)))
        end
        local cb = Checkbox:New(_name("RPE_EW_Check_" .. id), {
            parent = row, checked = defaultChecked
        })
        row:Add(cb)
        control = cb
        getter  = function() return cb:IsChecked() end

    elseif etype == "select" then
        local dd = Dropdown:New(_name("RPE_EW_Drop_" .. id), {
            parent  = row,
            width   = 180, height = 22,
            value   = (e.default ~= nil) and e.default or ((e.choices and e.choices[1]) or ""),
            choices = e.choices or {},
        })
        row:Add(dd)
        control = dd
        getter  = function() return dd:GetValue() end

    elseif etype == "interaction_options" then
        local IO = RPE_UI.Prefabs and RPE_UI.Prefabs.InteractionOptions
        if not IO then
            local t = Text:New(_name("RPE_EW_IO_Missing"), {
                parent = row,
                text   = "(InteractionOptions prefab missing)",
                fontTemplate = "GameFontDisable"
            })
            row:Add(t)
            control = t
            getter  = function() return {} end
        else
            if lbl and lbl.Hide then lbl:Hide() end
            local wrapper = VGroup:New(_name("RPE_EW_IO_Wrap_" .. id), {
                parent  = row,
                spacingY = 6,
                alignV   = "TOP",
                alignH   = "LEFT",
                autoSize = true,
            })
            row:Add(wrapper)

            local io = IO:New(_name("RPE_EW_InteractionOptions_" .. id), {
                parent      = wrapper,
                value       = type(e.default) == "table" and e.default or {},
                ownerSheet  = sheet,
            })
            wrapper:Add(io.root or io)

            control = io
            getter  = function() return io:GetValue() end
        end
        
    elseif etype == "slider" then
        local minv  = tonumber(e.min)   or 0
        local maxv  = tonumber(e.max)   or 100
        local step  = tonumber(e.step)  or 1
        local value = tonumber(e.default) or minv
        local sl = Slider:New(_name("RPE_EW_Slider_" .. id), {
            parent = row,
            width  = 240, height = 22,
            min    = minv, max = maxv, step = step,
            value  = value,
            showValue = true,
        })
        row:Add(sl)
        control = sl
        getter  = function() return sl:GetValue() end

    elseif etype == "icon" then
        local _, get = _iconRow(row, e.default)
        control = true
        getter  = get

    elseif etype == "editor_table" or etype == "table" or etype == "kv" then
        if not EditorTable then
            local t = Text:New(_name("RPE_EW_ET_Missing"), {
                parent = row, text = "(EditorTable prefab missing)", fontTemplate = "GameFontDisable"
            })
            row:Add(t)
            control = t
            getter  = function() return {} end
        else
            -- editor tables are full-width; hide form-label cell
            if lbl and lbl.Hide then lbl:Hide() end
            local wrapper = VGroup:New(_name("RPE_EW_ET_Wrap_" .. id), {
                parent  = row,
                spacingY = 4,
                alignV   = "TOP",
                alignH   = "LEFT",
                autoSize = true,
            })
            row:Add(wrapper)

            local et = EditorTable.New(_name("RPE_EW_ET_" .. id), {
                parent  = wrapper,
                data    = type(e.default) == "table" and e.default or {},
                columns = e.columns,
                headers = e.headers,
                compact = e.compact,
                minRows = e.minRows,
            })
            wrapper:Add(et.root or et)

            control = et
            getter  = function() return et:GetData() end
        end

    elseif etype == "spellbook" then
        local Prefab = RPE_UI.Prefabs and RPE_UI.Prefabs.NPCSpellbookPrefab
        assert(Prefab, "NPCSpellbookPrefab not loaded")
        local inst = Prefab:New("RPE_EW_" .. id, {
            parent   = row,
            value    = (type(e.default) == "table") and e.default or {},
            rows     = tonumber(e.rows) or 4,
            slotSize = tonumber(e.slotSize) or nil,
        })
        row:Add(inst.root)

        getter = function()
            local v = (inst.GetValue and inst:GetValue()) or {}
            if type(v) ~= "table" then
                if RPE and RPE.Debug and RPE.Debug.Warning then
                    RPE.Debug:Warning("EditorWizardSheet: spellbook getter returned invalid value")
                end
                return {}
            end
            if RPE and RPE.Debug and RPE.Debug.Print then
                local joined = (#v > 0) and table.concat(v, ", ") or "(none)"
                RPE.Debug:Internal(("EditorWizardSheet: spellbook getter -> %s"):format(joined))
            end
            return v
        end
        
    elseif etype == "spell_groups" then
        local SG = RPE_UI.Prefabs and RPE_UI.Prefabs.SpellGroups
        if not SG then
            local t = Text:New(_name("RPE_EW_SG_Missing"), {
                parent = row, text = "(SpellGroups prefab missing)", fontTemplate = "GameFontDisable"
            })
            row:Add(t)
            control = t
            getter  = function() return {} end
        else
            if lbl and lbl.Hide then lbl:Hide() end
            local wrapper = VGroup:New(_name("RPE_EW_SG_Wrap_" .. id), {
                parent  = row,
                spacingY = 6,
                alignV   = "TOP",
                alignH   = "LEFT",
                autoSize = true,
            })
            row:Add(wrapper)

            local ActionSchemas = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellActionSchemas or nil

            local sg = SG:New(_name("RPE_EW_SpellGroups_" .. id), {
                parent        = wrapper,
                value         = type(e.default) == "table" and e.default or {},
                ownerSheet    = sheet,
                actionSchemas = ActionSchemas,
            })
            wrapper:Add(sg.root or sg)

            control = sg
            getter  = function() return sg:GetValue() end
        end

    elseif etype == "custom" and e.prefab then
        if lbl and lbl.Hide then lbl:Hide() end
        local wrapper = VGroup:New(_name("RPE_EW_CustomWrap_" .. id), {
            parent  = row,
            spacingY = 4,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        row:Add(wrapper)

        local prefab = e.prefab
        local inst = prefab:New(_name("RPE_EW_Custom_" .. id), {
            parent  = wrapper,
            value   = e.default,
        })
        wrapper:Add(inst.root or inst)

        control = inst
        getter  = function()
            if inst.GetValue then return inst:GetValue() end
            return nil
        end

    elseif etype == "label" then
        -- A static text row that uses the "label" string as content.
        if lbl and lbl.Hide then lbl:Hide() end
        local txt = Text:New(_name("RPE_EW_StaticLabel_" .. id), {
            parent       = row,
            text         = e.text or e.label or "",
            fontTemplate = e.fontTemplate or "GameFontNormal",
            justifyH     = e.justifyH or "LEFT",
        })
        if RPE_UI.Colors and RPE_UI.Colors.ApplyText then
            RPE_UI.Colors.ApplyText(txt.fs, "textMuted")
        end
        row:Add(txt)
        control = txt
        getter  = function() return nil end

    elseif etype == "button" then
        -- A button that calls a function with the current form values
        if lbl and lbl.Hide then lbl:Hide() end
        local btn = TextBtn:New(_name("RPE_EW_Button_" .. id), {
            parent = row,
            width = 180, height = 22,
            text = e.text or e.label or "Button",
            noBorder = true,
            onClick = function()
                -- Call the onClick handler (will need sheet context from parent)
                if e.onClick and type(e.onClick) == "function" then
                    e.onClick({})
                end
            end,
        })
        row:Add(btn)
        control = btn
        getter  = function() return nil end

    elseif etype == "lookup" then
        -- Custom lookup field: input + paste icon button + lookup icon button
        local input = Input:New(_name("RPE_EW_Lookup_Input_" .. id), {
            parent = row, width = 200, height = 20, text = _text(e.default)
        })
        row:Add(input)

        -- Paste button (small icon button with paste icon)
        local pasteBtn = IconBtn:New(_name("RPE_EW_Lookup_Paste_" .. id), {
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
                
                local pattern = e.pattern or "^item%-[a-fA-F0-9]+$"
                local value = Clipboard:GetClipboardText(pattern)
                if value then
                    input:SetText(value)
                else
                    if RPE and RPE.Debug then
                        RPE.Debug:Warning("Clipboard is empty or content does not match pattern")
                    end
                end
            end,
        })
        row:Add(pasteBtn)

        -- Lookup button (small icon button with lookup icon, does nothing for now)
        local lookupBtn = IconBtn:New(_name("RPE_EW_Lookup_Search_" .. id), {
            parent = row, width = 16, height = 16,
            icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\lookup.png",
            noBackground = true, hasBackground = false,
            noBorder = true, hasBorder = false,
            tooltip = "Lookup",
            onClick = function()
                -- TODO: implement lookup functionality
            end,
        })
        row:Add(lookupBtn)

        control = input
        getter  = function() return input:GetText() end

    else
        local t = Text:New(_name("RPE_EW_Unsupported"), {
            parent = row, text = "(unsupported)", fontTemplate = "GameFontDisable"
        })
        row:Add(t)
        control = t
        getter  = function() return nil end
    end

    return { id = id, control = control, get = getter, required = required }
end

-- ===========================================================================
-- page factory
local function _buildPage(sheet, pageSchema, labelWidth)
    local group = VGroup:New(_name("RPE_EW_Page"), {
        parent  = sheet,
        padding = { left = 12, right = 12, top = 6, bottom = 6 },
        spacingY = 8,
        alignV  = "TOP",
        alignH  = pageSchema.alignH or "LEFT",
        autoSize = true,
    })

    local title = Text:New(_name("RPE_EW_PageTitle"), {
        parent       = group,
        text         = pageSchema.title or "",
        fontTemplate = "GameFontNormal",
        justifyH     = "CENTER",
    })
    if RPE_UI.Colors and RPE_UI.Colors.ApplyText then
        RPE_UI.Colors.ApplyText(title.fs, "textMuted")
    end
    group:Add(title)

    local body = VGroup:New(_name("RPE_EW_PageBody"), {
        parent = group, spacingY = 6, alignV = "TOP", alignH = "LEFT", autoSize = true,
    })
    group:Add(body)

    local fields = {}
    for _, e in ipairs(pageSchema.elements or {}) do
        local f = _buildFieldRow(sheet, body, e, labelWidth)
        table.insert(fields, f)
    end

    return group, fields
end

local function _collectValues(fieldsPerPage)
    local out = {}
    for _, fields in ipairs(fieldsPerPage) do
        for _, field in ipairs(fields) do
            local val = field.get and field.get() or nil
            out[field.id] = val

            -- Debug print
            if RPE and RPE.Debug and RPE.Debug.Print then
                local shown
                if type(val) == "table" then
                    local parts = {}
                    local max = 0
                    for k,v in pairs(val) do
                        max = max + 1
                        if type(v) == "table" then
                            parts[#parts+1] = ("[%s]...table"):format(tostring(k))
                        else
                            parts[#parts+1] = ("[%s]=%s"):format(tostring(k), tostring(v))
                        end
                        if max > 5 then
                            parts[#parts+1] = "..."
                            break
                        end
                    end
                    shown = "{" .. table.concat(parts, ", ") .. "}"
                else
                    shown = tostring(val)
                end
                RPE.Debug:Internal(("EditorWizardSheet:_collectValues %s = %s"):format(field.id, shown))
            end
        end
    end
    return out
end


-- ===========================================================================
-- API
function EditorWizardSheet:Relayout()
    if not self.sheet then return end
    if self.sheet.RequestAutoSize then self.sheet:RequestAutoSize() end
    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW and DW._recalcSizeForContent then
        DW:_recalcSizeForContent(self.sheet)
        if DW._resizeSoon then DW:_resizeSoon(self.sheet) end
    end
end

function EditorWizardSheet:Show() if self.sheet and self.sheet.Show then self.sheet:Show() end end
function EditorWizardSheet:Hide()
    if self.sheet and self.sheet.Hide then self.sheet:Hide() end
    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
    if DW and DW._resizeSoon then DW:_resizeSoon(self.sheet) end
end
function EditorWizardSheet:IsShown() return self.sheet and self.sheet.frame and self.sheet.frame:IsShown() end

function EditorWizardSheet:_setPage(i)
    self.cur = math.max(1, math.min(i, #self.pageGroups))
    for idx, grp in ipairs(self.pageGroups) do
        if grp and grp.Hide then grp:Hide() end
        if idx == self.cur and grp and grp.Show then grp:Show() end
    end
    if self.pageIndicator then
        self.pageIndicator:SetText(("Page %d / %d"):format(self.cur, math.max(1, #self.pageGroups)))
    end
    self:Relayout()
end

-- ===========================================================================
-- ctor
function EditorWizardSheet.New(args)
    local self = setmetatable({}, EditorWizardSheet)

    local parent = args.parent
    local schema = args.schema or { pages = {} }
    self.onSave   = args.onSave
    self.onCancel = args.onCancel
    self.cur      = 1
    self.controls = {}

    self.sheet = VGroup:New(_name("RPE_EW_Sheet"), {
        parent  = parent,
        padding = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV  = "TOP",
        alignH  = "LEFT",
        autoSize = true,
    })

    -- Top nav
    local nav = HGroup:New(_name("RPE_EW_Nav"), {
        parent = self.sheet, spacingX = 18, alignV = "CENTER", alignH = "CENTER", autoSize = true
    })
    self.sheet:Add(nav)

    self.pageGroups      = {}
    self._fieldsPerPage  = {}

    -- Pages
    for i, page in ipairs(schema.pages or {}) do
        local grp, fields = _buildPage(self.sheet, page, args.labelWidth or 120)
        self.sheet:Add(grp)
        table.insert(self.pageGroups, grp)
        table.insert(self._fieldsPerPage, fields)
        if i ~= 1 then grp:Hide() end
    end

    -- Nav buttons
    local cancelBtn = TextBtn:New(_name("RPE_EW_BtnCancel"), {
        parent = nav, width = 100, height = 24, text = "Cancel", noBorder = true,
        onClick = function()
            if self.onCancel then self.onCancel() end
            local DW = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.DatasetWindow
            if DW and DW.HideWizard then DW:HideWizard() end
        end,
    })
    nav:Add(cancelBtn)

    local prevBtn = TextBtn:New(_name("RPE_EW_BtnPrev"), {
        parent = nav, width = 80, height = 24, text = "Prev", noBorder = true,
        onClick = function()
            self:_setPage(self.cur - 1)
            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
            if DW and DW._resizeSoon then DW:_resizeSoon(self.sheet) end
        end,
    })
    nav:Add(prevBtn)

    self.pageIndicator = Text:New(_name("RPE_EW_PageInd"), {
        parent = nav, text = ("Page %d / %d"):format(1, math.max(1, #self.pageGroups)),
        fontTemplate = "GameFontNormalSmall",
    })
    nav:Add(self.pageIndicator)

    local nextBtn = TextBtn:New(_name("RPE_EW_BtnNext"), {
        parent = nav, width = 80, height = 24, text = "Next", noBorder = true,
        onClick = function()
            self:_setPage(self.cur + 1)
            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
            if DW and DW._resizeSoon then DW:_resizeSoon(self.sheet) end
        end,
    })
    nav:Add(nextBtn)

    local saveBtn = TextBtn:New(_name("RPE_EW_BtnSave"), {
        parent = nav, width = 100, height = 24, text = "Save", noBorder = true,
        onClick = function()
            local values = _collectValues(self._fieldsPerPage)
            RPE.Debug:Internal("EditorWizardSheet: Save clicked")

            if not args.navSaveAlways then
                for _, f in ipairs(self._fieldsPerPage[self.cur] or {}) do
                    if f.required and (values[f.id] == nil or values[f.id] == "") then
                        if RPE and RPE.Debug and RPE.Debug.Warning then
                            RPE.Debug:Warning("Missing required field: " .. tostring(f.id))
                        end
                        return
                    end
                end
            end

            for k,v in pairs(values) do
                RPE.Debug:Internal(("Collected field %s = %s"):format(k, tostring(v)))
            end

            if self.onSave then self.onSave(values) end
            local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
            if DW and DW._resizeSoon then DW:_resizeSoon(self.sheet) end
        end,
    })
    nav:Add(saveBtn)

    -- First layout
    self:_setPage(1)

    -- 💡 Immediately and next-frame reflow to avoid initial under-sizing
    self:Relayout()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if self.Relayout then self:Relayout() end
        end)
    end

    return self
end

return EditorWizardSheet
