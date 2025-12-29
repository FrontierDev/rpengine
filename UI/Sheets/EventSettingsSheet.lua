-- RPE_UI/Windows/EventSettingsSheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows  or {}

local VGroup       = RPE_UI.Elements.VerticalLayoutGroup
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local Text         = RPE_UI.Elements.Text
local Dropdown     = RPE_UI.Elements.Dropdown
local FrameElement = RPE_UI.Elements.FrameElement
local C            = RPE_UI.Colors

-- ===== EditField (FrameElement subclass) ===================================
---@class EditField: FrameElement
---@field edit EditBox
local EditField = setmetatable({}, { __index = FrameElement })
EditField.__index = EditField

local function _ApplyBoxLook(box)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontNormal")
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 6, 3, 3)
end

function EditField:New(name, opts)
    opts = opts or {}
    local parentFrame = (opts.parent and opts.parent.frame) or UIParent
    local f = CreateFrame("EditBox", name, parentFrame, "InputBoxTemplate")
    f:SetSize(opts.width or 220, opts.height or 22)
    f:SetAutoFocus(false)
    f:SetMultiLine(false)
    _ApplyBoxLook(f)
    if opts.text then f:SetText(opts.text) end

    local o = FrameElement.New(self, "EditField", f, opts.parent)
    o.edit = f
    f:SetScript("OnEnterPressed", function()
        f:ClearFocus()
        if opts.onCommit then opts.onCommit(o, f:GetText()) end
    end)
    f:SetScript("OnEditFocusLost", function()
        if opts.onCommit then opts.onCommit(o, f:GetText()) end
    end)
    return o
end
function EditField:GetText() return self.edit:GetText() end
function EditField:SetText(t) self.edit:SetText(t or "") end

-- ===== EventSettingsSheet ===================================================
---@class EventSettingsSheet
---@field sheet VGroup
---@field settings table
local EventSettingsSheet = {}
_G.RPE_UI.Windows.EventSettingsSheet = EventSettingsSheet
EventSettingsSheet.__index = EventSettingsSheet
EventSettingsSheet.Name = "EventSettingsSheet"

-- Fixed measurements to enforce alignment
local LABEL_WIDTH   = 140
local FIELD_WIDTH   = 260
local ROW_SPACING_X = 10

-- unique id helper (Text requires stable names)
local _uid = 0
local function _name(prefix) _uid=_uid+1; return string.format("%s_%04d", prefix or "RPE_ES", _uid) end

local function _label(parent, text, opts)
    opts = opts or {}
    local lbl = Text:New(_name("RPE_ES_Label"), {
        parent       = parent,
        text         = text or "",
        width        = LABEL_WIDTH,  -- request width
        justifyH     = opts.justifyH or "RIGHT",
        fontTemplate = opts.fontTemplate or "GameFontHighlight",
    })
    -- Enforce exact width (some Text implementations auto-size)
    if lbl.frame and lbl.frame.SetWidth then
        lbl.frame:SetWidth(LABEL_WIDTH)
    end
    -- Apply palette color
    C.ApplyText(lbl.fs, opts.variant or "text")
    return lbl
end

local function _heading(parent, text)
    local h = Text:New(_name("RPE_ES_Head"), {
        parent       = parent,
        text         = text or "",
        fontTemplate = "GameFontHighlightSmall",
        justifyH     = "LEFT",
    })
    C.ApplyText(h.fs, "textMuted")
    parent:Add(h)
    return h
end

local function AddEditRow(self, parent, labelText, key)
    local row = HGroup:New(_name("RPE_ES_Row"), {
        parent  = parent,
        spacingX= ROW_SPACING_X,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize= true,
    })
    local lbl = _label(row, labelText)                 -- normal color
    local field = EditField:New(_name("RPE_ES_Field"), {
        parent = row,
        width  = FIELD_WIDTH,
        text   = self.settings[key] or "",
        onCommit = function(_, val) self.settings[key] = val end,
    })
    -- keep widths strict
    if field.frame and field.frame.SetWidth then field.frame:SetWidth(FIELD_WIDTH) end

    row:Add(lbl)
    row:Add(field)
    parent:Add(row)
end

