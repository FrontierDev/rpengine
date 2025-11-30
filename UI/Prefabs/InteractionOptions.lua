-- RPE_UI/Prefabs/InteractionOptions.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local VGroup      = RPE_UI.Elements.VerticalLayoutGroup
local HGroup      = RPE_UI.Elements.HorizontalLayoutGroup
local Text        = RPE_UI.Elements.Text
local Button      = RPE_UI.Elements.TextButton
local Input       = RPE_UI.Elements.Input
local Dropdown    = RPE_UI.Elements.Dropdown
local EditorTable = RPE_UI.Elements.EditorTable

---@class InteractionOptions
local InteractionOptions = {}
InteractionOptions.__index = InteractionOptions
RPE_UI.Prefabs.InteractionOptions = InteractionOptions

local ACTION_TYPES = {
    "DIALOGUE", "SHOP", "TRAIN", "AUCTION", "SKIN", "SALVAGE", "RAISE"
}

-- Helpers
local function shallow_copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end

local function ensure_option(opt)
    opt.label = opt.label or ""
    opt.action = opt.action or ACTION_TYPES[1]
    opt.args = opt.args or {}
    return opt
end

local function relayout_window(self)
    if self.root and self.root.Relayout then self.root:Relayout() end
    local DW = _G.RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.DatasetWindow
    local target = self._ownerSheet or self.root
    if DW and DW._recalcSizeForContent then
        DW:_recalcSizeForContent(target)
        if DW._resizeSoon then DW:_resizeSoon(target) end
    end
end

local function wipe_children(group)
    if not (group and group.children) then return end
    for i = #group.children, 1, -1 do
        local ch = group.children[i]
        if ch and ch.frame and ch.frame.SetParent then ch.frame:SetParent(nil) end
        if ch and ch.Hide then ch:Hide() end
        group.children[i] = nil
    end
    if group.RequestAutoSize then group:RequestAutoSize() end
end

local function parse_csv_to_list(s)
    if type(s) ~= "string" then return s end
    local out = {}
    for token in s:gmatch("[^,]+") do
        local trimmed = token:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then table.insert(out, trimmed) end
    end
    return out
end

