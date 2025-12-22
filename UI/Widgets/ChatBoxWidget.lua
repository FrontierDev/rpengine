-- RPE_UI/Windows/ChatBoxWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window       = RPE_UI.Elements.Window
local FrameElement = RPE_UI.Elements.FrameElement
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local Panel        = RPE_UI.Elements.Panel
local Text         = RPE_UI.Elements.Text
local TextButton   = RPE_UI.Elements.TextButton
local IconButton   = RPE_UI.Elements.IconButton
local C            = RPE_UI.Colors

---@class ChatBoxWidget
---@field root Window
---@field content HGroup
---@field chrome Frame
---@field channelBtn TextButton
---@field targetEdit EditBox
---@field msgEdit EditBox
---@field sendBtn TextButton
---@field currentChannel string      -- "SAY","YELL","EMOTE","PARTY","RAID","INSTANCE_CHAT","GUILD","OFFICER","WHISPER"
---@field currentTarget string|nil   -- whisper target (Name-Realm)
---@field currentLanguage string|nil
---@field history string[]
---@field historyIndex integer
---@field log ScrollingMessageFrame
---@field logHeight integer
---@field listener Frame
local ChatBoxWidget = {}
_G.RPE_UI.Windows.ChatBoxWidget = ChatBoxWidget
ChatBoxWidget.__index = ChatBoxWidget
ChatBoxWidget.Name = "ChatBoxWidget"

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.ChatBoxWidget = self
end

-- ========= utilities =========

local function FadeInFrame(frame, duration)
    if not frame then return end
    frame:SetAlpha(0)
    frame:Show()
    UIFrameFadeIn(frame, duration or 0.25, 0, 1)
end

local function GetColor(key, fallback)
    if C and C.Get then
        local r,g,b,a = C.Get(key)
        return r or fallback[1], g or fallback[2], b or fallback[3], a or fallback[4]
    end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

-- Clipboard widget for displaying copied content
local Clipboard = RPE_UI.Windows.Clipboard

-- ========= chrome (background panel) =========

function ChatBoxWidget:_EnsureChrome()
    if self.chrome and self.chrome:IsObjectType("Frame") then return end
    local parent = self.root and self.root.frame or UIParent
    local f = CreateFrame("Frame", "RPE_ChatBox_Chrome", parent)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((parent:GetFrameLevel() or 0) + 1)
    self.chrome = f

    -- background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    do
        local r,g,b,a = GetColor("background", {0.06,0.06,0.06,0.92})
        bg:SetColorTexture(r, g, b, a)
    end

    -- edges
    local top = f:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    top:SetHeight(1)
    C.ApplyDivider(top)

    local bot = f:CreateTexture(nil, "BORDER")
    bot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    bot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    bot:SetHeight(1)
    local dr,dg,db,da = C.Get and C.Get("divider") or 1,1,1,0.4
    if type(dr) == "number" then
        bot:SetColorTexture(dr*0.5, dg*0.5, db*0.5, da or 0.4)
    else
        bot:SetColorTexture(0,0,0,0.4)
    end

    -- gloss
    local gloss = f:CreateTexture(nil, "ARTWORK")
    gloss:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    gloss:SetHeight(12)
    local hr,hg,hb,ha = C.Get and C.Get("highlight") or 1,1,1,0.07
    if type(hr) == "number" then
        gloss:SetColorTexture(hr, hg, hb, (ha or 0.07))
    else
        gloss:SetColorTexture(1,1,1,0.07)
    end

    f._bg = bg; f._top = top; f._bot = bot; f._gloss = gloss
end

-- ========= internals =========

local CHANNELS = { "SAY", "YELL", "EMOTE", "PARTY", "RAID", "GUILD", "OFFICER", "WHISPER" }
local CHANNEL_LABEL = {
    SAY = "Say", YELL = "Yell", EMOTE = "Emote",
    PARTY = "Party", RAID = "Raid",
    GUILD = "Guild", OFFICER = "Officer", WHISPER = "Whisper",
}

