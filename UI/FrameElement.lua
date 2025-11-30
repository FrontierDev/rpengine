-- RPE_UI/Core/FrameElement.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

---@class FrameElement
---@field frame Frame
---@field parent FrameElement|nil
---@field children FrameElement[]
---@field kind string
local FrameElement = {}
FrameElement.__index = FrameElement
RPE_UI.Elements.FrameElement = FrameElement

-- Utility: set child draw above parent (same strata, higher level)
local function AdoptDrawOrder(childFrame, parentFrame, extra)
    if not parentFrame then return end
    childFrame:SetFrameStrata(parentFrame:GetFrameStrata())
    childFrame:SetFrameLevel(parentFrame:GetFrameLevel() + (extra or 1))
end

-- Base ctor (you normally call via subclasses)
function FrameElement:New(kind, frame, parent)
    local o = setmetatable({}, self)
    o.kind = kind or "FrameElement"
    o.frame = frame
    o.parent = parent
    o.children = {}

    if parent and parent.frame then
        frame:SetParent(parent.frame)
        AdoptDrawOrder(frame, parent.frame, #parent.children + 1)
        table.insert(parent.children, o)
    end

    return o
end

-- Parenting (re-parents the *frame* and maintains draw order)
function FrameElement:SetParent(parent)
    -- remove from old parent list
    if self.parent then
        for i, c in ipairs(self.parent.children) do
            if c == self then table.remove(self.parent.children, i) break end
        end
    end
    self.parent = parent
    if parent and parent.frame then
        self.frame:SetParent(parent.frame)
        AdoptDrawOrder(self.frame, parent.frame, #parent.children + 1)
        table.insert(parent.children, self)
    else
        self.frame:SetParent(UIParent)
    end
end

function FrameElement:AddChild(child) child:SetParent(self) end

-- Basic passthroughs
function FrameElement:SetPoint(...) self.frame:SetPoint(...) end
function FrameElement:ClearAllPoints() self.frame:ClearAllPoints() end
function FrameElement:SetAllPoints(target) self.frame:SetAllPoints(target or self.parent and self.parent.frame or nil) end
function FrameElement:SetSize(w,h) self.frame:SetSize(w,h) end
function FrameElement:Show() self.frame:Show() end
function FrameElement:Hide() self.frame:Hide() end
function FrameElement:SetAlpha(a) self.frame:SetAlpha(a) end
function FrameElement:SetStrata(s) self.frame:SetFrameStrata(s) end
function FrameElement:SetLevel(l) self.frame:SetFrameLevel(l) end
function FrameElement:GetName()
    return self.frame:GetName() or self.kind
end

-- Destroy (hard cleanup)
function FrameElement:Destroy()
    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end
    self.children = {}
    if self.frame then
        self.frame:Hide()
        self.frame:SetParent(nil)
        self.frame = nil
    end
    self.parent = nil
end

function FrameElement:ResizeToChildren(padX, padY)
    if not self.frame then return end
    padX, padY = padX or 0, padY or 0

    local minL, minB, maxR, maxT
    for _, child in ipairs(self.children or {}) do
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
        self.frame:SetSize((maxR - minL) + padX, (maxT - minB) + padY)
    end
end

function FrameElement:IsShown()
    return self.frame and self.frame:IsShown()
end

function FrameElement:RequestAutoSize()
    if self.autoSize then
        self:ResizeToChildren(self.autoSizePadX, self.autoSizePadY)
        if self.parent and self.parent.RequestAutoSize then
            self.parent:RequestAutoSize()
        end
    end
end

