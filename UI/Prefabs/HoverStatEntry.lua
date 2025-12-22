RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local Text                  = RPE_UI.Elements.Text
local C                     = RPE_UI.Colors

---@class HoverStatEntry: FrameElement
---@field icon Texture
---@field name Text
---@field stat table|nil              -- CharacterStat
---@field profile table|nil           -- CharacterProfile
---@field tooltipTitle string|nil
---@field _iconSize number
---@field _onClick fun(self:HoverStatEntry, button?:string)|nil
local HoverStatEntry = setmetatable({}, { __index = FrameElement })
HoverStatEntry.__index = HoverStatEntry
RPE_UI.Prefabs.HoverStatEntry = HoverStatEntry

local function resolveBound(bound, profile)
    if type(bound) == "number" then return bound end
    if type(bound) == "table" and bound.ref and profile then
        -- Prefer profile:GetStat (respects active datasets), fallback to scanning flat profile.stats
        if type(profile.GetStat) == "function" then
            local ref = profile:GetStat(bound.ref)
            if ref and ref.GetValue then return ref:GetValue(profile) end
        end
        if profile.stats then
            for _, st in pairs(profile.stats) do
                if st and st.id == bound.ref and st.GetValue then return st:GetValue(profile) end
            end
        end
    end
    return nil
end

--- @param name string
--- @param opts table { parent, width, height, icon, label, stat, profile, onClick, tooltipTitle, iconSize }
function HoverStatEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "HoverStatEntry:New requires opts.parent")

    local width     = opts.width or 180
    local height    = opts.height or 18
    local iconSize  = opts.iconSize or 16

    local f = CreateFrame("Button", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)
    f:RegisterForClicks("LeftButtonUp")

    -- Palette-driven highlight
    local hl = f:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    C.ApplyHighlight(hl)
    hl:Hide()

    ---@type HoverStatEntry
    local o = FrameElement.New(self, "HoverStatEntry", f, opts.parent)
    o._iconSize    = iconSize
    o._onClick     = opts.onClick
    o.stat         = opts.stat
    o.profile      = opts.profile
    o.tooltipTitle = opts.tooltipTitle

    f:SetScript("OnEnter", function()
        hl:Show()
        local s, p = o.stat, o.profile
        if not (s and p) then return end
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        local title = o.tooltipTitle or s.name or s.id or "Stat"
        GameTooltip:AddLine(title, 1, 1, 1)

        local minV = resolveBound(s.min, p)
        local maxV = resolveBound(s.max, p)

        -- Breakdown lines
        GameTooltip:AddLine(("Base: %s"):format(tostring(s.base or 0)), 0.8, 0.8, 0.8)
        if (s.equipMod or 0) ~= 0 then
            GameTooltip:AddLine(("Equip: %+g"):format(s.equipMod), 0.8, 0.8, 0.8)
        end
        if (s.auraMod or 0) ~= 0 then
            GameTooltip:AddLine(("Aura:  %+g"):format(s.auraMod), 0.8, 0.8, 0.8)
        end
        if minV then GameTooltip:AddLine(("Min: %s"):format(tostring(minV)), 0.7, 0.7, 0.7) end
        if maxV and maxV ~= math.huge then
            GameTooltip:AddLine(("Max: %s"):format(tostring(maxV)), 0.7, 0.7, 0.7)
        end

        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() hl:Hide(); GameTooltip:Hide() end)
    f:SetScript("OnClick", function(_, btn) if o._onClick then o._onClick(o, btn) end end)

    -- Layout
    local hGroup = HorizontalLayoutGroup:New(name .. "_HGroup", {
        parent        = o,
        autoSize      = false,
        width         = width,
        height        = height,
        alignV        = "CENTER",
        spacingX      = 4,
        paddingLeft   = 0,
        paddingRight  = 0,
        paddingTop    = 0,
        paddingBottom = 0,
    })
    o:AddChild(hGroup)

    -- Icon
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local ic = iconContainer:CreateTexture(nil, "ARTWORK")
    ic:SetAllPoints()
    ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)
    o.icon = ic

    -- Name
    local nameWidth = width - iconSize - (2 * hGroup.spacingX)
    o.name = Text:New(name .. "_Name", {
        parent       = hGroup,
        width        = nameWidth,
        height       = height,
        text         = opts.label or "",
        fontTemplate = "GameFontNormalSmall",
    })
    o.name.fs:ClearAllPoints()
    o.name.fs:SetPoint("LEFT", o.name.frame, "LEFT", 0, 0)
    o.name.fs:SetJustifyH("LEFT")
    hGroup:Add(o.name)

    -- Initial populate if a stat was provided
    if o.stat then o:Refresh() else
        if opts.icon then ic:SetTexture(opts.icon) end
        if opts.label then o.name:SetText(opts.label) end
    end

    return o
end

function HoverStatEntry:SetIcon(path) if path then self.icon:SetTexture(path) end end
function HoverStatEntry:SetLabel(t)   self.name:SetText(t or "") end

function HoverStatEntry:SetStat(stat, profile)
    self.stat = stat
    self.profile = profile or self.profile
    self:Refresh()
end

function HoverStatEntry:Refresh()
    local s, p = self.stat, self.profile
    if not s then return end
    if s.icon then self.icon:SetTexture(s.icon) end
    self.name:SetText(s.name or s.id or "")
end

return HoverStatEntry