local function AddDropdownRow(self, parent, labelText, key, choices)
    local row = HGroup:New(_name("RPE_ES_Row"), {
        parent  = parent,
        spacingX= ROW_SPACING_X,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize= true,
    })
    local lbl = _label(row, labelText)                 -- normal color
    local dd = Dropdown:New(_name("RPE_ES_Dropdown"), {
        parent  = row,
        width   = FIELD_WIDTH,
        height  = 22,
        choices = choices,
        value   = self.settings[key] or choices[1],
        onChanged = function(_, v) self.settings[key] = v end,
    })
    if dd.SetSize then dd:SetSize(FIELD_WIDTH, 22) end

    row:Add(lbl)
    row:Add(dd)
    parent:Add(row)
end

function EventSettingsSheet:BuildUI(opts)
    opts = opts or {}
    self.settings = {
        title         = "",
        subtext       = "",
        difficulty    = "NORMAL",
        turnOrderType = "INITIATIVE",
        teamNames     = { "", "", "", "" },
        teamResourceIds = { "", "", "", "" },
    }

    self.sheet = VGroup:New("RPE_ES_Sheet", {
        parent     = opts.parent,
        width      = 1, height = 1,
        point      = "TOP", relativePoint = "TOP",
        padding    = { left = 0, right = 20, top = 20, bottom = 20 },
        spacingY   = 10,
        alignH     = "LEFT",
        autoSize   = true,
    })

    -- Header
    local header = Text:New(_name("RPE_ES_Header"), {
        parent       = self.sheet,
        text         = "Event Settings",
        fontTemplate = "GameFontHighlightLarge",
        justifyH     = "CENTER",
    })
    C.ApplyText(header.fs, "text")
    self.sheet:Add(header)

    -- Title + Subtext
    AddEditRow(self, self.sheet, "Event Title:", "title")
    AddEditRow(self, self.sheet, "Subtext:", "subtext")

    -- Difficulty (directly under Subtext)
    AddDropdownRow(self, self.sheet, "Difficulty:", "difficulty", { "NORMAL", "HEROIC", "MYTHIC" })

    -- Turn Order Type
    AddDropdownRow(self, self.sheet, "Turn Order:", "turnOrderType", { "INITIATIVE", "PHASE", "BALANCED", "NON-COMBAT" })

    -- Section heading (muted)
    _heading(self.sheet, "Team Names")

    -- Team rows (NORMAL color labels; fixed width enforced)
    for i = 1, 4 do
        local row = HGroup:New(_name("RPE_ES_TeamRow"), {
            parent   = self.sheet,
            spacingX = ROW_SPACING_X,
            alignV   = "CENTER",
            alignH   = "LEFT",
            autoSize = true,
        })
        
        -- Team label
        local lbl = _label(row, ("Team %d:"):format(i), { variant = "text" })
        row:Add(lbl)
        
        -- Name label + field
        local nameLbl = Text:New(_name("RPE_ES_NameLabel"), {
            parent       = row,
            text         = "Name:",
            fontTemplate = "GameFontNormal",
            justifyH     = "RIGHT",
        })
        C.ApplyText(nameLbl.fs, "text")
        row:Add(nameLbl)
        
        local nameField = EditField:New(_name("RPE_ES_TeamNameField"), {
            parent = row,
            width  = 120,
            text   = self.settings.teamNames[i],
            onCommit = function(_, val) self.settings.teamNames[i] = val end,
        })
        if nameField.frame and nameField.frame.SetWidth then nameField.frame:SetWidth(120) end
        row:Add(nameField)
        
        -- Resource ID label + field
        local resLbl = Text:New(_name("RPE_ES_ResLabel"), {
            parent       = row,
            text         = "Res:",
            fontTemplate = "GameFontNormal",
            justifyH     = "RIGHT",
        })
        C.ApplyText(resLbl.fs, "text")
        row:Add(resLbl)
        
        local resourceField = EditField:New(_name("RPE_ES_TeamResourceField"), {
            parent = row,
            width  = 120,
            text   = self.settings.teamResourceIds[i],
            onCommit = function(_, val) self.settings.teamResourceIds[i] = val end,
        })
        if resourceField.frame and resourceField.frame.SetWidth then resourceField.frame:SetWidth(120) end
        row:Add(resourceField)
        
        self.sheet:Add(row)
    end
end

function EventSettingsSheet.New(opts)
    local self = setmetatable({}, EventSettingsSheet)
    self:BuildUI(opts or {})
    return self
end

return EventSettingsSheet