local function nextChannel(cur)
    for i, k in ipairs(CHANNELS) do
        if k == cur then
            return CHANNELS[(i % #CHANNELS) + 1]
        end
    end
    return CHANNELS[1]

end

local function prevChannel(cur)
    for i, k in ipairs(CHANNELS) do
        if k == cur then
            return CHANNELS[((i - 2) % #CHANNELS) + 1]
        end
    end
    return CHANNELS[#CHANNELS]
end

-- ========= sending =========

function ChatBoxWidget:_DoSend(text)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end

    -- If it's a slash command, hand it to Blizzard and stop here.
    if text:find("^/") then
        self:_ExecuteSlash(text)
        self.msgEdit._editBox:SetText("")
        return
    end

    local ch   = self.currentChannel or "SAY"
    local lang = self.currentLanguage or nil

    if ch == "WHISPER" then
        local who = self.currentTarget
        if not who or who == "" then
            UIErrorsFrame:AddMessage("Whisper target missing.", 1, 0.2, 0.2)
            return
        end
        SendChatMessage(text, "WHISPER", lang, who)
    else
        SendChatMessage(text, ch, lang)
    end

    -- history
    self.history[#self.history+1] = text
    self.historyIndex = #self.history + 1

    if self.msgEdit and self.msgEdit._editBox then
        self.msgEdit._editBox:SetText("")
    end
end


-- ========= UI wiring =========

local function CreateInputBox(parent, width, height, placeholder)
    -- Create a container panel for the input box with styled background
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(width, height)

    -- Background texture
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.85)

    -- Border (transparent fill for border frame)
    local border = panel:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 0)

    -- Palette colors
    local dr, dg, db, da = C and C.Get and C.Get("divider") or 0.3, 0.3, 0.35, 0.6
    local hr, hg, hb, ha = C and C.Get and C.Get("highlight") or 0.5, 0.6, 0.7, 0.9

    -- Top highlight border (palette divider, highlight on focus)
    local topBorder = panel:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    topBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(dr * 0.6, dg * 0.6, db * 0.6, da * 0.8)

    -- Bottom/side subtle border (palette divider, darker)
    local botBorder = panel:CreateTexture(nil, "BORDER")
    botBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 1, 1)
    botBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 1)
    botBorder:SetHeight(1)
    botBorder:SetColorTexture(dr * 0.2, dg * 0.2, db * 0.2, da * 0.7)
    
    -- EditBox inside the panel
    local eb = CreateFrame("EditBox", nil, panel)
    eb:SetSize(width - 6, height - 4)
    eb:SetPoint("CENTER", panel, "CENTER", -1, 0)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(6, 6, 2, 2)
    eb.placeholder = placeholder or ""
    
    -- Set text color to brighter white
    eb:SetTextColor(0.95, 0.95, 0.95, 1.0)
    
    -- Placeholder text (subtle)
    eb._placeholderFS = eb:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    eb._placeholderFS:SetPoint("LEFT", eb, "LEFT", 8, 0)
    eb._placeholderFS:SetText(eb.placeholder)
    eb._placeholderFS:SetAlpha(0.5)
    eb._placeholderFS:SetTextColor(0.7, 0.7, 0.75, 0.5)
    
    -- Focus effect
    eb:HookScript("OnEditFocusGained", function(self)
        -- Use palette highlight color for focus
        local hr, hg, hb, ha = C and C.Get and C.Get("highlight") or 0.5, 0.6, 0.7, 0.9
        topBorder:SetColorTexture(hr, hg, hb, ha)
        local empty = (self:GetText() or "") == ""
        self._placeholderFS:SetShown(empty)
    end)

    eb:HookScript("OnEditFocusLost", function(self)
        -- Revert to palette divider color
        local dr, dg, db, da = C and C.Get and C.Get("divider") or 0.3, 0.3, 0.35, 0.6
        topBorder:SetColorTexture(dr * 0.6, dg * 0.6, db * 0.6, da * 0.8)
        local empty = (self:GetText() or "") == ""
        self._placeholderFS:SetShown(empty)
    end)
    
    eb:HookScript("OnTextChanged", function(self)
        local empty = (self:GetText() or "") == ""
        self._placeholderFS:SetShown(empty and not self:HasFocus())
    end)
    
    -- Store references to panel elements for potential future styling
    panel._editBox = eb
    panel._bg = bg
    panel._topBorder = topBorder
    
    return panel
end

-- ========= public API =========

---@param opts { point?:string, rel?:string, x?:number, y?:number, width?:number, onlyWhenUIHidden?:boolean }
function ChatBoxWidget:BuildUI(opts)
    opts = opts or {}
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent

    self.width   = tonumber(opts.width) or 520
    self.height  = 36
    self.onlyWhenUIHidden = (opts.onlyWhenUIHidden ~= false) -- default true

    self.currentChannel  = "SAY"
    self.currentTarget   = nil
    self.currentLanguage = nil
    self.history = {}
    self.historyIndex = 1
    self.currentTab = "Chat"  -- Track which tab is active
    self._debugFilters = {
        Info = true,
        Warning = true,
        Error = true,
    }  -- Debug message level filters

    -- Root window
    self.root = Window:New("RPE_ChatBox_Window", {
        parent = parentFrame,
        width  = 1, height = 1,
        autoSize = true,
        noBackground = false,
        point  = opts.point or "BOTTOMLEFT",
        pointRelative = opts.rel or "BOTTOMleft",
        x = opts.x or 80,
        y = opts.y or 80,
    })

    -- Initialize clipboard for debug log display
    self.clipboard = Clipboard.New({
        parent = parentFrame,
        width = 600,
        height = 500,
    })

    -- Immersion polish
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale() f:SetScale(UIParent and UIParent:GetScale() or 1) end
        local function UpdateMouseForUIVisibility()
            if not self.onlyWhenUIHidden then return end
            f:EnableMouse(not (UIParent and UIParent:IsShown()))
            -- hide chrome & inputs when UI visible (so default chat can be used)
            if UIParent and UIParent:IsShown() then
                self:Hide()
            else
                self:Show()
            end
        end
        SyncScale(); UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() SyncScale(); UpdateMouseForUIVisibility() end)

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Host for child widgets (with left padding)
    self.host = CreateFrame("Frame", "RPE_ChatBox_Host", self.root.frame)
    self.host:SetSize(self.width - 16, self.height)  -- reduce width for padding
    self.host:SetPoint("CENTER", self.root.frame, "CENTER", 8, 0)  -- offset right to center with padding

    -- Update tab button appearance
    self._UpdateTabButtons = function()
        if self.currentTab == "Chat" then
            -- Active: full color, not desaturated
            self.chatTab:SetColor(1.0, 1.0, 1.0, 1.0)
            if self.chatTab.icon and self.chatTab.icon.SetDesaturated then
                self.chatTab.icon:SetDesaturated(false)
            end
            
            -- Inactive: desaturate and dim
            self.debugTab:SetColor(1.0, 1.0, 1.0, 0.6)
            if self.debugTab.icon and self.debugTab.icon.SetDesaturated then
                self.debugTab.icon:SetDesaturated(true)
            end
            
            -- Show chat UI, hide debug UI
            if self.quickChannelsFrame then self.quickChannelsFrame:Show() end
            if self.debugFiltersFrame then self.debugFiltersFrame:Hide() end
            if self.sendBtn then self.sendBtn:Show() end
            if self.copyDebugBtn then self.copyDebugBtn:Hide() end
            if self.channelBtn then self.channelBtn:Show() end
            if self.targetEdit then self.targetEdit:Show() end
            if self.msgEdit then self.msgEdit:Show() end
        else  -- Debug tab
            -- Active: full color, not desaturated
            self.debugTab:SetColor(1.0, 1.0, 1.0, 1.0)
            if self.debugTab.icon and self.debugTab.icon.SetDesaturated then
                self.debugTab.icon:SetDesaturated(false)
            end
            
            -- Inactive: desaturate and dim
            self.chatTab:SetColor(1.0, 1.0, 1.0, 0.6)
            if self.chatTab.icon and self.chatTab.icon.SetDesaturated then
                self.chatTab.icon:SetDesaturated(true)
            end
            
            -- Show debug UI, hide chat UI
            if self.debugFiltersFrame then self.debugFiltersFrame:Show() end
            if self.quickChannelsFrame then self.quickChannelsFrame:Hide() end
            if self.sendBtn then self.sendBtn:Hide() end
            if self.copyDebugBtn then self.copyDebugBtn:Show() end
            if self.channelBtn then self.channelBtn:Hide() end
            if self.targetEdit then self.targetEdit:Hide() end
            if self.msgEdit then self.msgEdit:Hide() end
        end
    end

    -- Keyboard catcher: full-screen, non-interactive
    self.keyCatcher = CreateFrame("Frame", "RPE_ChatBox_KeyCatcher", self.root.frame)
    self.keyCatcher:SetAllPoints(UIParent or WorldFrame)
    self.keyCatcher:SetFrameStrata("DIALOG")
    self.keyCatcher:EnableMouse(false)
    self.keyCatcher:EnableKeyboard(true)
    self.keyCatcher:SetPropagateKeyboardInput(true) -- don't block other keys unless we act

    -- Helper to decide if catcher should respond
    local function CatcherActive()
        if not (self.root and self.root.frame and self.root.frame:IsShown()) then return false end
        if self.onlyWhenUIHidden then
            return UIParent and not UIParent:IsShown()
        else
            return true
        end
    end

    -- ENTER focuses the message box
    self.keyCatcher:SetScript("OnKeyDown", function(_, key)
        if not CatcherActive() then return end
        if key == "ENTER" then
            if self.msgEdit and self.msgEdit._editBox and not self.msgEdit._editBox:HasFocus() then
                self:Show()  -- make sure we're visible
                self:Focus()
            end
        end
    end)

    -- Slash: use OnChar to catch the typed "/" (locale-safe)
    self.keyCatcher:SetScript("OnChar", function(_, ch)
        if not CatcherActive() then return end
        if ch == "/" then
            if self.msgEdit and self.msgEdit._editBox and not self.msgEdit._editBox:HasFocus() then
                self:Show()
                self:Focus()
                self.msgEdit._editBox:SetText("/")
                self.msgEdit._editBox:SetCursorPosition(1)
            end
        end
    end)

    -- Mousewheel: handled by self.log frame only
    if self.log then
        self.log:SetScript("OnMouseWheel", function(_, delta)
            if self.log:IsVisible() then
                if delta > 0 then
                    self.log:ScrollUp(math.abs(delta) * 3)
                else
                    self.log:ScrollDown(math.abs(delta) * 3)
                end
            end
        end)
    end

    -- Log frame (above input) with improved styling
    self.logHeight = tonumber(opts.logHeight) or 140
    self.log = CreateFrame("ScrollingMessageFrame", "RPE_ChatBox_Log", self.root.frame)
    self.log:SetSize(self.width - 18, self.logHeight)
    self.log:SetPoint("BOTTOM", self.host, "TOP", 8, 6)
    self.log:SetFontObject(ChatFontNormal or "GameFontNormal")
    self.log:SetJustifyH("LEFT")
    self.log:SetIndentedWordWrap(true)
    self.log:SetHyperlinksEnabled(true)
    self.log:SetFading(false)
    self.log:SetMaxLines(500)
    self.log:EnableMouse(true)
    self.log:EnableMouseWheel(true)

    -- Mousewheel handler for scrolling
    self.log:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            self.log:ScrollUp(math.abs(delta) * 3)
        else
            self.log:ScrollDown(math.abs(delta) * 3)
        end
    end)
    
    -- Log background (slightly darker than chrome for visual separation)
    local logBg = self.log:CreateTexture(nil, "BACKGROUND")
    logBg:SetAllPoints()
    logBg:SetColorTexture(0.05, 0.05, 0.06, 0)

    -- Create tab IconButtons (Chat and Debug) positioned above the log at top-left
    self.chatTab = IconButton:New("RPE_ChatBox_Tab_Chat", {
        parent = self.root,
        width = 20,
        height = 20,
        point = "TOPRIGHT",
        relativeTo = self.log,
        relativePoint = "TOPLEFT",
        x = -18,
        y = 0,
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\talk.png",
        tooltip = "Chat",
    })
    self.chatTab:SetTooltip("Chat")
    self.chatTab:SetOnClick(function(btn)
        self.currentTab = "Chat"
        self:_UpdateTabButtons()
        self:_RefreshLogDisplay()
    end)
    
    self.debugTab = IconButton:New("RPE_ChatBox_Tab_Debug", {
        parent = self.root,
        width = 20,
        height = 20,
        point = "TOPRIGHT",
        relativeTo = self.log,
        relativePoint = "TOPLEFT",
        x = -18,
        y = -18,
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\info.png",
        tooltip = "Debug",
    })
    self.debugTab:SetTooltip("Debug")
    self.debugTab:SetOnClick(function(btn)
        self.currentTab = "Debug"
        self:_UpdateTabButtons()
        self:_RefreshLogDisplay()
    end)
    
    self:_UpdateTabButtons()

    -- Chrome
    self:_EnsureChrome()
    self.chrome:ClearAllPoints()
    -- wrap both the log and input with a bit of padding, accounting for tabs
    self.chrome:SetPoint("TOP", self.log, "TOP", 0, 8)
    self.chrome:SetPoint("BOTTOM", self.host, "BOTTOM", 0, -8)
    self.chrome:SetWidth(self.width)

    -- Channel button (custom styled)
    self.channelBtn = CreateFrame("Button", "RPE_ChatBox_ChannelBtn", self.host)
    self.channelBtn:SetSize(76, 22)
    self.channelBtn:SetPoint("LEFT", self.host, "LEFT", 8, 0)
    self.channelBtn:EnableMouse(true)
    self.channelBtn:RegisterForClicks("AnyUp")
    
    -- Button background (TextButton style)
    local btnBg = self.channelBtn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    local br, bg, bb, ba = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
    btnBg:SetColorTexture(br, bg, bb, ba)
    self.channelBtn._bg = btnBg

    -- Button border (TextButton style, top and bottom)
    local divR, divG, divB, divA = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
    local topBorder = self.channelBtn:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT", self.channelBtn, "TOPLEFT", 1, -1)
    topBorder:SetPoint("TOPRIGHT", self.channelBtn, "TOPRIGHT", -1, -1)
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(divR * 0.6, divG * 0.6, divB * 0.6, divA * 0.8)
    self.channelBtn._topBorder = topBorder

    local bottomBorder = self.channelBtn:CreateTexture(nil, "BORDER")
    bottomBorder:SetPoint("BOTTOMLEFT", self.channelBtn, "BOTTOMLEFT", 1, 1)
    bottomBorder:SetPoint("BOTTOMRIGHT", self.channelBtn, "BOTTOMRIGHT", -1, 1)
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(divR * 0.2, divG * 0.2, divB * 0.2, divA * 0.7)
    self.channelBtn._bottomBorder = bottomBorder
    
    -- Button text
    local btnText = self.channelBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    btnText:SetAllPoints(self.channelBtn)
    btnText:SetJustifyH("CENTER")
    btnText:SetJustifyV("MIDDLE")
    btnText:SetText(CHANNEL_LABEL[self.currentChannel])
    btnText:SetTextColor(0.9, 0.9, 0.95, 1.0)
    self.channelBtn._text = btnText
    
    -- Hover effects
    self.channelBtn:EnableMouse(true)
    self.channelBtn:SetScript("OnEnter", function(self)
        local br, bg, bb, ba = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
        self._bg:SetColorTexture(br * 0.6, bg * 0.6, bb * 0.6, ba * 0.9)
        local divR, divG, divB, divA = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
        self._topBorder:SetColorTexture(divR * 0.4, divG * 0.4, divB * 0.4, divA * 0.6)
        self._bottomBorder:SetColorTexture(divR * 0.15, divG * 0.15, divB * 0.15, divA * 0.5)
    end)
    self.channelBtn:SetScript("OnLeave", function(self)
        local br, bg, bb, ba = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
        self._bg:SetColorTexture(br, bg, bb, ba)
        local divR, divG, divB, divA = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
        self._topBorder:SetColorTexture(divR * 0.6, divG * 0.6, divB * 0.6, divA * 0.8)
        self._bottomBorder:SetColorTexture(divR * 0.2, divG * 0.2, divB * 0.2, divA * 0.7)
    end)
    self.channelBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            self:SetChannel(prevChannel(self.currentChannel))
        else
            self:SetChannel(nextChannel(self.currentChannel))
        end
        self.channelBtn._text:SetText(CHANNEL_LABEL[self.currentChannel])
    end)

    -- Whisper target edit (hidden unless WHISPER) - smaller size to prevent overlap
    self.targetEdit = CreateInputBox(self.host, 100, 22, "Target")
    self.targetEdit:SetPoint("LEFT", self.channelBtn, "RIGHT", 6, 0)
    self.targetEdit:Hide()
    local targetEditBox = self.targetEdit._editBox
    targetEditBox:HookScript("OnEnterPressed", function() 
        self.msgEdit._editBox:SetFocus() 
    end)
    targetEditBox:HookScript("OnEscapePressed", function() 
        targetEditBox:ClearFocus() 
    end)
    targetEditBox:HookScript("OnTextChanged", function(box)
        self.currentTarget = box:GetText()
    end)

    -- Message edit box
    self.msgEdit = CreateInputBox(self.host, 340, 22, "Type a message…")
    self.msgEdit:SetPoint("LEFT", self.targetEdit, "RIGHT", 6, 0)
    self.msgEdit:SetPoint("RIGHT", self.host, "RIGHT", -66, 0)
    local msgEditBox = self.msgEdit._editBox
    msgEditBox:HookScript("OnEnterPressed", function()
        self:_DoSend(msgEditBox:GetText())
    end)
    msgEditBox:HookScript("OnEscapePressed", function()
        msgEditBox:ClearFocus()
    end)
    -- history bindings
    msgEditBox:HookScript("OnArrowPressed", function(_, key)
        if key == "UP" then
            if #self.history == 0 then return end
            self.historyIndex = math.max(1, (self.historyIndex or (#self.history+1)) - 1)
            msgEditBox:SetText(self.history[self.historyIndex] or "")
            msgEditBox:HighlightText(0, -1)
        elseif key == "DOWN" then
            if #self.history == 0 then return end
            self.historyIndex = math.min(#self.history + 1, (self.historyIndex or (#self.history+1)) + 1)
            msgEditBox:SetText(self.history[self.historyIndex] or "")
            msgEditBox:HighlightText(0, -1)
        end
    end)

    -- Send button (custom styled with green tint)
    self.sendBtn = CreateFrame("Button", "RPE_ChatBox_SendBtn", self.host)
    self.sendBtn:SetSize(64, 22)
    self.sendBtn:SetPoint("RIGHT", self.host, "RIGHT", -8, 0)
    
    -- Button background (TextButton style, same as channelBtn)
    local sendBg = self.sendBtn:CreateTexture(nil, "BACKGROUND")
    sendBg:SetAllPoints()
    local sr, sg, sb, sa = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
    sendBg:SetColorTexture(sr, sg, sb, sa)
    self.sendBtn._bg = sendBg

    -- Button border (TextButton style, top and bottom)
    local divR2, divG2, divB2, divA2 = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
    local topBorder2 = self.sendBtn:CreateTexture(nil, "BORDER")
    topBorder2:SetPoint("TOPLEFT", self.sendBtn, "TOPLEFT", 1, -1)
    topBorder2:SetPoint("TOPRIGHT", self.sendBtn, "TOPRIGHT", -1, -1)
    topBorder2:SetHeight(1)
    topBorder2:SetColorTexture(divR2 * 0.6, divG2 * 0.6, divB2 * 0.6, divA2 * 0.8)
    self.sendBtn._topBorder = topBorder2

    local bottomBorder2 = self.sendBtn:CreateTexture(nil, "BORDER")
    bottomBorder2:SetPoint("BOTTOMLEFT", self.sendBtn, "BOTTOMLEFT", 1, 1)
    bottomBorder2:SetPoint("BOTTOMRIGHT", self.sendBtn, "BOTTOMRIGHT", -1, 1)
    bottomBorder2:SetHeight(1)
    bottomBorder2:SetColorTexture(divR2 * 0.2, divG2 * 0.2, divB2 * 0.2, divA2 * 0.7)
    self.sendBtn._bottomBorder = bottomBorder2
    
    -- Button text
    local sendText = self.sendBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sendText:SetAllPoints(self.sendBtn)
    sendText:SetJustifyH("CENTER")
    sendText:SetJustifyV("MIDDLE")
    sendText:SetText("Send")
    sendText:SetTextColor(0.85, 0.95, 0.85, 1.0)
    self.sendBtn._text = sendText
    
    -- Hover effects (slightly brighter green)
    self.sendBtn:EnableMouse(true)
    self.sendBtn:SetScript("OnEnter", function(self)
        local sr, sg, sb, sa = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
        self._bg:SetColorTexture(sr * 0.6, sg * 0.6, sb * 0.6, sa * 0.9)
        local divR2, divG2, divB2, divA2 = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
        self._topBorder:SetColorTexture(divR2 * 0.4, divG2 * 0.4, divB2 * 0.4, divA2 * 0.6)
        self._bottomBorder:SetColorTexture(divR2 * 0.15, divG2 * 0.15, divB2 * 0.15, divA2 * 0.5)
    end)
    self.sendBtn:SetScript("OnLeave", function(self)
        local sr, sg, sb, sa = C.Get and C.Get("background") or 0.10,0.10,0.14,0.95
        self._bg:SetColorTexture(sr, sg, sb, sa)
        local divR2, divG2, divB2, divA2 = C.Get and C.Get("divider") or 0.90,0.80,0.60,0.85
        self._topBorder:SetColorTexture(divR2 * 0.6, divG2 * 0.6, divB2 * 0.6, divA2 * 0.8)
        self._bottomBorder:SetColorTexture(divR2 * 0.2, divG2 * 0.2, divB2 * 0.2, divA2 * 0.7)
    end)
    self.sendBtn:SetScript("OnClick", function()
        self:_DoSend(msgEditBox:GetText())
    end)

    -- Copy Debug Log button (shown only on Debug tab)
    self.copyDebugBtn = CreateFrame("Button", "RPE_ChatBox_CopyDebugBtn", self.host)
    self.copyDebugBtn:SetSize(100, 22)
    self.copyDebugBtn:SetPoint("RIGHT", self.host, "RIGHT", -8, 0)
    self.copyDebugBtn:Hide()
    
    -- Button background
    local copyBg = self.copyDebugBtn:CreateTexture(nil, "BACKGROUND")
    copyBg:SetAllPoints()
    copyBg:SetColorTexture(0.15, 0.15, 0.2, 0.85)
    self.copyDebugBtn._bg = copyBg
    
    -- Button border
    local copyBorder = self.copyDebugBtn:CreateTexture(nil, "BORDER")
    copyBorder:SetPoint("TOPLEFT", self.copyDebugBtn, "TOPLEFT", 1, -1)
    copyBorder:SetPoint("TOPRIGHT", self.copyDebugBtn, "TOPRIGHT", -1, -1)
    copyBorder:SetHeight(1)
    copyBorder:SetColorTexture(0.4, 0.4, 0.45, 0.7)
    self.copyDebugBtn._border = copyBorder
    
    -- Button text
    local copyText = self.copyDebugBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    copyText:SetAllPoints(self.copyDebugBtn)
    copyText:SetJustifyH("CENTER")
    copyText:SetJustifyV("MIDDLE")
    copyText:SetText("Copy Log")
    copyText:SetTextColor(0.9, 0.9, 0.95, 1.0)
    self.copyDebugBtn._text = copyText
    
    -- Hover effects
    self.copyDebugBtn:EnableMouse(true)
    self.copyDebugBtn:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(0.2, 0.2, 0.25, 0.95)
        self._border:SetColorTexture(0.5, 0.5, 0.6, 0.8)
    end)
    self.copyDebugBtn:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(0.15, 0.15, 0.2, 0.85)
        self._border:SetColorTexture(0.4, 0.4, 0.45, 0.7)
    end)
    self.copyDebugBtn:SetScript("OnClick", function()
        -- Show Blizzard UI if hidden
        if UIParent and not UIParent:IsShown() then
            UIParent:Show()
        end
        
        -- Collect all debug messages from history
        local logText = ""
        for _, entry in ipairs(self._debugHistory or {}) do
            logText = logText .. entry.text .. "\n"
        end
        
        -- Show clipboard with debug log content
        self.clipboard:SetContent(logText)
        self.clipboard:Show()
    end)

    -- Layout adjustments
    self:Layout()

    -- Register chat channels.
    self:_RegisterChatEvents()

    -- Create quick channel FILTER buttons below the chatbox
    local quickChannelsFrame = CreateFrame("Frame", "RPE_ChatBox_QuickChannels", self.root.frame)
    quickChannelsFrame:SetSize(self.width, 28)  -- match full chat box width (no -16)
    quickChannelsFrame:SetPoint("TOP", self.host, "BOTTOM", 0, -12)
    self.quickChannelsFrame = quickChannelsFrame
    
    -- Create DEBUG FILTER buttons frame (hidden by default, shown when Debug tab active)
    local debugFiltersFrame = CreateFrame("Frame", "RPE_ChatBox_DebugFilters", self.root.frame)
    debugFiltersFrame:SetSize(self.width, 28)
    debugFiltersFrame:SetPoint("TOP", self.host, "BOTTOM", 0, -12)
    debugFiltersFrame:Hide()
    self.debugFiltersFrame = debugFiltersFrame
    
    -- Add filter icon texture
    local filterIcon = quickChannelsFrame:CreateTexture(nil, "ARTWORK")
    filterIcon:SetSize(16, 16)
    filterIcon:SetPoint("LEFT", quickChannelsFrame, "LEFT", 8, 0)
    filterIcon:SetTexture("Interface\\Addons\\RPEngine\\UI\\Textures\\filter.png")  -- Filter/search icon texture
    
    -- Add debug filter icon (similar)
    local debugFilterIcon = debugFiltersFrame:CreateTexture(nil, "ARTWORK")
    debugFilterIcon:SetSize(16, 16)
    debugFilterIcon:SetPoint("LEFT", debugFiltersFrame, "LEFT", 8, 0)
    debugFilterIcon:SetTexture("Interface\\Addons\\RPEngine\\UI\\Textures\\filter.png")
    
    -- Quick filter buttons (shows messages from this channel)
    local quickChannels = { "SAY", "YELL", "EMOTE", "PARTY", "RAID", "GUILD", "OFFICER", "WHISPER", "NPC", "DICE", "COMBAT" }
    self._quickChannels = quickChannels  -- Store reference for use in closures
    local buttonWidth = math.floor((quickChannelsFrame:GetWidth() - 40) / #quickChannels)  -- Reduced width to account for icon
    
    -- Track which filters are active (default: show all channels)
    -- When user clicks, we start filtering by showing only selected
    self._chatFilters = nil  -- nil = show all, table = show only these
    self._filterMode = false  -- false = show all (unfiltered), true = filtering active
    
    for idx, channel in ipairs(quickChannels) do
        local btn = CreateFrame("Button", "RPE_ChatBox_FilterBtn_" .. channel, quickChannelsFrame)
        btn:SetSize(24, 20)
        -- Add extra gap before DICE and COMBAT buttons
        local gap = 0
        if channel == "DICE" or channel == "COMBAT" then
            gap = 16  -- pixels of extra space
        end
        btn:SetPoint("LEFT", quickChannelsFrame, "LEFT", 30 + (idx - 1) * (26) + gap, 0)

        -- Tooltip text for each channel
        local channelTooltips = {
            SAY = "Filter Say messages",
            YELL = "Filter Yell messages",
            EMOTE = "Filter Emote messages",
            PARTY = "Filter Party messages",
            RAID = "Filter Raid messages",
            GUILD = "Filter Guild messages",
            OFFICER = "Filter Officer messages",
            WHISPER = "Filter Whisper messages",
            NPC = "Filter NPC messages",
            DICE = "Filter Dice roll results",
            COMBAT = "Filter Combat messages",
        }

        btn:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.15, 0.15, 0.18, 0.9)
            self._border:SetColorTexture(0.5, 0.5, 0.55, 0.8)
            if RPE and RPE.Common and RPE.Common.ShowTooltip then
                local desc = channelTooltips[channel] or ("Filter %s messages"):format(channel)
                RPE.Common:ShowTooltip(self, { title = "", lines = { { text = desc } } })
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self._widget:_UpdateFilterButtons()
            if RPE and RPE.Common and RPE.Common.HideTooltip then
                RPE.Common:HideTooltip()
            end
        end)
        
        -- Button background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
        btn._bg = bg
        
        -- Button border
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        border:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -1)
        border:SetHeight(1)
        border:SetColorTexture(0.35, 0.35, 0.4, 0.6)
        btn._border = border
        
        -- Button text (use textMuted by default, textMalus when filtering)
        local text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny")
        text:SetAllPoints(btn)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        if channel == "NPC" then
            text:SetText("N")
        elseif channel == "COMBAT" then
            text:SetText("C")
        else
            text:SetText(channel:sub(1, 1))  -- First letter only
        end
        local mutedR, mutedG, mutedB, mutedA = GetColor("textMuted", {0.75, 0.75, 0.80, 1.00})
        text:SetTextColor(mutedR, mutedG, mutedB, mutedA)
        btn._text = text
        
        btn:SetScript("OnClick", function(self)
            -- Toggle filter for this channel
            local w = self._widget
            
            -- Initialize filters if not already done (activate filter mode)
            if not w._filterMode then
                w._filterMode = true
                w._chatFilters = {}
                -- Start with only this channel selected when entering filter mode
                w._chatFilters[self._channel] = true
                -- All other channels are false (not selected)
                for _, ch in ipairs(w._quickChannels) do
                    if ch ~= self._channel then
                        w._chatFilters[ch] = false
                    end
                end
            else
                -- Toggle this specific channel (filtering already active)
                w._chatFilters[self._channel] = not w._chatFilters[self._channel]
            end
            
            w:_UpdateFilterButtons()
            w:_RefreshLogDisplay()  -- Re-render the chat log with current filters
        end)
        
        -- Store widget reference and channel for callbacks
        btn._widget = self
        btn._channel = channel
    end
    
    -- Update filter buttons to show which are active
    self._UpdateFilterButtons = function()
        local mutedR, mutedG, mutedB, mutedA = GetColor("textMuted", {0.75, 0.75, 0.80, 1.00})
        local malusR, malusG, malusB, malusA = GetColor("textMalus", {0.95, 0.55, 0.55, 1.00})
        
        for _, channel in ipairs(self._quickChannels) do
            local btn = _G["RPE_ChatBox_FilterBtn_" .. channel]
            if btn then
                -- When filtering is ACTIVE and this channel is SELECTED, show MALUS (bright)
                local isSelected = self._filterMode and self._chatFilters and self._chatFilters[channel]
                
                if isSelected then
                    btn._text:SetTextColor(malusR, malusG, malusB, malusA)
                    btn._bg:SetColorTexture(0.18, 0.18, 0.22, 0.95)
                else
                    -- Otherwise (no filtering or not selected), show MUTED (dim)
                    btn._text:SetTextColor(mutedR, mutedG, mutedB, mutedA)
                    btn._bg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
                end
            end
        end
    end
    self:_UpdateFilterButtons()

    -- Debug filter buttons (Info, Warning, Error, Internal)
    local debugLevels = { "Info", "Warning", "Error", "Internal" }
    self._debugLevels = debugLevels
    local debugButtonWidth = math.floor((debugFiltersFrame:GetWidth() - 40) / #debugLevels)
    
    -- Track debug filter state: true = SHOW this level, false = HIDE this level
    -- Default: all true = show all messages, no filtering
    self._debugFilters = { Info = true, Warning = true, Error = true, Internal = true }
    
    for idx, level in ipairs(debugLevels) do
        local btn = CreateFrame("Button", "RPE_ChatBox_DebugFilterBtn_" .. level, debugFiltersFrame)
        btn:SetSize(debugButtonWidth - 4, 20)
        btn:SetPoint("LEFT", debugFiltersFrame, "LEFT", 30 + (idx - 1) * (debugButtonWidth + 2), 0)
        
        -- Button background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
        btn._bg = bg
        
        -- Button border
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        border:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -1)
        border:SetHeight(1)
        border:SetColorTexture(0.35, 0.35, 0.4, 0.6)
        btn._border = border
        
        -- Button text
        local text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny")
        text:SetAllPoints(btn)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetText(level)
        local mutedR, mutedG, mutedB, mutedA = GetColor("textMuted", {0.75, 0.75, 0.80, 1.00})
        text:SetTextColor(mutedR, mutedG, mutedB, mutedA)
        btn._text = text
        
        -- Hover and click
        btn:EnableMouse(true)
        btn:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.15, 0.15, 0.18, 0.9)
            self._border:SetColorTexture(0.5, 0.5, 0.55, 0.8)
        end)
        btn:SetScript("OnLeave", function(self)
            self._widget:_UpdateDebugFilterButtons()
        end)
        btn:SetScript("OnClick", function(self)
            local w = self._widget
            w._debugFilters[self._level] = not w._debugFilters[self._level]
            w:_UpdateDebugFilterButtons()
            w:_RefreshLogDisplay()
        end)
        
        btn._widget = self
        btn._level = level
    end
    
    -- Update debug filter button appearance
    self._UpdateDebugFilterButtons = function()
        local mutedR, mutedG, mutedB, mutedA = GetColor("textMuted", {0.75, 0.75, 0.80, 1.00})
        local malusR, malusG, malusB, malusA = GetColor("textMalus", {0.95, 0.55, 0.55, 1.00})
        
        for _, level in ipairs(self._debugLevels) do
            local btn = _G["RPE_ChatBox_DebugFilterBtn_" .. level]
            if btn then
                -- true = SHOW messages (button is NOT active/filtering), false = HIDE messages (button IS active/filtering)
                local isShowing = self._debugFilters[level]
                if isShowing then
                    -- Showing this level = button in muted (inactive) state
                    btn._text:SetTextColor(mutedR, mutedG, mutedB, mutedA)
                    btn._bg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
                else
                    -- Hiding this level = button in bright (active/filtering) state
                    btn._text:SetTextColor(malusR, malusG, malusB, malusA)
                    btn._bg:SetColorTexture(0.18, 0.18, 0.22, 0.95)
                end
            end
        end
    end
    self:_UpdateDebugFilterButtons()

    -- Store all chat messages with their channel type for retroactive filtering
    self._chatHistory = {}  -- { {text=..., ctype=..., r=..., g=..., b=...}, ... }
    self._debugHistory = {}  -- Separate history for debug tab
    
    -- Channel type to filter button mapping
    self._channelMap = {
        SAY = "SAY", YELL = nil, EMOTE = "EMOTE",
        PARTY = "PARTY", RAID = "RAID", PARTY_LEADER = nil,
        GUILD = "GUILD", OFFICER = "OFFICER",
        WHISPER = "WHISPER", WHISPER_INFORM = "WHISPER",
        NPC = "NPC",
        DICE = "DICE",
        COMBAT = "COMBAT",
    }
    
    -- Function to check if a message should be displayed based on current filters
    local function shouldDisplayMessage(ctype, filterMode, filters, channelMap)
        if not filterMode or not filters then
            return true  -- Show everything when filtering is off
        end
        local filterChannel = channelMap[ctype]
        -- Show message if channel is NOT in filters (i.e., NOT being filtered out)
        return filterChannel and not filters[filterChannel] or false
    end
    
    -- Function to re-render chat log based on current filters
    self._RefreshLogDisplay = function()
        if not self.log then return end
        self.log:Clear()
        
        local history = (self.currentTab == "Debug") and self._debugHistory or self._chatHistory
        
        for _, entry in ipairs(history or {}) do
            if self.currentTab == "Debug" then
                -- Debug tab applies level filters (Info, Warning, Error)
                if self._debugFilters[entry.level] then
                    self.log:AddMessage(entry.text, entry.r, entry.g, entry.b)
                end
            else
                -- Chat tab applies channel filters
                if shouldDisplayMessage(entry.ctype, self._filterMode, self._chatFilters, self._channelMap) then
                    self.log:AddMessage(entry.text, entry.r, entry.g, entry.b)
                end
            end
        end
    end

    -- Initialize SpeechBubbleWidget for say/yell visual feedback
    if RPE_UI.Windows and RPE_UI.Windows.SpeechBubbleWidget then
        self.speechBubbleWidget = RPE_UI.Windows.SpeechBubbleWidget.New({
            chatBoxRoot = self.root and self.root.frame,
        })
    end

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)

    ------------------------------------------------------------------
    -- Visibility control: only show when immersion mode & UI hidden
    ------------------------------------------------------------------
    local function UpdateChatBoxVisibility()
        local immersion = RPE.Core and RPE.Core.ImmersionMode
        local uiVisible = UIParent and UIParent:IsShown()
        if immersion and not uiVisible then
            self:Show()
        else
            self:Hide()
        end
    end

    -- hook UIParent Filter
    if UIParent then
        UIParent:HookScript("OnShow", UpdateChatBoxVisibility)
        UIParent:HookScript("OnHide", UpdateChatBoxVisibility)
    end

    -- also listen for immersion mode changes (if toggled elsewhere)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent", function()
        UpdateChatBoxVisibility()
    end)

    -- run immediately on build
    self:Hide()
    UpdateChatBoxVisibility()
