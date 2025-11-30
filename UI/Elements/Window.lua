-- RPE_UI/Elements/Window.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class FrameWithBackdrop: Frame
---@field SetBackdrop fun(self:FrameWithBackdrop, backdrop:table)
---@field SetBackdropColor fun(self:FrameWithBackdrop, r:number, g:number, b:number, a?:number)

---@class Window: FrameElement
---@field frame FrameWithBackdrop
---@field autoSize boolean
---@field autoSizePadX number
---@field autoSizePadY number
---@field _noBackground boolean
local Window = setmetatable({}, { __index = FrameElement })
Window.__index = Window
RPE_UI.Elements.Window = Window

-- Resolve a usable parent frame from either a FrameElement or a Blizzard frame
local function ResolveParentFrame(p)
    if not p then return UIParent end
    -- If they passed a FrameElement (has .frame)
    if type(p) == "table" and p.frame and type(p.frame.GetObjectType) == "function" then
        return p.frame
    end
    -- If they passed a Blizzard frame directly
    if type(p) == "table" and type(p.GetObjectType) == "function" then
        return p
    end
    return UIParent
end

---@param name string
---@param opts table|nil
---@return Window
function Window:New(name, opts)
    opts = opts or {}
    local parentFrame = ResolveParentFrame(opts.parent)

    local f = CreateFrame("Frame", name, parentFrame, "BackdropTemplate")

    ---@type FrameWithBackdrop
    local f = CreateFrame("Frame", name, parentFrame, "BackdropTemplate")
    f:SetSize(opts.width or 480, opts.height or 320)
    f:SetPoint(
        opts.point or "CENTER",
        opts.relativeTo or parentFrame,
        opts.pointRelative or opts.relativePoint or "CENTER",
        opts.x or 0,
        opts.y or 0
    )
    
    -- Visuals: plain background (no border/title)
    if not opts.noBackground then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        local r,g,b,a = C.Get("background")
        f:SetBackdropColor(r,g,b,a)
    else
        f:SetBackdropColor(1,1,1,0)
    end

    -- ENFORCE: Windows are movable
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    if opts.clampToScreen ~= false then f:SetClampedToScreen(true) end

    ---@type Window
    local o = FrameElement.New(self, "Window", f, opts.parent)
    o.autoSize     = opts.autoSize or false
    o.autoSizePadX = opts.autoSizePadX or 0
    o.autoSizePadY = opts.autoSizePadY or 0
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

function Window:Add(child)
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

function Window:ApplyPalette()
    -- Update background color from palette
    if not self._noBackground and self.frame then
        local r, g, b, a = C.Get("background")
        self.frame:SetBackdropColor(r, g, b, a)
    end
end

return Window
