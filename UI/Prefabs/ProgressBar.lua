-- RPE_UI/Prefabs/ProgressBar.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C            = RPE_UI.Colors

---@class ProgressBar: FrameElement
---@field frame Frame
---@field bg Texture
---@field fill Texture
---@field label FontString|nil
---@field value number
---@field targetValue number
---@field max number
---@field styles table<string,string>|nil
---@field flash Texture|nil
---@field flashAlpha number
---@field _animSpeed number
local ProgressBar = setmetatable({}, { __index = FrameElement })
ProgressBar.__index = ProgressBar
RPE_UI.Prefabs.ProgressBar = ProgressBar

---@param name string
---@param opts table|nil
---@return ProgressBar
function ProgressBar:New(name, opts)
    opts = opts or {}
    local parentFrame = opts.parent and opts.parent.frame or UIParent

    local f = CreateFrame("Frame", name, parentFrame)
    f:SetSize(opts.width or 200, opts.height or 20)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parentFrame, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    C.ApplyBackground(bg)

    -- Fill
    local fill = f:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", f, "LEFT", 0, 0)
    fill:SetHeight(f:GetHeight())

    -- Resolve initial color (style or custom fillColor)
    local fr, fg, fb, fa
    if opts.fillColor then
        fr, fg, fb, fa = unpack(opts.fillColor)
    else
        local styleKey = opts.style or "default"
        fr, fg, fb, fa = C.Get("progress_" .. styleKey)
    end
    fill:SetColorTexture(fr, fg, fb, fa)

    -- Label
    local label
    if opts.showLabel ~= false then
        label = f:CreateFontString(nil, "OVERLAY", opts.fontTemplate or "GameFontNormalSmall")
        label:SetPoint("CENTER")
        C.ApplyText(label)
        label:SetText(opts.text or "")
    end

    -- Flash overlay (white, additive blend)
    local flash = f:CreateTexture(nil, "OVERLAY")
    flash:SetAllPoints()
    flash:SetColorTexture(1, 1, 1, 0)
    flash:SetBlendMode("ADD")

    ---@type ProgressBar
    local o = FrameElement.New(self, "ProgressBar", f, opts.parent)
    o.bg, o.fill, o.label, o.flash = bg, fill, label, flash
    o.value, o.max = 0, 1
    o.targetValue  = 0
    o._animSpeed   = opts.animSpeed or 10
    o.flashAlpha   = 0

    -- State styles
    o.styles = opts.styles or { default = opts.style or "default" }
    o.customColor = nil  -- Track if a custom color has been set
    o:SetStyle(o.styles.default)

    -- Animation driver
    f:SetScript("OnUpdate", function(_, elapsed)
        o:UpdateAnimation(elapsed)
    end)

    return o
end

--- Animate towards new value (does not snap immediately)
function ProgressBar:SetValue(v, max)
    if max then self.max = max end
    v = math.max(0, math.min(v or 0, self.max))

    -- Trigger flash if value increased
    if v > (self.targetValue or 0) then
        self:TriggerFlash()
    end

    self.targetValue = v
end

--- Smooth animation update
function ProgressBar:UpdateAnimation(elapsed)
    if not self.max then return end
    
    -- Handle zero max gracefully: still update label
    if self.max > 0 then
        -- Smooth value
        local diff = (self.targetValue or 0) - (self.value or 0)
        if math.abs(diff) > 0.5 then
            self.value = (self.value or 0) + diff * math.min(1, elapsed * self._animSpeed)
        else
            self.value = self.targetValue
        end

        local pct = self.value / self.max
        local w   = self.frame:GetWidth() * pct
        self.fill:SetWidth(w)

        -- auto style switching
        if self.value <= 0 and self.styles.empty then
            self:SetStyle(self.styles.empty)
        elseif self.value >= self.max and self.styles.full then
            self:SetStyle(self.styles.full)
        else
            self:SetStyle(self.styles.default)
        end
    else
        -- max is 0, set fill to 0 width
        self.fill:SetWidth(0)
        if self.styles.empty then
            self:SetStyle(self.styles.empty)
        end
    end

    if self.label then
        self.label:SetText(("%d / %d"):format(math.floor(self.value + 0.5), self.max))
    end

    -- Flash fadeout
    if self.flashAlpha > 0 then
        self.flashAlpha = self.flashAlpha - elapsed * 2.5
        if self.flashAlpha < 0 then self.flashAlpha = 0 end
        self.flash:SetAlpha(self.flashAlpha)
    end
end

--- Explicitly change fill color by RGBA (takes precedence over styles)
function ProgressBar:SetColor(r, g, b, a)
    self.customColor = {r, g, b, a or 1}
    self.fill:SetColorTexture(r, g, b, a or 1)
end

--- Apply a style key (from RPE_UI.Colors palette, only if no custom color is set)
function ProgressBar:SetStyle(style)
    if self.customColor then return end  -- Don't override custom colors with styles
    local key = (style or "default")
    local r,g,b,a = C.Get(key)
    self.fill:SetColorTexture(r, g, b, a or 1)
end

--- Trigger an interrupted state
function ProgressBar:Interrupt()
    if self.styles.interrupted then
        self:SetStyle(self.styles.interrupted)
    end
end

function ProgressBar:SetText(txt)
    if self.label then self.label:SetText(txt or "") end
end

--- Brief flash overlay (on heal/gain)
function ProgressBar:TriggerFlash()
    self.flashAlpha = 0.8
    self.flash:SetAlpha(self.flashAlpha)
end

return ProgressBar
