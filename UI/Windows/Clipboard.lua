-- RPE_UI/Windows/Clipboard.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window       = RPE_UI.Elements.Window
local FrameElement = RPE_UI.Elements.FrameElement
local C            = RPE_UI.Colors

---@class Clipboard
---@field root Window
---@field textArea ScrollingEditBox
---@field closeBtn Button
---@field _content string
local Clipboard = {}
_G.RPE_UI.Windows.Clipboard = Clipboard
Clipboard.__index = Clipboard
Clipboard.Name = "Clipboard"

-- Register Clipboard in core windows (like DatasetWindow)
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.Clipboard = self
end

function Clipboard.New(opts)
    opts = opts or {}
    local self = setmetatable({}, Clipboard)

    -- Root window
    self.root = Window:New("RPE_Clipboard_Window", {
        parent = opts.parent or UIParent,
        point = "CENTER",
        x = opts.x or 0,
        y = opts.y or 0,
        width = opts.width or 600,
        height = opts.height or 500,
    })

    local rootFrame = self.root.frame
    rootFrame:SetFrameStrata("DIALOG")
    
    -- Sync scale with UIParent if parent is WorldFrame
    if opts.parent == WorldFrame then
        rootFrame:SetToplevel(true)
        rootFrame:SetIgnoreParentScale(true)
        local function SyncScale()
            rootFrame:SetScale(UIParent and UIParent:GetScale() or 1)
        end
        SyncScale()
        UIParent:HookScript("OnShow", SyncScale)
        UIParent:HookScript("OnHide", SyncScale)
        
        -- Also sync when scale changes
        local scaleProxy = CreateFrame("Frame")
        scaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        scaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        scaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Title bar
    local titleFS = rootFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleFS:SetPoint("TOPLEFT", rootFrame, "TOPLEFT", 12, -12)
    titleFS:SetText("Clipboard")
    titleFS:SetTextColor(0.9, 0.9, 0.95, 1.0)

    -- Close button (top-right)
    self.closeBtn = CreateFrame("Button", "RPE_Clipboard_CloseBtn", rootFrame)
    self.closeBtn:SetSize(24, 24)
    self.closeBtn:SetPoint("TOPRIGHT", rootFrame, "TOPRIGHT", -8, -8)
    self.closeBtn:SetText("×")
    self.closeBtn:SetNormalFontObject("GameFontHighlightLarge")
    self.closeBtn:GetFontString():SetTextColor(0.9, 0.9, 0.95, 1.0)
    
    local closeHover = self.closeBtn:CreateTexture(nil, "BACKGROUND")
    closeHover:SetAllPoints()
    closeHover:SetColorTexture(0.2, 0.2, 0.25, 0)
    self.closeBtn._hoverTex = closeHover
    
    self.closeBtn:SetScript("OnEnter", function(btn)
        btn._hoverTex:SetColorTexture(0.3, 0.3, 0.35, 0.5)
    end)
    self.closeBtn:SetScript("OnLeave", function(btn)
        btn._hoverTex:SetColorTexture(0.2, 0.2, 0.25, 0)
    end)
    self.closeBtn:SetScript("OnClick", function()
        self:Hide()
    end)

    -- Text area (edit box for selectable text)
    self.textArea = CreateFrame("EditBox", "RPE_Clipboard_TextArea", rootFrame)
    self.textArea:SetPoint("TOPLEFT", rootFrame, "TOPLEFT", 12, -40)
    self.textArea:SetPoint("BOTTOMRIGHT", rootFrame, "BOTTOMRIGHT", -12, 12)
    self.textArea:SetAutoFocus(false)
    self.textArea:SetFontObject(ChatFontNormal or "GameFontNormal")
    self.textArea:SetTextColor(0.9, 0.9, 0.95, 1.0)
    self.textArea:EnableMouse(true)
    self.textArea:EnableMouseWheel(true)
    
    -- CRITICAL: Enable multi-line mode to display line breaks
    if self.textArea.SetMultiLine then
        self.textArea:SetMultiLine(true)
    end
    
    -- Background slightly darker than window background
    local textBg = self.textArea:CreateTexture(nil, "BACKGROUND")
    textBg:SetAllPoints()
    local r, g, b, a = 0.1, 0.1, 0.1, 0.9
    if C and C.Get then
        local bgR, bgG, bgB, bgA = C.Get("background")
        if bgR then
            r, g, b, a = bgR * 0.8, bgG * 0.8, bgB * 0.8, bgA or 0.9
        end
    end
    textBg:SetColorTexture(r, g, b, a)

    -- Store initial content
    self._content = ""

    -- Hide by default
    self.root.frame:Hide()

    exposeCoreWindow(self)

    return self
end

function Clipboard:SetContent(text)
    self._content = text or ""
    if self.textArea then
        self.textArea:SetText(self._content)
        self.textArea:HighlightText()
    end
end

function Clipboard:Show()
    if not self.root or not self.root.frame then
        print("Clipboard root or frame is missing. Recreating the clipboard window using New().")
        local opts = {
            parent = UIParent,
            x = 0,
            y = 0,
            width = 600,
            height = 500
        }
        local newClipboard = Clipboard.New(opts)
        _G.RPE_UI.Windows.Clipboard = newClipboard
        return newClipboard:Show()
    end

    self.root.frame:Show()
    self.root.frame:SetFrameStrata("DIALOG")
    self.textArea:SetFocus()
end

function Clipboard:Hide()
    if self.root and self.root.frame then
        self.root.frame:Hide()
    end
end

function Clipboard:IsShown()
    return self.root and self.root.frame and self.root.frame:IsShown() or false
end

---Get the current clipboard text, optionally validating against a regex pattern
---@param pattern string|nil Optional regex pattern to validate the text
---@return string|nil The clipboard text if valid, or nil if validation fails
function Clipboard:GetClipboardText(pattern)
    local text = self._content
    if not text or text == "" then return nil end
    
    -- If no pattern specified, return the text as-is
    if not pattern then return text end
    
    -- Validate against the pattern
    -- Since patterns like [a-fA-F0-9] already cover both cases, just match as-is
    if text:match(pattern) then
        return text
    end
    
    return nil
end

-- Utility: serialize a Lua table to a copy-pasteable string
local function serialize_lua_table(val, indent)
    indent = indent or ""
    local t = type(val)
    if t == "table" then
        local s = "{\n"
        local nextIndent = indent .. "  "
        for k, v in pairs(val) do
            local key
            if type(k) == "string" and k:match("^%a[%w_]*$") then
                key = k
            else
                key = "[" .. serialize_lua_table(k) .. "]"
            end
            s = s .. nextIndent .. key .. " = " .. serialize_lua_table(v, nextIndent) .. ",\n"
        end
        return s .. indent .. "}"
    elseif t == "string" then
        return string.format("%q", val)
    else
        return tostring(val)
    end
end

Clipboard.serialize_lua_table = serialize_lua_table

return Clipboard
