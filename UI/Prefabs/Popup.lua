-- RPE_UI/Prefabs/Popup.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local Text     = RPE_UI.Elements.Text
local Button   = RPE_UI.Elements.TextButton
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HBorder  = RPE_UI.Elements.HorizontalBorder

---@class Popup
---@field overlay Frame
---@field root Window
---@field topBorder any
---@field bottomBorder any
---@field content Panel
---@field footer Panel
---@field title Text
---@field body Text
---@field input EditBox|nil
---@field inputArea Panel|nil
---@field mid VGroup
---@field btnPrimary any
---@field btnSecondary any
---@field _onAccept fun(text?:string)|nil
---@field _onCancel fun()|nil
---@field _onInputChanged fun(text:string)|nil
---@field _clickOffToClose boolean
local Popup = {}
Popup.__index = Popup
RPE_UI.Prefabs.Popup = Popup

-- Layout constants
local DEFAULT_WIDTH    = 420
local CONTENT_PAD      = 14
local BUTTON_H         = 26
local BUTTON_W_MIN     = 120
local BUTTON_GAP       = 16
local FOOTER_PADDING_Y = 10

local function _trim(s) if type(s)~="string" then return s end return (s:gsub("^%s+",""):gsub("%s+$","")) end

function Popup:_accept()
    local text = nil
    if self.input and self.input.GetText then text = _trim(self.input:GetText() or "") end
    if self._onAccept then pcall(self._onAccept, text) end
    self:Hide()
end
function Popup:_cancel()
    if self._onCancel then pcall(self._onCancel) end
    self:Hide()
end

-- Compute sizes and place buttons relative to footer center
function Popup:_autoResize()
    if self.mid   and self.mid.Relayout   then self.mid:Relayout() end

    local midW = (self.mid and self.mid.frame and self.mid.frame:GetWidth()) or 0
    local midH = (self.mid and self.mid.frame and self.mid.frame:GetHeight()) or 0

    local okW  = (self.btnPrimary   and self.btnPrimary.frame   and self.btnPrimary.frame:GetWidth())   or BUTTON_W_MIN
    local canW = (self.btnSecondary and self.btnSecondary.frame and self.btnSecondary.frame:GetWidth()) or BUTTON_W_MIN
    local rowW = okW + BUTTON_GAP + canW

    -- Desired window width: fit content OR buttons (whichever is wider)
    local cw = math.max(self._baseWidth, midW + CONTENT_PAD * 2, rowW + CONTENT_PAD * 2)
    local ch = midH + CONTENT_PAD * 2

    if self.content and self.content.SetSize then
        self.content:SetSize(cw, ch)
    end

    local ftrH = FOOTER_PADDING_Y * 2 + BUTTON_H
    if self.footer and self.footer.frame then
        self.footer.frame:SetHeight(ftrH)
    end

    if self.root and self.root.SetSize then
        self.root:SetSize(cw, ch + ftrH)
    end

    -- Center the button row precisely
    if self.btnPrimary and self.btnPrimary.frame and self.btnSecondary and self.btnSecondary.frame and self.footer then
        self.btnPrimary.frame:ClearAllPoints()
        self.btnSecondary.frame:ClearAllPoints()

        local halfGap = math.floor(BUTTON_GAP / 2)
        -- OK sits to the left of center
        self.btnPrimary.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "BOTTOM", -halfGap, FOOTER_PADDING_Y)
        -- Cancel sits to the right of center
        self.btnSecondary.frame:SetPoint("BOTTOMLEFT",  self.footer.frame, "BOTTOM",  halfGap, FOOTER_PADDING_Y)
    end
end

