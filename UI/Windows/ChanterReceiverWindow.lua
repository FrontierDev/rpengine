-- RPE_UI/Windows/ChanterReceiverWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local Text     = RPE_UI.Elements.Text
local Button   = RPE_UI.Elements.TextButton
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local HBorder  = RPE_UI.Elements.HorizontalBorder

local Colors   = RPE_UI.Colors
local Common   = _G.RPE_UI and _G.RPE_UI.Common

---@class ChanterReceiverWindow
---@field Name string
---@field root Window
---@field content Panel
---@field footer Panel
---@field body VGroup
---@field leaderText Text
---@field respText Text
---@field acceptBtn Button
---@field declineBtn Button
---@field onAccept fun(self:ChanterReceiverWindow)|nil
---@field onDecline fun(self:ChanterReceiverWindow)|nil
local ChanterReceiverWindow = {}
ChanterReceiverWindow.__index = ChanterReceiverWindow
RPE_UI.Windows.ChanterReceiverWindow = ChanterReceiverWindow

ChanterReceiverWindow.Name = "ChanterReceiverWindow"

-- Layout constants
local DEFAULT_WIDTH    = 520
local CONTENT_PAD      = 14
local BUTTON_H         = 26
local BUTTON_W         = 120
local BUTTON_GAP       = 20
local FOOTER_PADDING_Y = 10

-- Build UI -------------------------------------------------------------------
function ChanterReceiverWindow:BuildUI(opts)
    opts = opts or {}
    local parent = UIParent

    -- Root window
    local root = Window:New("RPE_ChanterReceiver_Window", {
        parent   = parent,
        width    = DEFAULT_WIDTH,
        height   = 200,
        point    = "CENTER",
        autoSize = false,
    })

    -- Top border
    local topBorder = HBorder:New("RPE_ChanterReceiver_TopBorder", {
        parent    = root,
        stretch   = true,
        thickness = 5,
        y         = 0,
        layer     = "BORDER",
    })
    topBorder.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    topBorder.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    if Colors and Colors.ApplyHighlight then Colors.ApplyHighlight(topBorder) end

    -- Bottom border
    local bottomBorder = HBorder:New("RPE_ChanterReceiver_BottomBorder", {
        parent    = root,
        stretch   = true,
        thickness = 5,
        y         = 0,
        layer     = "BORDER",
    })
    bottomBorder.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT",  0, 0)
    bottomBorder.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)
    if Colors and Colors.ApplyHighlight then Colors.ApplyHighlight(bottomBorder) end

    -- Content panel
    local content = Panel:New("RPE_ChanterReceiver_Content", { parent = root, autoSize = true })
    root:Add(content)
    content.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    content.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    content.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT", 0, 0)
    content.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer
    local footer = Panel:New("RPE_ChanterReceiver_Footer", { parent = root, autoSize = false })
    root:Add(footer)
    footer.frame:SetHeight(FOOTER_PADDING_Y * 2 + BUTTON_H)
    footer.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT", 0, 0)
    footer.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)

    -- Re-anchor content above footer
    content.frame:ClearAllPoints()
    content.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    content.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    content.frame:SetPoint("BOTTOMLEFT",  footer.frame, "TOPLEFT", 0, 0)
    content.frame:SetPoint("BOTTOMRIGHT", footer.frame, "TOPRIGHT", 0, 0)

    -- Body group inside content
    local body = VGroup:New("RPE_ChanterReceiver_Body", {
        parent        = content,
        spacingY      = 12,
        paddingLeft   = CONTENT_PAD,
        paddingRight  = CONTENT_PAD,
        paddingTop    = CONTENT_PAD,
        paddingBottom = CONTENT_PAD,
        autoSize      = true,
        alignH        = "LEFT",
    })
    content:Add(body)

    -- Leader line
    body:Add(Text:New("RPE_ChanterReceiver_LeaderLabel", {
        parent = body, text = "Leader Line", fontTemplate = "GameFontNormal",
    }))
    self.leaderText = Text:New("RPE_ChanterReceiver_LeaderText", {
        parent = body, text = opts.leaderText or "—", wrap = true,
    })
    body:Add(self.leaderText)

    -- Response line
    body:Add(Text:New("RPE_ChanterReceiver_ResponseLabel", {
        parent = body, text = "Party Response", fontTemplate = "GameFontNormal",
    }))
    self.respText = Text:New("RPE_ChanterReceiver_ResponseText", {
        parent = body, text = opts.responseText or "—", wrap = true,
    })
    body:Add(self.respText)

    -- Footer buttons
    self.acceptBtn = Button:New("RPE_ChanterReceiver_Accept", {
        parent = footer,
        width  = BUTTON_W, height = BUTTON_H,
        text   = "Accept",
        onClick = function()
            if self.onAccept then self.onAccept(self) end
            self:Hide()
        end,
    })
    self.declineBtn = Button:New("RPE_ChanterReceiver_Decline", {
        parent = footer,
        width  = BUTTON_W, height = BUTTON_H,
        text   = "Decline",
        onClick = function()
            if self.onDecline then self.onDecline(self) end
            self:Hide()
        end,
    })

    -- Center them like Popup
    self.acceptBtn.frame:ClearAllPoints()
    self.declineBtn.frame:ClearAllPoints()
    local halfGap = math.floor(BUTTON_GAP / 2)
    self.acceptBtn.frame:SetPoint("BOTTOMRIGHT", footer.frame, "BOTTOM", -halfGap, FOOTER_PADDING_Y)
    self.declineBtn.frame:SetPoint("BOTTOMLEFT", footer.frame, "BOTTOM",  halfGap, FOOTER_PADDING_Y)

    -- Store refs
    self.root    = root
    self.content = content
    self.footer  = footer
    self.body    = body

    if Common and Common.RegisterWindow then
        Common:RegisterWindow(self)
    end
end

-- Lifecycle ------------------------------------------------------------------
function ChanterReceiverWindow.New(opts)
    local self = setmetatable({}, ChanterReceiverWindow)
    self:BuildUI(opts or {})
    return self
end
function ChanterReceiverWindow:Show() if self.root then self.root:Show() end end
function ChanterReceiverWindow:Hide() if self.root then self.root:Hide() end end

return ChanterReceiverWindow
