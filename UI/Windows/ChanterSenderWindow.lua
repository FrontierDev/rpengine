-- RPE_UI/Windows/ChanterSenderWindow.lua
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
local Input    = RPE_UI.Elements.Input

local Colors   = RPE_UI.Colors
local Common   = _G.RPE_UI and _G.RPE_UI.Common

---@class ChanterSenderWindow
---@field root Window
---@field content Panel
---@field footer Panel
---@field body VGroup
---@field modeRow HGroup
---@field _modeBtns table<string, any>
---@field senderInput Input
---@field respInput Input
---@field readyBtn Button
---@field sendBtn Button
local ChanterSenderWindow = {}
ChanterSenderWindow.__index = ChanterSenderWindow
RPE_UI.Windows.ChanterSenderWindow = ChanterSenderWindow

ChanterSenderWindow.Name = "ChanterSenderWindow"

-- Layout constants
local DEFAULT_WIDTH    = 520
local CONTENT_PAD      = 20
local BUTTON_H         = 26
local BUTTON_W         = 120
local BUTTON_GAP       = 20
local FOOTER_PADDING_Y = 10

-- Internal -------------------------------------------------------------------
local function _setMode(self, mode)
    self.mode = mode
    for k, b in pairs(self._modeBtns or {}) do
        if b.SetEnabled then b:SetEnabled(k ~= mode) end
    end
end

-- API ------------------------------------------------------------------------
function ChanterSenderWindow:GetMode() return self.mode end
function ChanterSenderWindow:GetLeaderText() return self.senderInput:GetText() end
function ChanterSenderWindow:GetResponseText() return self.respInput:GetText() end
function ChanterSenderWindow:SetReadyEnabled(b) if self.readyBtn then self.readyBtn:SetEnabled(b) end end
function ChanterSenderWindow:SetSendEnabled(b)  if self.sendBtn then  self.sendBtn:SetEnabled(b)  end end

