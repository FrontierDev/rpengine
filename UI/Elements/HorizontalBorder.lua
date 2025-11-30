-- RPE_UI/Elements/HorizontalBorder.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class HorizontalBorder: FrameElement
---@field tex Texture
local HorizontalBorder = setmetatable({}, { __index = FrameElement })
HorizontalBorder.__index = HorizontalBorder
RPE_UI.Elements.HorizontalBorder = HorizontalBorder

---@param name string
---@param opts table|nil
---@return HorizontalBorder
function HorizontalBorder:New(name, opts)
    opts = opts or {}
    local parentFrame = opts.parent and opts.parent.frame or UIParent

    local f = CreateFrame("Frame", name, parentFrame)

    if opts.stretch then
        -- Stretch across parent's width
        f:SetHeight(opts.thickness or 1)
        f:SetPoint("LEFT",  parentFrame, "LEFT",   opts.x or 0, opts.y or 0)
        f:SetPoint("RIGHT", parentFrame, "RIGHT",  opts.x2 or 0, opts.y or 0)
    else
        -- Fixed width
        f:SetSize(opts.width or (parentFrame:GetWidth() or 200), opts.thickness or 1)
        f:SetPoint(opts.point or "CENTER", opts.relativeTo or parentFrame, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)
    end

    local tex = f:CreateTexture(nil, opts.layer or "BORDER")
    tex:SetAllPoints()
    C.ApplyDivider(tex) -- palette divider color

    ---@type HorizontalBorder
    local o = FrameElement.New(self, "HorizontalBorder", f, opts.parent)
    o.tex = tex
    
    -- Register as palette consumer
    C.RegisterConsumer(o)
    
    return o
end

function HorizontalBorder:SetColor(r, g, b, a)
    self.tex:SetColorTexture(r, g, b, a)
end

function HorizontalBorder:ApplyPalette()
    local r,g,b,a = C.Get("divider")
    self.tex:SetColorTexture(r, g, b, a)
end

function HorizontalBorder:GetName()
    return self.frame:GetName() or "HorizontalBorder"
end

return HorizontalBorder
