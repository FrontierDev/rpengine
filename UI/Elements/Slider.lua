-- RPE_UI/Elements/Slider.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class SliderEl: FrameElement
---@field slider Slider
---@field valueText FontString
---@field onChanged fun(self:SliderEl, value:number)|nil
local SliderEl = setmetatable({}, { __index = FrameElement })
SliderEl.__index = SliderEl
RPE_UI.Elements.Slider = SliderEl

---@param name string
---@param opts table|nil -- { parent, width, height, min, max, step, value, onChanged, showValue }
---@return SliderEl
function SliderEl:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = opts.width or 240
    local h = opts.height or 22
    local minv = tonumber(opts.min) or 0
    local maxv = tonumber(opts.max) or 100
    local step = tonumber(opts.step) or 1
    local val  = tonumber(opts.value) or minv

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local s = CreateFrame("Slider", name .. "_SL", f, "OptionsSliderTemplate")
    s:ClearAllPoints()
    s:SetPoint("LEFT", f, "LEFT", 0, 0)
    s:SetPoint("RIGHT", f, "RIGHT", -40, 0)
    s:SetHeight(h)
    s:SetMinMaxValues(minv, maxv)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:SetValue(val)

    -- Kill default labels to avoid extra vertical space
    if s.Low then s.Low:Hide() end
    if s.High then s.High:Hide() end
    if s.Text then s.Text:Hide() end

    local vt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vt:SetPoint("LEFT", s, "RIGHT", 6, 0)
    vt:SetText(tostring(val))

    local o = FrameElement.New(self, "Slider", f, opts.parent)
    o.slider = s
    o.valueText = vt
    o.onChanged = opts.onChanged

    s:SetScript("OnValueChanged", function(_, v)
        if step and step > 0 then
            v = math.floor(v / step + 0.5) * step
            s:SetValue(v)
        end
        vt:SetText(tostring(v))
        if o.onChanged then o.onChanged(o, v) end
    end)

    function o:SetValue(v) self.slider:SetValue(tonumber(v) or minv) end
    function o:GetValue() return self.slider:GetValue() end
    function o:SetRange(a, b) self.slider:SetMinMaxValues(tonumber(a) or minv, tonumber(b) or maxv) end
    function o:SetOnChanged(cb) self.onChanged = cb end
    function o:SetSize(nw, nh)
        nh = nh or h
        self.frame:SetSize(nw, nh)
        self.slider:ClearAllPoints()
        self.slider:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
        self.slider:SetPoint("RIGHT", self.frame, "RIGHT", -40, 0)
        self.slider:SetHeight(nh)
    end

    return o
end

return SliderEl
