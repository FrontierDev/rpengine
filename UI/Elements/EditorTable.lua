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
                    -- TODO: implement lookup functionality
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
            parent = self.header, width = 72, height = 22, text = "+ Add",
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
