-- RPE_UI/Elements/Checkbox.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class Checkbox: FrameElement
---@field check CheckButton
---@field onChanged fun(self:Checkbox, checked:boolean)|nil
local Checkbox = setmetatable({}, { __index = FrameElement })
Checkbox.__index = Checkbox
RPE_UI.Elements.Checkbox = Checkbox

---@param name string
---@param opts table|nil -- { parent, width, height, checked, onChanged }
---@return Checkbox
function Checkbox:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = opts.width or 20
    local h = opts.height or 20

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local cb = CreateFrame("CheckButton", name .. "_CB", f, "UICheckButtonTemplate")
    cb:ClearAllPoints()
    cb:SetPoint("CENTER", f, "CENTER", 0, 0)
    cb:SetChecked(not not opts.checked)  -- Use 'not not' to convert any value to boolean, where 0/nil/false = false, and 1/true/string = true

    local o = FrameElement.New(self, "Checkbox", f, opts.parent)
    o.check = cb
    o.onChanged = opts.onChanged

    cb:SetScript("OnClick", function(self)
        -- Defer callback to next frame so checked state is updated
        C_Timer.After(0, function()
            if o.onChanged then o.onChanged(o, self:GetChecked() and true or false) end
        end)
    end)

    function o:SetChecked(b) self.check:SetChecked(not not b); if self.onChanged then self.onChanged(self, self:IsChecked()) end end
    function o:IsChecked() return self.check:GetChecked() and true or false end
    function o:SetOnChanged(cb) self.onChanged = cb end

    return o
end

return Checkbox