--- Create a new popup instance (window-style: top/bottom borders, content + footer).
--- opts: { title?, text?, showInput?, placeholder?, defaultText?, primaryText?, secondaryText?, clickOffToClose?, width? }
function Popup.New(opts)
    opts = opts or {}
    local self = setmetatable({}, Popup)

    -- Support custom parent frame (for Immersion mode)
    local parentFrame = opts.parentFrame or UIParent

    -- Modal overlay
    local overlay = CreateFrame("Frame", "RPE_UI_PopupOverlay_" .. tostring(math.random(1, 1e9)), parentFrame)
    overlay:SetAllPoints(parentFrame)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(1000)
    overlay:EnableMouse(true)
    overlay:EnableKeyboard(true)
    overlay:SetPropagateKeyboardInput(false)
    
    -- Handle Immersion mode scaling
    if parentFrame == WorldFrame then
        overlay:SetIgnoreParentScale(true)
        local function SyncScale()
            overlay:SetScale(UIParent and UIParent:GetScale() or 1)
        end
        SyncScale()
        UIParent:HookScript("OnShow", SyncScale)
    end

    local obg = overlay:CreateTexture(nil, "BACKGROUND")
    obg:SetAllPoints(overlay)
    obg:SetColorTexture(0, 0, 0, 0.45)

    overlay:SetScript("OnMouseDown", function()
        if self._clickOffToClose then self:_cancel() end
    end)

    self._baseWidth = tonumber(opts.width) or DEFAULT_WIDTH

    -- Root window (fixed width, autosized height)
    local root = Window:New("RPE_UI_PopupRoot_" .. tostring(math.random(1, 1e9)), {
        parent   = overlay,
        width    = self._baseWidth,
        height   = 100, -- minimal; will be resized
        point    = "CENTER",
        autoSize = false,
    })
    if root.frame then
        root.frame:SetFrameStrata("DIALOG")
        root.frame:SetFrameLevel(overlay:GetFrameLevel() + 1)
        root.frame:EnableKeyboard(true)
        root.frame:SetPropagateKeyboardInput(false)
        root.frame:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then self:_cancel()
            elseif key == "ENTER" then self:_accept() end
        end)
    end

    -- Top border
    local topBorder = HBorder:New("RPE_UI_PopupTopBorder", {
        parent    = root,
        stretch   = true,
        thickness = 5,
        y         = 0,
        layer     = "BORDER",
    })
    topBorder.frame:ClearAllPoints()
    topBorder.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    topBorder.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
        RPE_UI.Colors.ApplyHighlight(topBorder)
    end

    -- Bottom border
    local bottomBorder = HBorder:New("RPE_UI_PopupBottomBorder", {
        parent    = root,
        stretch   = true,
        thickness = 5,
        y         = 0,
        layer     = "BORDER",
    })
    bottomBorder.frame:ClearAllPoints()
    bottomBorder.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT",  0, 0)
    bottomBorder.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)
    if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
        RPE_UI.Colors.ApplyHighlight(bottomBorder)
    end

    -- Content panel (fills space above footer)
    local content = Panel:New("RPE_UI_PopupContent", {
        parent   = root,
        autoSize = true,
    })
    root:Add(content)
    content.frame:ClearAllPoints()
    content.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    content.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    content.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT", 0, 0) -- replaced after footer exists
    content.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer (button row lives here)
    local footer = Panel:New("RPE_UI_PopupFooter", {
        parent   = root,
        autoSize = false,
    })
    root:Add(footer)
    footer.frame:ClearAllPoints()
    footer.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT", 0, 0)
    footer.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)
    footer.frame:SetHeight(FOOTER_PADDING_Y * 2 + BUTTON_H)

    -- Re-anchor content above footer (DiaryWindow style)
    content.frame:ClearAllPoints()
    content.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    content.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    content.frame:SetPoint("BOTTOMLEFT",  footer.frame, "TOPLEFT", 0, 0)
    content.frame:SetPoint("BOTTOMRIGHT", footer.frame, "TOPRIGHT", 0, 0)

    -- Centered stack in content
    local mid = VGroup:New("RPE_UI_PopupMid", {
        parent        = content,
        spacingY      = 10,
        paddingLeft   = CONTENT_PAD,
        paddingRight  = CONTENT_PAD,
        paddingTop    = CONTENT_PAD + 6,
        paddingBottom = CONTENT_PAD + 6,
        autoSize      = true,
        alignH        = "CENTER",
    })
    content:Add(mid)
    mid.frame:ClearAllPoints()
    mid.frame:SetPoint("CENTER", content.frame, "CENTER", 0, 0)

    -- Title (centered)
    local title = Text:New("RPE_UI_PopupTitle", {
        parent = mid,
        text   = tostring(opts.title or "Confirm"),
    })
    if title.SetJustifyH then title:SetJustifyH("CENTER") end
    mid:Add(title)

    -- Body text (centered)
    local body = Text:New("RPE_UI_PopupBody", {
        parent = mid,
        text   = tostring(opts.text or ""),
        wrap   = true,
    })
    if body.SetJustifyH then body:SetJustifyH("CENTER") end
    mid:Add(body)

    -- Optional input (centered)
    local inputBox = nil
    if opts.showInput then
        local holder = Panel:New("RPE_UI_PopupInputHolder", { parent = mid, autoSize = false })
        mid:Add(holder)

        local ebW = math.max(260, self._baseWidth - (CONTENT_PAD * 2) - 40)
        holder.frame:SetSize(ebW, 28)

        local eb = CreateFrame("EditBox", nil, holder.frame, "InputBoxTemplate")
        eb:SetAutoFocus(true)
        eb:SetSize(ebW, 24)
        eb:ClearAllPoints()
        eb:SetPoint("CENTER", holder.frame, "CENTER", 0, 0)
        eb:SetJustifyH("CENTER")
        eb:SetTextInsets(6, 6, 2, 2)
        if opts.defaultText then eb:SetText(tostring(opts.defaultText)); eb:HighlightText() end
        eb:SetScript("OnEscapePressed", function() self:_cancel() end)
        eb:SetScript("OnEnterPressed",  function() self:_accept() end)
        inputBox = eb

        if opts.placeholder and opts.placeholder ~= "" then
            local ph = holder.frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            ph:SetPoint("CENTER", eb, "CENTER", 0, 0)
            ph:SetText(opts.placeholder)
            ph:SetAlpha((eb:GetText() or "") == "" and 0.7 or 0)
            eb:HookScript("OnTextChanged", function()
                ph:SetAlpha((eb:GetText() or "") == "" and 0.7 or 0)
            end)
        end
        
        -- Hook input changes to fire the callback
        eb:HookScript("OnTextChanged", function()
            if self._onInputChanged then
                pcall(self._onInputChanged, eb:GetText() or "")
            end
        end)
    end

    -- Buttons (manual placement, centered around footer center)
    local halfW = math.max(BUTTON_W_MIN, math.floor((self._baseWidth - (CONTENT_PAD * 2) - BUTTON_GAP) * 0.5))

    local btnPrimary = Button:New("RPE_UI_PopupPrimary", {
        parent  = footer,
        width   = halfW,
        height  = BUTTON_H,
        text    = tostring(opts.primaryText or (opts.showInput and "OK" or "Yes")),
        onClick = function() self:_accept() end,
    })

    local btnSecondary = Button:New("RPE_UI_PopupSecondary", {
        parent  = footer,
        width   = halfW,
        height  = BUTTON_H,
        text    = tostring(opts.secondaryText or "Cancel"),
        onClick = function() self:_cancel() end,
    })

    -- Store refs
    self.overlay      = overlay
    self.root         = root
    self.topBorder    = topBorder
    self.bottomBorder = bottomBorder
    self.content      = content
    self.footer       = footer
    self.mid          = mid
    self.title        = title
    self.body         = body
    self.input        = inputBox
    self.btnPrimary   = btnPrimary
    self.btnSecondary = btnSecondary
    self._clickOffToClose = not not opts.clickOffToClose

    -- Final auto sizing + precise button anchors
    self:_autoResize()

    -- Start hidden
    self:Hide()
    return self
