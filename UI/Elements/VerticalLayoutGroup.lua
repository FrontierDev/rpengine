-- RPE_UI/Elements/VerticalLayoutGroup.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class VerticalLayoutGroup: FrameElement
---@field name string
---@field paddingLeft number
---@field paddingRight number
---@field paddingTop number
---@field paddingBottom number
---@field spacingY number
---@field alignH "LEFT"|"CENTER"|"RIGHT"
---@field autoSize boolean
---@field autoSizePadX number
---@field autoSizePadY number
---@field fillWidth boolean        -- if true, force children to the group's inner width
local VerticalLayoutGroup = setmetatable({}, { __index = FrameElement })
VerticalLayoutGroup.__index = VerticalLayoutGroup
RPE_UI.Elements.VerticalLayoutGroup = VerticalLayoutGroup

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
---@return VerticalLayoutGroup
function VerticalLayoutGroup:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "VerticalLayoutGroup:New requires opts.parent")


    local parentFrame = opts.parent.frame
    local f = CreateFrame("Frame", name, parentFrame)
    f:SetSize(opts.width or 200, opts.height or 200)
    f:SetPoint(opts.point or "TOPLEFT", opts.relativeTo or parentFrame, opts.relativePoint or "TOPLEFT", opts.x or 0, opts.y or 0)

    ---@type VerticalLayoutGroup
    local o = FrameElement.New(self, "VerticalLayoutGroup", f, opts.parent)

    o.name = opts.name
    o.paddingLeft, o.paddingRight, o.paddingTop, o.paddingBottom = readPadding(opts)
    o.spacingY = opts.spacingY or 6
    o.alignH   = (opts.alignH == "LEFT" or opts.alignH == "RIGHT") and opts.alignH or "CENTER"

    -- sizing
    o.autoSize     = opts.autoSize or false
    o.autoSizePadX = opts.autoSizePadX or 0
    o.autoSizePadY = opts.autoSizePadY or 0
    o.fillWidth    = opts.fillWidth or false

    f:SetScript("OnSizeChanged", function() o:Relayout() end)
    return o
end

function VerticalLayoutGroup:SetPadding(left, right, top, bottom)
    self.paddingLeft  = left or 0
    self.paddingRight = right or 0
    self.paddingTop   = top or 0
    self.paddingBottom= bottom or 0
    self:Relayout()
end

function VerticalLayoutGroup:SetSpacingY(spacing)
    self.spacingY = spacing or 0
    self:Relayout()
end

function VerticalLayoutGroup:SetAlignH(align)
    if align == "LEFT" or align == "RIGHT" or align == "CENTER" then
        self.alignH = align
        self:Relayout()
    end
end

function VerticalLayoutGroup:SetFillWidth(fill)
    self.fillWidth = not not fill
    self:Relayout()
end

function VerticalLayoutGroup:Add(child)
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

-- Top -> bottom stacking (with optional fillWidth and proper horizontal alignment)
function VerticalLayoutGroup:Relayout()
    if not self.frame then return end

    local prev = nil
    local innerW = math.max(0, (self.frame:GetWidth() or 0) - (self.paddingLeft + self.paddingRight))

    for _, child in ipairs(self.children) do
        local cf = child.frame
        if cf and cf:IsShown() then
            cf:ClearAllPoints()

            -- Optional: force child width to inner width
            if self.fillWidth and innerW > 0 then
                pcall(function() cf:SetWidth(innerW) end)
            end

            if not prev then
                if self.alignH == "LEFT" then
                    cf:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.paddingLeft, -self.paddingTop)
                elseif self.alignH == "RIGHT" then
                    cf:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -self.paddingRight, -self.paddingTop)
                else
                    local offsetX = (self.paddingLeft - self.paddingRight) / 2
                    cf:SetPoint("TOP", self.frame, "TOP", offsetX, -self.paddingTop)
                end
            else
                if self.alignH == "LEFT" then
                    cf:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -self.spacingY)
                elseif self.alignH == "RIGHT" then
                    cf:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -self.spacingY)
                else
                    cf:SetPoint("TOP", prev, "BOTTOM", 0, -self.spacingY)
                end
            end

            prev = cf
        end
    end

    if self.autoSize then
        self:RequestAutoSize()
    end
end

return VerticalLayoutGroup
