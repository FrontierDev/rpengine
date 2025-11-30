-- RPE_UI/Windows/ModelFinderWindow.lua
-- Model Finder — styled like IconFinderWindow:
--  • Window with header/content/footer + borders
--  • 4x4 grid of PlayerModel previews (16/page)
--  • Filter by path (case-insensitive) or DisplayID prefix
--  • Selected meta + pager + Apply/Cancel
--  • Callback(displayID, fileDataID, filePath)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Colors   = RPE_UI.Colors or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local HBorder  = RPE_UI.Elements.HorizontalBorder
local Text     = RPE_UI.Elements.Text
local Button   = RPE_UI.Elements.TextButton
local Input    = RPE_UI.Elements.Input
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Colors   = RPE_UI.Colors

---@class ModelFinderWindow
local W = {}
W.__index = W
RPE_UI.Windows.ModelFinderWindow = W
RPE.Core.Windows.ModelFinderWindow  = W
W.Name = "ModelFinderWindow"

-- ── layout constants ─────────────────────────────────────────────────────────
local GRID_COLS     = 4
local GRID_ROWS     = 4
local CELL_SIZE     = 96
local CELL_SPACING  = 8
local GRID_PAD      = 10

local GRID_W = GRID_PAD + (GRID_COLS - 1) * (CELL_SIZE + CELL_SPACING) + CELL_SIZE + GRID_PAD
local GRID_H = GRID_PAD + (GRID_ROWS - 1) * (CELL_SIZE + CELL_SPACING) + CELL_SIZE + GRID_PAD

local HEADER_H   = 36
local META_H     = 48
local NAV_H      = 30
local V_SPACING  = 6
local SIDE_PAD   = 8

local WIN_W = math.max(GRID_W + 2*SIDE_PAD, 420)
local WIN_H = HEADER_H + V_SPACING + GRID_H + V_SPACING + META_H + V_SPACING + NAV_H + 10

-- ── helpers ──────────────────────────────────────────────────────────────────
local function _norm(p) return (tostring(p or ""):gsub("\\","/"):lower()) end

local function _buildIndex(self)
    self._all = {}
    local src = nil
    if RPE.Core.ModelData and type(RPE.Core.ModelData.GetTable)=="function" then
        src = RPE.Core.ModelData:GetTable()
    elseif RPE.Core.ModelData then
        src = RPE.Core.ModelData
    end
    if type(src) ~= "table" then
        self._all = {}
        return
    end
    for displayID, data in pairs(src) do
        local fileDataID = data.FileDataID or data.fileDataID
        local filePath   = data.FilePath   or data.filePath
        if fileDataID and filePath then
            self._all[#self._all+1] = {
                displayID = tonumber(displayID) or 0,
                fileDataID= tonumber(fileDataID) or 0,
                filePath  = tostring(filePath),
                pathL     = _norm(filePath),
            }
        end
    end
    table.sort(self._all, function(a,b)
        if a.displayID ~= b.displayID then return a.displayID < b.displayID end
        return a.fileDataID < b.fileDataID
    end)
end

