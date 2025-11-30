-- RPE_UI/Windows/IconFinderWindow.lua
-- Icon Finder (compact) — built like other RPE windows:
-- Window + top/bottom borders + Header/Content/Footer panels.
--  • Top-left position
--  • Fixed 10x10 grid of 32x32 (100/page)
--  • Filter searches file path (case-insensitive)
--  • Selected preview + Path + FileDataID
--  • Pager row under the selected data

RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local HBorder  = RPE_UI.Elements.HorizontalBorder
local Text     = RPE_UI.Elements.Text
local Button   = RPE_UI.Elements.TextButton
local Input    = RPE_UI.Elements.Input
local IconBtn  = RPE_UI.Elements.IconButton
local Colors   = RPE_UI.Colors

---@class IconFinderWindow
---@field root Window
---@field header Panel
---@field content Panel
---@field footer Panel
---@field topBorder any
---@field bottomBorder any
---@field _search Input
---@field _pageText Text
---@field _prevBtn any
---@field _nextBtn any
---@field _applyBtn any
---@field _cancelBtn any
---@field _preview any
---@field _metaPath Text
---@field _metaId Text
---@field _icons any[]
---@field _all table[]
---@field _filtered table[]
---@field _selected table|nil
---@field _cols integer
---@field _rows integer
---@field _itemsPerPage integer
---@field _page integer
---@field _pages integer
local W = {}
W.__index = W
_G.RPE_UI.Windows.IconFinderWindow = W
RPE.Core.Windows.IconFinderWindow  = W
W.Name = "IconFinderWindow"

-- ── layout constants ─────────────────────────────────────────────────────────
local GRID_COLS     = 10
local GRID_ROWS     = 10
local ICON_SIZE     = 32
local ICON_SPACING  = 6
local GRID_PAD      = 8

local GRID_W = GRID_PAD + (GRID_COLS - 1) * (ICON_SIZE + ICON_SPACING) + ICON_SIZE + GRID_PAD
local GRID_H = GRID_PAD + (GRID_ROWS - 1) * (ICON_SIZE + ICON_SPACING) + ICON_SIZE + GRID_PAD

local HEADER_H   = 36
local META_H     = 48
local NAV_H      = 30
local V_SPACING  = 6
local SIDE_PAD   = 8

-- widen a bit so footer controls don’t collide on long page text
local WIN_W = math.max(GRID_W + 2*SIDE_PAD, 480)
local WIN_H = HEADER_H + V_SPACING + GRID_H + V_SPACING + META_H + V_SPACING + NAV_H + 10

-- ── helpers ──────────────────────────────────────────────────────────────────
local function _norm(p) return (tostring(p or ""):gsub("\\","/"):lower()) end

local function _shallowCopy(t)
    local n, out = #t, {}
    for i=1,n do out[i]=t[i] end
    return out
end

