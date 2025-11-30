-- RPE_UI/Elements/Panel.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class FrameWithBackdrop: Frame
---@field SetBackdrop fun(self:FrameWithBackdrop, backdrop:table)
---@field SetBackdropColor fun(self:FrameWithBackdrop, r:number, g:number, b:number, a?:number)

---@class Panel: FrameElement
---@field frame FrameWithBackdrop
---@field autoSize boolean
---@field autoSizePadX number
---@field autoSizePadY number
---@field _paletteKey string
---@field _noBackground boolean
local Panel = setmetatable({}, { __index = FrameElement })
Panel.__index = Panel
RPE_UI.Elements.Panel = Panel

---@param name string
---@param opts table|nil
---@return Panel
function Panel:New(name, opts)
    opts = opts or {}
    local parentFrame = opts.parent and opts.parent.frame or UIParent

    ---@type FrameWithBackdrop
    local f = CreateFrame("Frame", name, parentFrame, "BackdropTemplate")
    f:SetSize(opts.width or 200, opts.height or 120)
    if opts.setAllPoints then
        f:SetAllPoints(parentFrame)
    else
        f:SetPoint(opts.point or "CENTER", opts.relativeTo or parentFrame, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)
    end

    -- Visuals: plain background (no border)
    if not opts.noBackground then
        if not opts.bgTexture then
            f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            local r,g,b,a = C.Get("background")
            f:SetBackdropColor(r,g,b,a)
        else
            f:SetBackdrop({ bgFile = opts.bgTexture })
            local r,g,b,a = C.Get(opts.paletteKey)
            f:SetBackdropColor(r,g,b,a)
        end
    end

    -- ENFORCE: Panels are not interactive/movable
    f:EnableMouse(false)
    f:SetMovable(false)
    f:RegisterForDrag()                -- clears any previous registrations
    f:SetScript("OnDragStart", nil)
    f:SetScript("OnDragStop",  nil)

    ---@type Panel
    local o = FrameElement.New(self, "Panel", f, opts.parent)
    o.autoSize     = opts.autoSize or false
    o.autoSizePadX = opts.autoSizePadX or 0
    o.autoSizePadY = opts.autoSizePadY or 0
    o._paletteKey  = opts.paletteKey or "background"
    o._noBackground = opts.noBackground or false
    
    -- Register as palette consumer so colors update when palette changes
    C.RegisterConsumer(o)
    
    return o
end

local function resizeToChildren(self)
    local minL, minB, maxR, maxT
    for _, child in ipairs(self.children) do
        local cf = child.frame
        if cf and cf:IsShown() then
            local l, b, w, h = cf:GetLeft(), cf:GetBottom(), cf:GetWidth(), cf:GetHeight()
            if l and b and w and h then
                local r, t = l + w, b + h
                minL = (minL and math.min(minL, l)) or l
                minB = (minB and math.min(minB, b)) or b
                maxR = (maxR and math.max(maxR, r)) or r
                maxT = (maxT and math.max(maxT, t)) or t
            end
        end
    end
    if minL and minB and maxR and maxT then
        self.frame:SetSize((maxR - minL) + self.autoSizePadX, (maxT - minB) + self.autoSizePadY)
    end
end

function Panel:Add(child)
    FrameElement.AddChild(self, child)
    if child.frame then
        child.frame:HookScript("OnShow", function()
            if self.autoSize then self:RequestAutoSize() end
        end)
        child.frame:HookScript("OnHide", function()
            if self.autoSize then self:RequestAutoSize() end
        end)
    end
    if self.autoSize then
        self:RequestAutoSize()
    end
end

function Panel:ApplyPalette()
    -- Update background color from palette
    if not self._noBackground and self.frame then
        local paletteKey = self._paletteKey or "background"
        local r, g, b, a = C.Get(paletteKey)
        self.frame:SetBackdropColor(r, g, b, a)
    end
end

return Panel
