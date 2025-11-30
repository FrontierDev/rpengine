-- RPE_UI/Elements/HorizontalLayoutGroup.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class HorizontalLayoutGroup: FrameElement
---@field paddingLeft number
---@field paddingRight number
---@field paddingTop number
---@field paddingBottom number
---@field spacingX number
---@field alignV "TOP"|"CENTER"|"BOTTOM"
---@field alignH "LEFT"|"CENTER"|"RIGHT"
---@field autoSize boolean
---@field autoSizePadX number
---@field autoSizePadY number
local HorizontalLayoutGroup = setmetatable({}, { __index = FrameElement })
HorizontalLayoutGroup.__index = HorizontalLayoutGroup
RPE_UI.Elements.HorizontalLayoutGroup = HorizontalLayoutGroup

local function readPadding(opts)
    local p = opts.padding or {}
    return
        (opts.paddingLeft or p.left or 0),
        (opts.paddingRight or p.right or 0),
        (opts.paddingTop or p.top or 0),
        (opts.paddingBottom or p.bottom or 0)
end

---@param name string
---@param opts table|nil
---@return HorizontalLayoutGroup
function HorizontalLayoutGroup:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "HorizontalLayoutGroup:New requires opts.parent")

    local parentFrame = opts.parent.frame
    local f = CreateFrame("Frame", name, parentFrame, "BackdropTemplate")
    f:SetSize(opts.width or 200, opts.height or 40)
    f:SetPoint(opts.point or "TOPLEFT", opts.relativeTo or parentFrame, opts.relativePoint or "TOPLEFT", opts.x or 0, opts.y or 0)

    if opts.hasBackground then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        local r,g,b,a = C.Get("background")
        a = opts.alpha or a
        f:SetBackdropColor(r,g,b,a)
    else
        f:SetBackdropColor(1,1,1,0)
    end

    if opts.hasBorder then
        -- Borders
        local top = f:CreateTexture(nil, "BORDER")
        top:SetPoint("TOPLEFT", f, "TOPLEFT")
        top:SetPoint("TOPRIGHT", f, "TOPRIGHT")
        top:SetHeight(2); C.ApplyDivider(top)

        local bottom = f:CreateTexture(nil, "BORDER")
        bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
        bottom:SetHeight(2); C.ApplyDivider(bottom)    
    end

    ---@type HorizontalLayoutGroup
    local o = FrameElement.New(self, "HorizontalLayoutGroup", f, opts.parent)

    o.paddingLeft, o.paddingRight, o.paddingTop, o.paddingBottom = readPadding(opts)
    o.spacingX = opts.spacingX or 6
    o.alignV   = (opts.alignV == "TOP" or opts.alignV == "BOTTOM") and opts.alignV or "CENTER"
    o.alignH   = (opts.alignH == "CENTER" or opts.alignH == "RIGHT") and opts.alignH or "LEFT"

    -- Auto-size settings
    o.autoSize     = opts.autoSize or false
    o.autoSizePadX = opts.autoSizePadX or 0
    o.autoSizePadY = opts.autoSizePadY or 0

    f:SetScript("OnSizeChanged", function() o:Relayout() end)
    return o
end

function HorizontalLayoutGroup:SetPadding(left, right, top, bottom)
    self.paddingLeft  = left or 0
    self.paddingRight = right or 0
    self.paddingTop   = top or 0
    self.paddingBottom= bottom or 0
    self:Relayout()
end

function HorizontalLayoutGroup:SetSpacingX(spacing)
    self.spacingX = spacing or 0
    self:Relayout()
end

function HorizontalLayoutGroup:SetAlignV(align)
    if align == "TOP" or align == "BOTTOM" or align == "CENTER" then
        self.alignV = align
        self:Relayout()
    end
end

function HorizontalLayoutGroup:SetAlignH(align)
    if align == "LEFT" or align == "CENTER" or align == "RIGHT" then
        self.alignH = align
        self:Relayout()
    end
end

-- Preferred add: forces parent, hooks show/hide, and relayouts.
function HorizontalLayoutGroup:Add(child)
    FrameElement.AddChild(self, child)
    if child.frame then
        child.frame:HookScript("OnShow", function()
            if self.frame then self:Relayout() end
            if self.autoSize then self:RequestAutoSize() end
        end)
        child.frame:HookScript("OnHide", function()
            if self.frame then self:Relayout() end
            if self.autoSize then self:RequestAutoSize() end
        end)
    end
    self:Relayout()
    if self.autoSize then
        self:RequestAutoSize()
    end
end

local function measureChildren(self)
    local totalWidth, maxHeight = 0, 0
    local visible = {}
    for _, child in ipairs(self.children) do
        local cf = child.frame
        if cf and cf:IsShown() then
            table.insert(visible, cf)
            local w = cf:GetWidth() or 0
            local h = cf:GetHeight() or 0
            totalWidth = totalWidth + w
            if #visible > 1 then totalWidth = totalWidth + self.spacingX end
            if h > maxHeight then maxHeight = h end
        end
    end
    return visible, totalWidth, maxHeight
end

-- Left/Center/Right horizontal stacking with vertical alignment
function HorizontalLayoutGroup:Relayout()
    if not self.frame then return end

    -- Measure visible children first
    local visible, totalWidth = measureChildren(self)

    -- Compute initial X based on horizontal alignment
    local contentArea = self.frame:GetWidth() - (self.paddingLeft + self.paddingRight)
    local startX = self.paddingLeft
    if self.alignH == "CENTER" then
        startX = self.paddingLeft + math.max(0, (contentArea - totalWidth) / 2)
    elseif self.alignH == "RIGHT" then
        startX = self.paddingLeft + math.max(0, contentArea - totalWidth)
    end

    -- Place children
    local x = startX
    for _, cf in ipairs(visible) do
        cf:ClearAllPoints()
        if self.alignV == "TOP" then
            cf:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, -self.paddingTop)
        elseif self.alignV == "BOTTOM" then
            cf:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", x, self.paddingBottom)
        else -- CENTER vertically
            local offsetY = (self.paddingBottom - self.paddingTop) / 2
            cf:SetPoint("LEFT", self.frame, "LEFT", x, offsetY)
        end
        x = x + (cf:GetWidth() or 0) + self.spacingX
    end

    if self.autoSize then
        self:RequestAutoSize()
    end
end

return HorizontalLayoutGroup
