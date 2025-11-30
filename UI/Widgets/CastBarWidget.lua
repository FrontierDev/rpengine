-- RPE_UI/Windows/CastBarWidget.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window      = RPE_UI.Elements.Window
local HGroup      = RPE_UI.Elements.HorizontalLayoutGroup
local ProgressBar = RPE_UI.Prefabs.ProgressBar

---@class CastBarWidget
---@field root Window
---@field content HGroup
---@field bar ProgressBar
---@field icon any
---@field currentCast table|nil
---@field castType string|nil
---@field totalTurns integer|nil
local CastBarWidget = {}
CastBarWidget.__index = CastBarWidget
RPE_UI.Windows.CastBarWidget = CastBarWidget
CastBarWidget.Name = "CastBarWidget"

function CastBarWidget:BuildUI()
    -- Root window (auto-sized, transparent background)
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_CastBar_Window", {
        parent   = parentFrame,
        width    = 1,
        height   = 1,
        autoSize = true,
        point    = "CENTER", x = 0, y = -180,
        noBackground = true,
    })

    -- Immersion polish (match UI scale + mouse gating on Alt+Z)
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

    -- Horizontal layout: icon left, bar right
    self.content = HGroup:New("RPE_CastBar_Content", {
        parent   = self.root,
        autoSize = true,
        spacingX = 6,
        alignV   = "CENTER",
    })
    self.root:Add(self.content)

    -- Spell icon (click to cancel)
    self.icon = RPE_UI.Elements.IconButton:New("RPE_CastBar_Icon", {
        parent = self.content,
        width  = 32,
        height = 32,
        noBackground = true,
        icon = 135274,
        hoverDarkenFactor = 0.90,
    })
    self.icon:SetOnClick(function()
        if self.currentCast then
            local ctx = { event = RPE.Core.ActiveEvent, resources = RPE.Core.Resources }
            self.currentCast:Interrupt(ctx, "Cancelled by player")
        end
    end)
    self.content:Add(self.icon)

    -- Cast progress bar
    self.bar = ProgressBar:New("RPE_CastBar_Progress", {
        parent = self.content,
        width  = 250,
        height = 14,
        style  = "progress_cast",
        animSpeed = 3
    })
    -- Styles for different states
    self.bar.styles = {
        default     = "progress_cast",
        interrupted = "progress_interrupted",
        full        = "progress_default",
    }
    self.content:Add(self.bar)

    RPE.Core.Windows.CastBarWidget = self
    self:Hide()
end

-- Public API ---------------------------------------------------------------

function CastBarWidget:Show()
    if self.root then
        self.root:Show()
        self.root:SetAlpha(1)
    end
end

function CastBarWidget:Hide() if self.root then self.root:Hide() end end

function CastBarWidget:Begin(cast, ctx)
    if not self.root then self:BuildUI() end
    self.currentCast = cast

    local ct = (cast.def and cast.def.cast) or { type = "INSTANT" }
    self.castType   = ct.type or "INSTANT"
    self.totalTurns = tonumber(ct.turns) or 0

    -- Set spell icon
    if self.icon and self.icon.SetIcon then
        self.icon:SetIcon((cast.def and cast.def.icon) or 135274)
    end

    -- Reset style
    self.bar:SetStyle(self.bar.styles.default)

    if self.castType == "INSTANT" then
        self.bar:SetValue(1, 1)
        self:Show()
        self.bar:TriggerFlash()
        self:FadeOut(0.5)
        return
    end

    local total     = (self.totalTurns > 0) and self.totalTurns or 1
    local remaining = cast.remainingTurns or total
    local done      = math.max(0, total - remaining)

    self.bar:SetValue(done, total)
    self:Show()
end

function CastBarWidget:Update(cast, ctx, currentTurn)
    -- For INSTANT casts, don't update (they flash immediately in Begin)
    if self.castType == "INSTANT" then 
        return 
    end

    -- If this is the displayed cast, update the UI
    if cast == self.currentCast then
        local total     = (self.totalTurns > 0) and self.totalTurns or 1
        local remaining = cast.remainingTurns or total
        local done      = math.max(0, total - remaining)

        self.bar:SetValue(done, total)
    end

    -- Check if this cast (displayed or hidden) is complete, and resolve it
    -- This allows player casts to complete even when an NPC cast is displayed
    local total     = (self.totalTurns > 0) and self.totalTurns or 1
    local remaining = cast.remainingTurns or total
    local done      = math.max(0, total - remaining)

    if done >= total then
        self:Finish(cast, ctx, currentTurn)
    end
end

function CastBarWidget:Finish(cast, ctx, currentTurn)
    
    -- Only update UI visually if this is the displayed cast
    if cast == self.currentCast then
        if self.castType ~= "INSTANT" then
            local total = (self.totalTurns > 0) and self.totalTurns or 1
            self.bar:SetStyle(self.bar.styles.full)
            self.bar:SetValue(total, total)
            self.bar:TriggerFlash()
        end
        self:FadeOut(0.8)
    end
    
    -- Always resolve the cast, regardless of whether it's displayed
    if cast and cast.Resolve then 
        cast:Resolve(ctx, currentTurn) 
    end
end

function CastBarWidget:Interrupt(cast, reason)
    if cast ~= self.currentCast then return end
    self.bar:SetStyle(self.bar.styles.interrupted)
    self.bar:SetValue(0, 1)
    self:FadeOut(0.8)
end

-- Utility: fade out then hide
function CastBarWidget:FadeOut(duration)
    duration = duration or 0.5
    local frame = self.root
    if not frame then return end
    
    -- Cancel any existing fade animation
    if self._fadeOutTicker then
        self._fadeOutTicker:Cancel()
        self._fadeOutTicker = nil
    end
    
    local alpha = 1
    frame:SetAlpha(alpha)
    self._fadeOutTicker = C_Timer.NewTicker(0.05, function(t)
        alpha = alpha - (0.05 / duration)
        if alpha <= 0 then
            frame:SetAlpha(0)
            frame:Hide()
            self.currentCast = nil
            t:Cancel()
            self._fadeOutTicker = nil
        else
            frame:SetAlpha(alpha)
        end
    end)
end

-- Immediately hide the cast bar (cancels any fade animations)
function CastBarWidget:ImmediateHide()
    if self._fadeOutTicker then
        self._fadeOutTicker:Cancel()
        self._fadeOutTicker = nil
    end
    if self.root then
        self.root:SetAlpha(0)
        self.root:Hide()
    end
    self.currentCast = nil
end

function CastBarWidget.New()
    local o = setmetatable({}, CastBarWidget)
    o:BuildUI()
    return o
end

return CastBarWidget