end

function Popup:SetTitle(text)  if self.title and self.title.SetText then self.title:SetText(tostring(text or "")) self:_autoResize() end end
function Popup:SetText(text)   if self.body  and self.body.SetText  then self.body:SetText(tostring(text or ""))   self:_autoResize() end end
function Popup:SetButtons(primaryText, secondaryText)
    if primaryText  and self.btnPrimary   and self.btnPrimary.SetText   then self.btnPrimary:SetText(primaryText)   end
    if secondaryText and self.btnSecondary and self.btnSecondary.SetText then self.btnSecondary:SetText(secondaryText) end
    self:_autoResize()
end
function Popup:SetCallbacks(onAccept, onCancel) self._onAccept = onAccept; self._onCancel = onCancel end
function Popup:SetInputChanged(onInputChanged) self._onInputChanged = onInputChanged end
function Popup:SetInputText(text) if self.input and self.input.SetText then self.input:SetText(tostring(text or "")) end end
function Popup:FocusInput() if self.input and self.input.SetFocus then self.input:SetFocus() end end

function Popup:Show()
    if self.overlay then self.overlay:Show() end
    if self.root and self.root.Show then self.root:Show() end
    if self.input and self.input.SetFocus then self.input:SetFocus() end
end
function Popup:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
    if self.overlay then self.overlay:Hide() end
end
function Popup:Destroy()
    if self.overlay then self.overlay:Hide(); self.overlay:SetParent(nil); self.overlay = nil end
    self.root, self.topBorder, self.bottomBorder = nil, nil, nil
    self.content, self.footer, self.mid = nil, nil, nil
    self.title, self.body, self.input = nil, nil, nil
    self.btnPrimary, self.btnSecondary = nil, nil
end

-- Convenience helpers -------------------------------------------------------

function Popup.Confirm(title, text, onAccept, onCancel)
    local p = Popup.New({ title = title, text = text, showInput = false })
    p:SetCallbacks(onAccept, onCancel)
    p:Show()
    return p
end

function Popup.Prompt(title, text, defaultText, onAccept, onCancel)
    local p = Popup.New({
        title        = title,
        text         = text,
        showInput    = true,
        defaultText  = defaultText or "",
        primaryText  = "OK",
        secondaryText= "Cancel",
    })
    p:SetCallbacks(onAccept, onCancel)
    p:Show()
    return p
end

return Popup
