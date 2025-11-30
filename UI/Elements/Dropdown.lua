-- RPE_UI/Elements/Dropdown.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local ButtonEl    = RPE_UI.Elements.TextButton  -- for a consistent look

---@class Dropdown: FrameElement
---@field button any
---@field value any
---@field choices any[]
---@field onChanged fun(self:Dropdown, value:any)|nil
local Dropdown = setmetatable({}, { __index = FrameElement })
Dropdown.__index = Dropdown
RPE_UI.Elements.Dropdown = Dropdown

local function _ctxMenu(btn, choices, onPick, current)
    if not (RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu) then return end
    RPE_UI.Common:ContextMenu(btn.frame or UIParent, function(level)
        if level ~= 1 then return end
        local info = UIDropDownMenu_CreateInfo()
        info.isTitle = true; info.notCheckable = true; info.text = "Select"
        UIDropDownMenu_AddButton(info, level)
        for _, v in ipairs(choices or {}) do
            local nfo = UIDropDownMenu_CreateInfo()
            nfo.text = tostring(v)
            nfo.func = function() if onPick then onPick(v) end end
            nfo.checked = (v == current)
            UIDropDownMenu_AddButton(nfo, level)
        end
    end)
end

---@param name string
---@param opts table|nil -- { parent, width, height, value, choices, onChanged }
---@return Dropdown
function Dropdown:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = opts.width or 180
    local h = opts.height or 20

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local o = FrameElement.New(self, "Dropdown", f, opts.parent)
    o.choices   = opts.choices or {}
    o.value     = opts.value ~= nil and opts.value or (o.choices[1] or "")
    o.onChanged = opts.onChanged

    o.button = ButtonEl:New(name .. "_Btn", {
        parent = o, width = w, height = h, text = tostring(o.value),
        onClick = function(btn)
            _ctxMenu(btn, o.choices, function(v)
                o:SetValue(v)
            end, o.value)
        end,
        noBorder = true,
    })

    function o:SetValue(v)
        o.value = v
        if o.button and o.button.SetText then o.button:SetText(tostring(v)) end
        if o.onChanged then o.onChanged(o, v) end
    end
    function o:GetValue() return o.value end
    function o:SetChoices(list)
        o.choices = list or {}
        if #o.choices > 0 and not o.value then o:SetValue(o.choices[1]) end
    end
    function o:SetOnChanged(cb) o.onChanged = cb end
    function o:SetSize(nw, nh)
        nh = nh or h
        self.frame:SetSize(nw, nh)
        if self.button and self.button.SetSize then self.button:SetSize(nw, nh) end
    end

    return o
end

return Dropdown