end

function ChatBoxWidget:Layout()
    -- Resize message field based on whisper target visibility
    if self.currentChannel == "WHISPER" then
        self.targetEdit:Show()
        self.msgEdit:ClearAllPoints()
        self.msgEdit:SetPoint("LEFT", self.targetEdit, "RIGHT", 4, 0)
        self.msgEdit:SetPoint("RIGHT", self.host, "RIGHT", -78, 0)
    else
        self.targetEdit:Hide()
        self.msgEdit:ClearAllPoints()
        self.msgEdit:SetPoint("LEFT", self.channelBtn, "RIGHT", 6, 0)
        self.msgEdit:SetPoint("RIGHT", self.host, "RIGHT", -78, 0)
    end
end

-- ====== channel & language ======

function ChatBoxWidget:SetChannel(kind, target)
    kind = kind or "SAY"
    if not CHANNEL_LABEL[kind] then kind = "SAY" end
    self.currentChannel = kind
    self.channelBtn._text:SetText(CHANNEL_LABEL[kind])
    if kind == "WHISPER" and target then
        self.currentTarget = target
        if self.targetEdit._editBox then
            self.targetEdit._editBox:SetText(target)
        end
    end
    self:Layout()
end

function ChatBoxWidget:SetTarget(nameRealm)
    self.currentTarget = nameRealm
    if self.currentChannel == "WHISPER" then
        if self.targetEdit._editBox then
            self.targetEdit._editBox:SetText(nameRealm or "")
        end
        self:Layout()
    end
