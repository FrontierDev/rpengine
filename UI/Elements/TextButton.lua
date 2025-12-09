-- RPE_UI/Elements/TextButton.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class TextButton: FrameElement
---@field frame Button
---@field bg Texture
---@field topBorder Texture
---@field bottomBorder Texture
---@field label FontString
---@field text string
---@field onClick fun(self:TextButton, button?:string)|nil
---@field _locked boolean
---@field _baseR number @cached base bg color
---@field _baseG number
---@field _baseB number
---@field _baseA number
---@field _hoverR number @cached hover bg color
---@field _hoverG number
---@field _hoverB number
---@field _hoverA number
---@field _textR number @cached normal text color
---@field _textG number
---@field _textB number
---@field _textA number
local TextButton = setmetatable({}, { __index = FrameElement })
TextButton.__index = TextButton
RPE_UI.Elements.TextButton = TextButton

function TextButton:New(name, opts)
    opts = opts or {}
    local parentFrame = (opts.parent and opts.parent.frame) or UIParent

    local f = CreateFrame("Button", name, parentFrame)
    f:SetSize(opts.width or 160, opts.height or 28)
    f:SetPoint(opts.point or "TOPLEFT", opts.relativeTo or parentFrame, opts.relativePoint or "TOPLEFT", opts.x or 0, opts.y or 0)
    f:RegisterForClicks("LeftButtonUp")
    f:SetMotionScriptsWhileDisabled(true)

    -- Background (full background color)
    local bgR, bgG, bgB, bgA = C.Get("background")
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(bgR, bgG, bgB, bgA)

    -- Borders (based on divider color)
    local divR, divG, divB, divA = C.Get("divider")
    local top, bottom
    if not opts.noBorder then
        top = f:CreateTexture(nil, "BORDER")
        top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        top:SetHeight(1)
        top:SetColorTexture(divR * 0.6, divG * 0.6, divB * 0.6, divA * 0.8)

        bottom = f:CreateTexture(nil, "BORDER")
        bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, -1)
        bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, -1)
        bottom:SetHeight(1)
        bottom:SetColorTexture(divR * 0.2, divG * 0.2, divB * 0.2, divA * 0.7)
    end
    
    -- Label (use text color from palette)
    local label = f:CreateFontString(nil, "OVERLAY", opts.fontTemplate or "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(opts.text or "")
    local txtR, txtG, txtB, txtA = C.Get("text")
    label:SetTextColor(txtR, txtG, txtB, txtA)

    ---@type TextButton
    local o = FrameElement.New(self, "TextButton", f, opts.parent)
    o.bg, o.topBorder, o.bottomBorder, o.label = bg, top, bottom, label
    o.text = opts.text
    o.onClick = opts.onClick
    o._locked = false

    -- Cache base colors for later use (e.g., highlight/unhighlight)
    o._baseR, o._baseG, o._baseB, o._baseA = bgR, bgG, bgB, bgA
    
    -- Cache hover colors
    o._hoverR, o._hoverG, o._hoverB, o._hoverA = C.Get("background")
    
    -- Cache text colors
    o._textR, o._textG, o._textB, o._textA = C.Get("text")

    -- Hover handlers (darken bg and border on hover)
    f:SetScript("OnEnter", function()
        if not o._locked then 
            local hBgR, hBgG, hBgB, hBgA = C.Get("background")
            o.bg:SetColorTexture(hBgR * 0.6, hBgG * 0.6, hBgB * 0.6, hBgA * 0.9)
            if o.topBorder then 
                local hDivR, hDivG, hDivB, hDivA = C.Get("divider")
                o.topBorder:SetColorTexture(hDivR * 0.4, hDivG * 0.4, hDivB * 0.4, hDivA * 0.6)
            end
        end
    end)
    f:SetScript("OnLeave", function()
        local bgR2, bgG2, bgB2, bgA2 = C.Get("background")
        o.bg:SetColorTexture(bgR2, bgG2, bgB2, bgA2)
        if o.topBorder then 
            local divR2, divG2, divB2, divA2 = C.Get("divider")
            o.topBorder:SetColorTexture(divR2 * 0.6, divG2 * 0.6, divB2 * 0.6, divA2 * 0.8)
        end
    end)

    f:SetScript("OnClick", function(_, btn)
        if o.onClick and not o._locked then
            PlaySoundFile("Interface\\UChatScrollButton", "Master")
            o.onClick(o, btn)
        end
    end)

    -- Register as palette consumer so it updates when palette changes
    C.RegisterConsumer(o)

    return o
end

-- Public API
function TextButton:SetText(text) self.label:SetText(text or "") end
function TextButton:SetOnClick(fn) self.onClick = fn end

function TextButton:ApplyPalette()
    -- Update text color
    local txtR, txtG, txtB, txtA = C.Get("text")
    if self.label then
        self.label:SetTextColor(txtR, txtG, txtB, txtA)
    end
    
    -- Update background and borders from palette
    if not self._locked then
        local bgR, bgG, bgB, bgA = C.Get("background")
        self.bg:SetColorTexture(bgR, bgG, bgB, bgA)
        
        if self.topBorder then
            local divR, divG, divB, divA = C.Get("divider")
            self.topBorder:SetColorTexture(divR * 0.6, divG * 0.6, divB * 0.6, divA * 0.8)
        end
        if self.bottomBorder then
            local divR, divG, divB, divA = C.Get("divider")
            self.bottomBorder:SetColorTexture(divR * 0.2, divG * 0.2, divB * 0.2, divA * 0.7)
        end
    else
        -- Locked state uses muted palette colors
        local mutedR, mutedG, mutedB, mutedA = C.Get("textMuted")
        self.bg:SetColorTexture(mutedR * 0.5, mutedG * 0.5, mutedB * 0.5, mutedA * 0.7)
        
        if self.topBorder then
            local divR, divG, divB, divA = C.Get("divider")
            self.topBorder:SetColorTexture(divR * 0.3, divG * 0.3, divB * 0.3, divA * 0.5)
        end
        if self.bottomBorder then
            local divR, divG, divB, divA = C.Get("divider")
            self.bottomBorder:SetColorTexture(divR * 0.1, divG * 0.1, divB * 0.1, divA * 0.3)
        end
    end
end

function TextButton:Lock()
    if self._locked then return end
    self._locked = true
    self.frame:Disable()

    local mutedR, mutedG, mutedB, mutedA = C.Get("textMuted")
    self.label:SetTextColor(mutedR, mutedG, mutedB, mutedA * 0.6)
    
    -- Use darkened muted color for locked bg
    self.bg:SetColorTexture(mutedR * 0.5, mutedG * 0.5, mutedB * 0.5, mutedA * 0.7)

    -- Use darkened divider color for locked borders
    if self.topBorder then
        local divR, divG, divB, divA = C.Get("divider")
        self.topBorder:SetColorTexture(divR * 0.3, divG * 0.3, divB * 0.3, divA * 0.5)
    end
    if self.bottomBorder then
        local divR, divG, divB, divA = C.Get("divider")
        self.bottomBorder:SetColorTexture(divR * 0.1, divG * 0.1, divB * 0.1, divA * 0.3)
    end
end

function TextButton:Unlock()
    if not self._locked then return end
    self._locked = false
    self.frame:Enable()

    local txtR, txtG, txtB, txtA = C.Get("text")
    self.label:SetTextColor(txtR, txtG, txtB, txtA)
    
    -- Restore normal bg from palette
    local bgR, bgG, bgB, bgA = C.Get("background")
    self.bg:SetColorTexture(bgR, bgG, bgB, bgA)

    -- Restore normal borders from palette
    if self.topBorder then
        local divR, divG, divB, divA = C.Get("divider")
        self.topBorder:SetColorTexture(divR * 0.6, divG * 0.6, divB * 0.6, divA * 0.8)
    end
    if self.bottomBorder then
        local divR, divG, divB, divA = C.Get("divider")
        self.bottomBorder:SetColorTexture(divR * 0.2, divG * 0.2, divB * 0.2, divA * 0.7)
    end
end

---Convenience: enable/disable a button
---@param enabled boolean
function TextButton:SetEnabled(enabled)
    if enabled then
        self:Unlock()
    else
        self:Lock()
    end
end

return TextButton