local function _buildIndex(self)
    self._all = {}
    local src = RPE.Core.IconData or {}
    for id, path in pairs(src) do
        local pl = _norm(path)
        if type(path)=="string" and pl:find("^interface/icons/") then
            self._all[#self._all+1] = { id = tonumber(id) or 0, path = path, pathL = pl }
        end
    end
end

local function _applySort(list)
    table.sort(list, function(a,b) return a.id < b.id end)
end

local function _refilter(self, text)
    local q = _norm(text or "")
    if q=="" then
        self._filtered = _shallowCopy(self._all)
    else
        local out, n = {}, 0
        for _, e in ipairs(self._all) do
            if e.pathL:find(q, 1, true) then
                n=n+1; out[n]=e
            end
        end
        self._filtered = out
    end
    _applySort(self._filtered)
end

local function _updatePager(self)
    local total = #self._filtered
    self._pages = math.max(1, math.ceil(total / self._itemsPerPage))
    if self._page < 1 then self._page = 1 end
    if self._page > self._pages then self._page = self._pages end
    if self._pageText and self._pageText.SetText then
        self._pageText:SetText(("Page %d / %d  (%d icons)"):format(self._page, self._pages, total))
    end
    if self._prevBtn and self._prevBtn.Lock then
        if self._page<=1 then self._prevBtn:Lock() else self._prevBtn:Unlock() end
    end
    if self._nextBtn and self._nextBtn.Lock then
        if self._page>=self._pages then self._nextBtn:Lock() else self._nextBtn:Unlock() end
    end
end

local function _ensureButtons(self, needed)
    for i = #self._icons + 1, needed do
        local ib = IconBtn:New(("RPE_IF_Icon_%d"):format(i), {
            parent = self.content,
            width = ICON_SIZE, height = ICON_SIZE,
        })
        ib.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local sel = ib.frame:CreateTexture(nil, "OVERLAY"); sel:SetAllPoints(); sel:Hide(); Colors.ApplyHighlight(sel)
        ib._sel = sel
        self._icons[i] = ib
    end
    for i = needed + 1, #self._icons do
        local ib = self._icons[i]; if ib then ib:Hide() end
    end
end

local function _placeButtons(self)
    local startX, startY = SIDE_PAD + GRID_PAD, -V_SPACING - GRID_PAD - HEADER_H
    -- but our icons live in content panel; compute relative to its TOPLEFT
    startX, startY = GRID_PAD, -GRID_PAD
    for i=1,self._itemsPerPage do
        local ib = self._icons[i]; if not ib then break end
        ib:Show(); ib:SetSize(ICON_SIZE, ICON_SIZE); ib:ClearAllPoints()
        local idx=i-1; local row=math.floor(idx/GRID_COLS); local col=idx%GRID_COLS
        ib:SetPoint("TOPLEFT", self.content.frame, "TOPLEFT",
            startX + col*(ICON_SIZE+ICON_SPACING),
            startY - row*(ICON_SIZE+ICON_SPACING))
    end
end

local function _bindHandlers(self, ib, data, pageIdx)
    ib:SetOnClick(function(_, btn)
        if btn=="RightButton" then
            return
        end
        self._selected = data
        for _, b in ipairs(self._icons) do if b and b._sel then b._sel:Hide() end end
        if ib._sel then ib._sel:Show() end
        self._preview:SetIcon(data.path)
        self._metaPath:SetText("Path: "..data.path)
        self._metaId:SetText(("FileDataID: %d"):format(data.id))

        local t = GetTime and GetTime() or 0
        if ib._lastClick and t - ib._lastClick < 0.25 then
            if self._callback and self._selected then
                self._callback(self._selected.id, self._selected.path)
                self:Hide()
            end
        end
        ib._lastClick = t
    end)

    ib.frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(ib.frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Icon")
        GameTooltip:AddLine(("FileDataID: %d"):format(data.id))
        GameTooltip:AddLine(("Path: %s"):format(data.path))
        GameTooltip:Show()
    end)
    ib.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function _fillPage(self)
    _updatePager(self)
    local total = #self._filtered
    if total==0 then
        for _, ib in ipairs(self._icons) do ib:Hide() end
        self._selected = nil
        self._preview:SetIcon(nil)
        self._metaPath:SetText("Path: —")
        self._metaId:SetText("")
        return
    end
    local s = (self._page-1)*self._itemsPerPage + 1
    local e = math.min(s + self._itemsPerPage - 1, total)
    local n = e - s + 1

    _ensureButtons(self, self._itemsPerPage)
    _placeButtons(self)

    for i=1,self._itemsPerPage do
        local ib = self._icons[i]
        if i<=n then
            local data = self._filtered[s+(i-1)]
            ib:SetIcon(data.path)
            if ib._sel then ib._sel:Hide() end
            _bindHandlers(self, ib, data, i)
            ib:Show()
        else
            ib:Hide()
        end
    end
end

-- ── build ────────────────────────────────────────────────────────────────────
function W:BuildUI()
    if self.root then return end

    self._icons, self._page = {}, 1
    self._cols, self._rows  = GRID_COLS, GRID_ROWS
    self._itemsPerPage      = GRID_COLS*GRID_ROWS

    -- Root window (like others)
    self.root = Window:New("RPE_IconFinder_Window", {
        width  = WIN_W,
        height = WIN_H,
        point  = "TOPLEFT",
        relativePoint = "TOPLEFT",
        x = 10, y = -10,
        autoSize = false,
    })

    -- Top border
    self.topBorder = HBorder:New("RPE_IF_TopBorder", { parent=self.root, stretch=true, thickness=5, y=0, layer="BORDER" })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT",  self.root.frame, "TOPLEFT",  0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    if Colors and Colors.ApplyHighlight then Colors.ApplyHighlight(self.topBorder) end

    -- Header panel
    self.header = Panel:New("RPE_IF_Header", { parent=self.root, autoSize=false })
    self.header.frame:ClearAllPoints()
    self.header.frame:SetPoint("TOPLEFT",  self.topBorder.frame, "BOTTOMLEFT", 0, 0)
    self.header.frame:SetPoint("TOPRIGHT", self.topBorder.frame, "BOTTOMRIGHT", 0, 0)
    self.header.frame:SetHeight(HEADER_H)

    -- Header contents: label, input, clear
    local lbl = Text:New("RPE_IF_FilterLabel", { parent=self.header, text="Path contains:", fontTemplate="GameFontHighlight" })
    lbl.frame:ClearAllPoints()
    lbl.frame:SetPoint("LEFT", self.header.frame, "LEFT", SIDE_PAD, 0)

    self._search = Input:New("RPE_IF_FilterInput", {
        parent = self.header, width = 260, height = 22, text = "",
        onChanged = function(_, text)
            _refilter(self, text or "")
            self._page = 1
            _fillPage(self)
        end
    })
    self._search.frame:ClearAllPoints()
    self._search.frame:SetPoint("LEFT", lbl.frame, "RIGHT", 8, 0)

    local clearBtn = Button:New("RPE_IF_Clear", {
        parent=self.header, width=60, height=22, text="Clear",
        onClick=function()
            if self._search and self._search.SetText then self._search:SetText("") end
            _refilter(self, ""); self._page=1; _fillPage(self)
        end
    })
    clearBtn.frame:ClearAllPoints()
    clearBtn.frame:SetPoint("RIGHT", self.header.frame, "RIGHT", -SIDE_PAD, 0)

    -- Bottom border
    self.bottomBorder = HBorder:New("RPE_IF_BottomBorder", { parent=self.root, stretch=true, thickness=5, y=0, layer="BORDER" })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT",  self.root.frame, "BOTTOMLEFT",  0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    if Colors and Colors.ApplyHighlight then Colors.ApplyHighlight(self.bottomBorder) end

    -- Footer panel (fixed height)
    self.footer = Panel:New("RPE_IF_Footer", { parent=self.root, autoSize=false })
    self.footer.frame:ClearAllPoints()
    self.footer.frame:SetPoint("BOTTOMLEFT", self.bottomBorder.frame, "TOPLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.bottomBorder.frame, "TOPRIGHT", 0, 0)
    self.footer.frame:SetHeight(META_H + V_SPACING + NAV_H)

    -- Content panel (between header and footer)
    self.content = Panel:New("RPE_IF_Content", { parent=self.root, autoSize=false })
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT",  self.header.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT",  self.footer.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)
    self.content:SetSize(GRID_W + 2*SIDE_PAD, GRID_H) -- width not strictly used; icons positioned inside

    -- Selected META row (preview + 2 lines), anchored to top of footer
    self._preview = IconBtn:New("RPE_IF_Preview", { parent=self.footer, width=40, height=40 })
    self._preview.frame:ClearAllPoints()
    self._preview.frame:SetPoint("TOPLEFT", self.footer.frame, "TOPLEFT", SIDE_PAD, -6)

    self._metaPath = Text:New("RPE_IF_MetaPath", { parent=self.footer, text="Path: —", justifyH="LEFT" })
    self._metaPath.frame:ClearAllPoints()
    self._metaPath.frame:SetPoint("LEFT", self._preview.frame, "RIGHT", 8, 6)
    self._metaPath.frame:SetPoint("RIGHT", self.footer.frame, "RIGHT", -SIDE_PAD, 6)

    self._metaId = Text:New("RPE_IF_MetaId", { parent=self.footer, text="", fontTemplate="GameFontHighlightSmall", justifyH="LEFT" })
    self._metaId.frame:ClearAllPoints()
    self._metaId.frame:SetPoint("LEFT", self._preview.frame, "RIGHT", 8, -10)
    self._metaId.frame:SetPoint("RIGHT", self.footer.frame, "RIGHT", -SIDE_PAD, -10)

    -- NAV row (under meta)
    self._prevBtn = Button:New("RPE_IF_Prev", { parent=self.footer, width=60, height=22, text="Prev" })
    self._prevBtn.frame:ClearAllPoints()
    self._prevBtn.frame:SetPoint("BOTTOMLEFT", self.footer.frame, "BOTTOMLEFT", SIDE_PAD, 6)

    self._pageText = Text:New("RPE_IF_PageText", { parent=self.footer, text="Page 1 / 1  (0 icons)", fontTemplate="GameFontHighlight" })
    self._pageText.frame:ClearAllPoints()
    self._pageText.frame:SetPoint("LEFT", self._prevBtn.frame, "RIGHT", 10, 0)

    self._nextBtn = Button:New("RPE_IF_Next", { parent=self.footer, width=60, height=22, text="Next" })
    self._nextBtn.frame:ClearAllPoints()
    self._nextBtn.frame:SetPoint("LEFT", self._pageText.frame, "RIGHT", 10, 0)

    self._cancelBtn = Button:New("RPE_IF_Cancel", { parent=self.footer, width=80, height=22, text="Cancel" })
    self._cancelBtn.frame:ClearAllPoints()
    self._cancelBtn.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "BOTTOMRIGHT", -SIDE_PAD, 6)

    self._applyBtn = Button:New("RPE_IF_Apply", { parent=self.footer, width=80, height=22, text="Apply" })
    self._applyBtn.frame:ClearAllPoints()
    self._applyBtn.frame:SetPoint("RIGHT", self._cancelBtn.frame, "LEFT", -8, 0)

    -- Wiring
    self._prevBtn:SetOnClick(function() if self._page>1 then self._page=self._page-1; _fillPage(self) end end)
    self._nextBtn:SetOnClick(function() if self._page<self._pages then self._page=self._page+1; _fillPage(self) end end)
    self._applyBtn:SetOnClick(function()
        if self._callback and self._selected then self._callback(self._selected.id, self._selected.path); self:Hide()
        else print("IconFinder: No icon selected.") end
    end)
    self._cancelBtn:SetOnClick(function() self:Hide() end)

    -- Data + first render
    _buildIndex(self)
    _refilter(self, "")
    _fillPage(self)

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
end

function W:Show() if not self.root then self:BuildUI() end; self.root:Show() end
function W:Hide() if self.root then self.root:Hide() end end

-- Open for selection; callback(fileDataID, filePath)
function W:Open(callback, opts)
    self._callback = callback
    self:Show()
    local filter = (opts and opts.filter) or ""
    if self._search and self._search.SetText then self._search:SetText(filter) end
    _refilter(self, filter); self._page=1; _fillPage(self)
end

function W:Get()
    if not self._singleton then self._singleton=setmetatable({}, W); self._singleton:BuildUI() end
    return self._singleton
end

function RPE.Core.OpenIconFinder(callback, opts)
    return W:Get():Open(callback, opts)
end

return W