end

function ChatBoxWidget:SetLanguage(lang)
    self.currentLanguage = lang
end

function ChatBoxWidget:Focus()
    if self.msgEdit and self.msgEdit._editBox then 
        self.msgEdit._editBox:SetFocus() 
    end
end

function ChatBoxWidget:Blur()
    if self.msgEdit and self.msgEdit._editBox then 
        self.msgEdit._editBox:ClearFocus() 
    end
end

function ChatBoxWidget:Send(text)
    self:_DoSend(text or (self.msgEdit and self.msgEdit._editBox and self.msgEdit._editBox:GetText()) or "")
end

-- === Chat Message handling === --
-- Map WoW events to ChatType keys we’ll use for color lookup
local EVENT_TO_TYPE = {
    CHAT_MSG_SAY            = "SAY",
    CHAT_MSG_EMOTE          = "EMOTE",
    CHAT_MSG_YELL           = "YELL",
    CHAT_MSG_RAID           = "RAID",
    CHAT_MSG_PARTY          = "PARTY",
    CHAT_MSG_PARTY_LEADER   = "PARTY_LEADER",
    CHAT_MSG_GUILD          = "GUILD",
    CHAT_MSG_WHISPER        = "WHISPER",          -- incoming
    CHAT_MSG_WHISPER_INFORM = "WHISPER_INFORM",   -- outgoing
}


