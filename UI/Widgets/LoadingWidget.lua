-- RPE_UI/Widgets/LoadingWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Widgets  = RPE_UI.Widgets or {}

local FrameElement = RPE_UI.Elements and RPE_UI.Elements.FrameElement
local Colors     = RPE_UI.Colors

---@class LoadingWidget
---@field frame Frame
---@field icon Texture
---@field text FontString
---@field isVisible boolean
---@field hideTimer any
---@field rotateTimer any
local LoadingWidget = {}
LoadingWidget.__index = LoadingWidget
RPE_UI.Widgets.LoadingWidget = LoadingWidget

-- Configuration
local ICON_PATH = "Interface\\Addons\\RPEngine\\UI\\Textures\\rpe.png"
local SIZE = 20
local ROTATE_SPEED = 180  -- degrees per second
local HIDE_DELAY = 1.0    -- seconds before hiding after last activity

-- ====== Private Methods ======

-- Start the rotation animation
local function StartRotate(self)
    if not self.frame or not self.frame:IsShown() then return end
    
    if self.rotateTimer then
        C_Timer.Cancel(self.rotateTimer)
    end
    
    local rotation = 0
    local function RotateFrame()
        if not self.frame or not self.frame:IsShown() then return end
        rotation = (rotation + ROTATE_SPEED * 0.016) % 360  -- ~60 FPS
        self.icon:SetRotation(math.rad(rotation))
        self.rotateTimer = C_Timer.After(0.016, RotateFrame)
    end
    
    self.rotateTimer = C_Timer.After(0.016, RotateFrame)
end

-- Stop the rotation animation
local function StopRotate(self)
    if self.rotateTimer then
        C_Timer.Cancel(self.rotateTimer)
        self.rotateTimer = nil
    end
    self.icon:SetRotation(0)
end

-- ====== Public Methods ======

---Create and initialize the loading widget
---@return LoadingWidget
function LoadingWidget:New()
    local o = setmetatable({}, self)
    
    -- Create main frame (parented to UIParent, positioned top-center)
    local f = CreateFrame("Frame", "RPE_LoadingWidget", UIParent)
    f:SetSize(SIZE + 40, SIZE + 60)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(999)
    f:Hide()
    
    -- Create icon texture
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_PATH)
    icon:SetSize(SIZE, SIZE)
    icon:SetPoint("TOP", f, "TOP", 0, -5)
    
    -- Create progress text
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOP", icon, "BOTTOM", 0, -8)
    text:SetText("")
    if Colors then
        local r, g, b, a = Colors.Get("textMuted")
        text:SetTextColor(r, g, b, a)
    else
        text:SetTextColor(1, 1, 1, 1)
    end
    
    o.frame = f
    o.icon = icon
    o.text = text
    o.isVisible = false
    o.rotateTimer = nil
    o.hideTimer = nil
    
    return o
end

---Show the loading indicator and start rotating
function LoadingWidget:Show()
    if not self.frame then return end
    
    -- Cancel any pending hide
    if self.hideTimer then
        C_Timer.Cancel(self.hideTimer)
        self.hideTimer = nil
    end
    
    if not self.isVisible then
        self.frame:Show()
        self.isVisible = true
        StartRotate(self)
    end
end

---Hide the loading indicator after a brief delay
function LoadingWidget:Hide()
    if not self.frame or not self.isVisible then return end
    
    -- Cancel any pending hide
    if self.hideTimer then
        C_Timer.Cancel(self.hideTimer)
    end
    
    -- Defer hide to allow multiple rapid updates without flicker
    self.hideTimer = C_Timer.After(HIDE_DELAY, function()
        StopRotate(self)
        self.frame:Hide()
        self.isVisible = false
        self.hideTimer = nil
    end)
end

---Update the progress text
---@param text string
function LoadingWidget:SetProgress(text)
    if self.text then
        self.text:SetText(text)
    end
end

---Check if widget is visible
---@return boolean
function LoadingWidget:IsVisible()
    return self.isVisible
end

-- ====== Initialization ======

-- Create global instance
local instance = LoadingWidget:New()
_G.RPE_UI = _G.RPE_UI or {}
_G.RPE_UI.Widgets = _G.RPE_UI.Widgets or {}
_G.RPE_UI.Widgets.LoadingWidget = instance

return LoadingWidget