-- Build UI -------------------------------------------------------------------
function ChanterSenderWindow:BuildUI(opts)
    opts = opts or {}
    local parent = UIParent

    -- Root window
    local root = Window:New("RPE_ChanterSender_Window", {
        parent   = parent,
        width    = DEFAULT_WIDTH,
        height   = 200,
        point    = "CENTER",
        autoSize = false,
    })

    -- Top border
    local topBorder = HBorder:New("RPE_ChanterSender_TopBorder", {
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
    local bottomBorder = HBorder:New("RPE_ChanterSender_BottomBorder", {
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
    local content = Panel:New("RPE_ChanterSender_Content", { parent = root, autoSize = true })
    root:Add(content)
    content.frame:SetPoint("TOPLEFT",  root.frame, "TOPLEFT",  0, 0)
    content.frame:SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", 0, 0)
    content.frame:SetPoint("BOTTOMLEFT",  root.frame, "BOTTOMLEFT", 0, 0)
    content.frame:SetPoint("BOTTOMRIGHT", root.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer
    local footer = Panel:New("RPE_ChanterSender_Footer", { parent = root, autoSize = false })
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
    local body = VGroup:New("RPE_ChanterSender_Body", {
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

    -- Mode row
    local modeRow = HGroup:New("RPE_ChanterSender_ModeRow", {
        parent   = body,
        spacingX = 8,
        alignV   = "CENTER",
        alignH   = "CENTER",
        autoSize = true,
    })
    body:Add(modeRow)

    self._modeBtns = {}
    local function addModeBtn(key, label)
        local btn = Button:New("RPE_ChanterSender_Mode_" .. key, {
            parent = modeRow,
            height = BUTTON_H, width = 110,
            text   = label,
            onClick = function() _setMode(self, key) end,
        })
        modeRow:Add(btn)
        self._modeBtns[key] = btn
    end
    addModeBtn("EMOTE", "Emote")
    addModeBtn("SAY",   "Say")
    addModeBtn("YELL",  "Yell")
    _setMode(self, "EMOTE")

    -- Leader input
    body:Add(Text:New("RPE_ChanterSender_LeaderLabel", {
        parent = body, text = "Leader Line", fontTemplate = "GameFontNormal",
    }))
    self.senderInput = Input:New("RPE_ChanterSender_SenderInput", {
        parent = body, width = DEFAULT_WIDTH - (CONTENT_PAD * 2), height = 26,
    })
    body:Add(self.senderInput)

    -- Response input
    body:Add(Text:New("RPE_ChanterSender_ResponseLabel", {
        parent = body, text = "Party Response", fontTemplate = "GameFontNormal",
    }))
    self.respInput = Input:New("RPE_ChanterSender_ResponseInput", {
        parent = body, width = DEFAULT_WIDTH - (CONTENT_PAD * 2), height = 26,
    })
    body:Add(self.respInput)

    -- Footer buttons
    self.readyBtn = Button:New("RPE_ChanterSender_Ready", {
        parent = footer,
        width  = BUTTON_W, height = BUTTON_H,
        text   = "Ready",
        onClick = function()
            local payload = {
                mode        = self.mode,
                leaderText  = self:GetLeaderText(),
                responseText= self:GetResponseText(),
            }
            self._responses = {}

            self._reqId = RPE.Core.Comms.Request:CheckChanter(payload, function(responses, sender)
                self._responses = self._responses or {}
                self._responses[sender:lower()] = (responses == "yes")

                local allAnswered = true
                local declined = {}
                local members = RPE.Core.ActiveSupergroup and RPE.Core.ActiveSupergroup:GetMembers() or {}

                for _, member in ipairs(members) do
                    if self._responses[member] == nil then
                        allAnswered = false
                    elseif not self._responses[member] then
                        -- strip realm name for display
                        local shortName = member:gsub("%-.*", "")
                        table.insert(declined, shortName)
                    end
                end

                if allAnswered then
                    self:SetSendEnabled(true)

                    if #declined > 0 and RPE.Debug and RPE.Debug.Warning then
                        RPE.Debug:Warning("[Chanter] Declined: " .. table.concat(declined, ", "))
                    end
                end
            end,

            function(missing)
                self:SetSendEnabled(false)
            end)
        end,
    })



    self.sendBtn = Button:New("RPE_ChanterSender_Send", {
        parent = footer,
        width  = BUTTON_W, height = BUTTON_H,
        text   = "Send",
        onClick = function()
            if not self._reqId then return end
            local payload = {
                mode        = self.mode,
                leaderText  = self:GetLeaderText(),
                responseText= self:GetResponseText(),
            }
            RPE.Core.Comms.Request:ChanterPerform(self._reqId, payload)
        end,
    })


    -- Center them like Popup
    self.readyBtn.frame:ClearAllPoints()
    self.sendBtn.frame:ClearAllPoints()
    local halfGap = math.floor(BUTTON_GAP / 2)
    self.readyBtn.frame:SetPoint("BOTTOMRIGHT", footer.frame, "BOTTOM", -halfGap, FOOTER_PADDING_Y)
    self.sendBtn.frame:SetPoint("BOTTOMLEFT",   footer.frame, "BOTTOM",  halfGap, FOOTER_PADDING_Y)

    -- Store refs
    self.root    = root
    self.content = content
    self.footer  = footer
    self.body    = body
    self.modeRow = modeRow

    self:SetSendEnabled(false)
    self:SetReadyEnabled(true)

    if Common and Common.RegisterWindow then
        Common:RegisterWindow(self)
    end
end

-- Lifecycle ------------------------------------------------------------------
function ChanterSenderWindow.New(opts)
    local self = setmetatable({}, ChanterSenderWindow)
    self:BuildUI(opts or {})
    return self
end
function ChanterSenderWindow:Show() if self.root then self.root:Show() end end
function ChanterSenderWindow:Hide() if self.root then self.root:Hide() end end

return ChanterSenderWindow