-- Register only the channels we care about
function ChatBoxWidget:_RegisterChatEvents()
    if self.listener then return end
    self.listener = CreateFrame("Frame", "RPE_ChatBox_Listener", self.root.frame)
    for ev in pairs(EVENT_TO_TYPE) do
        self.listener:RegisterEvent(ev)
    end
    self.listener:SetScript("OnEvent", function(_, event, msg, author, ...)
        self:_OnChatEvent(event, msg, author, ...)
    end)
end

-- Push text into the scrolling log and store in history
function ChatBoxWidget:PushMessage(text, r, g, b, ctype)
    if not self.log then return end
    
    -- Store in chat history with channel type (for retroactive filtering)
    if ctype then
        table.insert(self._chatHistory, {
            text = text,
            r = r or 1,
            g = g or 1,
            b = b or 1,
            ctype = ctype,
            level = "Info",  -- Chat messages default to Info level
        })
    end
    
    -- Determine if message should be shown based on current filter state
    local shouldShow = true
    if self._filterMode and self._chatFilters and ctype then
        local filterChannel = self._channelMap[ctype]
        shouldShow = filterChannel and not self._chatFilters[filterChannel] or false
    end
    
    -- Only show if we're on Chat tab
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(text or "", r or 1, g or 1, b or 1)
    end