local function args_to_rows(tbl)
    local rows = {}
    for k, v in pairs(tbl or {}) do
        local str = (type(v) == "table") and table.concat(v, ", ") or tostring(v)
        rows[#rows+1] = { key = tostring(k), value = str }
    end
    return rows
end

local function rows_to_args(rows)
    local out = {}
    for _, kv in ipairs(rows or {}) do
        local k = kv.key and kv.key:match("^%s*(.-)%s*$")
        local v = kv.value and kv.value:match("^%s*(.-)%s*$")
        if k and k ~= "" then
            out[k] = (v and v:find(",")) and parse_csv_to_list(v) or v
        end
    end
    return out
end

-- Rebuild single option UI
local function rebuild_page(self)
    wipe_children(self.body)

    local i = self._page or 1
    local opt = self._options[i]
    if not opt then return end

    self.pageText:SetText(("Option %d / %d"):format(i, #self._options))

    local row = VGroup:New(("RPE_InteractionOpt_Row_%d"):format(i), {
        parent = self.body, spacingY = 6, alignH = "LEFT", alignV = "TOP", autoSize = true,
    })
    self.body:Add(row)

    local top = HGroup:New(("RPE_InteractionOpt_Top_%d"):format(i), {
        parent = row, spacingX = 8, alignH = "LEFT", alignV = "CENTER", autoSize = true,
    })
    row:Add(top)

    local labelLbl = Text:New(("RPE_InteractionOpt_LabelTxt_%d"):format(i), {
        parent = top, text = "Label:", fontTemplate = "GameFontHighlightSmall",
    })
    top:Add(labelLbl)

    local labelInput = Input:New(("RPE_InteractionOpt_Label_%d"):format(i), {
        parent = top, width = 160, height = 20, text = opt.label or "",
        onChanged = function(_, txt) opt.label = txt or "" end,
    })
    top:Add(labelInput)

    local actionLbl = Text:New(("RPE_InteractionOpt_ActionTxt_%d"):format(i), {
        parent = top, text = "Action:", fontTemplate = "GameFontHighlightSmall",
    })
    top:Add(actionLbl)

    local actionDrop = Dropdown:New(("RPE_InteractionOpt_Action_%d"):format(i), {
        parent = top, width = 140, height = 22, value = opt.action or ACTION_TYPES[1],
        choices = ACTION_TYPES,
        onChanged = function(_, val)
            opt.action = val or ACTION_TYPES[1]
            relayout_window(self)
        end,
    })
    top:Add(actionDrop)

    local delBtn = Button:New(("RPE_InteractionOpt_Del_%d"):format(i), {
        parent = top, width = 26, height = 22, text = "×",
        onClick = function()
            table.remove(self._options, i)
            if #self._options == 0 then table.insert(self._options, ensure_option({})) end
            self._page = math.max(1, math.min(self._page, #self._options))
            rebuild_page(self)
            relayout_window(self)
        end,
    })
    top:Add(delBtn)

    local argsLabel = Text:New(("RPE_InteractionOpt_ArgsLbl_%d"):format(i), {
        parent = row, text = "Arguments:", fontTemplate = "GameFontHighlightSmall",
    })
    row:Add(argsLabel)

    local et = EditorTable.New(("RPE_InteractionOpt_Args_%d"):format(i), {
        parent = row,
        data = args_to_rows(opt.args),
        columns = {
            { id = "key", header = "Key", type = "input", width = 140 },
            { id = "value", header = "Value", type = "input", width = 180 },
        },
        minRows = 0,
    })
    row:Add(et.root or et)

    self._activeEditorTable = et  -- store reference for GetValue()

    if et.SetOnChange then
        et:SetOnChange(function(tbl)
            local newArgs = rows_to_args(tbl)
            opt.args = newArgs
            self._options[self._page].args = newArgs
            DevTools_Dump(newArgs)
        end)
    end

    relayout_window(self)
end

-- Public API
function InteractionOptions:New(name, opts)
    opts = opts or {}
    local root = VGroup:New(name or "InteractionOptions", {
        parent = opts.parent, spacingY = 10, alignH = "LEFT", alignV = "TOP", autoSize = true,
    })

    local self = setmetatable({
        frame = root.frame,
        root = root,
        body = nil,
        _ownerSheet = opts.ownerSheet,
        _options = {},
        _page = 1,
        _activeEditorTable = nil,
    }, InteractionOptions)

    local header = HGroup:New((name or "InteractionOptions") .. "_Header", {
        parent = root, spacingX = 10, alignH = "LEFT", alignV = "CENTER", autoSize = true,
    })
    root:Add(header)

    local title = Text:New(header.frame:GetName() .. "_Title", {
        parent = header, text = " ", fontTemplate = "GameFontNormal",
    })
    header:Add(title)

    local prev = Button:New(header.frame:GetName() .. "_Prev", {
        parent = header, width = 70, height = 22, text = "Prev", noBorder = true,
        onClick = function()
            self._page = math.max(1, self._page - 1)
            rebuild_page(self)
        end,
    })
    header:Add(prev)

    self.pageText = Text:New(header.frame:GetName() .. "_PageText", {
        parent = header, text = "Option 1 / 1", fontTemplate = "GameFontNormalSmall",
    })
    header:Add(self.pageText)

    local next = Button:New(header.frame:GetName() .. "_Next", {
        parent = header, width = 70, height = 22, text = "Next", noBorder = true,
        onClick = function()
            self._page = math.min(#self._options, self._page + 1)
            rebuild_page(self)
        end,
    })
    header:Add(next)

    local addBtn = Button:New(header.frame:GetName() .. "_Add", {
        parent = header, width = 120, height = 22, text = "+ Add Option",
        onClick = function()
            table.insert(self._options, ensure_option({}))
            self._page = #self._options
            rebuild_page(self)
        end,
    })
    header:Add(addBtn)

    self.body = VGroup:New((name or "InteractionOptions") .. "_Body", {
        parent = root, spacingY = 12, alignH = "LEFT", alignV = "TOP", autoSize = true,
    })
    root:Add(self.body)

    self:SetValue(opts.value or opts.default or {
        { label = "Talk", action = "DIALOGUE", args = {} }
    })

    return self
end

function InteractionOptions:SetValue(list)
    self._options = {}
    if type(list) == "table" then
        for _, opt in ipairs(list) do
            local copy = ensure_option(shallow_copy(opt))
            local fixedArgs = {}
            for k, v in pairs(copy.args or {}) do
                if type(v) == "string" and v:find(",") then
                    fixedArgs[k] = parse_csv_to_list(v)
                else
                    fixedArgs[k] = v
                end
            end
            copy.args = fixedArgs
            table.insert(self._options, copy)
        end
    end
    if #self._options == 0 then table.insert(self._options, ensure_option({})) end
    self._page = math.max(1, math.min(self._page or 1, #self._options))
    rebuild_page(self)
end

function InteractionOptions:GetValue()
    local curOpt = self._options[self._page]
    if curOpt and self._activeEditorTable and self._activeEditorTable.GetData then
        local rows = self._activeEditorTable:GetData()

        local args = rows_to_args(rows)
        curOpt.args = args
    end

    local out = {}
    for idx, opt in ipairs(self._options) do
        table.insert(out, {
            label = opt.label,
            action = opt.action,
            args = opt.args or {},
        })
    end

    return out
end

return InteractionOptions
