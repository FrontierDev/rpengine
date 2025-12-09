-- RPE_UI/Elements/MultiSelectDropdown.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local ButtonEl    = RPE_UI.Elements.TextButton

---@class MultiSelectDropdown: FrameElement
---@field button any
---@field values table
---@field choices any[]
---@field onChanged fun(self:MultiSelectDropdown, values:table)|nil
local MultiSelectDropdown = setmetatable({}, { __index = FrameElement })
MultiSelectDropdown.__index = MultiSelectDropdown
RPE_UI.Elements.MultiSelectDropdown = MultiSelectDropdown

local function _ctxMenu(btn, choices, onPick, currentValues, onSelectAll)
    if not (RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu) then return end
    RPE_UI.Common:ContextMenu(btn.frame or UIParent, function(level)
        if level ~= 1 then return end
        local info = UIDropDownMenu_CreateInfo()
        info.isTitle = true; info.notCheckable = true; info.text = "Select Categories"
        UIDropDownMenu_AddButton(info, level)
        
        -- Select All button
        local selectAllInfo = UIDropDownMenu_CreateInfo()
        selectAllInfo.text = "Select All"
        selectAllInfo.func = function() if onSelectAll then onSelectAll() end end
        selectAllInfo.notCheckable = true
        UIDropDownMenu_AddButton(selectAllInfo, level)
        
        -- Divider
        local dividerInfo = UIDropDownMenu_CreateInfo()
        dividerInfo.isTitle = true; dividerInfo.notCheckable = true; dividerInfo.text = ""
        UIDropDownMenu_AddButton(dividerInfo, level)
        
        for _, v in ipairs(choices or {}) do
            local nfo = UIDropDownMenu_CreateInfo()
            nfo.text = tostring(v)
            nfo.func = function() if onPick then onPick(v) end end
            nfo.checked = (currentValues[v] == true)
            nfo.keepShownOnClick = true
            UIDropDownMenu_AddButton(nfo, level)
        end
    end)
end

local function _formatValues(values)
    local count = 0
    for _, _ in pairs(values) do
        count = count + 1
    end
    return "Filters: " .. count
end

---@param name string
---@param opts table|nil -- { parent, width, height, values, choices, onChanged }
---@return MultiSelectDropdown
function MultiSelectDropdown:New(name, opts)
    opts = opts or {}
    local parent = (opts.parent and opts.parent.frame) or UIParent
    local w = opts.width or 180
    local h = opts.height or 20

    local f = CreateFrame("Frame", name, parent)
    f:SetSize(w, h)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parent, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local o = FrameElement.New(self, "MultiSelectDropdown", f, opts.parent)
    o.choices   = opts.choices or {}
    o.values    = {}
    o.onChanged = opts.onChanged

    -- Initialize with provided values
    if opts.values then
        if type(opts.values) == "table" then
            for _, v in ipairs(opts.values) do
                o.values[v] = true
            end
        end
    end

    o.button = ButtonEl:New(name .. "_Btn", {
        parent = o, width = w, height = h, text = _formatValues(o.values) ~= "Filters: 0" and _formatValues(o.values) or "Filters: 0",
        onClick = function(btn)
            _ctxMenu(btn, o.choices, function(v)
                if o.values[v] then
                    o.values[v] = nil
                else
                    o.values[v] = true
                end
                o:_updateButton()
                if o.onChanged then o.onChanged(o, o:GetValue()) end
            end, o.values, function()
                -- Select All handler
                for _, choice in ipairs(o.choices) do
                    o.values[choice] = true
                end
                o:_updateButton()
                if o.onChanged then o.onChanged(o, o:GetValue()) end
            end)
        end,
        noBorder = true,
    })

    function o:_updateButton()
        local text = _formatValues(self.values)
        if self.button and self.button.SetText then self.button:SetText(text) end
    end

    function o:SetValue(values)
        self.values = {}
        if values then
            if type(values) == "table" then
                for _, v in ipairs(values) do
                    self.values[v] = true
                end
            end
        end
        self:_updateButton()
    end

    function o:GetValue()
        local list = {}
        for v, _ in pairs(self.values) do
            table.insert(list, v)
        end
        table.sort(list)
        return list
    end

    function o:GetValueAsString()
        local list = self:GetValue()
        return table.concat(list, ",")
    end

    function o:SetChoices(list)
        self.choices = list or {}
    end

    function o:SetOnChanged(cb)
        self.onChanged = cb
    end

    function o:SetSize(nw, nh)
        nh = nh or h
        self.frame:SetSize(nw, nh)
        if self.button and self.button.SetSize then self.button:SetSize(nw, nh) end
    end

    return o
end

return MultiSelectDropdown