end

--- Push an NPC message to the chat log (with NPC filter support)
function ChatBoxWidget:PushNPCMessage(senderName, message, language)
    if not self.log or not senderName or not message then return end
    
    -- Message is already obfuscated by Handle.lua, just apply language prefix
    local senderPrefix = senderName or "NPC"
    
    -- Determine if language should be shown (hide for default languages)
    local playerFaction = UnitFactionGroup("player")
    local defaultLanguage = (playerFaction == "Alliance") and "Common" or "Orcish"
    local languagePrefix = language and language ~= defaultLanguage and ("[" .. language .. "] ") or ""
    
    local line = senderPrefix .. " says: " .. languagePrefix .. message
    
    -- NPC message color (#FFFF9F)
    local r, g, b = 1.0, 1.0, 0.624  -- #FFFF9F
    
    -- Store in chat history with NPC channel type
    table.insert(self._chatHistory, {
        text = line,
        r = r,
        g = g,
        b = b,
        ctype = "NPC",
        level = "Info",  -- NPC messages default to Info level
    })
    
    -- Determine if message should be shown based on current filter state
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        -- Show if NPC is NOT filtered out (i.e., not self._chatFilters["NPC"])
        shouldShow = not self._chatFilters["NPC"]
    end
    
    -- Show on Chat tab if passes filter, always show on Debug tab
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(line or "", r, g, b)
    elseif self.currentTab == "Debug" then
        self.log:AddMessage(("%s"):format(line or ""), r, g, b)
    end
end

--- Push a dice/reaction roll message to the chat log (with DICE filter support)
-- @param message string The reaction/roll outcome message
function ChatBoxWidget:PushDiceMessage(message)
    if not self.log or not message then return end
    -- Dice message color (grey/silver)
    local r, g, b = 0.82, 0.82, 0.82  -- Silver/grey
    table.insert(self._chatHistory, {
        text = message,
        r = r,
        g = g,
        b = b,
        ctype = "DICE",
        level = "Info",
    })
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        shouldShow = not self._chatFilters["DICE"]
    end
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(message or "", r, g, b)
    end
end

--- Push a combat message to the chat log (with COMBAT filter support)
-- @param message string The combat outcome message
function ChatBoxWidget:PushCombatMessage(message)
    if not self.log or not message then return end
    -- Combat message color (light red)
    local r, g, b = 1.0, 0.4, 0.4  -- Light red
    table.insert(self._chatHistory, {
        text = message,
        r = r,
        g = g,
        b = b,
        ctype = "COMBAT",
        level = "Info",
    })
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        shouldShow = not self._chatFilters["COMBAT"]
    end
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(message or "", r, g, b)
    end
end

--- Push a player turn start message to the chat log
-- @param turn number The current turn number
function ChatBoxWidget:PushPlayerTurnStartMessage(turn)
    if not self.log then return end
    
    local message = string.format("→ Your turn started (Turn %d)", turn)
    
    -- Get textBonus color from palette (default green)
    local r, g, b = 0.55, 0.95, 0.65
    if RPE_UI and RPE_UI.Colors and RPE_UI.Colors.Get then
        local pr, pg, pb, pa = RPE_UI.Colors.Get("textBonus")
        if pr then r, g, b = pr, pg, pb end
    end
    
    table.insert(self._chatHistory, {
        text = message,
        r = r,
        g = g,
        b = b,
        ctype = "COMBAT",
        level = "Info",
    })
    
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        shouldShow = not self._chatFilters["COMBAT"]
    end
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(message, r, g, b)
    end
end

--- Push a player turn end message to the chat log
function ChatBoxWidget:PushPlayerTurnEndMessage()
    if not self.log then return end
    
    local message = "← Your turn ended"
    
    -- Get textMalus color from palette (default red)
    local r, g, b = 0.95, 0.55, 0.55
    if RPE_UI and RPE_UI.Colors and RPE_UI.Colors.Get then
        local pr, pg, pb, pa = RPE_UI.Colors.Get("textMalus")
        if pr then r, g, b = pr, pg, pb end
    end
    
    table.insert(self._chatHistory, {
        text = message,
        r = r,
        g = g,
        b = b,
        ctype = "COMBAT",
        level = "Info",
    })
    
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        shouldShow = not self._chatFilters["COMBAT"]
    end
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(message, r, g, b)
    end
end

--- Push a summoned unit turn start message to the chat log
-- @param unitName string The name of the summoned unit
function ChatBoxWidget:PushSummonedTurnStartMessage(unitName)
    if not self.log then return end
    
    local message = string.format("→ %s's turn started", unitName or "Summoned unit")
    
    -- Get textModified color from palette (default blue)
    local r, g, b = 0.55, 0.75, 0.95
    if RPE_UI and RPE_UI.Colors and RPE_UI.Colors.Get then
        local pr, pg, pb, pa = RPE_UI.Colors.Get("textModified")
        if pr then r, g, b = pr, pg, pb end
    end
    
    table.insert(self._chatHistory, {
        text = message,
        r = r,
        g = g,
        b = b,
        ctype = "COMBAT",
        level = "Info",
    })
    
    local shouldShow = true
    if self._filterMode and self._chatFilters then
        shouldShow = not self._chatFilters["COMBAT"]
    end
    if self.currentTab == "Chat" and shouldShow then
        self.log:AddMessage(message, r, g, b)
    end
end

--- Push a debug message to the Debug tab of the chat log
-- @param message string The debug message text
-- @param level string "Info", "Warning", "Error", or "Dice" (defaults to "Info")
function ChatBoxWidget:PushDebugMessage(message, level)
    if not self.log or not message then return end
    
    level = level or "Info"
    
    -- Get inline icon for this level
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    local icon = icons[level] or ""
    
    -- Get timestamp (MM:SS format from game time)
    local gameTime = GetTime()
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timestamp = string.format("%02d:%02d", minutes % 60, seconds)
    
    -- Color based on debug level
    local r, g, b
    if level == "Warning" then
        r, g, b = 1.0, 0.647, 0.0  -- Orange (#FFA500)
    elseif level == "Error" then
        r, g, b = 1.0, 0.0, 0.0  -- Red (#FF0000)
    elseif level == "Internal" then
        r, g, b = 0.5, 0.5, 0.5  -- Dark grey for internal messages
    else
        r, g, b = 0.62, 0.62, 0.62  -- Grey (default Info)
    end
    
    -- Format with fixed-width columns: [Timestamp(8)] | [Level+Icon(20)] | [Message]
    -- Use non-breaking spaces for alignment
    local formattedMessage = string.format("[%s] %-20s     %s", timestamp, icon .. " " .. level, message)
    
    -- Store in debug history
    table.insert(self._debugHistory, {
        text = formattedMessage,
        r = r,
        g = g,
        b = b,
        level = level,
    })
    
    -- Refresh display if on Debug tab (filtering will be applied in _RefreshLogDisplay)
    if self.currentTab == "Debug" then
        self:_RefreshLogDisplay()
    end
end

-- Format + color incoming chat lines and display them with aligned sender names
function ChatBoxWidget:_OnChatEvent(event, msg, author, ...)
    local ctype = EVENT_TO_TYPE[event]
    if not ctype then return end

    local short = (Ambiguate and Ambiguate(author or "", "short")) or (author or "")
    local senderPrefix = ""
    local line

    -- Determine sender prefix for alignment (left-aligned to fixed width)
    if ctype == "EMOTE" then
        -- Emotes are continuous text with no spacing
        senderPrefix = short
        line = senderPrefix .. " " .. msg

    elseif ctype == "SAY" then
        senderPrefix = short .. " says:"
        line = senderPrefix .. " " .. msg

    elseif ctype == "YELL" then
        senderPrefix = short .. " yells:"
        line = senderPrefix .. " " .. msg

    elseif ctype == "RAID" then
        senderPrefix = "[R] " .. short
        line = senderPrefix .. " " .. msg

    elseif ctype == "PARTY" then
        senderPrefix = "[P] " .. short
        line = senderPrefix .. " " .. msg

    elseif ctype == "PARTY_LEADER" then
        senderPrefix = "[PL] " .. short
        line = senderPrefix .. " " .. msg

    elseif ctype == "GUILD" then
        senderPrefix = "[G] " .. short
        line = senderPrefix .. " " .. msg

    elseif ctype == "WHISPER" then
        -- incoming whisper
        senderPrefix = "[From] " .. short
        line = senderPrefix .. " " .. msg

    elseif ctype == "WHISPER_INFORM" then
        -- your outgoing whisper
        senderPrefix = "[To] " .. short
        line = senderPrefix .. " " .. msg
    end
    
    -- Add continuation line padding for wrapped text (16 spaces to match sender width)
    if line and (ctype == "SAY" or ctype == "YELL" or ctype == "RAID" or ctype == "PARTY" or 
                 ctype == "PARTY_LEADER" or ctype == "GUILD" or ctype == "WHISPER" or ctype == "WHISPER_INFORM") then
        line = line:gsub("\n", "\n" .. string.rep(" ", 16))
    end

    -- Channel color (falls back to white)
    local r, g, b = 1, 1, 1
    if ChatTypeInfo and ChatTypeInfo[ctype] then
        local info = ChatTypeInfo[ctype]
        r, g, b = info.r, info.g, info.b
    end

    -- Show speech bubble for SAY and YELL
    if (ctype == "SAY" or ctype == "YELL") and self.speechBubbleWidget then
        -- Try to find the unit (player nearby)
        local unitToken = nil
        
        -- First check if it's the player themselves
        local playerName = UnitName("player")
        if playerName and (author == playerName or short == playerName) then
            unitToken = "player"
        end
        
        -- Check other common units
        if not unitToken then
            if UnitName("target") == author or UnitName("target") == short then
                unitToken = "target"
            elseif UnitName("mouseover") == author or UnitName("mouseover") == short then
                unitToken = "mouseover"
            end
        end
        
        -- Check party/raid members
        if not unitToken then
            for i = 1, 40 do
                local token = "raid" .. i
                if UnitName(token) == author or UnitName(token) == short then
                    unitToken = token
                    break
                end
            end
        end
        
        if not unitToken then
            for i = 1, 4 do
                local token = "party" .. i
                if UnitName(token) == author or UnitName(token) == short then
                    unitToken = token
                    break
                end
            end
        end

        if unitToken then
            self.speechBubbleWidget:ShowBubble(unitToken, short, msg)
        end
    end

    -- Pass ctype so PushMessage can filter properly
    self:PushMessage(line, r, g, b, ctype)
end

-- Execute a Blizzard slash command (e.g. "/reload", "/w Name hi")
function ChatBoxWidget:_ExecuteSlash(text)
    text = tostring(text or "")
    -- Pick a Blizzard chat edit box to drive
    local eb = (ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME))
              or _G.ChatFrame1EditBox
    if not eb then return end

    eb:SetText(text)

    -- Mirror Blizzard's Enter behavior on their edit box
    if ChatEdit_OnEnterPressed then
        ChatEdit_OnEnterPressed(eb)         -- runs slash or sends depending on content
    else
        -- Fallback path if the global handler isn't available for some reason
        if ChatEdit_ParseText then ChatEdit_ParseText(eb, 0) end
        if ChatEdit_SendText  then ChatEdit_SendText(eb, 0)  end
        if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(eb) end
    end
end


-- ====== boilerplate ======

function ChatBoxWidget.New(opts)
    local self = setmetatable({}, ChatBoxWidget)
    self:BuildUI(opts or {})
    return self
end

function ChatBoxWidget:Show()
    if self.chrome then self.chrome:Show() end
    if self.root and self.root.Show then self.root:Show() end
    if self.host then self.host:Show() end
end

function ChatBoxWidget:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
    if self.host then self.host:Hide() end
end

return ChatBoxWidget
