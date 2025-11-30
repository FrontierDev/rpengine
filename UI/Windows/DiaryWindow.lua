-- RPE_UI/Windows/DiaryWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local TextBtn  = RPE_UI.Elements.TextButton
local HBorder  = RPE_UI.Elements.HorizontalBorder

---@class DiaryWindow
---@field root Window
---@field footer Panel
---@field content Panel
---@field tabs table<string, TextBtn>
local DiaryWindow = {}
_G.RPE_UI.Windows.DiaryWindow = DiaryWindow
DiaryWindow.__index = DiaryWindow
DiaryWindow.Name = "DiaryWindow"

local FOOTER_COLS   = 3
local BUTTON_HEIGHT = 26
local BUTTON_SPACING = 4
local FOOTER_PADDING_Y = 7

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.DiaryWindow = self
end

-- RPE_UI/Windows/DiaryWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local TextBtn  = RPE_UI.Elements.TextButton
local HBorder  = RPE_UI.Elements.HorizontalBorder

---@class DiaryWindow
---@field root Window
---@field footer Panel
---@field content Panel
---@field tabs table<string, TextBtn>
local DiaryWindow = {}
_G.RPE_UI.Windows.DiaryWindow = DiaryWindow
DiaryWindow.__index = DiaryWindow
DiaryWindow.Name = "DiaryWindow"

local FOOTER_COLS   = 3
local BUTTON_HEIGHT = 26
local BUTTON_SPACING = 4
local FOOTER_PADDING_Y = 7

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.DiaryWindow = self
end

function DiaryWindow:BuildUI()
    -- Root window
    self.root = Window:New("RPE_Diary_Window", {
        width  = 480,
        height = 680,
        point  = "CENTER",
        autoSize = false, -- fixed size
    })

    -- Top border (stretched full width)
    self.topBorder = HBorder:New("RPE_Diary_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 5,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)

    -- Bottom border (stretched full width)
    self.bottomBorder = HBorder:New("RPE_Diary_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 5,
        y             = 0,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- Content panel (fills space above footer)
    self.content = Panel:New("RPE_Diary_Content", {
        parent  = self.root,
        autoSize = true,
    })
    self.root:Add(self.content)
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, -0)
    self.content.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, -0)
    self.content.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0) -- will be adjusted when footer resizes
    self.content.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer panel (auto-expands in height)
    self.footer = Panel:New("RPE_Diary_Footer", {
        parent  = self.root,
        autoSize = false,
    })
    self.root:Add(self.footer)
    self.footer.frame:ClearAllPoints()
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    self.footer.frame:SetHeight(40) -- initial, will expand

    self.tabs = {}
    self.pages = {}
    self._colHeights = { [1] = 0, [2] = 0, [3] = 0 } -- track Y offset per column

    -- Add buttons
    self:AddTabButton(1, "control",         "Control")
    self:AddTabButton(2, "units",           "Units")
    self:AddTabButton(3, "settings",        "Settings")

    -- Add sheets
    local control = _G.RPE_UI.Windows.EventControlSheet.New({ parent = self.content})
    self.pages["control"] = control


    if self.content and self.content.SetSize and control.sheet and control.sheet.frame then
        local w = control.sheet.frame:GetWidth() + 12
        local h = control.sheet.frame:GetHeight() + 12
        if w and h then
            local padX = self.content.autoSizePadX or 0
            local padY = self.content.autoSizePadY or 0
            local minW = self.footer.frame:GetWidth() or 0

            -- apply padding and enforce minimum width
            local cw = math.max(w + padX, minW)
            local ch = h + padY

            self.content:SetSize(cw, ch)
            self.root:SetSize(cw, ch + self.footer.frame:GetHeight())
        end
    end

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function DiaryWindow:ShowTab(key)
    -- Hide all pages first
    for k, page in pairs(self.pages or {}) do
        if page.sheet and page.sheet.Hide then
            page.sheet:Hide()
        elseif page.root and page.root.Hide then
            page.root:Hide()
        end
    end

    -- Show the requested page
    local page = self.pages[key]
    if not page then
        RPE.Debug:Error("No page registered for key: " .. tostring(key))
        return
    end

    if page.sheet and page.sheet.Show then
        page.sheet:Show()
    elseif page.root and page.root.Show then
        page.root:Show()
    end

    if self.content and self.content.SetSize and page.sheet and page.sheet.frame then
        local w = page.sheet.frame:GetWidth() + 12
        local h = page.sheet.frame:GetHeight() + 12
        if w and h then
            local padX = self.content.autoSizePadX or 0
            local padY = self.content.autoSizePadY or 0
            local minW = self.footer.frame:GetWidth() or 0

            -- apply padding and enforce minimum width
            local cw = math.max(w + padX, minW)
            local ch = h + padY

            self.content:SetSize(cw, ch)
            self.root:SetSize(cw, ch + self.footer.frame:GetHeight())
        end
    end
end

--- Add a tab button into a footer column
---@param col integer 1..3
---@param key string
---@param title string
function DiaryWindow:AddTabButton(col, key, title)
    assert(col >= 1 and col <= FOOTER_COLS, "Column index must be 1..3")

    local colWidth = self.root.frame:GetWidth() / FOOTER_COLS
    local btn = TextBtn:New("RPE_Diary_TabBtn_" .. key, {
        parent  = self.footer,
        width   = colWidth - 12,
        height  = BUTTON_HEIGHT,
        text    = title,
        noBorder = true,
        onClick = function()
            self:ShowTab(key)  -- ✅ use instance
        end,
    })

    -- place in correct column, stacked upward
    local left = (col - 1) * colWidth
    local offsetY = FOOTER_PADDING_Y + self._colHeights[col]
    btn.frame:ClearAllPoints()
    btn.frame:SetPoint("BOTTOMLEFT", self.footer.frame, "BOTTOMLEFT", left + 6, offsetY)
    btn.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "BOTTOMLEFT", left + colWidth - 6, offsetY)

    -- advance column height
    self._colHeights[col] = self._colHeights[col] + BUTTON_HEIGHT + BUTTON_SPACING

    self.tabs[key] = btn

    -- ensure footer tall enough
    local tallest = math.max(self._colHeights[1], self._colHeights[2], self._colHeights[3])
    self.footer.frame:SetHeight(tallest + FOOTER_PADDING_Y + BUTTON_HEIGHT)

    -- adjust content panel top of footer
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT", self.footer.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)

    return btn
end


function DiaryWindow.New()
    local self = setmetatable({}, DiaryWindow)
    self:BuildUI()
    return self
end

function DiaryWindow:Show()
    if self.root and self.root.Show then self.root:Show() end
end

function DiaryWindow:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

return DiaryWindow