local function _refilter(self, text)
    local q = tostring(text or "")
    local ql = _norm(q)
    local qnumPrefix = tonumber(q) and tostring(math.floor(tonumber(q))) or nil
    if q=="" then
        self._filtered = {}
        for i=1,#self._all do self._filtered[i] = self._all[i] end
        return
    end
    local out = {}
    for _, e in ipairs(self._all) do
        local match = false
        if ql ~= "" and e.pathL:find(ql, 1, true) then
            match = true
        elseif qnumPrefix then
            local s = tostring(e.displayID)
            if s:sub(1, #qnumPrefix) == qnumPrefix then match = true end
        end
        if match then out[#out+1] = e end
    end
    self._filtered = out
end

local function _updatePager(self)
    local total = #self._filtered
    self._pages = math.max(1, math.ceil(total / self._itemsPerPage))
    if self._page < 1 then self._page = 1 end
    if self._page > self._pages then self._page = self._pages end
    if self._pageText and self._pageText.SetText then
        self._pageText:SetText(("Page %d / %d  (%d models)"):format(self._page, self._pages, total))
    end
end

local function _ensureCells(self, needed)
    for i = #self._items + 1, needed do
        local holder = CreateFrame("Frame", "RPE_MF_Cell_"..i, self.content.frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
        holder:SetSize(CELL_SIZE, CELL_SIZE)
        local border = holder:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(holder)
        border:Hide()
        if Colors and Colors.ApplyHighlight then Colors.ApplyHighlight(border) end
        local pm = CreateFrame("PlayerModel", nil, holder)
        pm:SetAllPoints(holder)
        pm:SetKeepModelOnHide(true)
        pm:ClearTransform()
        pm:SetCamDistanceScale(1.0)
        pm:SetCustomCamera(1)
        pm:SetPosition(0,0,0)
        self._items[i] = { frame = holder, model = pm, border = border }
    end
    for i = needed + 1, #self._items do
        local cell = self._items[i]; if cell and cell.frame then cell.frame:Hide() end
    end
end

local function _placeCells(self)
    local startX, startY = GRID_PAD, -GRID_PAD
    for i=1,self._itemsPerPage do
        local cell = self._items[i]; if not cell then break end
        local idx=i-1; local row=math.floor(idx/GRID_COLS); local col=idx%GRID_COLS
        cell.frame:ClearAllPoints()
        cell.frame:SetPoint("TOPLEFT", self.content.frame, "TOPLEFT",
            startX + col*(CELL_SIZE+CELL_SPACING),
            startY - row*(CELL_SIZE+CELL_SPACING))
        cell.frame:Show()
    end
end

local function _bindCellHandlers(self, cell, data)
    cell.frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(cell.frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Model")
        GameTooltip:AddLine(("DisplayID: %d"):format(data.displayID))
        GameTooltip:AddLine(("FileDataID: %d"):format(data.fileDataID))
        GameTooltip:AddLine(("Path: %s"):format(data.filePath))
        GameTooltip:Show()
    end)
    cell.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cell.frame:SetScript("OnMouseDown", function()
        self._selected = data
        for _, c in ipairs(self._items) do if c.border then c.border:Hide() end end
        if cell.border then cell.border:Show() end
        if self._metaLine1 then
            self._metaLine1:SetText(("DisplayID: %d    FileDataID: %d"):format(data.displayID, data.fileDataID))
        end
        if self._metaLine2 then
            self._metaLine2:SetText(("Path: %s"):format(data.filePath or "—"))
        end
    end)
end

local function _fillPage(self)
    _updatePager(self)
    local total = #self._filtered
    if total==0 then
        for _, cell in ipairs(self._items) do if cell.frame then cell.frame:Hide() end end
        self._selected = nil
        if self._metaLine1 then self._metaLine1:SetText("DisplayID: —    FileDataID: —") end
        if self._metaLine2 then self._metaLine2:SetText("Path: —") end
        return
    end
    local s = (self._page-1)*self._itemsPerPage + 1
    local e = math.min(s + self._itemsPerPage - 1, total)
    local n = e - s + 1
    _ensureCells(self, self._itemsPerPage)
    _placeCells(self)
    for i=1,self._itemsPerPage do
        local cell = self._items[i]
        if i<=n then
            local data = self._filtered[s+(i-1)]
            cell.model:ClearTransform()
            cell.model:SetModel(data.fileDataID)
            cell.model:SetDisplayInfo(data.displayID)
            cell.border:Hide()
            _bindCellHandlers(self, cell, data)
            cell.frame:Show()
        else
            cell.frame:Hide()
        end
    end
end

-- ── build ────────────────────────────────────────────────────────────────────
function W:BuildUI()
    if self.root then return end
    self._items, self._page = {}, 1
    self._itemsPerPage      = GRID_COLS*GRID_ROWS

    self.root = Window:New("RPE_ModelFinder_Window", {
        width  = WIN_W, height = WIN_H,
        point  = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -20,
        autoSize = false,
    })

    -- Header
    self.header = HGroup:New("RPE_MF_Header", {
        parent   = self.root,
        spacingX = 8,
        alignH   = "LEFT",
        alignV   = "CENTER",
        autoSize = true,
        padding  = { left=SIDE_PAD, right=SIDE_PAD, top=4, bottom=4 },
    })
    self.root:Add(self.header)

    local lbl = Text:New("RPE_MF_FilterLabel", { parent=self.header, text="Filter:", fontTemplate="GameFontHighlight" })
    self.header:Add(lbl)

    self._search = Input:New("RPE_MF_FilterInput", {
        parent=self.header, width = 260, height = 22, text = "",
        placeholder = "path or DisplayID prefix...",
        onChanged = function(_, text)
            _refilter(self, text or "")
            self._page = 1
            _fillPage(self)
        end
    })
    self.header:Add(self._search)

    -- Content
    self.content = Panel:New("RPE_MF_Content", {
        parent   = self.root,
        autoSize = false,
    })
    self.content:SetSize(GRID_W + 2*SIDE_PAD, GRID_H)
    self.root:Add(self.content)

    -- Footer
    self.footer = VGroup:New("RPE_MF_Footer", {
        parent   = self.root,
        spacingY = 6,
        alignH   = "FILL",
        alignV   = "TOP",
        autoSize = true,
        padding  = { left=SIDE_PAD, right=SIDE_PAD, top=6, bottom=6 },
    })
    self.root:Add(self.footer)

    -- Meta lines
    local metaGroup = VGroup:New("RPE_MF_MetaGroup", { parent=self.footer, spacingY=2, alignH="LEFT", autoSize=true })
    self.footer:Add(metaGroup)

    self._metaLine1 = Text:New("RPE_MF_Meta1", { parent=metaGroup, text="DisplayID: —    FileDataID: —" })
    metaGroup:Add(self._metaLine1)

    self._metaLine2 = Text:New("RPE_MF_Meta2", { parent=metaGroup, text="Path: —", fontTemplate="GameFontHighlightSmall" })
    metaGroup:Add(self._metaLine2)

    -- Navigation + actions
    local navRow = HGroup:New("RPE_MF_NavRow", { parent=self.footer, spacingX=10, alignH="FILL", alignV="CENTER", autoSize=true })
    self.footer:Add(navRow)

    self._prevBtn = Button:New("RPE_MF_Prev", { parent=navRow, width=60, height=22, text="Prev" })
    navRow:Add(self._prevBtn)

    self._pageText = Text:New("RPE_MF_PageText", { parent=navRow, text="Page 1 / 1 (0 models)" })
    navRow:Add(self._pageText)

    self._nextBtn = Button:New("RPE_MF_Next", { parent=navRow, width=60, height=22, text="Next" })
    navRow:Add(self._nextBtn)

    local spacer = Panel:New("RPE_MF_Spacer", { parent=navRow, width=1, height=1 })
    spacer.flex = 1
    navRow:Add(spacer)

    self._applyBtn  = Button:New("RPE_MF_Apply", { parent=navRow, width=80, height=22, text="Apply" })
    navRow:Add(self._applyBtn)

    self._cancelBtn = Button:New("RPE_MF_Cancel", { parent=navRow, width=80, height=22, text="Cancel" })
    navRow:Add(self._cancelBtn)

    -- Wiring
    self._prevBtn:SetOnClick(function() if self._page>1 then self._page=self._page-1; _fillPage(self) end end)
    self._nextBtn:SetOnClick(function() if self._page<self._pages then self._page=self._page+1; _fillPage(self) end end)
    self._applyBtn:SetOnClick(function()
        if self._callback and self._selected then
            self._callback(self._selected.displayID, self._selected.fileDataID, self._selected.filePath)
            self:Hide()
        else
            
        end
    end)
    self._cancelBtn:SetOnClick(function() self:Hide() end)

    -- Data
    _buildIndex(self); _refilter(self, ""); _fillPage(self)

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
end

function W:Show() if not self.root then self:BuildUI() end; self.root:Show() end
function W:Hide() if self.root then self.root:Hide() end end
function W:Open(callback, opts)
    self._callback = callback
    self:Show()
    local filter = (opts and opts.filter) or ""
    if self._search and self._search.SetText then self._search:SetText(filter) end
    _refilter(self, filter); self._page=1; _fillPage(self)
end
function W:Get() if not self._singleton then self._singleton=setmetatable({}, W); self._singleton:BuildUI() end; return self._singleton end
function RPE.Core.OpenModelFinder(callback, opts) return W:Get():Open(callback, opts) end

return W
