-- RPE_UI/Elements/Input.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class Input: FrameElement
---@field editBox EditBox
---@field onChanged fun(self:Input, text:string)|nil
local Input = setmetatable({}, { __index = FrameElement })
Input.__index = Input
RPE_UI.Elements.Input = Input

---@param name string
---@param opts table|nil  -- { parent, width, height, text, autoFocus, onChanged }
---@return Input
function Input:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = opts.width or 200
    local h = opts.height or 22

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local eb = CreateFrame("EditBox", name .. "_EB", f, "InputBoxTemplate")
    eb:SetAutoFocus(opts.autoFocus or false)
    eb:ClearAllPoints()
    eb:SetPoint("LEFT", 4, 0)
    eb:SetPoint("RIGHT", -4, 0)
    eb:SetHeight(h - 4)
    eb:SetText(opts.text or "")

    local o = FrameElement.New(self, "Input", f, opts.parent)
    o.editBox = eb
    o.onChanged = opts.onChanged

    eb:SetScript("OnTextChanged", function()
        if o.onChanged then o.onChanged(o, eb:GetText() or "") end
    end)

    function o:SetText(t) self.editBox:SetText(t or "") end
    function o:GetText()  return self.editBox:GetText() or "" end
    function o:SetOnChanged(cb) self.onChanged = cb end
    function o:SetSize(nw, nh)
        nh = nh or self.frame:GetHeight()
        self.frame:SetSize(nw, nh)
        self.editBox:SetHeight(nh - 4)
        self.editBox:ClearAllPoints()
        self.editBox:SetPoint("LEFT", 4, 0)
        self.editBox:SetPoint("RIGHT", -4, 0)
    end

    return o
end

return Input
