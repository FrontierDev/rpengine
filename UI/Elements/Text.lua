-- RPE_UI/Elements/Text.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class Text: FrameElement
---@field fs FontString
---@field _colorKey string
local Text = setmetatable({}, { __index = FrameElement })
Text.__index = Text
RPE_UI.Elements.Text = Text

---@param name string
---@param opts table|nil
---@return Text
function Text:New(name, opts)
    opts = opts or {}
    local parent = opts.parent and opts.parent.frame or UIParent

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(opts.width or 0.01, opts.height or 0.01)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local fs = f:CreateFontString(nil, "OVERLAY", opts.fontTemplate or "GameFontNormal")
    fs:SetPoint(opts.textPoint or "CENTER", f, opts.textRelativePoint or "CENTER", opts.textX or 0, opts.textY or 0)

    -- Default colors from palette if none provided
    if opts.color then
        fs:SetTextColor(opts.color[1], opts.color[2], opts.color[3], opts.color[4] or 1)
    else
        local r,g,b,a = C.Get("text")
        fs:SetTextColor(r,g,b,a)
    end

    if opts.justifyH then fs:SetJustifyH(opts.justifyH) end
    if opts.justifyV then fs:SetJustifyV(opts.justifyV) end
    if opts.shadow then
        fs:SetShadowOffset(opts.shadow.x or 1, opts.shadow.y or -1)
        fs:SetShadowColor(opts.shadow.r or 0, opts.shadow.g or 0, opts.shadow.b or 0, opts.shadow.a or 0.75)
    end
    if opts.text then fs:SetText(opts.text) end
    if opts.maxLines then fs:SetMaxLines(opts.maxLines) end
    if opts.wordWrap ~= nil then fs:SetWordWrap(opts.wordWrap) end

    ---@type Text
    local o = FrameElement.New(self, "Text", f, opts.parent)
    o.fs = fs
    o._colorKey = opts.colorKey or "text"

    -- Initial size to fit text
    o:ResizeToText()
    
    -- Register as palette consumer so colors update when palette changes
    C.RegisterConsumer(o)

    return o
end

function Text:SetText(t)
    self.fs:SetText(t or "")
    self:ResizeToText()
end
function Text:SetColor(r,g,b,a)       self.fs:SetTextColor(r,g,b,a or 1) end
function Text:SetFont(path, size, f)  self.fs:SetFont(path, size, f) end
function Text:SetJustifyH(j)          self.fs:SetJustifyH(j) end
function Text:SetJustifyV(j)          self.fs:SetJustifyV(j) end
function Text:SetShadow(x,y,r,g,b,a)  self.fs:SetShadowOffset(x or 1, y or -1); self.fs:SetShadowColor(r or 0, g or 0, b or 0, a or 0.75) end

function Text:ResizeToText()
    local w = self.fs:GetStringWidth() or 0
    local h = self.fs:GetStringHeight() or 0
    self.frame:SetSize(w, h)
end

function Text:ApplyPalette()
    -- Update text color from palette
    local r, g, b, a = C.Get(self._colorKey or "text")
    self.fs:SetTextColor(r, g, b, a)
end

return Text
