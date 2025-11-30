-- RPE_UI/Elements/InputArea.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class InputArea: FrameElement
---@field scrollFrame ScrollFrame
---@field editBox EditBox
---@field placeholder FontString|nil
---@field onChanged fun(self:InputArea, text:string)|nil
local InputArea = setmetatable({}, { __index = FrameElement })
InputArea.__index = InputArea
RPE_UI.Elements.InputArea = InputArea

-- Internal --------------------------------------------------------------------
local function _updatePlaceholder(self)
    if not self.placeholder then return end
    local t = (self.editBox and self.editBox:GetText()) or ""
    if t == "" then self.placeholder:Show() else self.placeholder:Hide() end
end

local function _resizeChildWidth(self)
    if not (self.scrollFrame and self.editBox) then return end
    -- Allow a bit of padding and space for a visible scrollbar
    local pad = 8
    local sb = self.scrollFrame.ScrollBar
    local sbPad = (sb and sb:IsShown()) and 16 or 0
    local w = math.max(0, (self.scrollFrame:GetWidth() or 0) - pad - sbPad)
    self.editBox:SetWidth(w)
end

-- Public API ------------------------------------------------------------------
---@param name string
---@param opts table|nil -- { parent, width, height, text, placeholder, onChanged, autoFocus }
---@return InputArea
function InputArea:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = (opts.width and (opts.width ~= 1 and opts.width or 300)) or 300  -- "1" in your layout means "fill" visually; pick a sane default here
    local h = opts.height or 110

    -- Root frame
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    -- Subtle backdrop; your skin can override later
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 0.6)
        f:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
    end

    -- Scroll frame
    local sf = CreateFrame("ScrollFrame", name .. "_Scroll", f, "UIPanelScrollFrameTemplate")
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)

    -- Multiline edit box
    local eb = CreateFrame("EditBox", name .. "_EditBox", sf)
    eb:SetAutoFocus(opts.autoFocus or false)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal or GameFontHighlightSmall or GameFontNormal)
    eb:SetJustifyH("LEFT")      -- supported by EditBox
    eb:SetSpacing(2)            -- line spacing
    eb:EnableMouse(true)
    eb:SetText(opts.text or "")
    -- Width is managed dynamically; give it a starting width
    eb:SetWidth((w or 300) - 24)

    sf:SetScrollChild(eb)

    -- Placeholder (optional)
    local placeholder
    if opts.placeholder and opts.placeholder ~= "" then
        placeholder = f:CreateFontString(name .. "_Placeholder", "OVERLAY", "GameFontDisableSmall")
        placeholder:SetPoint("TOPLEFT", sf, "TOPLEFT", 8, -8)
        placeholder:SetJustifyH("LEFT")
        placeholder:SetText(opts.placeholder)
    end

    -- Wrap it in our element type
    local o = FrameElement.New(self, "InputArea", f, opts.parent)
    o.scrollFrame = sf
    o.editBox     = eb
    o.placeholder = placeholder
    o.onChanged   = opts.onChanged

    -- Scripts ----------------------------------------------------------------
    eb:SetScript("OnTextChanged", function(_, user)
        if o.onChanged then o.onChanged(o, eb:GetText() or "") end
        _updatePlaceholder(o)
        if user then _resizeChildWidth(o) end
    end)
    eb:SetScript("OnEscapePressed", function() eb:ClearFocus() end)

    -- Keep child width correct on size changes & scrollbar changes
    f:SetScript("OnSizeChanged", function() _resizeChildWidth(o) end)
    if sf.ScrollBar then
        sf.ScrollBar:HookScript("OnShow", function() _resizeChildWidth(o) end)
        sf.ScrollBar:HookScript("OnHide", function() _resizeChildWidth(o) end)
        sf.ScrollBar:HookScript("OnValueChanged", function() _resizeChildWidth(o) end)
    end

    -- Initial layout updates
    _resizeChildWidth(o)
    _updatePlaceholder(o)

    -- Public methods ---------------------------------------------------------
    function o:SetText(t)
        self.editBox:SetText(t or "")
        _updatePlaceholder(self)
    end

    function o:GetText()
        return self.editBox:GetText() or ""
    end

    function o:SetOnChanged(cb) self.onChanged = cb end

    function o:SetEnabled(enabled)
        enabled = not not enabled
        self.editBox:SetEnabled(enabled)
        self.editBox:EnableMouse(enabled)
        self.frame:SetAlpha(enabled and 1 or 0.6)
    end

    function o:SetPlaceholder(text)
        if not self.placeholder then
            self.placeholder = self.frame:CreateFontString(name .. "_Placeholder", "OVERLAY", "GameFontDisableSmall")
            self.placeholder:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 8, -8)
            self.placeholder:SetJustifyH("LEFT")
        end
        self.placeholder:SetText(text or "")
        _updatePlaceholder(self)
    end

    function o:Focus() self.editBox:SetFocus() end
    function o:ClearFocus() self.editBox:ClearFocus() end

    function o:SetSize(nw, nh)
        self.frame:SetSize(nw, nh or self.frame:GetHeight())
        -- After size settles, recompute child width next frame
        C_Timer.After(0, function()
            if self.scrollFrame and self.editBox then _resizeChildWidth(self) end
        end)
    end

    return o
end

return InputArea
