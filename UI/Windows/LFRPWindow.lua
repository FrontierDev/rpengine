-- RPE_UI/Windows/LFRPWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local TextBtn  = RPE_UI.Elements.TextButton
local HBorder  = RPE_UI.Elements.HorizontalBorder

---@class LFRPWindow
---@field root Window
---@field footer Panel
---@field content Panel
---@field tabs table<string, TextBtn>
---@field pages table<string, any>
local LFRPWindow = {}
_G.RPE_UI.Windows.LFRPWindow = LFRPWindow
LFRPWindow.__index = LFRPWindow
LFRPWindow.Name = "LFRPWindow"

local FOOTER_COLS   = 2
local BUTTON_HEIGHT = 26
local BUTTON_SPACING = 4
local FOOTER_PADDING_Y = 7

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.LFRPWindow = self
end

function LFRPWindow:BuildUI()
    -- Root window
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_LFRP_Window", {
        parent = parentFrame,
        width  = 480,
        height = 400,
        point  = "CENTER",
        autoSize = false,
    })

    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale() f:SetScale(UIParent and UIParent:GetScale() or 1) end
        local function UpdateMouseForUIVisibility() f:EnableMouse(UIParent and UIParent:IsShown()) end
        SyncScale(); UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Top border (stretched full width)
    self.topBorder = HBorder:New("RPE_LFRP_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 3)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 3)
    _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)

    -- Bottom border (stretched full width)
    self.bottomBorder = HBorder:New("RPE_LFRP_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, -3)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, -3)
    _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- Content panel (fills space above footer)
    self.content = Panel:New("RPE_LFRP_Content", {
        parent  = self.root,
        autoSize = true,
    })
    self.root:Add(self.content)
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer panel (auto-expands in height)
    self.footer = Panel:New("RPE_LFRP_Footer", {
        parent  = self.root,
        autoSize = false,
    })
    self.root:Add(self.footer)
    self.footer.frame:ClearAllPoints()
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    self.footer.frame:SetHeight(40)

    self.tabs = {}
    self.pages = {}
    self._colHeights = { [1] = 0, [2] = 0 }

    -- Add tab buttons
    self:AddTabButton(1, "settings", "Settings")
    self:AddTabButton(2, "browse",   "Browse")

    -- Add sheets
    local LFRPSettingsSheet = _G.RPE_UI.Windows.LFRPSettingsSheet
    if LFRPSettingsSheet then
        local settings = LFRPSettingsSheet.New({ parent = self.content })
        self.pages["settings"] = settings
    end

    local LFRPBrowseSheet = _G.RPE_UI.Windows.LFRPBrowseSheet
    if LFRPBrowseSheet then
        local browse = LFRPBrowseSheet.New({ parent = self.content })
        self.pages["browse"] = browse
        browse.sheet:Hide()
    end

    -- Size the window to fit initial content
    if self.content and self.content.SetSize and self.pages["settings"] and self.pages["settings"].sheet and self.pages["settings"].sheet.frame then
        local w = self.pages["settings"].sheet.frame:GetWidth() + 12
        local h = self.pages["settings"].sheet.frame:GetHeight() + 12
        if w and h then
            local padX = self.content.autoSizePadX or 0
            local padY = self.content.autoSizePadY or 0
            local minW = self.footer.frame:GetWidth() or 0

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

function LFRPWindow:ShowTab(key)
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

    -- Defer resize to allow layout to settle
    if C_Timer and C_Timer.After then
        C_Timer.After(0.01, function()
            if self.root and self.root.frame and self.root.frame:IsVisible() then
                self:_resizeToSheet(page)
            end
        end)
    else
        self:_resizeToSheet(page)
    end
end

function LFRPWindow:_resizeToSheet(page)
    if not page then return end
    
    local sheet = page.sheet or page.root
    if not (self.content and self.content.SetSize and sheet and sheet.frame) then return end
    
    -- Call Relayout if available
    if sheet.Relayout then
        pcall(function() sheet:Relayout() end)
    end
    
    local w = sheet.frame:GetWidth()
    local h = sheet.frame:GetHeight()
    
    if not w or w == 0 or not h or h == 0 then
        return
    end
    
    w = w + 12
    h = h + 12
    
    local padX = self.content.autoSizePadX or 0
    local padY = self.content.autoSizePadY or 0
    local minW = self.footer.frame:GetWidth() or 480

    local cw = math.max(w + padX, minW)
    local ch = h + padY

    self.content:SetSize(cw, ch)
    self.root:SetSize(cw, ch + self.footer.frame:GetHeight())
end

--- Add a tab button into a footer column
---@param col integer 1..2
---@param key string
---@param title string
function LFRPWindow:AddTabButton(col, key, title)
    assert(col >= 1 and col <= FOOTER_COLS, "Column index must be 1..2")

    local colWidth = self.root.frame:GetWidth() / FOOTER_COLS
    local btn = TextBtn:New("RPE_LFRP_TabBtn_" .. key, {
        parent  = self.footer,
        width   = colWidth - 12,
        height  = BUTTON_HEIGHT,
        text    = title,
        noBorder = true,
        onClick = function()
            self:ShowTab(key)
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
    local tallest = math.max(self._colHeights[1], self._colHeights[2])
    self.footer.frame:SetHeight(tallest + FOOTER_PADDING_Y + BUTTON_HEIGHT)

    -- adjust content panel to sit above footer
    self.content.frame:ClearAllPoints()
    self.content.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    self.content.frame:SetPoint("BOTTOMLEFT", self.footer.frame, "TOPLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)

    return btn
end

function LFRPWindow.New()
    local self = setmetatable({}, LFRPWindow)
    self:BuildUI()
    return self
end

function LFRPWindow:Show()
    if self.root and self.root.Show then self.root:Show() end
end

function LFRPWindow:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

return LFRPWindow
