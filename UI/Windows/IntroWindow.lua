-- RPE_UI/Windows/IntroWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window  = RPE_UI.Elements.Window
local Panel   = RPE_UI.Elements.Panel
local VGroup  = RPE_UI.Elements.VerticalLayoutGroup
local Text    = RPE_UI.Elements.Text

-- Config
local WIN_W, WIN_H   = 480, 420
local BG_W,  BG_H    = 420, 420
local HEADER_TEXT    = "RPEngine"
local BG_TEXTURE     = "Interface\\AddOns\\RPEngine\\UI\\Textures\\action.png"
local FADE_IN_DUR    = 0.60
local HOLD_DUR       = 3.0      -- time at full opacity before fade out
local FADE_OUT_DUR   = 0.60

---@class IntroWindow
---@field Name string
---@field root Window
---@field targetW number
---@field targetH number
---@field duration number
local IntroWindow = {}
_G.RPE_UI.Windows.IntroWindow = IntroWindow
IntroWindow.__index = IntroWindow
IntroWindow.Name = "IntroWindow"

local function _getVersion()
    local v = (_G.RPE and _G.RPE.AddonVersion)
            or (GetAddOnMetadata and GetAddOnMetadata("RPEngine", "Version"))
            or "dev"
    return "Loaded "..tostring(v)
end

function IntroWindow:BuildUI(opts)
    opts = opts or {}
    self.targetW  = tonumber(opts.width)    or WIN_W
    self.targetH  = tonumber(opts.height)   or WIN_H
    self.duration = tonumber(opts.duration) or FADE_IN_DUR
    self.holdDur  = tonumber(opts.hold)     or HOLD_DUR
    self.fadeOut  = tonumber(opts.fadeOut)  or FADE_OUT_DUR

    -- Fixed-size window
    self.root = Window:New("RPE_IntroWindow", {
        width = self.targetW, height = self.targetH,
        point = "CENTER", autoSize = false, clampToScreen = true,
        hasBackground = false, noBackground = true,
    })

    -- Background panel
    self.bg = Panel:New("RPE_IntroWindow_BG", {
        parent = self.root, width = BG_W, height = BG_H,
        autoSize = false, hasBackground = true, bgTexture = BG_TEXTURE,
        point = "CENTER", relativePoint = "CENTER",
    })
    self.root:Add(self.bg)
    self.bg.frame:SetBackdropColor(0.3,0.3,0.3,0.3)

    -- ===== Header (CENTERED IN WINDOW)
    local header = VGroup:New("RPE_Intro_Header", {
        parent=self.root, width=360, autoSize=true, alignH="CENTER", spacingY=2,
        point="CENTER", relativePoint="CENTER", x=0, y=0,
    })
    header:Add(Text:New("RPE_Intro_Title", {
        parent=header, text=HEADER_TEXT, fontTemplate="GameFontHighlightHuge", justifyH="CENTER",
    }))
    header.AddVersion = Text:New("RPE_Intro_Version", {
        parent=header, text=("v%s"):format(_getVersion()), fontTemplate="GameFontNormal", justifyH="CENTER",
    })
    header:Add(header.AddVersion)
    self.root:Add(header)

    -- Animation prep
    local f = self.root.frame
    f:SetFrameStrata("DIALOG")
    f:SetScale(0.01)
    f:SetAlpha(0)
end

-- Fade out then destroy the window
function IntroWindow:_fadeOutAndDestroy()
    local f = self.root and self.root.frame
    if not f then return end
    local elapsed, dur = 0, self.fadeOut
    f:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + (dt or 0)
        local t = elapsed / dur
        if t >= 1 then
            f:SetScript("OnUpdate", nil)
            if self.root.Destroy then self.root:Destroy() else self.root:Hide() end
            _G.RPE_UI.Windows.IntroWindow._instance = nil
            return
        end
        local a = 1 - t
        f:SetAlpha(a < 0 and 0 or a)
    end)
end

function IntroWindow:AnimateIn()
    local f = self.root and self.root.frame
    if not f then return end
    self.root:Show()

    local elapsed, dur = 0, self.duration
    f:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + (dt or 0)
        local t = elapsed / dur
        if t >= 1 then
            f:SetScript("OnUpdate", nil)
            f:SetScale(1); f:SetAlpha(1)
            -- Hold, then fade out & destroy
            if C_Timer and C_Timer.After then
                C_Timer.After(self.holdDur, function() self:_fadeOutAndDestroy() end)
            else
                -- Fallback: simple delay using OnUpdate
                local wait = 0
                f:SetScript("OnUpdate", function(_, ddt)
                    wait = wait + (ddt or 0)
                    if wait >= self.holdDur then
                        f:SetScript("OnUpdate", nil)
                        self:_fadeOutAndDestroy()
                    end
                end)
            end
            return
        end
        if t < 0 then t = 0 end
        local s = 0.01 + (1 - 0.01) * t
        f:SetScale(s); f:SetAlpha(t)
    end)
end

function IntroWindow.Ensure(opts)
    if IntroWindow._instance then return IntroWindow._instance end
    local self = setmetatable({}, IntroWindow)
    self:BuildUI(opts or {})
    IntroWindow._instance = self
    return self
end

-- Show on first relevant event
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
local fired = false
loader:SetScript("OnEvent", function(self)
    if fired then return end
    fired = true
    self:UnregisterAllEvents()
    local win = IntroWindow.Ensure({ width = WIN_W, height = WIN_H, duration = FADE_IN_DUR, hold = HOLD_DUR, fadeOut = FADE_OUT_DUR })
    win:AnimateIn()
end)
